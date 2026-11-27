/* HYP 2026 — 공통 스크립트 (의존성 없음) */

/* 문의 폼 수신 주소.
   GitHub Pages는 정적 호스팅이라 기존 mail_*.php가 동작하지 않는다.
   Formspree 같은 폼 수신 서비스의 엔드포인트를 넣으면 실제 접수되고,
   비워 두면 전화 상담 안내창을 띄운다. 예: "https://formspree.io/f/xxxxxxx" */
const FORM_ENDPOINT = "";
const TEL = "031-756-0449";

document.documentElement.classList.remove("no-js");

document.addEventListener("DOMContentLoaded", () => {
  const header = document.querySelector(".header");
  // 밝은 배경으로 시작하는 페이지는 처음부터 흰 헤더
  const alwaysSolid = document.body.dataset.header === "solid";
  let lastY = window.scrollY;

  function onScroll() {
    const y = window.scrollY;
    if (header) {
      header.classList.toggle("solid", alwaysSolid || y > 40);
      // 아래로 스크롤하면 숨기고, 위로 올리면 다시 보여 콘텐츠를 가리지 않게 한다
      const goingDown = y > lastY && y > 400;
      header.classList.toggle("hide", goingDown && !document.body.classList.contains("menu-open"));
      document.body.classList.toggle("hdr-hide", header.classList.contains("hide"));
    }
    document.querySelector(".float")?.classList.toggle("show", y > 600);
    lastY = y;
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* 모바일 메뉴 */
  const menuBtn = document.querySelector(".menu-btn");
  menuBtn?.addEventListener("click", () => {
    const open = document.body.classList.toggle("menu-open");
    menuBtn.setAttribute("aria-expanded", String(open));
  });
  document.querySelectorAll(".m-menu a").forEach(a =>
    a.addEventListener("click", () => document.body.classList.remove("menu-open"))
  );

  /* 맨 위로 */
  document.querySelector(".float .top")?.addEventListener("click", () =>
    window.scrollTo({ top: 0, behavior: "smooth" })
  );

  /* 스크롤 등장 + 숫자 카운트업 */
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const io = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (!e.isIntersecting) return;
      e.target.classList.add("in");
      e.target.querySelectorAll("[data-count]").forEach(countUp);
      io.unobserve(e.target);
    });
  }, { threshold: 0.15, rootMargin: "0px 0px -40px 0px" });
  document.querySelectorAll(".reveal").forEach(el => io.observe(el));

  function countUp(el) {
    const target = parseFloat(el.dataset.count);
    const fmt = n => Math.round(n).toLocaleString("ko-KR");
    if (reduce) { el.textContent = fmt(target); return; }
    const dur = 1400, t0 = performance.now();
    (function tick(t) {
      const p = Math.min(1, (t - t0) / dur);
      el.textContent = fmt(target * (1 - Math.pow(1 - p, 3)));
      if (p < 1) requestAnimationFrame(tick);
    })(t0);
  }

  /* 배경 영상: 화면 밖에 있으면 멈춰 배터리·CPU 절약, 데이터 절약 모드면 재생하지 않고 포스터만 */
  const saveData = navigator.connection && navigator.connection.saveData;
  document.querySelectorAll("video[autoplay]").forEach(v => {
    if (saveData || reduce) { v.removeAttribute("autoplay"); v.pause(); if (saveData) v.preload = "none"; return; }
    new IntersectionObserver(([e]) => { e.isIntersecting ? v.play().catch(() => {}) : v.pause(); }).observe(v);
  });

  /* 움직임 줄이기 설정이면 배경 영상 정지 (포스터만 표시) */
  if (reduce) document.querySelectorAll("video[autoplay]").forEach(v => { v.pause(); v.removeAttribute("autoplay"); });

  /* 실적 가로 스크롤 버튼 */
  document.querySelectorAll(".ref-wrap").forEach(wrap => {
    const track = wrap.querySelector(".ref-track");
    const step = () => (track.querySelector(".ref-card")?.offsetWidth || 360) + 20;
    wrap.querySelector("[data-dir=prev]")?.addEventListener("click", () => track.scrollBy({ left: -step(), behavior: "smooth" }));
    wrap.querySelector("[data-dir=next]")?.addEventListener("click", () => track.scrollBy({ left: step(), behavior: "smooth" }));
  });

  /* 탭 (지점 지도, 문의 종류) — role=tablist 공통 처리 */
  document.querySelectorAll("[role=tablist]").forEach(list => {
    const tabs = [...list.querySelectorAll("[role=tab]")];
    function select(tab) {
      tabs.forEach(t => {
        const on = t === tab;
        t.setAttribute("aria-selected", String(on));
        t.tabIndex = on ? 0 : -1;
        const panel = document.getElementById(t.getAttribute("aria-controls"));
        if (panel) {
          panel.hidden = !on;
          // 지도 iframe은 탭을 처음 열 때 로드해 초기 로딩을 가볍게 한다
          panel.querySelectorAll("iframe[data-src]").forEach(f => { if (on) { f.src = f.dataset.src; f.removeAttribute("data-src"); } });
        }
      });
    }
    tabs.forEach((t, i) => {
      t.addEventListener("click", () => select(t));
      t.addEventListener("keydown", e => {
        const d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
        if (!d) return;
        const next = tabs[(i + d + tabs.length) % tabs.length];
        next.focus(); select(next);
      });
    });
    // URL 해시로 특정 탭 열기 (예: form.html#hotel)
    const fromHash = tabs.find(t => t.dataset.hash && "#" + t.dataset.hash === location.hash);
    select(fromHash || tabs.find(t => t.getAttribute("aria-selected") === "true") || tabs[0]);
  });

  /* 문의 폼 */
  const dialog = document.querySelector(".dialog");
  function openDialog(title, msg) {
    if (!dialog) return alert(title + "\n" + msg);
    dialog.querySelector("h3").textContent = title;
    dialog.querySelector("p").textContent = msg;
    dialog.classList.add("open");
    dialog.querySelector(".btn")?.focus();
  }
  dialog?.addEventListener("click", e => { if (e.target === dialog || e.target.closest("[data-close]")) dialog.classList.remove("open"); });
  document.addEventListener("keydown", e => { if (e.key === "Escape") { dialog?.classList.remove("open"); document.body.classList.remove("menu-open"); } });

  document.querySelectorAll("form.inquiry").forEach(form => {
    form.addEventListener("submit", async e => {
      e.preventDefault();
      const data = new FormData(form);
      const missing = [...form.querySelectorAll("[required]")].find(el =>
        el.type === "radio" ? !form.querySelector(`[name="${el.name}"]:checked`) :
        el.type === "checkbox" ? !el.checked : !el.value.trim()
      );
      if (missing) {
        const label = missing.closest(".field, .fieldset, .agree")?.querySelector(".lbl, legend")?.textContent?.replace("*", "").trim();
        openDialog("입력 내용을 확인해 주세요", label ? `‘${label}’ 항목을 입력해 주세요.` : "개인정보 수집·이용에 동의해 주세요.");
        missing.focus?.();
        return;
      }
      const tel = data.get("phone") || "";
      if (tel && !/^[0-9\-\s+()]{9,}$/.test(tel)) { openDialog("연락처를 확인해 주세요", "숫자와 - 만 입력해 주세요."); return; }

      if (!FORM_ENDPOINT) {
        openDialog("상담 신청 안내", `온라인 접수는 준비 중입니다. 대표전화 ${TEL}로 연락 주시면 바로 상담해 드리겠습니다.`);
        return;
      }
      const btn = form.querySelector("[type=submit]");
      btn.disabled = true;
      try {
        const res = await fetch(FORM_ENDPOINT, { method: "POST", body: data, headers: { Accept: "application/json" } });
        if (!res.ok) throw new Error(res.status);
        form.reset();
        openDialog("신청이 접수되었습니다", "담당자가 확인 후 영업일 기준 1일 이내에 연락드리겠습니다.");
      } catch {
        openDialog("전송에 실패했습니다", `잠시 후 다시 시도하시거나 대표전화 ${TEL}로 연락 주세요.`);
      } finally {
        btn.disabled = false;
      }
    });
  });

  /* 회사소개 목차: 현재 보고 있는 섹션 강조 */
  const subLinks = [...document.querySelectorAll(".subnav a")];
  if (subLinks.length) {
    const secs = subLinks.map(a => document.querySelector(a.getAttribute("href"))).filter(Boolean);
    const markActive = () => {
      const y = window.scrollY + window.innerHeight * 0.3;
      let cur = secs[0];
      secs.forEach(s => { if (s.offsetTop <= y) cur = s; });
      subLinks.forEach(a => a.classList.toggle("active", a.getAttribute("href") === "#" + cur.id));
    };
    window.addEventListener("scroll", markActive, { passive: true });
    markActive();
  }

  /* 사업실적 분류 필터 */
  document.querySelectorAll(".filter").forEach(group => {
    const btns = [...group.querySelectorAll("button")];
    btns.forEach(b => b.addEventListener("click", () => {
      btns.forEach(x => x.setAttribute("aria-pressed", String(x === b)));
      const f = b.dataset.filter;
      document.querySelectorAll(".project").forEach(p => {
        p.hidden = !(f === "all" || p.dataset.cat === f);
        p.classList.add("in");   // 숨겼다 다시 보일 때 등장 애니메이션 대기 상태로 남지 않게
      });
    }));
  });

  /* 현재 페이지 메뉴 표시 */
  const here = location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".gnb a, .m-menu nav a").forEach(a => {
    if (a.getAttribute("href") === here) a.setAttribute("aria-current", "page");
  });

  const yearEl = document.querySelector("[data-year]");
  if (yearEl) yearEl.textContent = new Date().getFullYear();
});
