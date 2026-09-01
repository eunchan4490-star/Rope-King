# 줄넘킹 캐릭터 상점 (외부 웹사이트)

Google Play 앱 안에서는 결제를 하지 않고, 이 별도 웹사이트에서 캐릭터 구매
신청 → 계좌이체 → 관리자 수동 승인 → 게임에서 캐릭터 사용 흐름을 처리하는
서비스입니다. Next.js(App Router) + Supabase(Auth/DB/RLS)만 사용하고,
Vercel 무료 플랜에서 그대로 돌아갑니다. 별도 서버, PG사 결제, 자동 계좌
조회는 없습니다 — 입금 확인은 관리자가 직접 합니다.

## 1. 전체 폴더 구조

```
character-shop/
├── README.md                     ← 이 파일 (설치/운영 가이드)
├── GAME_INTEGRATION.md           ← 게임(Godot) 개발자용 연동 가이드
├── package.json
├── next.config.js
├── tsconfig.json
├── tailwind.config.ts
├── postcss.config.js
├── .env.example                  ← 실제 값은 .env.local 에 (git에 커밋 금지)
├── supabase/
│   └── schema.sql                ← Supabase SQL Editor에서 한 번 실행
└── src/
    ├── middleware.ts             ← 세션 쿠키 갱신
    ├── lib/
    │   ├── auth.ts                ← 서버에서 "현재 로그인 유저 + 관리자 여부" 조회
    │   ├── types.ts
    │   └── supabase/
    │       ├── client.ts          ← 브라우저용 Supabase 클라이언트 (anon key)
    │       └── server.ts          ← 서버 컴포넌트/서버 액션용 (anon key, 쿠키 세션)
    ├── components/
    │   └── NavBar.tsx
    └── app/
        ├── layout.tsx
        ├── globals.css
        ├── page.tsx                        (/)
        ├── login/page.tsx                  (/login)
        ├── auth/callback/route.ts          (OAuth 콜백)
        ├── shop/
        │   ├── page.tsx                    (/shop — 목록)
        │   └── [itemId]/
        │       ├── page.tsx                (/shop/[id] — 구매 신청)
        │       ├── actions.ts              (주문 생성 Server Action)
        │       └── PurchaseForm.tsx
        ├── orders/
        │   ├── page.tsx                    (/orders — 내 주문 목록)
        │   └── [orderId]/page.tsx          (/orders/[id] — 주문 상세 + 계좌정보)
        └── admin/
            ├── page.tsx                    (/admin — 대기중 주문 목록)
            ├── actions.ts                  (승인/거절 Server Action)
            └── OrderRow.tsx
```

**서비스 키(service_role)는 이 프로젝트 어디에도 없습니다.** 관리자 승인/거절,
주문 생성은 Supabase의 `SECURITY DEFINER` Postgres 함수
(`create_order`, `approve_order`, `reject_order`)가 자기 자신 안에서
`auth.uid()` / `is_admin()`을 다시 검사하는 방식으로 안전하게 처리합니다.
자세한 내용은 `supabase/schema.sql` 주석을 참고하세요.

## 2. 필요한 환경변수

`.env.example`을 복사해 `.env.local`을 만들고 값을 채우세요.

| 변수 | 설명 |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase 프로젝트 URL (Project Settings → API) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon(public) key. **service_role key는 절대 넣지 마세요.** |
| `DEPOSIT_BANK_NAME` | 입금 안내에 표시할 은행명 |
| `DEPOSIT_ACCOUNT_NUMBER` | 입금 안내에 표시할 계좌번호 |
| `DEPOSIT_ACCOUNT_HOLDER` | 입금 안내에 표시할 예금주명 |
| `NEXT_PUBLIC_SITE_URL` | 배포 후 사이트 URL (로컬은 `http://localhost:3000`) |

```bash
cp .env.example .env.local
# .env.local을 열어 값 채우기
```

## 3. Supabase 생성/설정 방법

1. https://supabase.com 에서 새 프로젝트 생성 (Free plan).
2. Project Settings → API에서 **Project URL**과 **anon public key**를 복사해
   `.env.local`에 넣습니다.
3. Authentication → Providers → Google을 켭니다. (아래 5번 참고)
4. Authentication → URL Configuration → **Redirect URLs**에 다음을 추가합니다.
   - `http://localhost:3000/auth/callback` (로컬 테스트용)
   - `https://<your-vercel-domain>/auth/callback` (배포 후)

## 4. SQL 실행 방법

1. Supabase 대시보드 → **SQL Editor** → **New query**.
2. `supabase/schema.sql` 파일 내용을 전부 복사해 붙여넣고 **Run**.
3. 성공하면 `profiles`, `items`, `orders`, `owned_items` 테이블과
   `is_admin`, `create_order`, `approve_order`, `reject_order`,
   `get_my_owned_items` 함수, 그리고 테스트용 캐릭터 3종(스켈레/마녀/과학자,
   id는 게임 폴더명과 동일하게 `skele`/`witch`/`scientist`)이 생성됩니다.
4. 스키마를 다시 실행해도 안전합니다 (모두 `IF NOT EXISTS` / `OR REPLACE` /
   `ON CONFLICT`로 작성되어 있음).

## 5. Google 로그인 설정 방법

1. [Google Cloud Console](https://console.cloud.google.com/) → 새 프로젝트(또는
   기존 프로젝트) → **APIs & Services → Credentials**.
2. **Create Credentials → OAuth client ID → Web application**.
3. **Authorized redirect URIs**에 Supabase가 안내하는 콜백 URL을 추가합니다.
   Supabase 대시보드의 Authentication → Providers → Google 화면에 정확한
   URL이 표시됩니다 (형식: `https://<project-ref>.supabase.co/auth/v1/callback`).
4. 생성된 **Client ID**와 **Client Secret**을 Supabase 대시보드의
   Authentication → Providers → Google 설정에 붙여넣고 저장합니다.
5. 이 저장소의 `.env.local`에는 Google 키를 넣지 않습니다 — Google 연동은
   전부 Supabase 쪽 설정이고, 앱은 `supabase.auth.signInWithOAuth({provider:"google"})`
   만 호출합니다.

## 6. 로컬 실행 방법

```bash
cd character-shop
npm install
npm run dev
```

브라우저에서 http://localhost:3000 접속.

## 7. Vercel 배포 방법

1. 이 저장소를 GitHub에 올린 뒤 (또는 이미 올라와 있다면) Vercel에서
   **New Project → Import Git Repository**.
2. **Root Directory**를 `character-shop`으로 지정합니다 (모노레포이므로 중요).
3. Environment Variables에 `.env.local`과 동일한 키/값을 등록합니다
   (`NEXT_PUBLIC_SITE_URL`은 실제 배포 도메인, 예: `https://your-app.vercel.app`).
4. Deploy. 별도 도메인 없이 Vercel 기본 주소(`*.vercel.app`)로 바로 동작합니다.
5. 배포 후 Supabase Authentication → URL Configuration의 Redirect URLs에
   `https://<your-vercel-domain>/auth/callback`을 추가하는 것을 잊지 마세요.

## 8. 관리자 계정 지정 방법

1. 지정하고 싶은 사람이 사이트에서 Google로 **한 번 로그인**합니다
   (그래야 `profiles` 테이블에 행이 생깁니다).
2. Supabase SQL Editor에서:
   ```sql
   update public.profiles set role = 'admin' where email = 'you@example.com';
   ```
3. 그 계정으로 다시 로그인하면 네비게이션 바에 "관리자" 메뉴가 보이고
   `/admin`에 접근할 수 있습니다.

## 9. 주문 테스트 방법

1. 일반 계정으로 로그인 → `/shop` → 캐릭터 선택 → 입금자명 입력 →
   "구매 신청하기".
2. 주문 상세 페이지(`/orders/[id]`)에 주문번호와 입금 계좌 안내가 표시됩니다.
3. 관리자 계정으로 로그인 → `/admin` → 방금 만든 주문이 "대기중"으로 보입니다.
4. **승인**을 누르면: `orders.status`가 `approved`로 바뀌고, `approved_at`이
   기록되고, `owned_items`에 해당 캐릭터가 추가됩니다 (모두 `approve_order()`
   함수 안에서 원자적으로 처리).
5. 같은 승인 버튼을 실수로 다시 눌러도(또는 함수를 다시 호출해도) 캐릭터가
   중복 지급되지 않습니다 — 이미 `approved`면 아무 것도 하지 않고 조용히
   끝납니다.
6. 일반 계정으로 `/orders/[id]`를 다시 보면 상태가 "지급 완료"로 바뀝니다.

## 10. 게임에서 캐릭터 보유 목록 가져오는 방법

`GAME_INTEGRATION.md`에 전체 절차가 있습니다. 요약:

```js
// 게임 클라이언트(웹뷰/브라우저 기반이라고 가정)에서
const { data, error } = await supabase.rpc("get_my_owned_items");
// data === ["skele", "witch"] 형태의 string[] (본인 소유만, RLS+RPC로 강제)
```

## 보안 요약

- **RLS 전부 적용**: `profiles`, `items`, `orders`, `owned_items` 모두
  Row Level Security 켜짐. 일반 유저는 자기 것만 SELECT 가능, INSERT/UPDATE는
  직접 불가능 (RPC 함수를 통해서만).
- **가격 위조 불가**: 주문 생성은 항상 `create_order()` 함수가 서버(DB)에서
  `items.price`를 다시 읽어서 저장합니다. 클라이언트가 보낸 가격은 애초에
  받지도 않습니다.
- **user_id 위조 불가**: 주문 생성/조회 모두 `auth.uid()`(로그인 세션)를
  기준으로만 동작합니다. 클라이언트가 다른 사람의 `user_id`를 보내도
  무시됩니다.
- **관리자 승인 위조 불가**: `approve_order()`/`reject_order()`는 함수
  내부에서 `is_admin()`을 다시 검사합니다. 페이지 리다이렉트나 프론트엔드
  체크를 우회해도 DB 레벨에서 막힙니다.
- **service_role key 미사용**: 이 프로젝트는 service_role key를 아예
  쓰지 않습니다 (필요한 모든 권한 상승은 `SECURITY DEFINER` 함수로 좁게
  처리). 노출될 시크릿 자체가 하나 줄어듭니다.
