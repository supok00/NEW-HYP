# NEW-HYP

(주)에이치와이피(HYP) 홈페이지 리뉴얼본. 기존 사이트([supok00/HYP](https://github.com/supok00/HYP),
hypkorea.com 복원본)의 내용과 이미지를 바탕으로 디자인과 구조를 다시 만들었다.

- 공개 주소: https://supok00.github.io/NEW-HYP/ (GitHub Pages, `main` 브랜치 루트)
- 작성일: 2026-11-27
- 버전별 변경 내용과 결정 근거: [CHANGELOG.md](CHANGELOG.md) — **수정 전에 먼저 확인**

## 바뀐 점

| 항목 | 기존 HYP | NEW-HYP |
|---|---|---|
| 의존성 | jQuery 3.4 + slick 슬라이더, 로컬 OTF 폰트 | 의존성 없음 (바닐라 JS), Pretendard CDN |
| 레이아웃 | 고정 폭 슬라이더 위주 | 반응형 (모바일·태블릿·데스크톱), 벤토 그리드·가로 스크롤 카드 |
| 헤더 | 고정 | 스크롤 시 반투명 블러 → 내리면 숨김, 모바일 전체화면 메뉴 |
| 연출 | 슬라이더 | 스크롤 등장 애니메이션, 숫자 카운트업 (움직임 줄이기 설정 존중) |
| 문의 폼 | `mail_*.php` (GitHub Pages에서 동작 안 함) | 정적 폼 + 접수 엔드포인트 설정식 (아래 참고) |
| 지도 | iframe 3개 동시 로드 | 탭 전환 시 로드 |
| 접근성 | — | 시맨틱 마크업, 탭 키보드 조작, 본문 바로가기, 포커스 표시 |

페이지 파일명(`company.html`, `manpower.html`, `disinfection.html`, `result.html`, `form.html`)은
기존과 같게 유지해, 나중에 hypkorea.com 도메인을 이 저장소로 옮겨도 기존 링크가 깨지지 않는다.

## 구조

```
index.html … form.html   빌드 결과 (GitHub Pages가 그대로 서빙 — 직접 수정하지 말 것)
src/pages/*.html         페이지 본문 (여기를 고친다)
tools/build.py           본문 + 공통 헤더·푸터 → 루트 HTML 생성
assets/css/style.css     전체 스타일 (디자인 토큰은 :root)
assets/js/main.js        헤더·메뉴·탭·카운터·폼 처리
tools/make-media.sh      배경 영상 재편집 + 이미지 최적화(AVIF) — 원본은 ../hypkorea-site/img
img/                     사진(JPG + 같은 이름 AVIF), video/(배경 영상), poster/(영상 첫 화면)
HYP.pptx                 회사소개서 (다운로드 링크)
```

## 수정 방법

```sh
# 0) 사진·영상을 바꿨다면: bash tools/make-media.sh
# 1) src/pages/*.html 또는 tools/build.py(헤더·푸터·메뉴) 수정
python3 tools/build.py          # 2) 루트 HTML 재생성
python3 -m http.server 8000     # 3) http://localhost:8000 확인
git add -A && git commit -m "…" && git push   # 4) 1~2분 뒤 공개 주소에 반영
```

## 문의 폼 실제 접수 설정

GitHub Pages는 서버 코드를 실행할 수 없어 폼 내용을 직접 메일로 보낼 수 없다.
현재는 **신청 버튼을 누르면 대표전화 안내창**이 뜬다. 실제 접수를 받으려면:

1. [Formspree](https://formspree.io) 등 폼 수신 서비스에서 폼을 만들고 엔드포인트 URL을 받는다.
2. `assets/js/main.js` 맨 위 `FORM_ENDPOINT` 에 그 URL을 넣고 push 한다.

폼 필드(`type`, `category`, `name`, `company`, `phone`, `headcount`/`area`, `address`, `message`)가 그대로 전송된다.

## 방역 인증서 이미지

`img/disinfection/cert01~04.jpg` 는 기존 `se03_bg01~04.jpg` 에서 공개 웹에 불필요한 개인정보를
회색 띠로 가린 사본이다 (생년월일, 주민번호 앞자리, 신고증의 시청 담당자 이름·전화번호).
원본은 기존 HYP 저장소에 그대로 있다.

## 기존 사이트 대비 뺀 것

- 카카오톡 플로팅 버튼 — 기존에도 링크가 비어 있었다(`href="#"`). 채널 주소가 생기면 `tools/build.py`의 `.float` 에 추가
- 방역 살균제의 독성 수치 문구(“소금보다 274배…”) — 근거 자료 확인 전까지 생략
