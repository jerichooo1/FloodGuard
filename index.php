<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="description" content="FloodGuard provides live flood and bridge conditions, verified community updates, and resident reporting for Spillway Bridge.">
  <title>FloodGuard | Spillway Bridge Safety</title>
  <link rel="stylesheet" href="assets/css/public-home.css?v=20260928-1">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<header class="site-header">
  <a class="brand" href="#top"><span class="brand-mark"><img src="assets/images/floodguard-logo.png" alt="FloodGuard"></span><span><strong>FloodGuard</strong><small>Public Monitoring</small></span></a>
  <nav aria-label="Main navigation"><a href="#about">About</a><a href="#monitoring">Conditions</a><a href="#updates">Community Updates</a><a href="#resident-app">Resident App</a><a href="#safety">Safety</a></nav>
</header>
<main id="top">
  <section class="hero">
    <div><span class="eyebrow"><i class="bi bi-shield-check"></i> Flood and bridge safety for Barangay San Isidro</span><h1>Know the conditions before you approach the bridge.</h1><p>FloodGuard combines live environmental monitoring, early warnings, verified resident updates, and barangay response coordination for the Spillway Bridge community.</p><div class="hero-actions"><a class="hero-primary" href="#monitoring"><i class="bi bi-broadcast-pin"></i> View live conditions</a><a class="hero-secondary" href="#resident-app">Explore the resident app</a></div></div>
  </section>
  <section class="content-section about-section" id="about"><div class="section-heading"><div><span class="section-label">About the system</span><h2>One platform for safer flood decisions</h2></div><p>FloodGuard gives the public a clear view of current conditions while helping barangay teams verify information and coordinate response.</p></div><div class="about-grid"><article><span><i class="bi bi-water"></i></span><h3>Monitor conditions</h3><p>Water level, rainfall, wind, bridge access, and station health are presented in one public view.</p></article><article><span><i class="bi bi-bell"></i></span><h3>Warn the community</h3><p>Verified changes support early warnings and help residents avoid unsafe bridge approaches.</p></article><article><span><i class="bi bi-people"></i></span><h3>Coordinate response</h3><p>Resident reports connect with barangay personnel and assigned response teams through a controlled workflow.</p></article></div></section>
  <section class="monitoring-shell" id="monitoring" aria-labelledby="monitoring-title">
    <div class="station-bar"><div><span class="section-label">Monitoring station</span><h2 id="monitoring-title"><span id="stationName">Spillway Bridge Monitoring Station</span></h2><p><i class="bi bi-geo-alt"></i> <span id="stationLocation">Barangay San Isidro, Rodriguez, Rizal</span></p></div><div class="station-meta"><span id="connectionBadge" class="status-badge state-loading"><span></span><b id="connectionLabel">Connecting</b></span><small>Last sensor reading: <time id="lastUpdated">Checking…</time></small></div></div>
    <div id="alertPanel" class="alert-panel state-loading" role="status" aria-live="polite"><span class="alert-icon"><i id="alertIcon" class="bi bi-hourglass-split"></i></span><div><span id="alertLevel" class="section-label">Connecting</span><h2 id="alertTitle">Retrieving current conditions</h2><p id="alertMessage">Please wait while FloodGuard contacts the monitoring station.</p></div></div>
    <div class="reading-grid" aria-label="Latest sensor readings">
      <article class="reading-card water"><span class="card-icon"><i class="bi bi-water"></i></span><div><span>Water level</span><strong id="waterLevel">--</strong><small id="waterDistance">Distance: --</small></div></article>
      <article class="reading-card rain"><span class="card-icon"><i class="bi bi-cloud-rain"></i></span><div><span>Rain condition</span><strong id="rainStatus">--</strong><small id="rainDetail">Awaiting reading</small></div></article>
      <article class="reading-card wind"><span class="card-icon"><i class="bi bi-wind"></i></span><div><span>Wind speed</span><strong id="windSpeed">--</strong><small>Local station measurement</small></div></article>
    </div>
    <div class="detail-grid">
      <article class="bridge-card"><div class="card-heading"><div><span class="section-label">Bridge access</span><h2>Barrier status</h2></div><i class="bi bi-sign-stop"></i></div><div class="barrier-grid"><div><span>North barrier</span><strong id="northBarrier">--</strong></div><div><span>South barrier</span><strong id="southBarrier">--</strong></div></div><p class="safety-note"><i class="bi bi-exclamation-triangle"></i> Obey physical barriers and official instructions even if this page shows an older condition.</p></article>
      <article class="health-card"><div class="card-heading"><div><span class="section-label">Data confidence</span><h2>Station health</h2></div><i class="bi bi-shield-check"></i></div><dl><div><dt>Sensor</dt><dd id="sensorHealth">Checking</dd></div><div><dt>Device ID</dt><dd id="deviceId">FG-STATION-001</dd></div><div><dt>Reading age</dt><dd id="readingAge">--</dd></div></dl></article>
    </div>
  </section>
  <section class="content-section updates-section" id="updates"><div class="section-heading section-heading-action"><div><span class="section-label">Verified community newsfeed</span><h2>Latest updates from residents</h2><p>Recent observations submitted through the FloodGuard resident app and reviewed by barangay personnel before publication.</p></div><a class="text-action" href="community-updates.php">See all posts <i class="bi bi-arrow-right"></i></a></div><div id="publicPosts" class="public-post-list public-post-preview" aria-live="polite"><article class="empty-state"><i class="bi bi-chat-square-text"></i><div><h3>Loading verified updates</h3><p>Please wait while FloodGuard retrieves the latest community posts.</p></div></article></div><div class="feed-footer"><span id="postCount" class="feed-count">Loading updates…</span></div></section>
  <section class="content-section app-promo app-download-promo" id="resident-app"><div class="app-promo-copy"><span class="section-label">FloodGuard for Android</span><h2>Are you a resident? Stay informed and help protect your community.</h2><p>Receive bridge updates, submit flood reports with photos, share verified observations, and follow barangay response—all from one secure resident app.</p><div class="app-benefits"><div><i class="bi bi-bell"></i><span><strong>Receive important alerts</strong><small>Stay informed about bridge access and changing flood conditions.</small></span></div><div><i class="bi bi-camera"></i><span><strong>Report local conditions</strong><small>Send photos, location, and incident details directly to the barangay.</small></span></div><div><i class="bi bi-people"></i><span><strong>Share verified updates</strong><small>Help neighbors with observations reviewed before public posting.</small></span></div><div><i class="bi bi-geo-alt"></i><span><strong>Follow the response</strong><small>Track your report and the responder assigned to it.</small></span></div></div><div class="download-actions">
  <a
  class="download-button"
  href="/downloads/floodguard-resident-v1.0.apk?v=20261001-1"
  download="floodguard-resident-v1.0.apk"
>
  <i class="bi bi-android2"></i>

  <span>
    <strong>Download for Android</strong>
    <small>Version 1.0 · APK</small>
  </span>

  <i class="bi bi-download"></i>
</a>

  <p class="download-note">
    <i class="bi bi-shield-check"></i>
    Official download from floodguard.site. Android may ask you to allow
    installation from your browser.
  </p>
</div></div><aside class="app-access-card"><span class="app-logo"><img src="assets/images/floodguard-logo.png" alt="FloodGuard logo"></span><span class="resident-only">Barangay San Isidro residents</span><h3>How resident access works</h3><p>Create an account using accurate contact and residency information.</p><ol><li><span>1</span>Download and register</li><li><span>2</span>Verify your email</li><li><span>3</span>Upload proof of residency</li><li><span>4</span>Wait for barangay approval</li></ol><div class="requirements"><strong><i class="bi bi-phone"></i> Android application</strong><small>Internet connection required. Keep the app updated through this official website.</small></div></aside></section>
  <section class="content-section" id="safety"><div class="safety-banner"><i class="bi bi-shield-fill-exclamation"></i><div><span class="section-label">Safety first</span><h2>Digital readings support—but never replace—official instructions.</h2><p>During severe weather, avoid flooded roads and bridges. Follow barangay, MDRRMO, police, and emergency-responder directions.</p></div></div></section>
</main>
<footer><div><strong>FloodGuard</strong><span>Spillway Bridge · Barangay San Isidro, Rodriguez, Rizal</span></div><p>Emergency information remains subject to official confirmation.</p></footer>
<script src="assets/js/public-monitoring.js?v=20260925-3" defer></script>
</body></html>
