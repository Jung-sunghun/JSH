/* ═══════════════════════════════════════════════════════════════════════
   목회서고(書庫) 공통 — 교리설교 🎰 카운터 · 방명록
   ─────────────────────────────────────────────────────────────────────
   · 카운터 : 교리설교 1~27번 주제마다 그 주제 안의 어느 부서든
              (장년·청년·중고등·유년·유치) 설교를 열거나 링크를 복사·보내면
              +1 하여 「🎰 000」 배지로 합산 횟수를 보여 준다.
   · 방명록 : 오른쪽 위 「글쓰기」 — 방문객은 자기 글만 쓰고 남의 글은 못 본다.
              운영자 열쇠를 아는 이만 「운영자 열람」에서 전체 글을 최신순으로 본다.
   · 저장소 : 구글 스프레드시트 「목회서고_방명록_및_카운터」
              (Google Apps Script 웹앱이 기록·집계를 맡는다)
   ═══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var API = 'https://script.google.com/macros/s/AKfycbyUwSi-1Ad5aFbvVNaZasCd2YxOBV7PzT87y9aWQjf3y_FilUOvYuPjQQxKD9G4x66_CA/exec';  /* 배포된 Apps Script 웹앱 주소 */
  var READY = API && API.indexOf('http') === 0;

  /* ── 작은 도구 ─────────────────────────────────────────────────────── */
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
  function pad3(n) {
    n = Number(n) || 0;
    if (n > 999) return String(n);
    return ('00' + n).slice(-3);
  }
  function p2(n) { n = Number(n) || 0; return (n < 10 ? '0' : '') + n; }
  /* 시트에는 날짜값으로 들어가 돌아올 때 영문 Date 문자열이 된다 — 늘 「2026-11-26 04:53」 꼴로 */
  function fmtAt(v) {
    var s = String(v == null ? '' : v).trim();
    if (!s) return '';
    var m = s.match(/^(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{2})/);
    if (m) return m[1] + '-' + p2(m[2]) + '-' + p2(m[3]) + ' ' + p2(m[4]) + ':' + m[5];
    var d = new Date(s);
    if (!isNaN(d.getTime())) {
      return d.getFullYear() + '-' + p2(d.getMonth() + 1) + '-' + p2(d.getDate()) +
        ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes());
    }
    return s;
  }
  function $(sel, root) { return (root || document).querySelector(sel); }

  /* 주제 키(trinity) → 주제 번호(1). 이미 번호면 그대로. */
  function noOfTopic(k) {
    k = String(k == null ? '' : k).trim();
    if (!k) return '';
    var t = (window.DOCTRINE && window.DOCTRINE.topics) ? window.DOCTRINE.topics[k] : null;
    if (t && t.no) return String(t.no);
    if (/^[0-9]+$/.test(k)) return String(parseInt(k, 10));
    var order = (window.DOCTRINE && window.DOCTRINE.order) || [];
    for (var i = 0; i < order.length; i++) {
      var x = window.DOCTRINE.topics[order[i]];
      if (x && (x.name === k || String(x.en || '').toLowerCase() === k.toLowerCase())) return String(x.no);
    }
    return '';
  }

  /* ── 서버 통신 ─────────────────────────────────────────────────────── */
  var jsonpSeq = 0;
  function jsonp(params) {
    return new Promise(function (resolve) {
      if (!READY) { resolve(null); return; }
      var name = 'mhbCb' + (++jsonpSeq) + '_' + Math.floor(Math.random() * 1e6);
      var script = document.createElement('script');
      var done = false;
      var timer = setTimeout(function () { finish(null); }, 12000);
      function finish(data) {
        if (done) return;
        done = true;
        clearTimeout(timer);
        try { delete window[name]; } catch (e) { window[name] = undefined; }
        if (script.parentNode) script.parentNode.removeChild(script);
        resolve(data);
      }
      window[name] = function (data) { finish(data); };
      script.onerror = function () { finish(null); };
      var q = [];
      for (var k in params) { if (params.hasOwnProperty(k)) q.push(encodeURIComponent(k) + '=' + encodeURIComponent(params[k])); }
      script.src = API + '?' + q.join('&') + '&callback=' + name;
      document.head.appendChild(script);
    });
  }

  function send(payload) {
    if (!READY) return Promise.resolve(null);
    var body = JSON.stringify(payload);
    return fetch(API, {
      method: 'POST',
      mode: 'cors',
      redirect: 'follow',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: body
    }).then(function (r) { return r.text(); }).then(function (t) {
      try { return JSON.parse(t); } catch (e) { return null; }
    }).catch(function () {
      /* 응답을 못 받아도 기록은 남는다 — 방문객에게 실패로 보이지 않게 한 번 더 보낸다 */
      try { fetch(API, { method: 'POST', mode: 'no-cors', headers: { 'Content-Type': 'text/plain;charset=utf-8' }, body: body }); } catch (e) {}
      return null;
    });
  }

  /* ══════════════════════════════════════════════════════════════════
     ① 교리설교 🎰 카운터
     ══════════════════════════════════════════════════════════════════ */
  var counts = {};          /* { "1": 12, "2": 3 … } */
  var countsLoaded = false;
  var pending = {};         /* 아직 못 보낸 +1 (서버 응답 전 낙관 반영) */

  function totalOf(no) { return (Number(counts[no]) || 0) + (Number(pending[no]) || 0); }

  function paintBadges() {
    var nodes = document.querySelectorAll('.mhb-slot');
    for (var i = 0; i < nodes.length; i++) {
      var no = nodes[i].getAttribute('data-no');
      var n = totalOf(no);
      var num = nodes[i].querySelector('.mhb-slot-n');
      if (num) num.textContent = pad3(n);
      nodes[i].setAttribute('title', '이 주제(교리설교 ' + no + '번) 안의 모든 부서 설교를 열거나 보낸 횟수 — 지금까지 ' + n + '회');
    }
  }

  function badgeHTML(no) {
    return '<span class="mhb-slot" data-no="' + esc(no) + '"><span class="mhb-slot-i">🎰</span><span class="mhb-slot-n">' + pad3(totalOf(no)) + '</span></span>';
  }

  function decorateDocGrid() {
    var grid = document.getElementById('docGrid');
    if (!grid) return;
    var cards = grid.querySelectorAll('.doccard');
    for (var i = 0; i < cards.length; i++) {
      var card = cards[i];
      if (card.querySelector('.mhb-slot')) continue;
      var head = card.querySelector('.dc-head');
      var noEl = card.querySelector('.dc-no');
      if (!head || !noEl) continue;
      var no = String(noEl.textContent).trim();
      var box = document.createElement('span');
      box.innerHTML = badgeHTML(no);
      head.appendChild(box.firstChild);
    }
  }

  function loadCounts() {
    jsonp({ action: 'counts' }).then(function (d) {
      if (d && d.ok && d.counts) {
        counts = d.counts;
        countsLoaded = true;
        pending = {};
        paintBadges();
      }
    });
  }

  function bump(no) {
    no = String(no || '').trim();
    if (!no) return;
    pending[no] = (Number(pending[no]) || 0) + 1;
    paintBadges();
    send({ action: 'hit', no: Number(no) }).then(function (d) {
      if (d && d.ok) {
        counts[no] = Number(d.count) || (Number(counts[no]) || 0) + 1;
        pending[no] = Math.max(0, (Number(pending[no]) || 0) - 1);
        paintBadges();
      }
    });
  }

  /* 어느 부서든 — 설교를 열거나, 링크를 복사하거나, 보내기 하면 그 주제 +1 */
  function watchCountHits() {
    document.addEventListener('click', function (ev) {
      var el = ev.target;
      var sm = el.closest ? el.closest('[data-sermon]') : null;
      if (sm) { bump(noOfTopic(sm.getAttribute('data-sermon'))); return; }
      var sl = el.closest ? el.closest('[data-slink]') : null;
      if (sl) { bump(noOfTopic(sl.getAttribute('data-sl-topic'))); }
    }, true);

    /* 단독 설교 링크(?sermon=3&age=adult · ?sermon=trinity)로 곧바로 들어온 경우 */
    try {
      var m = (location.search || '').match(/[?&]sermon=([^&#]*)/);
      if (m) bump(noOfTopic(decodeURIComponent(m[1].replace(/\+/g, ' '))));
    } catch (e) {}
  }

  /* ══════════════════════════════════════════════════════════════════
     ② 방명록 — 글쓰기 · 운영자 열람
     ══════════════════════════════════════════════════════════════════ */
  var NOTICE = '운영자에게 조언, 질문 등 글을 남기면 확인 후 답장을 보내드리며, 답장 발송 시간이 지체될 수 있음을 이해 해 주시기 바랍니다.';

  var CSS = [
    /* 교리설교 🎰 배지 */
    '.mhb-slot{display:inline-flex;align-items:center;gap:6px;margin-left:auto;flex:none;padding:3px 10px 3px 8px;',
    'border-radius:999px;border:1.5px solid #d9b25f;background:linear-gradient(180deg,#fff7e2,#f6e4b6);color:#7a4b16;',
    'font-family:"Malgun Gothic",system-ui,-apple-system,sans-serif;font-size:.82em;font-weight:900;line-height:1.35;',
    'box-shadow:inset 0 1px 0 rgba(255,255,255,.8),0 1px 3px rgba(90,60,10,.13);cursor:default;-webkit-user-select:none;user-select:none;white-space:nowrap}',
    '.mhb-slot-i{font-size:1.06em;line-height:1;letter-spacing:0}',
    '.mhb-slot-n{font-variant-numeric:tabular-nums;font-feature-settings:"tnum";letter-spacing:.11em}',
    /* 오른쪽 위 글쓰기 단추 */
    '#mhbBtn{position:fixed;top:8px;right:8px;z-index:2147482000;display:flex;flex-direction:column;align-items:center;gap:1px;',
    'margin:0;padding:9px 17px 8px;cursor:pointer;border:2px solid #f6e2ab;border-radius:13px;',
    'background:linear-gradient(180deg,#8a5a1e,#6d4312);color:#fff;font-family:inherit;line-height:1.15;',
    'box-shadow:0 4px 14px rgba(40,22,0,.38),inset 0 1px 0 rgba(255,255,255,.22);text-align:center;-webkit-tap-highlight-color:transparent}',
    '#mhbBtn:hover{background:linear-gradient(180deg,#9c6622,#7a4b16);border-color:#fff0c4}',
    '#mhbBtn .mhb-b1{font-size:1.16em;font-weight:900;letter-spacing:.04em;display:block;color:#fff;text-shadow:0 1px 2px rgba(0,0,0,.35)}',
    '#mhbBtn .mhb-b2{font-size:.68em;font-weight:700;letter-spacing:-.01em;opacity:.93;display:block;color:#ffeec4;white-space:nowrap}',
    '@media (max-width:430px){#mhbBtn{padding:7px 12px 6px;top:6px;right:6px;border-radius:11px}#mhbBtn .mhb-b1{font-size:1.02em}#mhbBtn .mhb-b2{font-size:.62em}}',
    /* 겹창 판 */
    '.mhb-veil{position:fixed;inset:0;z-index:2147482400;display:flex;align-items:flex-start;justify-content:center;',
    'padding:max(18px,env(safe-area-inset-top,0px)) 12px 24px;overflow-y:auto;background:rgba(18,12,4,.5);-webkit-backdrop-filter:blur(2px);backdrop-filter:blur(2px)}',
    '.mhb-card{width:100%;max-width:560px;max-height:calc(100vh - 44px);margin:auto;display:flex;flex-direction:column;',
    'background:#fdfaf3;color:#241c10;border:1.5px solid #d9c48d;border-radius:16px;',
    'box-shadow:0 20px 50px rgba(30,18,0,.35);font-family:inherit;font-size:1rem;line-height:1.6;text-align:left;overflow:hidden}',
    '.mhb-card.small{max-width:430px}',
    '.mhb-head{flex:none;display:flex;align-items:center;justify-content:space-between;gap:10px;padding:13px 16px;',
    'background:linear-gradient(180deg,#7a4b16,#63390d);color:#fff}',
    '.mhb-head b{font-size:1.05em;font-weight:900;letter-spacing:.01em;color:#fff}',
    '.mhb-x{border:1px solid rgba(255,255,255,.5);background:rgba(255,255,255,.14);color:#fff;border-radius:9px;',
    'padding:3px 10px;font-size:.86em;font-weight:700;cursor:pointer;font-family:inherit}',
    '.mhb-x:hover{background:rgba(255,255,255,.3)}',
    '.mhb-body{padding:15px 16px 18px;overflow-y:auto;min-height:0}',
    '.mhb-row{margin:0 0 11px}',
    '.mhb-row label{display:block;font-size:.82em;font-weight:800;color:#6a4a15;margin:0 0 4px;letter-spacing:.01em}',
    '.mhb-row input,.mhb-row textarea{width:100%;box-sizing:border-box;font-family:inherit;font-size:1em;color:#241c10;',
    'background:#fff;border:1.5px solid #cbb37c;border-radius:9px;padding:9px 11px;outline:none}',
    '.mhb-row input:focus,.mhb-row textarea:focus{border-color:#8a5a1e;box-shadow:0 0 0 3px rgba(138,90,30,.16)}',
    '.mhb-row textarea{min-height:170px;resize:vertical;line-height:1.7}',
    '.mhb-sub{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-top:14px;flex-wrap:wrap}',
    '.mhb-send{border:1.5px solid #6d4312;border-radius:10px;background:linear-gradient(180deg,#8a5a1e,#6d4312);color:#fff;',
    'font-family:inherit;font-size:1.04em;font-weight:900;padding:11px 26px;cursor:pointer;letter-spacing:.03em;box-shadow:0 3px 10px rgba(70,40,0,.28)}',
    '.mhb-send:hover{background:linear-gradient(180deg,#9c6622,#7a4b16)}',
    '.mhb-send[disabled]{opacity:.6;cursor:default}',
    '.mhb-admin-link{border:0;background:none;color:#8a6a2a;text-decoration:underline;font-family:inherit;font-size:.82em;cursor:pointer;padding:4px 0}',
    '.mhb-note{font-size:.8em;color:#7a6a4e;margin:10px 0 0;line-height:1.6}',
    '.mhb-msg{font-size:.9em;font-weight:700;margin:10px 0 0;min-height:1.2em}',
    '.mhb-msg.ok{color:#1d6b3f}.mhb-msg.err{color:#a02222}',
    /* 안내 겹창 */
    '.mhb-notice-body{padding:18px 18px 15px;font-size:.98em;line-height:1.75;color:#2b2110;word-break:keep-all}',
    '.mhb-notice-body b{color:#7a4b16}',
    '.mhb-notice-foot{padding:0 18px 16px;text-align:right}',
    '.mhb-ok{border:1.5px solid #6d4312;border-radius:9px;background:#8a5a1e;color:#fff;font-family:inherit;font-size:.95em;',
    'font-weight:800;padding:8px 22px;cursor:pointer}',
    /* 운영자 열람 */
    '.mhb-list{margin:12px 0 0;border-top:1px solid #e0d0a8}',
    '.mhb-item{border-bottom:1px solid #ebe0c4;padding:11px 2px 12px}',
    '.mhb-item h4{margin:0 0 3px;font-size:1em;font-weight:900;color:#2b2110;line-height:1.45;word-break:break-word}',
    '.mhb-meta{font-size:.76em;color:#7a6a4e;margin:0 0 6px;line-height:1.5;word-break:break-all}',
    '.mhb-content{font-size:.92em;color:#332a1b;white-space:pre-wrap;word-break:break-word;line-height:1.68}',
    '.mhb-empty{color:#7a6a4e;font-size:.9em;padding:14px 0;text-align:center}',
    '.mhb-tools{display:flex;gap:8px;align-items:center;margin:10px 0 0;flex-wrap:wrap}',
    '.mhb-tools input{flex:1 1 120px;min-width:110px;font-family:inherit;font-size:1em;padding:8px 10px;border:1.5px solid #cbb37c;border-radius:9px;background:#fff;color:#241c10}'
  ].join('');

  function injectCSS() {
    if (document.getElementById('mhbCSS')) return;
    var st = document.createElement('style');
    st.id = 'mhbCSS';
    st.textContent = CSS;
    document.head.appendChild(st);
  }

  function openLayer(html, cls) {
    var veil = document.createElement('div');
    veil.className = 'mhb-veil';
    veil.innerHTML = '<div class="mhb-card ' + (cls || '') + '" role="dialog" aria-modal="true">' + html + '</div>';
    document.body.appendChild(veil);
    veil.addEventListener('click', function (e) { e.stopPropagation(); });
    veil.addEventListener('mousedown', function (e) { e.stopPropagation(); });
    return veil;
  }
  function closeLayer(veil) { if (veil && veil.parentNode) veil.parentNode.removeChild(veil); }

  /* ── 안내 겹창 (글쓰기 창 위에) ───────────────────────────────────── */
  function openNotice(parentVeil) {
    var veil = openLayer(
      '<div class="mhb-head"><b>✉️ 글을 남기시기 전에</b><button type="button" class="mhb-x" data-mhb="notice-close">닫기 ✕</button></div>' +
      '<div class="mhb-notice-body">' + esc(NOTICE) + '</div>' +
      '<div class="mhb-notice-foot"><button type="button" class="mhb-ok" data-mhb="notice-close">확인</button></div>',
      'small');
    veil.style.background = 'rgba(18,12,4,.34)';
    veil.style.alignItems = 'center';
    var z = 2147483000;
    veil.style.zIndex = z;
    if (parentVeil) parentVeil.style.zIndex = z - 10;
    veil.addEventListener('click', function (e) {
      var t = e.target;
      if (t && t.getAttribute && t.getAttribute('data-mhb') === 'notice-close') {
        closeLayer(veil);
        if (parentVeil) parentVeil.style.zIndex = '';
        var ta = parentVeil && parentVeil.querySelector('textarea');
        if (ta) ta.focus();
      }
    });
    return veil;
  }

  /* ── 글쓰기 창 ─────────────────────────────────────────────────────── */
  function openWrite() {
    if (!READY) {
      var w = openLayer(
        '<div class="mhb-head"><b>✉️ 운영자에게 글쓰기</b><button type="button" class="mhb-x" data-mhb="close">닫기 ✕</button></div>' +
        '<div class="mhb-body"><p class="mhb-msg err">방명록 저장소 연결을 마무리하는 중입니다. 잠시 뒤 다시 열어 주십시오.</p></div>', 'small');
      w.addEventListener('click', function (e) {
        if (e.target.getAttribute && e.target.getAttribute('data-mhb') === 'close') closeLayer(w);
      });
      return;
    }

    var veil = openLayer(
      '<div class="mhb-head"><b>✉️ 운영자에게 글쓰기</b><button type="button" class="mhb-x" data-mhb="close">닫기 ✕</button></div>' +
      '<div class="mhb-body">' +
      '  <div class="mhb-row"><label for="mhbT">제목</label><input id="mhbT" type="text" maxlength="120" autocomplete="off" placeholder="예) 창세기 강해 관련 질문"></div>' +
      '  <div class="mhb-row"><label for="mhbN">이름</label><input id="mhbN" type="text" maxlength="60" autocomplete="name" placeholder="성명"></div>' +
      '  <div class="mhb-row"><label for="mhbE">이메일</label><input id="mhbE" type="email" maxlength="120" autocomplete="email" inputmode="email" placeholder="답장 받으실 주소"></div>' +
      '  <div class="mhb-row"><label for="mhbB">글쓰기 내용</label><textarea id="mhbB" maxlength="4000" placeholder="조언·질문·나누실 말씀을 적어 주십시오."></textarea></div>' +
      '  <input type="text" name="mhbTrap" id="mhbTrap" tabindex="-1" autocomplete="off" style="position:absolute;left:-9999px;width:1px;height:1px;opacity:0" aria-hidden="true">' +
      '  <div class="mhb-sub"><button type="button" class="mhb-send" data-mhb="send">보내기</button>' +
      '    <button type="button" class="mhb-admin-link" data-mhb="admin">운영자 열람</button></div>' +
      '  <p class="mhb-msg" id="mhbMsg"></p>' +
      '  <p class="mhb-note">적어 주신 글은 <b>운영자만 확인</b>합니다. 다른 방문객에게는 보이지 않습니다.</p>' +
      '</div>');

    veil.addEventListener('click', function (e) {
      var t = e.target;
      var act = t && t.getAttribute ? t.getAttribute('data-mhb') : '';
      if (act === 'close') { closeLayer(veil); return; }
      if (act === 'admin') { openAdmin(veil); return; }
      if (act === 'send') { submitWrite(veil); return; }
    });

    openNotice(veil);
  }

  function submitWrite(veil) {
    var t = $('#mhbT', veil), n = $('#mhbN', veil), m = $('#mhbE', veil), b = $('#mhbB', veil), trap = $('#mhbTrap', veil);
    var msg = $('#mhbMsg', veil), btn = veil.querySelector('[data-mhb="send"]');
    var body = (b.value || '').trim();
    if (!body) {
      msg.className = 'mhb-msg err';
      msg.textContent = '글쓰기 내용을 적어 주십시오.';
      b.focus();
      return;
    }
    msg.className = 'mhb-msg';
    msg.textContent = '보내는 중…';
    btn.disabled = true;
    send({
      action: 'write',
      title: (t.value || '').trim(),
      name: (n.value || '').trim(),
      email: (m.value || '').trim(),
      body: body,
      trap: trap && trap.value ? trap.value : ''
    }).then(function (d) {
      btn.disabled = false;
      if (d && d.ok) {
        msg.className = 'mhb-msg ok';
        msg.textContent = '✓ 잘 접수되었습니다' + (d.at ? ' (' + d.at + ')' : '') + '. 확인 후 답장을 보내드리겠습니다.';
        t.value = ''; n.value = ''; m.value = ''; b.value = '';
        setTimeout(function () { if (veil.parentNode) closeLayer(veil); }, 2600);
      } else if (d && d.error) {
        msg.className = 'mhb-msg err';
        msg.textContent = '보내지 못했습니다 — ' + d.error;
      } else {
        msg.className = 'mhb-msg err';
        msg.textContent = '보내지 못했습니다. 잠시 뒤 다시 시도해 주십시오.';
      }
    });
  }

  /* ── 운영자 열람 ───────────────────────────────────────────────────── */
  function openAdmin(fromVeil) {
    var veil = openLayer(
      '<div class="mhb-head"><b>🔑 운영자 열람</b><button type="button" class="mhb-x" data-mhb="close">닫기 ✕</button></div>' +
      '<div class="mhb-body" id="mhbAdminBody">' +
      '  <div class="mhb-row"><label for="mhbKey">운영자 열쇠 (숫자 6자리)</label>' +
      '    <input id="mhbKey" type="password" inputmode="numeric" maxlength="20" autocomplete="off" placeholder="열쇠를 넣어 주십시오"></div>' +
      '  <div class="mhb-tools"><button type="button" class="mhb-send" data-mhb="open">열기</button></div>' +
      '  <p class="mhb-msg" id="mhbAdminMsg"></p>' +
      '</div>');
    veil.addEventListener('click', function (e) {
      var act = e.target && e.target.getAttribute ? e.target.getAttribute('data-mhb') : '';
      if (act === 'close') { closeLayer(veil); return; }
      if (act === 'open') { loadAdmin(veil); return; }
    });
    var key = $('#mhbKey', veil);
    if (key) {
      key.addEventListener('keydown', function (e) { if (e.key === 'Enter') loadAdmin(veil); });
      setTimeout(function () { key.focus(); }, 60);
    }
  }

  function loadAdmin(veil) {
    var key = $('#mhbKey', veil), msg = $('#mhbAdminMsg', veil), body = $('#mhbAdminBody', veil);
    var k = (key.value || '').trim();
    if (!k) { msg.className = 'mhb-msg err'; msg.textContent = '열쇠를 넣어 주십시오.'; return; }
    msg.className = 'mhb-msg';
    msg.textContent = '여는 중…';
    send({ action: 'list', key: k }).then(function (d) {
      if (!d || !d.ok) {
        msg.className = 'mhb-msg err';
        msg.textContent = (d && d.error) ? d.error : '열지 못했습니다. 열쇠와 연결을 확인해 주십시오.';
        return;
      }
      var rows = d.rows || [];
      var h = ['<p style="margin:0 0 2px;font-size:.86em;font-weight:900;color:#6a4a15">모두 ' + rows.length + '편 — 최신 글이 위</p>'];
      if (!rows.length) {
        h.push('<p class="mhb-empty">아직 남겨진 글이 없습니다.</p>');
      } else {
        h.push('<div class="mhb-list">');
        for (var i = 0; i < rows.length; i++) {
          var r = rows[i];
          h.push('<div class="mhb-item">' +
            '<h4>' + (r.title ? esc(r.title) : '(제목 없음)') + '</h4>' +
            '<p class="mhb-meta">' + esc(fmtAt(r.at)) + ' · ' + (r.name ? esc(r.name) : '이름 없음') +
            (r.email ? ' · ' + esc(r.email) : '') + '</p>' +
            '<div class="mhb-content">' + esc(r.body) + '</div></div>');
        }
        h.push('</div>');
      }
      body.innerHTML = h.join('');
    });
  }

  /* ══════════════════════════════════════════════════════════════════
     시작
     ══════════════════════════════════════════════════════════════════ */
  function boot() {
    injectCSS();

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.id = 'mhbBtn';
    btn.setAttribute('aria-label', '운영자에게 글쓰기');
    btn.innerHTML = '<span class="mhb-b1">✍️ 글쓰기</span><span class="mhb-b2">운영자만 확인합니다</span>';
    btn.addEventListener('click', function (e) { e.stopPropagation(); openWrite(); });
    document.body.appendChild(btn);

    /* 교리설교 화면이면 🎰 배지 */
    if (document.getElementById('docGrid')) {
      decorateDocGrid();
      var grid = document.getElementById('docGrid');
      if (window.MutationObserver) {
        var mo = new MutationObserver(function () { decorateDocGrid(); });
        mo.observe(grid, { childList: true });
      }
      watchCountHits();
      loadCounts();
      setInterval(function () { if (!countsLoaded) loadCounts(); }, 20000);
    }
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();

  window.MokhoeBoard = { bump: bump, reload: loadCounts, openWrite: openWrite };
})();
