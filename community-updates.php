<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="Browse verified FloodGuard community updates for Spillway Bridge and Barangay San Isidro.">
  <title>Community Updates | FloodGuard</title>
  <link rel="stylesheet" href="assets/css/public-home.css?v=20260928-1">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body class="community-page">
<header class="site-header">
  <a class="brand" href="index.php"><span class="brand-mark"><img src="assets/images/floodguard-logo.png" alt="FloodGuard"></span><span><strong>FloodGuard</strong><small>Public Monitoring</small></span></a>
  <nav aria-label="Main navigation"><a href="index.php#monitoring">Live conditions</a><a href="index.php#resident-app">Resident app</a><a class="nav-primary" href="index.php"><i class="bi bi-house"></i> Home</a></nav>
</header>
<main class="updates-page">
  <section class="updates-page-hero"><div><span class="eyebrow"><i class="bi bi-patch-check-fill"></i> Barangay-reviewed information</span><h1>Community updates</h1><p>Browse approved observations from verified residents around Spillway Bridge and Barangay San Isidro.</p></div><a href="index.php#resident-app" class="hero-primary"><i class="bi bi-android2"></i> Get the resident app</a></section>
  <section class="content-section updates-directory" aria-labelledby="updates-title">
    <div class="section-heading"><div><span class="section-label">Public newsfeed</span><h2 id="updates-title">Verified resident posts</h2></div><p>Only posts reviewed by authorized barangay personnel appear here.</p></div>
    <div class="feed-toolbar"><div class="feed-filters" role="group" aria-label="Filter community updates"><button class="active" type="button" data-post-filter="all">All updates</button><button type="button" data-post-filter="spillway_update">Spillway</button><button type="button" data-post-filter="road_condition">Road conditions</button><button type="button" data-post-filter="flood_update">Flood updates</button><button type="button" data-post-filter="community_update">Community</button></div><span id="postCount" class="feed-count">Loading updates…</span></div>
    <div id="allPublicPosts" class="public-post-list" aria-live="polite"><article class="empty-state"><i class="bi bi-chat-square-text"></i><div><h3>Loading verified updates</h3><p>Please wait while FloodGuard retrieves community posts.</p></div></article></div>
    <nav id="postPagination" class="post-pagination" aria-label="Community updates pages"></nav>
  </section>
</main>
<footer><div><strong>FloodGuard</strong><span>Spillway Bridge · Barangay San Isidro, Rodriguez, Rizal</span></div><p>Emergency information remains subject to official confirmation.</p></footer>
<script src="assets/js/public-posts.js?v=20260925-3" defer></script>
</body>
</html>
