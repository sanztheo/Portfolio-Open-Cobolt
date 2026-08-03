<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{{SITE_TITRE}}</title>
<meta name="description" content="{{SITE_DESCRIPTION}}">
<meta name="author" content="{{NOM}}">
<link rel="canonical" href="{{SITE_URL}}">
<meta property="og:type" content="profile">
<meta property="og:title" content="{{SITE_TITRE}}">
<meta property="og:description" content="{{SITE_DESCRIPTION}}">
<meta property="og:url" content="{{SITE_URL}}">
<meta property="og:locale" content="fr_FR">
<meta name="twitter:card" content="summary">
<meta name="theme-color" content="#EFEFE8">
<link rel="icon" href="{{FAVICON}}">
<script type="application/ld+json">{{&JSONLD}}</script>
<style>
{{@STYLE}}
</style>
</head>
<body>
<a class="skip" href="#contenu">Aller au contenu</a>
<div class="sheet">

<nav class="nav" aria-label="Navigation principale">
<p class="nav-id"><span class="nav-id-name">{{NOM}}</span><span class="nav-id-role">{{ROLE_COURT}}</span></p>
<ul class="nav-list">
<li><a href="#profil">Profil</a></li>
<li><a href="#apropos">À propos</a></li>
<li><a href="#competences">Compétences</a></li>
<li><a href="#projets">Projets</a></li>
<li><a href="#parcours">Parcours</a></li>
<li><a href="#contact">Contact</a></li>
</ul>
</nav>

<main id="contenu">

<header class="block" id="profil">
<p class="division">IDENTIFICATION DIVISION.</p>
<h1 class="name">{{NOM}}</h1>
<p class="tagline">{{&ACCROCHE}}</p>
<ul class="facts">
<li><b>Poste</b> {{FAIT_POSTE}}</li>
<li><b>Alternance</b> {{FAIT_ALTERNANCE}}</li>
<li><b>Formation</b> {{FAIT_FORMATION}}</li>
<li><b>Terrain</b> {{FAIT_TERRAIN}}</li>
</ul>
</header>

<section class="block" id="apropos" aria-labelledby="t-apropos">
<h2 class="division" id="t-apropos">01 &nbsp;À propos <span class="gloss">— qui je suis, en six temps</span></h2>
<ol class="pitch">
<li><h3>{{PITCH_1_TITRE}}</h3><p>{{PITCH_1_TEXTE}}</p></li>
<li><h3>{{PITCH_2_TITRE}}</h3><p>{{PITCH_2_TEXTE}}</p></li>
<li><h3>{{PITCH_3_TITRE}}</h3><p>{{PITCH_3_TEXTE}}</p></li>
<li><h3>{{PITCH_4_TITRE}}</h3><p>{{PITCH_4_TEXTE}}</p></li>
<li><h3>{{PITCH_5_TITRE}}</h3><p>{{PITCH_5_TEXTE}}</p></li>
<li><h3>{{PITCH_6_TITRE}}</h3><p>{{PITCH_6_TEXTE}}</p></li>
</ol>
</section>

<section class="block" id="competences" aria-labelledby="t-competences">
<h2 class="division" id="t-competences">ENVIRONMENT DIVISION. <span class="gloss">— ce avec quoi je travaille</span></h2>
<p class="lead">{{COMPETENCES_CHAPO}}</p>
<dl class="skills">
{{@COMPETENCES}}
</dl>
<p class="note">{{COMPETENCES_NOTE}}</p>
</section>

<section class="block" id="projets" aria-labelledby="t-projets">
<h2 class="division" id="t-projets">DATA DIVISION. <span class="gloss">— ce que j&#39;ai construit</span></h2>
<p class="lead">{{PROJETS_CHAPO}}</p>
<ol class="rows">
{{@PROJETS}}
</ol>
</section>

<section class="block" id="parcours" aria-labelledby="t-parcours">
<h2 class="division" id="t-parcours">PROCEDURE DIVISION. <span class="gloss">— comment j&#39;en suis arrivé là</span></h2>
<ol class="timeline">
{{@PARCOURS}}
</ol>
</section>

<section class="block" id="contact" aria-labelledby="t-contact">
<h2 class="division" id="t-contact">STOP RUN. <span class="gloss">— me joindre</span></h2>
<p class="lead">{{CONTACT_CHAPO}}</p>
<ul class="contact">
<li><a href="mailto:{{CONTACT_EMAIL}}">{{CONTACT_EMAIL}}</a></li>
<li><a href="{{CONTACT_GITHUB}}" rel="me noopener">GitHub</a></li>
<li><a href="{{CONTACT_LINKEDIN}}" rel="me noopener">LinkedIn</a></li>
<li><a href="{{CONTACT_SOLVA}}" rel="noopener">Solva</a></li>
</ul>
</section>

</main>

<footer class="colophon">
<p class="stamp">Généré par COBOL</p>
<p>{{&COLOPHON}}</p>
<p class="build">{{COLOPHON_BUILD}}</p>
</footer>

</div>
</body>
</html>
