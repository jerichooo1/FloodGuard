(() => {
  'use strict';
  const list = document.getElementById('allPublicPosts');
  const count = document.getElementById('postCount');
  const pagination = document.getElementById('postPagination');
  const filters = [...document.querySelectorAll('[data-post-filter]')];
  let page = 1;
  let category = 'all';
  let requestId = 0;
  const label = value => String(value || 'update').replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());
  const publishedAt = value => {
    if (!value) return 'Publication time unavailable';
    const date = new Date(String(value).replace(' ', 'T'));
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString([], {dateStyle: 'medium', timeStyle: 'short'});
  };
  function createPost(item) {
    const article = document.createElement('article'); article.className = 'public-post';
    if (item.photo_url) { const image = document.createElement('img'); image.src = item.photo_url; image.alt = `Community photograph: ${item.title}`; image.loading = 'lazy'; article.append(image); }
    const body = document.createElement('div'); body.className = 'public-post-body';
    const top = document.createElement('div'); top.className = 'post-topline';
    const type = document.createElement('span'); type.className = 'post-category'; type.textContent = label(item.category);
    const verified = document.createElement('span'); verified.className = 'post-verified'; verified.innerHTML = '<i class="bi bi-patch-check-fill"></i> Barangay reviewed'; top.append(type, verified);
    const title = document.createElement('h3'); title.textContent = item.title;
    const content = document.createElement('p'); content.textContent = item.content;
    const meta = document.createElement('div'); meta.className = 'post-meta';
    const location = document.createElement('span'); location.innerHTML = '<i class="bi bi-geo-alt"></i>'; location.append(document.createTextNode(item.location_name || 'Spillway Bridge area'));
    const date = document.createElement('span'); date.innerHTML = '<i class="bi bi-clock"></i>'; date.append(document.createTextNode(`Published ${publishedAt(item.published_at)}`)); meta.append(location, date);
    body.append(top, title, content, meta); article.append(body); return article;
  }
  function renderPagination(meta) {
    pagination.replaceChildren();
    if (meta.pages <= 1) return;
    const add = (text, target, disabled = false, current = false) => { const button = document.createElement('button'); button.type = 'button'; button.textContent = text; button.disabled = disabled; if (current) button.classList.add('active'); button.addEventListener('click', () => { page = target; load(); window.scrollTo({top: list.offsetTop - 130, behavior: 'smooth'}); }); pagination.append(button); };
    add('‹ Previous', meta.page - 1, meta.page <= 1);
    const start = Math.max(1, meta.page - 2), end = Math.min(meta.pages, meta.page + 2);
    for (let number = start; number <= end; number++) add(String(number), number, false, number === meta.page);
    add('Next ›', meta.page + 1, meta.page >= meta.pages);
  }
  async function load() {
    const current = ++requestId;
    list.innerHTML = '<article class="empty-state"><i class="bi bi-hourglass-split"></i><div><h3>Loading verified updates</h3><p>Please wait while FloodGuard retrieves community posts.</p></div></article>';
    pagination.replaceChildren(); count.textContent = 'Loading updates…';
    const params = new URLSearchParams({page: String(page), limit: '10'}); if (category !== 'all') params.set('category', category);
    try {
      const response = await fetch(`api/v1/public/posts/index.php?${params}`, {cache: 'no-store', headers: {Accept: 'application/json'}});
      const payload = await response.json(); if (!response.ok || !payload.success) throw new Error(payload.message || 'Request failed'); if (current !== requestId) return;
      const posts = Array.isArray(payload.data) ? payload.data : [], meta = payload.pagination || {page: 1, pages: 1, total: posts.length};
      count.textContent = `${meta.total} verified update${meta.total === 1 ? '' : 's'}`;
      if (!posts.length) list.innerHTML = '<article class="empty-state"><i class="bi bi-chat-square-text"></i><div><h3>No updates in this category</h3><p>Barangay-reviewed posts will appear here when available.</p></div></article>'; else list.replaceChildren(...posts.map(createPost));
      renderPagination(meta);
    } catch { if (current !== requestId) return; count.textContent = 'Updates unavailable'; list.innerHTML = '<article class="empty-state"><i class="bi bi-cloud-slash"></i><div><h3>Community updates unavailable</h3><p>Please check your connection and try again shortly.</p></div></article>'; }
  }
  filters.forEach(button => button.addEventListener('click', () => { category = button.dataset.postFilter || 'all'; page = 1; filters.forEach(item => item.classList.toggle('active', item === button)); load(); }));
  load();
})();
