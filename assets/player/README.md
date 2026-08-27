# 플레이어 스프라이트 교체

이 폴더에 투명 배경 PNG를 `player.png`라는 이름으로 넣으면 게임 실행 시 자동으로 플레이어 캐릭터에 적용됩니다.

- 권장 형식: 투명 배경 PNG
- 파일 위치: `assets/player/player.png`
- 이미지 비율은 유지되며 최대 160×190 범위로 자동 조절됩니다.
- 이미지의 아래쪽 중앙이 플레이어의 발 위치에 맞춰집니다.
- `player.png`가 없으면 기존 도형 캐릭터가 표시됩니다.

Godot 편집기에서는 `Main` 노드의 **Player Sprite** 항목에 이미지를 직접 지정할 수도 있습니다. 위치나 크기를 조절해야 하면 같은 항목의 `Player Sprite Max Size`와 `Player Sprite Ground Offset` 값을 변경합니다.
