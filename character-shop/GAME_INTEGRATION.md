# 게임(Godot) 연동 가이드

이 문서는 **문서만** 입니다 — `scripts/main.gd`(줄넘킹 게임)는 이 작업에서
건드리지 않았습니다. 게임 쪽에서 아래 내용을 실제로 구현할 때 참고하세요.

게임은 이미 `scripts/main.gd`에서 `SUPABASE_URL` / `SUPABASE_ANON_KEY`를
`HTTPRequest` 노드로 호출해서 랭킹(`leaderboard` 테이블)을 읽고 쓰고
있습니다. 캐릭터 상점도 **같은 Supabase 프로젝트**(같은 URL/anon key)를
가리키기만 하면, 그 위에 이 문서의 호출들을 추가하는 방식으로 연동됩니다.
Godot에는 공식 Supabase SDK가 없으므로, 전부 REST(HTTPRequest) 방식으로
설명합니다.

## 0. 전제

- 웹사이트(`character-shop`)와 게임이 **같은** `NEXT_PUBLIC_SUPABASE_URL` /
  anon key를 가리켜야 합니다. 게임의 `SUPABASE_URL`/`SUPABASE_ANON_KEY`
  상수를 캐릭터 상점의 `.env.local`에 넣은 값과 동일하게 맞추세요.
- `supabase/schema.sql`을 그 프로젝트에 먼저 실행해 두어야 합니다.

## 1. Supabase 로그인 방법 (Google, REST 기반)

Godot에는 웹뷰가 기본 내장되어 있지 않으므로, 실전에서는 보통 아래 둘 중
하나를 씁니다.

- **웹 빌드(HTML5 export)**: 브라우저에서 실행되므로 `JavaScriptBridge`로
  브라우저의 `window.location`을 Supabase의 OAuth authorize URL로 이동시키고,
  콜백에서 URL 프래그먼트(`#access_token=...`)를 읽어오는 방식이 가장
  간단합니다.
  ```gdscript
  var authorize_url := "%s/auth/v1/authorize?provider=google&redirect_to=%s" % [
      SUPABASE_URL, "https://your-game-domain.example/game.html"
  ]
  JavaScriptBridge.eval("window.location.href = '%s'" % authorize_url, true)
  # 리다이렉트되어 돌아온 뒤, 아래 스니펫으로 URL 프래그먼트에서 토큰을 읽습니다.
  var fragment := JavaScriptBridge.eval("window.location.hash", true) as String
  ```
- **Android APK**: `OS.shell_open()`으로 시스템 브라우저를 열어 Supabase
  authorize URL로 보내고, 앱을 커스텀 URL 스킴(예: `ropeking://auth-callback`)의
  딥링크로 등록해 로그인 완료 후 앱으로 돌아오게 합니다. 이 부분은 Android
  매니페스트에 인텐트 필터를 추가하는 별도 네이티브 작업이 필요합니다
  (이 문서 범위 밖 — 실제 구현 시 별도로 다뤄야 합니다).

두 경우 모두 최종적으로 얻는 것은 **`access_token`(JWT)**과
**`refresh_token`** 문자열입니다. 이후 모든 API 호출은 이 `access_token`을
`Authorization: Bearer <access_token>` 헤더로 붙여서 보냅니다 — 이래야
Supabase가 "누가 요청했는지"(`auth.uid()`)를 알고 RLS를 적용합니다.

## 2. access token 얻는 방법 (요약)

| 방식 | access_token을 얻는 곳 |
|---|---|
| 웹 빌드 | OAuth 리다이렉트 후 URL의 `#access_token=...&refresh_token=...` 프래그먼트 |
| 이메일 로그인(대안) | `POST {SUPABASE_URL}/auth/v1/token?grant_type=password` 응답의 `access_token` |

토큰을 얻으면 게임 쪽에 안전하게 보관하세요 (웹 빌드는 `localStorage`,
Android는 Godot의 `user://` 저장 파일 — 이미 `RopeSaveManager`가 세이브
파일을 다루고 있으니 같은 방식으로 저장하면 됩니다).

## 3. 현재 로그인 유저의 owned_items 조회 방법

`get_my_owned_items()` RPC 함수(스키마에 이미 포함됨)를 호출하면 문자열
배열이 바로 옵니다. 별도 파싱이 필요 없습니다.

```gdscript
func fetch_owned_characters(access_token: String) -> void:
    var url := "%s/rest/v1/rpc/get_my_owned_items" % SUPABASE_URL
    var headers := [
        "apikey: %s" % SUPABASE_ANON_KEY,
        "Authorization: Bearer %s" % access_token,
        "Content-Type: application/json",
    ]
    var request := HTTPRequest.new()
    add_child(request)
    request.request_completed.connect(_on_owned_items_fetched)
    request.request(url, headers, HTTPClient.METHOD_POST, "{}")

func _on_owned_items_fetched(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != OK or response_code != 200:
        # See "네트워크 실패 시 처리" below.
        return
    var owned_ids: Array = JSON.parse_string(body.get_string_from_utf8())
    # owned_ids == ["skeleton", "witch", ...]
```

`access_token` 없이(또는 만료된 토큰으로) 호출하면 빈 배열이 오거나 401이
옵니다 — 다른 사람 데이터가 섞여 나올 일은 없습니다 (RLS가
`user_id = auth.uid()`로 강제).

## 4. 캐릭터 ID와 게임 내부 캐릭터 ID를 매칭하는 방법

`items.id`(상점 DB)는 **게임의 `assets/characters/<id>/` 폴더 이름과
그대로 일치**하도록 만들어 두었습니다 — 예시 데이터도 게임 폴더명 그대로
`skele`, `witch`, `scientist`로 등록되어 있습니다. 새 상품을 추가할 때도
`items.id`를 게임 폴더명과 정확히 맞춰서 등록하면 별도 매핑 테이블 없이
바로 쓸 수 있습니다.

```gdscript
# owned_ids에서 곧바로 owned_character_ids에 합치면 끝.
for character_id in owned_ids:
    if character_ids.has(character_id) and not owned_character_ids.has(character_id):
        owned_character_ids.append(character_id)
```

폴더명과 상품 id를 다르게 유지하고 싶다면, `items` 테이블에
`game_character_id text` 컬럼을 추가해 상점 표시용 id와 게임 내부 id를
분리하는 방법도 있습니다 (스키마 마이그레이션 한 줄로 가능).

## 5. 로그아웃 처리

```gdscript
func sign_out(access_token: String) -> void:
    var url := "%s/auth/v1/logout" % SUPABASE_URL
    var headers := [
        "apikey: %s" % SUPABASE_ANON_KEY,
        "Authorization: Bearer %s" % access_token,
    ]
    var request := HTTPRequest.new()
    add_child(request)
    request.request(url, headers, HTTPClient.METHOD_POST, "")
    # 로컬에 저장해둔 access_token/refresh_token도 지워야 합니다.
```

## 6. 토큰 만료 및 갱신 방법

Supabase access token(JWT)은 기본 1시간 뒤 만료됩니다. 만료 전에
`refresh_token`으로 새 토큰을 받으세요.

```gdscript
func refresh_session(refresh_token: String) -> void:
    var url := "%s/auth/v1/token?grant_type=refresh_token" % SUPABASE_URL
    var headers := ["apikey: %s" % SUPABASE_ANON_KEY, "Content-Type: application/json"]
    var body := JSON.stringify({"refresh_token": refresh_token})
    var request := HTTPRequest.new()
    add_child(request)
    request.request_completed.connect(_on_session_refreshed)
    request.request(url, headers, HTTPClient.METHOD_POST, body)
    # 응답 JSON의 access_token/refresh_token으로 저장값을 갱신합니다.
```

실전에서는 `owned_items` 조회 요청이 401로 실패했을 때 자동으로
`refresh_session()`을 한 번 시도하고, 그래도 실패하면 로그아웃 처리(3번
로그인 화면 유도)하는 흐름을 권장합니다.

## 7. 네트워크 실패 시 처리 방법

- **오프라인/타임아웃**: `request_completed`의 `result != OK`인 경우 —
  이미 로컬에 저장된 `owned_character_ids`(마지막으로 성공했던 목록)를
  그대로 유지하고, 사용자에게 "네트워크 연결을 확인해주세요" 정도의
  안내만 표시합니다. 구매한 캐릭터를 오프라인이라고 잠그면 안 됩니다.
- **401 (토큰 만료)**: 6번의 리프레시를 한 번 시도 → 그래도 401이면
  로그인 화면으로.
- **그 외 4xx/5xx**: 조용히 재시도하지 말고, 다음에 상점/캐릭터 화면을
  열 때 다시 시도하는 정도로 충분합니다 (Supabase Free 플랜의 무료
  트래픽을 아끼기 위해 실패했다고 계속 재시도 루프를 돌리지 마세요).
- 랭킹 제출 로직(`_submit_score`, `_fetch_ranking`)이 이미 `result`/
  `response_code`를 확인하고 실패 시 조용히 넘어가는 패턴을 쓰고 있으니,
  같은 패턴을 그대로 재사용하면 됩니다.
