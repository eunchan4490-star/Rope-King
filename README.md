# 줄넘킹 (Rope King)

Godot 4로 만든 세로형 모바일 줄넘기 타이밍 게임 프로토타입입니다. 줄이 발밑을 통과하는 순간 화면을 터치하면 점수가 오르고, 성공할수록 속도가 빨라집니다. 실패하면 현재 점수와 속도가 초기화됩니다.

## 실행

1. Godot 4.3 이상에서 이 폴더의 `project.godot`을 엽니다.
2. 편집기에서 **F6/F5**를 누르거나 우측 상단 실행 버튼을 누릅니다.
3. 화면 터치, 마우스 클릭 또는 `Space`로 점프합니다.

게임은 720×1280 세로 화면을 기준으로 제작됐으며 다양한 화면 크기에 맞게 비율을 유지합니다. 외부 이미지·폰트 에셋은 필요하지 않습니다.

## Android 테스트 빌드

1. Godot의 **Editor Settings > Export > Android**에서 Android SDK와 Java 경로를 설정합니다.
2. **Project > Install Android Build Template**를 실행합니다.
3. **Project > Export**에서 Android 프리셋을 추가합니다.
4. 디버그 APK를 내보낸 뒤 휴대폰에 설치합니다.

> Android APK를 만들려면 Godot 편집기, Android SDK/JDK, Export Template가 빌드 PC에 설치되어 있어야 합니다.

## 원격 작업 흐름

1. 원격으로 수정 명령을 전달합니다.
2. 수정 후 검증하고 Git 커밋을 만듭니다.
3. GitHub 저장소로 push합니다.
4. 휴대폰에서 GitHub의 최신 소스를 내려받아 Godot Android Editor에서 열거나, CI가 만든 APK를 설치해 테스트합니다.

GitHub 자동 업로드를 시작하려면 이 PC에서 `gh auth login`으로 다시 로그인하고, 연결할 저장소를 한 번 정해야 합니다.
