/* Site navigation — the only JavaScript on the site. Progressive enhancement:
   - mobile hamburger toggle
   - Product / Company dropdowns: click/tap opens them (hover opens them too on
     desktop, via CSS); outside-click and Escape close them
   - marks the parent button active when the section holds the current page.
   Without JS the flat links still work and the dropdowns open on hover/focus. */
(function () {
  var toggle = document.querySelector(".nav-toggle");
  var nav = document.getElementById("site-nav");
  if (!nav) return;

  var groupBtns = Array.prototype.slice.call(nav.querySelectorAll(".nav-group__btn"));

  function closeGroups(except) {
    groupBtns.forEach(function (b) {
      if (b !== except) b.setAttribute("aria-expanded", "false");
    });
  }

  // mobile hamburger
  if (toggle) {
    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      if (!open) closeGroups();
    });
  }

  // dropdown buttons
  groupBtns.forEach(function (b) {
    b.addEventListener("click", function (e) {
      e.stopPropagation();
      var open = b.getAttribute("aria-expanded") === "true";
      closeGroups(b);
      b.setAttribute("aria-expanded", open ? "false" : "true");
    });
  });

  // outside click closes dropdowns
  document.addEventListener("click", function (e) {
    if (!nav.contains(e.target)) closeGroups();
  });

  // Escape closes dropdowns (and the mobile menu), returning focus to the button
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" || e.keyCode === 27) {
      var openBtn = groupBtns.filter(function (b) { return b.getAttribute("aria-expanded") === "true"; })[0];
      closeGroups();
      if (openBtn) openBtn.focus();
      if (nav.classList.contains("open") && toggle) {
        nav.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    }
  });

  // following a real link closes the mobile menu and any open dropdown
  nav.addEventListener("click", function (e) {
    var link = e.target.closest ? e.target.closest("a") : null;
    if (link) {
      closeGroups();
      if (nav.classList.contains("open")) {
        nav.classList.remove("open");
        if (toggle) toggle.setAttribute("aria-expanded", "false");
      }
    }
  });

  // highlight the parent button of the section that contains the current page
  Array.prototype.forEach.call(nav.querySelectorAll(".nav-group"), function (g) {
    if (g.querySelector("a.active")) {
      var b = g.querySelector(".nav-group__btn");
      if (b) b.classList.add("active");
    }
  });
})();
