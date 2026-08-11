# Portfolio généré en COBOL

Un portfolio dont **chaque octet de HTML est écrit par un programme COBOL**.
Pas de framework, pas de JavaScript, pas une dépendance à installer.

Le HTML ne vit pas dans le COBOL : le programme est un **moteur de gabarits**
qui lit des fichiers de contenu, remplit des gabarits, et écrit la page.

## Ce qu'il y a dedans

```
src/buildsite.cbl    orchestrateur : lit les fichiers, appelle, écrit
src/render.cbl       substitution des marqueurs d'une ligne de gabarit
src/dictget.cbl      résolution d'une clé dans le dictionnaire
src/htmlesc.cbl      échappement des caractères significatifs en HTML
src/cpy/dicttab.cpy  disposition de la table, partagée par tous les modules
src/style.css        feuille de style, injectée en ligne dans le <head>

templates/page.tpl        squelette de la page
templates/projet.tpl      gabarit d'une fiche projet
templates/competence.tpl  gabarit d'une famille de compétences
templates/etape.tpl       gabarit d'une étape de parcours

content/site.dat        clés globales
content/projets.dat     un enregistrement par projet
content/competences.dat un enregistrement par famille
content/parcours.dat    un enregistrement par étape

tests/testunit.cbl    13 tests unitaires, écrits en COBOL
tests/integration.sh  8 tests du programme entier face à du contenu cassé

dist/index.html       la sortie
```

## Lancer

```bash
brew install gnucobol          # macOS
sudo apt install gnucobol      # Debian, Ubuntu

./build.sh          # compile, teste, génère dist/
./serve.sh          # construit puis ouvre le site dans le navigateur
```

`build.sh` compile, lance les tests unitaires, génère le site, lance les tests
d'intégration. Il s'arrête au premier problème — y compris sur un simple
avertissement du compilateur.

`serve.sh` construit puis sert `dist/` en local. Sans argument il prend le
premier port libre à partir de 8000 et ouvre le navigateur ; `./serve.sh 3000`
impose un port, `./serve.sh --sans-build` sert la sortie existante sans
reconstruire. Un vrai serveur plutôt qu'un `file://` : les types MIME sont
corrects et le comportement est celui qu'aura le site en ligne.

## Le moteur

Un gabarit contient des marqueurs. Deux formes, et la différence compte :

```html
<h1>{{NOM}}</h1>          la valeur est échappée avant d'être insérée
<p>{{&ACCROCHE}}</p>      la valeur est insérée telle quelle
```

`{{CLE}}` est le cas par défaut, donc le cas sûr : une valeur de contenu ne peut
pas injecter de balise. `{{&CLE}}` désigne un fragment déjà formé en HTML, et
l'esperluette rend ce choix visible à la lecture du gabarit plutôt que caché
dans le code.

Quatre directives occupent une ligne à elles seules :

```
{{@STYLE}}         recopie la feuille de style
{{@PROJETS}}       déroule content/projets.dat dans templates/projet.tpl
{{@COMPETENCES}}   idem pour les compétences
{{@PARCOURS}}      idem pour le parcours
```

## Le format de contenu

Une ligne `[ITEM]` ouvre un enregistrement. Sur les autres lignes, **la clé
occupe les 40 premières colonnes**, la valeur suit jusqu'en fin de ligne.

```
[ITEM]
P_TITRE                                 Nina Carducci
P_ANNEE                                 2026
P_RESUME                                Audit et correction d'un site vitrine.
```

Ce format n'est pas un caprice d'époque. Il n'y a **aucun code d'analyse** dans
le projet : la description d'enregistrement COBOL

```cobol
01  DAT-PRJ-LIGNE.
    05  PRJ-CLE       PIC X(40).
    05  PRJ-VALEUR    PIC X(700).
```

*est* l'analyseur. La lecture d'une ligne remplit directement les deux champs.
Le prix à payer est l'alignement : une clé mal cadrée devient une autre clé.
Le générateur le dit alors explicitement, avec le nom du fichier et de la clé.

## Ce qui arrête la construction

Le moteur refuse de produire une page approximative. Une page à moitié juste se
publie sans que personne ne la regarde ; une construction qui échoue se voit.

| Cas | Code |
|---|---|
| Clé absente du contenu | 1 |
| Fichier illisible | 2 |
| Table de clés pleine | 3 |
| Trop de champs dans un enregistrement | 4 |
| Gabarit de bloc trop long | 5 |
| Ligne de contenu de plus de 700 caractères | 6 |
| Gabarit de page vide | 7 |

Les trois derniers cas viennent de défauts réels : ils produisaient une page
fausse en annonçant un succès. Une ligne trop longue débordait sur
l'enregistrement suivant et fabriquait une clé fantôme ; un gabarit vide donnait
une page de zéro octet. `tests/integration.sh` rejoue chacun de ces cas.

Le rendu part par ailleurs dans `dist/index.html.part`, que `build.sh` ne promeut
en page finale qu'après un succès complet — sans quoi un échec à mi-course
remplaçait un site valide par du HTML tronqué.

## Le choix du COBOL, et ce qu'il coûte

Le format est fixe, colonnes 8 à 72, et le tout compile sous `-std=cobol2014`
sans aucune concession de dialecte : pas de niveau 78 hérité d'IBM mais
`CONSTANT AS`, pas d'`ASSIGN` dynamique mais des noms de fichiers littéraux.

Cette dernière contrainte a un coût visible : chaque liste a son propre couple
de fichiers déclaré, donc les trois paragraphes qui déroulent les listes se
ressemblent beaucoup. Un `ASSIGN` vers un nom de données aurait factorisé
l'ensemble, mais c'est une extension GnuCOBOL. La duplication est le prix du
COBOL normalisé, et elle est assumée.

Le format fixe, lui, ne coûte plus rien depuis que le HTML a quitté le code
pour vivre dans les gabarits : il ne reste plus de longs littéraux à découper.

## Mesures

Relevées sur la sortie réelle, Chrome sans interface, Lighthouse 13 et
axe-core 4.13 :

| | Bureau | Mobile |
|---|---|---|
| Performance | 100 | 100 |
| Accessibilité | 100 | 100 |
| Bonnes pratiques | 100 | 100 |
| SEO | 100 | 100 |

axe-core ne relève aucune violation. 43 Ko au total, CLS nul, aucun temps de
blocage. Les 27 éléments focusables ont un focus visible et une cible d'au moins
44 pixels. Aucun débordement horizontal de 320 à 2560 pixels.

Les deux captures de projet sont en WebP, chargement différé, rangées dans une
fiche repliée : une fiche jamais ouverte ne télécharge rien.

## Modifier le contenu

Aucune recompilation n'est nécessaire — le contenu est lu à l'exécution.

Ajouter un projet : un bloc `[ITEM]` dans `content/projets.dat`, avec les mêmes
clés que les autres. Si une clé manque, la construction s'arrête et la nomme.

Changer le texte de présentation, les liens : `content/site.dat`.
Les couleurs, la typographie : `src/style.css`.
La structure de la page : `templates/page.tpl`.

## Déployer

Le COBOL tourne à la construction, pas au service : l'hébergeur ne sert que des
fichiers statiques et n'a jamais besoin d'un compilateur.

Le site est en ligne ici :
**<https://sanztheo.github.io/portfolio-cobol/>**

`.github/workflows/deploy.yml` installe GnuCOBOL sur un runner Ubuntu neuf,
compile, lance les deux suites de tests, génère la page et publie sur GitHub
Pages à chaque poussée sur `main`. Il vérifie donc aussi que le projet se
reconstruit depuis zéro sur une machine qui ne connaît rien de mon poste —
avec GnuCOBOL 3.1.2 côté Ubuntu là où je développe en 3.2 sur macOS.

Pour un autre hébergeur : lancer `./build.sh` et livrer `dist/`.

## Le parti pris visuel

Le référentiel n'est pas le terminal à phosphore vert, qui est un cliché et qui
date d'ailleurs d'après COBOL. C'est le **listing d'imprimante à bandes** : le
papier en accordéon vert pâle, les perforations d'entraînement sur les côtés,
une seule chasse de caractères, les lignes de points de conduite.

Les bandes vertes ne sont pas un décor : ce sont les lignes paires de la liste
de projets. Elles s'alignent donc sur le contenu, comme sur une vraie sortie
d'imprimante ligne.

Les sections reprennent les divisions du langage. `IDENTIFICATION DIVISION` pour
l'identité, `ENVIRONMENT DIVISION` pour les compétences — c'est la division qui
décrit la machine et les ressources dont le programme a besoin —, `DATA
DIVISION` pour les projets, `PROCEDURE DIVISION` pour le parcours, `STOP RUN`
pour le contact.
