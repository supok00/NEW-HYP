#!/usr/bin/env python3
"""src/pages/*.html 본문을 공통 레이아웃(헤더·푸터)으로 감싸 루트에 HTML을 만든다.

GitHub Pages는 빌드 없이 루트의 HTML을 그대로 서빙하므로, 결과물도 함께 커밋한다.
헤더·푸터를 6개 페이지에 복붙하면 한 곳만 고쳐도 어긋나기 쉬워서 이렇게 나눴다.

사용: python3 tools/build.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
SITE = "https://supok00.github.io/NEW-HYP/"

NAV = [
    ("company.html", "회사소개", "About"),
    ("manpower.html", "호텔·인력서비스", "Outsourcing"),
    ("disinfection.html", "방역서비스", "Hygiene"),
    ("result.html", "사업실적", "Track record"),
]

ICON = {
    "arrow": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>',
    "arrow-left": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 12H5M11 6l-6 6 6 6"/></svg>',
    "up": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 19V5M6 11l6-6 6 6"/></svg>',
    "phone": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/></svg>',
    "download": '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 4v12M6 10l6 6 6-6M5 20h14"/></svg>',
}

LAYOUT = """<!doctype html>
<html lang="ko" class="no-js">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="theme-color" content="#15130f">
<meta property="og:type" content="website">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:image" content="{site}img/poster/main.jpg">
<meta property="og:locale" content="ko_KR">
<link rel="icon" href="img/favicon.ico">
<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/wanteddev/wanted-sans@v1.0.3/packages/wanted-sans/fonts/webfonts/variable/split/WantedSansVariable.min.css">
<link rel="stylesheet" href="assets/css/style.css">
<script src="assets/js/main.js" defer></script>
</head>
<body data-header="{header}">
<a class="sr-only" href="#main">본문 바로가기</a>

<header class="header">
  <div class="container">
    <a class="logo" href="index.html" aria-label="HYP 홈"><img src="img/logo.svg" alt="HYP" width="72" height="34"></a>
    <nav class="gnb" aria-label="주 메뉴">{gnb}</nav>
    <div class="header-actions">
      <a class="btn btn-ghost dl" href="HYP.pptx" download>{i_download}회사소개서</a>
      <a class="btn btn-gold cta-btn" href="form.html">상담 신청</a>
      <button class="menu-btn" type="button" aria-label="메뉴 열기" aria-expanded="false" aria-controls="m-menu"><span></span></button>
    </div>
  </div>
</header>

<div class="m-menu" id="m-menu">
  <nav aria-label="모바일 메뉴">{mnav}</nav>
  <div class="m-foot">
    <a class="btn btn-gold" href="form.html">상담 신청 {i_arrow}</a>
    <a class="btn btn-ghost" href="tel:{tel_raw}">{i_phone}{tel}</a>
    <a class="btn btn-ghost" href="HYP.pptx" download>{i_download}회사소개서 다운로드</a>
  </div>
</div>

<main id="main">
{body}
</main>

<footer class="footer">
  <div class="container">
    <div class="footer-top">
      <div class="footer-brand">
        <img src="img/logo.svg" alt="HYP" width="85" height="40">
        <p>호텔 출신 전문가들이 만드는 서비스 인력 아웃소싱. 객실관리부터 방역까지, 고객의 모든 공간에서 최고의 가치를 만듭니다.</p>
      </div>
      <div class="footer-col">
        <h4>Menu</h4>
        <ul>{fnav}</ul>
      </div>
      <div class="footer-col">
        <h4>Contact</h4>
        <a class="big" href="tel:{tel_raw}">{tel}</a>
        <ul style="margin-top:12px"><li><a href="form.html">온라인 상담 신청</a></li><li><a href="HYP.pptx" download>회사소개서 다운로드</a></li></ul>
        <h4 style="margin-top:32px">About</h4>
        <ul><li><a href="company.html#greeting">인사말</a></li><li><a href="company.html#organization">조직도</a></li><li><a href="company.html#history">연혁</a></li><li><a href="company.html#info">회사정보</a></li></ul>
      </div>
      <div class="footer-col">
        <h4>Locations</h4>
        <address><b>서울·경기 본사</b><span>경기도 성남시 수정구 위례광장로 21-9, 1806호 (창곡동, 위례우남역KCC웰츠타워)</span></address>
        <address><b>제주 지점</b><span>제주도 서귀포시 중문상로17번길 52-17</span></address>
        <address><b>강릉 지점</b><span>강원도 강릉시 강릉대로 411, 3층</span></address>
        <a href="company.html#location" style="display:inline-block;margin-top:14px;color:var(--gold-2)">오시는 길 →</a>
      </div>
    </div>
    <div class="footer-bottom">
      <p class="biz"><span>(주)에이치와이피</span><span>대표 위종복</span><span>대표전화 {tel}</span></p>
      <p>© <span data-year>2026</span> HYP Co., Ltd. All rights reserved.</p>
    </div>
  </div>
</footer>

<div class="float" aria-label="빠른 메뉴">
  <a class="call" href="tel:{tel_raw}" aria-label="전화 상담 {tel}">{i_phone}</a>
  <button class="top" type="button" aria-label="맨 위로">{i_up}</button>
</div>

<div class="dialog" role="dialog" aria-modal="true" aria-labelledby="dlg-title">
  <div class="dialog-box">
    <h3 id="dlg-title"></h3>
    <p></p>
    <div class="acts">
      <a class="btn btn-gold" href="tel:{tel_raw}">{i_phone}전화 상담 {tel}</a>
      <button class="btn btn-line" type="button" data-close>닫기</button>
    </div>
  </div>
</div>
</body>
</html>
"""


def with_avif(html):
    """<img src="x.jpg"> 옆에 x.avif 가 있으면 <picture> 로 감싸 최신 브라우저는 AVIF를 받게 한다.
    AVIF는 tools/make-media.sh 가 만든다. CSS에서 picture는 display:contents 라 레이아웃에 영향 없다."""
    def repl(m):
        tag, src = m.group(0), m.group(1)
        avif = src[:-4] + ".avif"
        if not (ROOT / avif).exists():
            return tag
        return f'<picture><source srcset="{avif}" type="image/avif">{tag}</picture>'
    return re.sub(r'<img [^>]*?src="([^"]+\.jpg)"[^>]*>', repl, html)


def build():
    tel = "031-756-0449"
    out = []
    for page in sorted((SRC / "pages").glob("*.html")):
        raw = page.read_text(encoding="utf-8")
        # 맨 위 <!-- key: value --> 줄들을 메타데이터로 읽는다
        meta = dict(re.findall(r"^<!--\s*(\w+):\s*(.*?)\s*-->$", raw, re.M))
        body = re.sub(r"^<!--\s*\w+:.*?-->\n", "", raw, flags=re.M)
        for k, v in ICON.items():
            body = body.replace("{{icon:%s}}" % k, v)
        html = LAYOUT.format(
            title=meta.get("title", "HYP"),
            desc=meta.get("desc", ""),
            header=meta.get("header", "transparent"),
            site=SITE,
            gnb="".join(f'<a href="{h}">{t}</a>' for h, t, _ in NAV),
            mnav="".join(f'<a href="{h}">{t}<small>{e}</small></a>' for h, t, e in NAV),
            fnav="".join(f'<li><a href="{h}">{t}</a></li>' for h, t, _ in NAV),
            tel=tel, tel_raw=tel.replace("-", ""),
            i_download=ICON["download"], i_phone=ICON["phone"], i_up=ICON["up"], i_arrow=ICON["arrow"],
            body=with_avif(body.strip()),
        )
        (ROOT / page.name).write_text(html, encoding="utf-8")
        out.append(page.name)
    print("built:", ", ".join(out))


if __name__ == "__main__":
    build()
