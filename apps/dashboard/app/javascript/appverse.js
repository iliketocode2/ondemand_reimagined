// Appverse home page: live search/filter across installed and catalog grids.

document.addEventListener('DOMContentLoaded', () => {
  const searchInput     = document.getElementById('appverse-search');
  const installedGrid   = document.getElementById('installed-grid');
  const catalogGrid     = document.getElementById('catalog-grid');
  const installedEmpty  = document.getElementById('installed-empty-state');
  const catalogEmpty    = document.getElementById('catalog-empty-state');

  if (!searchInput) return;

  searchInput.addEventListener('input', () => {
    const query = searchInput.value.trim().toLowerCase();
    filterGrid(installedGrid, installedEmpty, query);
    filterGrid(catalogGrid,   catalogEmpty,   query);
  });

  function filterGrid(grid, emptyState, query) {
    if (!grid) return;

    const items   = grid.querySelectorAll('.appverse-item');
    let   visible = 0;

    items.forEach((item) => {
      const title   = item.dataset.title || '';
      const matches = !query || title.includes(query);
      item.style.display = matches ? '' : 'none';
      if (matches) visible++;
    });

    if (emptyState) {
      emptyState.classList.toggle('d-none', visible > 0 || !query);
    }
  }
});
