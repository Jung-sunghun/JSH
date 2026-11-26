/* ══════════════════════════════════════════════════════════════════════════
   krv-xref.js — 성경주석서고 8권 공통 「관주 창 개역개정 보충」
   · 이 서고의 관주 창은 권마다 실린 개역한글 색인(VB66) 안의 구절만 펼 수
     있어서, 다른 책을 가리키는 관주는 눌러도 본문이 뜨지 않았다.
   · 이 스크립트는 그런 구절을 개역개정 본문으로 펼친다(krv-xN.js 자료).
   · 이미 잘 열리는 개역한글 관주는 손대지 않고, 열리지 않던 자리만 채운다.
   ══════════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  if (window.KRVXF || !window.KRV_X) return;
  var D = window.KRV_X;                       /* {"45:9": [[8,"본문"], ...]} */
  var ALIAS = {"창세기":1,"창세":1,"창":1,"출애굽기":2,"출애굽":2,"출":2,"레위기":3,"레":3,"민수기":4,"민":4,"신명기":5,"신":5,"여호수아":6,"수":6,"사사기":7,"삿":7,"룻기":8,"룻":8,"사무엘상":9,"삼상":9,"사무엘하":10,"삼하":10,"열왕기상":11,"왕상":11,"열왕기하":12,"왕하":12,"역대상":13,"대상":13,"역대하":14,"대하":14,"에스라":15,"스":15,"느헤미야":16,"느":16,"에스더":17,"에":17,"욥기":18,"욥":18,"시편":19,"시":19,"잠언":20,"잠":20,"전도서":21,"전":21,"아가":22,"아":22,"이사야":23,"사":23,"예레미야":24,"렘":24,"예레미야애가":25,"애가":25,"애":25,"에스겔":26,"겔":26,"다니엘":27,"단":27,"호세아":28,"호":28,"요엘":29,"욜":29,"아모스":30,"암":30,"오바댜":31,"옵":31,"요나":32,"욘":32,"미가":33,"미":33,"나훔":34,"나":34,"하박국":35,"합":35,"스바냐":36,"습":36,"학개":37,"학":37,"스가랴":38,"슥":38,"말라기":39,"말":39,"마태복음":40,"마태":40,"마":40,"마가복음":41,"마가":41,"막":41,"누가복음":42,"누가":42,"눅":42,"요한복음":43,"요한":43,"요":43,"사도행전":44,"행":44,"로마서":45,"롬":45,"고린도전서":46,"고전":46,"고린도후서":47,"고후":47,"갈라디아서":48,"갈":48,"에베소서":49,"엡":49,"빌립보서":50,"빌":50,"골로새서":51,"골":51,"데살로니가전서":52,"살전":52,"데살로니가후서":53,"살후":53,"디모데전서":54,"딤전":54,"디모데후서":55,"딤후":55,"디도서":56,"딛":56,"빌레몬서":57,"몬":57,"히브리서":58,"히":58,"야고보서":59,"약":59,"베드로전서":60,"벧전":60,"베드로후서":61,"벧후":61,"요한1서":62,"요한일서":62,"요일":62,"요한2서":63,"요한이서":63,"요이":63,"요한3서":64,"요한삼서":64,"요삼":64,"유다서":65,"유":65,"요한계시록":66,"계시록":66,"계":66};

  function rowsOf(num, ch, a, b) {
    var r = D[num + ':' + ch];
    if (!r) return [];
    return r.filter(function (x) { return x[0] >= a && x[0] <= b; });
  }
  function covered(num, ch, a, b) { return rowsOf(num, ch, a, b).length === (b - a + 1); }
  function esc(s) {
    return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }
  function bookShort(num) {
    try { if (typeof bok === 'function') return bok(num)[0]; } catch (e) {}
    return '';
  }
  function hasHangul(num, ch, a, b) {
    try { if (typeof vRows === 'function') return vRows(num, ch, a, b).length > 0; } catch (e) {}
    return true;
  }

  /* ── 1) 관주 창 — 개역한글 색인에 없으면 개역개정으로 펼친다 ─────────── */
  function gaeRows(num, ch, a, b) { return rowsOf(num, ch, a, b); }

  function renderGae(ref, p, rows, it) {
    var m = document.getElementById('xmodal'); if (!m) return;
    var why = (it && it.dataset) ? (it.dataset.why || '') : ((it && it.w) || '');
    if (!why) {
      try {
        if (window.S && S.cur && typeof DATA !== 'undefined') {
          var e = DATA.find(function (x) { return x.id === S.cur; });
          if (e && e.xr) { var hit = e.xr.find(function (x) { return x.r === ref; }); if (hit) why = hit.w || ''; }
        }
      } catch (e2) {}
    }
    var label = bookShort(p.num) + ' ' + p.ch + ':' + (p.v2 !== p.v1 ? p.v1 + '-' + p.v2 : p.v1);
    var body = '<div class="xverses">' + rows.map(function (r) {
      return '<div class="xv"><div class="n">' + r[0] + '</div><div>' + esc(r[1]) +
        ' <button type="button" class="xcopy1" data-c="' + esc(label + ' ' + r[0] + ' ' + r[1]) + '">복사</button></div></div>';
    }).join('') + '</div>' +
      '<div class="xnote">이 구절은 이 권의 개역한글 색인 밖에 있어 <b>개역개정</b> 본문으로 펼쳤습니다.</div>';

    m.innerHTML = '<div class="xbk"></div><div class="xcard" role="dialog" aria-label="관주 본문">' +
      '<div class="xh"><span class="xref">' + esc(ref) + '</span><span class="xplace">' + esc(label) + ' · 개역개정</span>' +
      '<button class="xclose" type="button">닫기 ✕</button></div>' + body +
      (why ? '<div class="xwhy"><b>연결 이유</b> — ' + esc(why) + '</div>' : '') +
      '<div class="xfoot"><button class="xcopy" type="button">본문 복사</button>' +
      '<span class="small">바깥을 누르거나 Esc 키로 닫힙니다.</span></div></div>';
    m.classList.add('open');

    var text = label + '\n' + rows.map(function (r) { return r[0] + '. ' + r[1]; }).join('\n');
    var cp = m.querySelector('.xcopy');
    if (cp) cp.onclick = function () { try { copy(text, cp); } catch (e) {} };
    Array.prototype.forEach.call(m.querySelectorAll('.xcopy1'), function (b) {
      b.onclick = function (ev) { ev.stopPropagation(); try { copy(b.dataset.c, b); } catch (e) {} };
    });
    var xbk = m.querySelector('.xbk'); if (xbk) xbk.onclick = function () { try { closeXref(); } catch (e) {} };
    var xcl = m.querySelector('.xclose');
    if (xcl) xcl.onclick = function (ev) { ev.preventDefault(); ev.stopPropagation(); try { closeXref(); } catch (e) {} };
    setTimeout(function () {
      try {
        document.addEventListener('click', xrefAnyClose);
        document.addEventListener('keydown', closeXrefKey, true);
      } catch (e) {}
    }, 0);
  }

  var origOpen = window.openXref;
  if (typeof origOpen === 'function') {
    window.openXref = function (it) {
      try {
        var ref = (it && it.dataset) ? (it.dataset.r || '') : ((it && it.r) || '');
        var p = (typeof parseFull === 'function') ? parseFull(ref) : null;
        if (p && !hasHangul(p.num, p.ch, p.v1, p.v2)) {
          var rows = gaeRows(p.num, p.ch, p.v1, p.v2);
          if (rows.length) { renderGae(ref, p, rows, it); return; }
        }
      } catch (e) {}
      return origOpen.apply(this, arguments);
    };
  }

  /* ── 2) 본문 글자 가운데 아직 눌리지 않는 관주만 눌러지게 ───────────── */
  var NAMES = Object.keys(ALIAS).sort(function (a, b) { return b.length - a.length; });
  function rx(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }
  var SP = '[ \\t\\u00a0\\u2009]';
  var RE = new RegExp('(' + NAMES.map(rx).join('|') + ')' + SP + '*(\\d{1,3})' + SP +
    '*:' + SP + '*(\\d{1,3})(?:' + SP + '*[-\u2013\u2014~\u301c]' + SP + '*(\\d{1,3}))?', 'g');
  var BAD = /[가-힣A-Za-z0-9]/;
  var SKIP = 'a,button,summary,label,input,textarea,select,option,code,kbd,samp,[contenteditable=""],[contenteditable="true"],script,style,noscript,.vlink,#xmodal,#xm2';

  function hits(str) {
    var out = [], m;
    RE.lastIndex = 0;
    while ((m = RE.exec(str))) {
      var at = m.index, before = at > 0 ? str.charAt(at - 1) : '';
      if (before && BAD.test(before)) continue;
      var num = ALIAS[m[1]], ch = parseInt(m[2], 10), a = parseInt(m[3], 10);
      var b = m[4] ? parseInt(m[4], 10) : a;
      if (b < a) { var t = a; a = b; b = t; }
      if (!num || b - a > 200) continue;
      if (hasHangul(num, ch, a, b)) continue;       /* 이미 열리는 관주는 그대로 둔다 */
      if (!covered(num, ch, a, b)) continue;
      out.push({ at: at, len: m[0].length, text: m[0] });
    }
    return out;
  }

  function linkify(root) {
    if (!root) return;
    var w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (n) {
        if (!n.nodeValue || n.nodeValue.indexOf(':') < 0) return NodeFilter.FILTER_REJECT;
        var p = n.parentNode;
        if (!p || p.nodeType !== 1) return NodeFilter.FILTER_REJECT;
        if (p.closest && p.closest(SKIP)) return NodeFilter.FILTER_REJECT;
        if (p.closest && p.closest('[hidden]')) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var list = [], n;
    while ((n = w.nextNode())) list.push(n);
    list.forEach(function (node) {
      var hs = hits(node.nodeValue);
      if (!hs.length) return;
      var src = node.nodeValue, pos = 0, frag = document.createDocumentFragment();
      hs.forEach(function (h) {
        if (h.at > pos) frag.appendChild(document.createTextNode(src.slice(pos, h.at)));
        var a = document.createElement('a');
        a.href = '#';
        a.className = 'vlink';
        a.setAttribute('data-r', h.text);
        a.setAttribute('title', h.text + ' — 개역개정 본문 열기');
        a.textContent = h.text;
        frag.appendChild(a);
        pos = h.at + h.len;
      });
      if (pos < src.length) frag.appendChild(document.createTextNode(src.slice(pos)));
      if (node.parentNode) node.parentNode.replaceChild(frag, node);
    });
  }

  function scope() { return document.querySelector('main') || document.body; }
  function run() { try { linkify(scope()); } catch (e) {} }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { run(); setTimeout(run, 600); });
  } else { run(); setTimeout(run, 600); }

  if (window.MutationObserver) {
    var timer = null;
    new MutationObserver(function (recs) {
      for (var i = 0; i < recs.length; i++) {
        var an = recs[i].addedNodes;
        for (var j = 0; j < an.length; j++) {
          var nd = an[j];
          if (nd.nodeType !== 1) continue;
          if (nd.classList && nd.classList.contains('vlink')) continue;
          if (nd.closest && nd.closest('.vlink')) continue;
          if (timer) clearTimeout(timer);
          timer = setTimeout(function () { timer = null; run(); }, 250);
          return;
        }
      }
    }).observe(scope(), { childList: true, subtree: true });
  }

  window.KRVXF = true;
})();
