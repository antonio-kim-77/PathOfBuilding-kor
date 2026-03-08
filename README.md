# Path of Building 한글판 (Korean)
## 패스 오브 엑자일 오프라인 빌드 플래너 — 한국어 번역 버전

> **Path of Building** 한글 버전입니다. UI, 패시브 스킬 트리, 아이템 등이 한국어로 번역되어 있습니다.
> 원본: [PathOfBuildingCommunity/PathOfBuilding](https://github.com/PathOfBuildingCommunity/PathOfBuilding)

<p float="middle">
  <img alt="Tree tab" src="https://github.com/user-attachments/assets/0826b7ab-84ba-440f-be52-2f216f13e75c" width="48%" />
  <img alt="Items tab" src="https://github.com/user-attachments/assets/e5af1326-7e22-43d8-ab12-aa5500da611a" width="48%" />
</p>

### 주요 기능
* 종합적인 공격 + 방어 계산:
  * 스킬 DPS, 지속 피해, 생명력/마나/에너지 보호막 합계 등을 계산합니다
  * 오라, 버프, 충전, 저주, 몬스터 저항 등을 반영하여 실질 DPS를 추정합니다
  * 생명력/마나 점유량도 계산합니다
  * 사이드바에 캐릭터 스탯 요약을 표시하며, 상세 계산 탭에서 스탯이 어떻게 산출되었는지 확인할 수 있습니다
  * 모든 스킬과 서포트 젬을 지원하며, 대부분의 패시브와 아이템 속성을 지원합니다
    * 프로그램 전반에서 지원되는 속성은 파란색, 미지원 속성은 빨간색으로 표시됩니다
  * 미니언 완벽 지원
  * 파티 플레이 및 서포트 빌드 지원
* 패시브 스킬 트리 플래너:
  * 대부분의 반경/전환 주얼 및 시간을 초월한 주얼 지원
  * 대체 경로 추적 기능 (Shift를 누른 채 노드 위를 지나간 후 클릭하면 한 번에 배분)
  * 공격/방어 계산과 완전 통합 — 각 노드가 캐릭터에 미치는 영향을 즉시 확인 가능
  * PathOfExile.com 및 PoEPlanner.com 패시브 트리 링크 불러오기 지원 (PoEURL.com 단축 링크도 가능)
* 스킬 플래너:
  * 빌드에 메인 스킬과 보조 스킬을 원하는 만큼 추가 가능
  * 보조 스킬(오라, 저주, 버프)을 켜고 끌 수 있습니다
  * 스킬이 장착된 아이템의 소켓 젬 속성을 자동 적용
  * 아이템이 부여하는 서포트 젬을 자동 적용
* 아이템 플래너:
  * 게임 내 아이템을 복사하여 프로그램에 바로 붙여넣기 가능
  * 타락하지 않은 아이템에 퀄리티를 자동 추가
  * 트레이드 사이트에서 가장 효과적인 아이템 검색
  * 공격/방어 계산과 완전 통합 — 특정 아이템이 얼마나 업그레이드되는지 즉시 확인 가능
  * 현재 게임에 존재하는 모든 고유 아이템의 검색 가능한 데이터베이스 내장 (아직 출시되지 않은 것도 일부 포함)
    * 빌드에 고유 아이템 추가 시 속성 수치를 선택 가능
    * 모든 리그 전용 아이템 및 레거시 변형 포함
  * 아이템 제작 시스템:
    * 게임 내 모든 기본 아이템 유형 선택 가능
    * 목록에서 접두사/접미사 속성 선택 가능
    * 마스터 및 에센스 속성을 포함한 커스텀 속성 추가 가능
  * 레어 아이템 템플릿 데이터베이스 내장:
    * 사용할 장비에 맞는 레어 아이템을 빌드용으로 생성 가능
    * 각 아이템에 표시될 속성과 수치를 필요에 맞게 선택
    * 대부분의 빌드를 커버하는 템플릿 제공
* 기타 기능:
  * 기존 캐릭터에서 패시브 트리, 아이템, 스킬 불러오기 가능
  * 공유 코드를 생성하여 다른 사용자와 빌드 공유
  * 자동 업데이트 — 대부분의 업데이트는 몇 초 만에 적용됩니다

## 다운로드 / Download
[Releases](https://github.com/antonio-kim-77/PathOfBuilding-kor/releases) 페이지에서 최신 빌드를 다운로드하세요.

## Changelog
You can find the full version history [here](CHANGELOG.md).

## Contribute
You can find instructions on how to contribute code and bug reports [here](CONTRIBUTING.md).

## Licence
[MIT](https://opensource.org/licenses/MIT)

For 3rd-party licences, see [LICENSE](LICENSE.md).
The licencing information is considered to be part of the documentation.
