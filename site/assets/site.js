"use strict";

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
