"use strict";

// Copy-to-clipboard buttons (install snippets and directory pages).
document.querySelectorAll("[data-copy-target]").forEach((button) => {
  button.addEventListener("click", async () => {
    const source = document.getElementById(button.dataset.copyTarget);
    if (!source) return;
    const originalLabel = button.textContent;
    try {
      await navigator.clipboard.writeText(source.textContent.trim());
      button.textContent = "Copied ✓";
    } catch {
      button.textContent = "Copy failed";
    }
    window.setTimeout(() => { button.textContent = originalLabel; }, 1800);
  });
});

// Platform tabs: keep one panel visible, remember the choice for the session.
const tabs = [...document.querySelectorAll("[role=tab]")];
const panels = tabs.map((tab) => document.getElementById(tab.getAttribute("aria-controls")));
const storageKey = "openrtmp-packages-platform";

function selectTab(tab) {
  tabs.forEach((candidate, index) => {
    const selected = candidate === tab;
    candidate.setAttribute("aria-selected", String(selected));
    candidate.tabIndex = selected ? 0 : -1;
    if (panels[index]) panels[index].hidden = !selected;
  });
}

if (tabs.length) {
  const saved = (() => {
    try { return window.localStorage.getItem(storageKey); } catch { return null; }
  })();
  const initial = tabs.find((tab) => tab.id === `tab-${saved}`) ||
    tabs.find((tab) => tab.getAttribute("aria-selected") === "true") || tabs[0];
  selectTab(initial);

  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => {
      selectTab(tab);
      try {
        window.localStorage.setItem(storageKey, tab.id.replace(/^tab-/, ""));
      } catch { /* storage may be unavailable in private modes */ }
    });
    tab.addEventListener("keydown", (event) => {
      const direction = event.key === "ArrowRight" ? 1 : event.key === "ArrowLeft" ? -1 : 0;
      if (!direction) return;
      event.preventDefault();
      const next = tabs[(index + direction + tabs.length) % tabs.length];
      selectTab(next);
      next.focus();
    });
  });
}

// Directory search on generated repository pages.
const search = document.querySelector("[data-file-search]");
if (search) {
  const rows = [...document.querySelectorAll("[data-file-row]")];
  const emptyMessage = document.querySelector("[data-no-results]");
  search.addEventListener("input", () => {
    const query = search.value.trim().toLocaleLowerCase();
    let visible = 0;
    rows.forEach((row) => {
      const matches = row.textContent.toLocaleLowerCase().includes(query);
      row.hidden = !matches;
      if (matches) visible += 1;
    });
    if (emptyMessage) emptyMessage.hidden = visible !== 0;
  });
}
