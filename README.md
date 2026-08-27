# 줄넘킹 (Rope King)

Godot 4로 만든 세로형 모바일 줄넘기 타이밍 게임 프로토타입입니다. 줄이 빨간색으로 바뀔 때 점프해서 발밑을 통과하면 점수가 오릅니다. 4회 성공부터 엇박자·급가속·물결 리듬이 번갈아 등장하며, 줄이 통과할 때 충분히 뛰지 못하면 게임 오버됩니다.

## 실행

1. Godot 4.3 이상에서 이 폴더의 `project.godot`을 엽니다.
2. 편집기에서 **F6/F5**를 누르거나 우측 상단 실행 버튼을 누릅니다.
3. 화면 터치, 마우스 클릭 또는 `Space`로 점프합니다.

게임은 720×1280 세로 화면을 기준으로 제작됐으며 다양한 화면 크기에 맞게 비율을 유지합니다. 외부 이미지·폰트 에셋은 필요하지 않습니다.

## 플레이어 캐릭터 교체

투명 배경 캐릭터 이미지를 `assets/player/player.png`로 넣으면 기존 도형 캐릭터 대신 자동으로 표시됩니다. 비율 유지, 크기 조절, 발 위치 정렬이 자동 적용되며 이미지가 없을 때는 기존 캐릭터로 돌아갑니다. 세부 조절 방법은 `assets/player/README.md`를 참고합니다.

## Android 테스트 빌드

1. Godot의 **Editor Settings > Export > Android**에서 Android SDK와 Java 경로를 설정합니다.
2. **Project > Install Android Build Template**를 실행합니다.
3. **Project > Export**에서 Android 프리셋을 추가합니다.
4. 디버그 APK를 내보낸 뒤 휴대폰에 설치합니다.

> Android APK를 만들려면 Godot 편집기, Android SDK/JDK, Export Template가 빌드 PC에 설치되어 있어야 합니다.

## 원격 작업 흐름

1. 원격으로 수정 명령을 전달합니다.
2. 수정이 끝난 뒤 **"설치할 수 있게 해"**라고 말합니다.
3. 프로젝트 검증, 선택한 변경 파일의 커밋과 push, GitHub APK 빌드 확인이 자동으로 이어집니다.
4. 빌드가 성공하면 GitHub 다운로드 링크와 이 PC에 내려받은 APK 경로를 안내합니다.

자동 배포는 `tools/publish-android.ps1`을 사용합니다. 예를 들어 메인 게임 스크립트를 배포하려면 다음과 같이 실행합니다.

```powershell
.\tools\publish-android.ps1 -Message "fix: update jump timing" -Files "scripts/main.gd"
```

여러 파일을 함께 배포할 때는 `-Files @("파일1", "파일2")`처럼 배열로 전달합니다.

GitHub 자동 업로드를 시작하려면 이 PC에서 `gh auth login`으로 다시 로그인하고, 연결할 저장소를 한 번 정해야 합니다.

## 휴대폰에 APK 설치

`main` 브랜치에 코드가 올라오면 GitHub Actions가 디버그 APK를 자동 생성합니다.

1. 저장소의 **Actions > Android APK**로 이동합니다.
2. 가장 최근의 성공한 실행을 엽니다.
3. **Artifacts**에서 `Rope-King-Android`를 다운로드합니다.
4. ZIP 압축을 풀고 APK를 실행해 설치합니다.

Android가 설치를 차단하면 브라우저 또는 파일 관리자의 **알 수 없는 앱 설치** 권한을 허용해야 합니다. 테스트용 APK는 30일 동안 보관됩니다.
