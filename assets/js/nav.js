/* Mobile navigation toggle — the only JavaScript on the site.
   Progressive enhancement: the nav links work without it; this just
   shows/hides them on narrow viewports. */
(function () {
  var btn = document.querySelector(".nav-toggle");
  var nav = document.getElementById("site-nav");
  if (!btn || !nav) return;

  btn.addEventListener("click", function () {
    var open = nav.classList.toggle("open");
    btn.setAttribute("aria-expanded", open ? "true" : "false");
  });

  // Close the menu after following a link (single-page anchors / navigation).
  nav.addEventListener("click", function (e) {
    if (e.target.tagName === "A" && nav.classList.contains("open")) {
      nav.classList.remove("open");
      btn.setAttribute("aria-expanded", "false");
    }
  });
})();
