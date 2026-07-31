      ******************************************************************
      *  BUILDSITE - GENERATEUR DU PORTFOLIO                           *
      *                                                                *
      *  ROLE : ORCHESTRER. IL NE SAIT NI ECHAPPER, NI SUBSTITUER, NI  *
      *  RESOUDRE UNE CLE : IL DELEGUE TOUT A RENDER, QUI DELEGUE A    *
      *  DICTGET ET HTMLESC. CE PROGRAMME NE FAIT QUE LIRE DES         *
      *  FICHIERS, APPELER, ET ECRIRE.                                 *
      *                                                                *
      *  ENTREES                                                       *
      *    content/site.dat         CLES GLOBALES DU SITE              *
      *    templates/page.tpl       SQUELETTE DE LA PAGE               *
      *    src/style.css            FEUILLE DE STYLE, INJECTEE TELLE   *
      *                             QUELLE DANS LE <head>              *
      *  SORTIE                                                        *
      *    dist/index.html                                             *
      *                                                                *
      *  DIRECTIVE RECONNUE DANS UN GABARIT, SEULE SUR SA LIGNE :      *
      *    {{@STYLE}}                                                  *
      *        RECOPIE LA FEUILLE DE STYLE OCTET POUR OCTET.           *
      *                                                                *
      *  FORMAT DU FICHIER DE CONTENU                                  *
      *    CHAQUE LIGNE EST UNE PAIRE : LA CLE OCCUPE LES 40           *
      *    PREMIERES COLONNES, LA VALEUR SUIT JUSQU EN FIN DE LIGNE.   *
      *    UNE LIGNE VIDE OU DEBUTANT PAR "#" EST IGNOREE.             *
      *                                                                *
      *  PORTEE DES CLES                                               *
      *    LES 40 PREMIERS EMPLACEMENTS DE LA TABLE SONT RESERVES AUX  *
      *    CLES DE L ENREGISTREMENT EN COURS, LES SUIVANTS AUX CLES    *
      *    GLOBALES. COMME DICTGET RETIENT LA PREMIERE CORRESPONDANCE, *
      *    UNE CLE D ENREGISTREMENT MASQUE SON HOMONYME GLOBAL. CE     *
      *    N EST PAS UN EFFET DE BORD : C EST LA REGLE DE PORTEE, ET   *
      *    ELLE EST OBTENUE PAR LA DISPOSITION MEMOIRE PLUTOT QUE PAR  *
      *    UNE COMPARAISON SUPPLEMENTAIRE.                             *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BUILDSITE.
      *
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-SITE   ASSIGN TO "content/site.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-ST-SITE.
           SELECT F-PAGE   ASSIGN TO "templates/page.tpl"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-ST-PAGE.
           SELECT F-CSS    ASSIGN TO "src/style.css"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-ST-CSS.
           SELECT F-SORTIE ASSIGN TO "dist/index.html"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-ST-SORTIE.
      *    UN COUPLE GABARIT + DONNEES PAR LISTE. LES NOMS DE FICHIERS
      *    SONT DES LITTERAUX : C EST LA SEULE FORME D ASSIGN CONFORME
      *    A LA NORME. GNUCOBOL ACCEPTE UN NOM DE DONNEES A LA PLACE,
      *    MAIS C EST UNE EXTENSION, ET CE PROGRAMME TIENT A COMPILER
      *    SOUS -std=cobol2014 SANS AUCUNE CONCESSION DE DIALECTE.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  F-SITE.
       01  SITE-LIGNE.
           05  SITE-CLE      PIC X(40).
           05  SITE-VALEUR   PIC X(700).
       FD  F-PAGE.
       01  PAGE-LIGNE        PIC X(2000).
       FD  F-CSS.
       01  CSS-LIGNE         PIC X(400).
       FD  F-SORTIE.
       01  SORTIE-LIGNE      PIC X(6000).
      *
       WORKING-STORAGE SECTION.
      *
      *    ----- CONSTANTES DE DIMENSIONNEMENT -----
      *    LES 40 PREMIERS EMPLACEMENTS SONT LA PORTEE LOCALE.
      *    ECRIT AVEC "CONSTANT AS", LA FORME NORMALISEE, ET NON AVEC
      *    LE NIVEAU 78 HERITE D IBM QUE COBOL 2014 REJETTE.
       01  MAX-LOCALES       CONSTANT AS 40.
       01  MAX-TOTAL         CONSTANT AS 240.
       01  MAX-LIGNES-BLOC   CONSTANT AS 120.
      *
       COPY "dicttab.cpy".
      *
      *    ----- ETATS DE FICHIER -----
       01  WS-ST-SITE        PIC XX VALUE SPACES.
       01  WS-ST-PAGE        PIC XX VALUE SPACES.
       01  WS-ST-CSS         PIC XX VALUE SPACES.
       01  WS-ST-SORTIE      PIC XX VALUE SPACES.
       01  WS-ST-TPL         PIC XX VALUE SPACES.
       01  WS-ST-DAT         PIC XX VALUE SPACES.
      *
      *    ----- COMPTEURS DE PORTEE -----
       01  WS-NB-GLOBALES    PIC 9(4) VALUE ZERO.
       01  WS-NB-LOCALES     PIC 9(4) VALUE ZERO.
       01  WS-NB-VISIBLES    PIC 9(4) VALUE ZERO.
      *
      *    ----- INDICE DE PARCOURS DE LA PORTEE LOCALE -----
       01  WS-IDX-BLOC       PIC 9(4) VALUE ZERO.
      *
      *    ----- DRAPEAUX DE FIN DE FICHIER -----
       01  WS-FIN            PIC X VALUE "N".
           88  WS-EST-FIN     VALUE "Y".
       01  WS-FIN-DAT        PIC X VALUE "N".
           88  WS-DAT-FINI    VALUE "Y".
      *
      *    ----- ECHANGES AVEC RENDER -----
       01  WS-LIGNE-RENDUE   PIC X(6000) VALUE SPACES.
       01  WS-CODE-RENDER    PIC 9(2) VALUE ZERO.
       01  WS-CLE-FAUTIVE    PIC X(40) VALUE SPACES.
       01  WS-NO-LIGNE       PIC 9(6) VALUE ZERO.
       01  WS-SECTION-COUR   PIC X(30) VALUE SPACES.
      *
      *    ----- DIVERS -----
       01  WS-DIRECTIVE      PIC X(40) VALUE SPACES.
       01  WS-CLE-COURANTE   PIC X(40)  VALUE SPACES.
       01  WS-VALEUR-COURANTE PIC X(700) VALUE SPACES.
       01  WS-ENR-OUVERT     PIC X VALUE "N".
           88  WS-DANS-ENR    VALUE "Y".
      *
       PROCEDURE DIVISION.
      *
       PRINCIPAL.
           PERFORM CHARGER-CLES-GLOBALES
           PERFORM GENERER-PAGE
           PERFORM AFFICHER-BILAN
           STOP RUN.
      *
      ******************************************************************
      *  CHARGEMENT DES CLES GLOBALES                                  *
      ******************************************************************
       CHARGER-CLES-GLOBALES.
           MOVE "site.dat" TO WS-SECTION-COUR
           MOVE SPACES TO DICT-TABLE
           MOVE ZERO TO WS-NB-GLOBALES
           MOVE "N" TO WS-FIN
           OPEN INPUT F-SITE
           IF WS-ST-SITE NOT = "00"
               MOVE "content/site.dat" TO WS-DIRECTIVE
               PERFORM ARRET-FICHIER-INTROUVABLE
           END-IF
           PERFORM UNTIL WS-EST-FIN
               READ F-SITE
                   AT END
                       MOVE "Y" TO WS-FIN
                   NOT AT END
                       PERFORM RANGER-CLE-GLOBALE
               END-READ
           END-PERFORM
           CLOSE F-SITE.
      *
       RANGER-CLE-GLOBALE.
           IF SITE-LIGNE = SPACES OR SITE-CLE(1:1) = "#"
               EXIT PARAGRAPH
           END-IF
           IF WS-NB-GLOBALES + MAX-LOCALES >= MAX-TOTAL
               DISPLAY "BUILDSITE : TROP DE CLES GLOBALES, LA TABLE "
                       "EST PLEINE. AUGMENTER OCCURS DANS dicttab.cpy."
               STOP RUN RETURNING 3
           END-IF
           MOVE SITE-CLE    TO WS-CLE-COURANTE
           MOVE SITE-VALEUR TO WS-VALEUR-COURANTE
           ADD 1 TO WS-NB-GLOBALES
           MOVE WS-CLE-COURANTE
               TO DICT-CLE(MAX-LOCALES + WS-NB-GLOBALES)
           MOVE WS-VALEUR-COURANTE
               TO DICT-VALEUR(MAX-LOCALES + WS-NB-GLOBALES).
      *
      ******************************************************************
      *  GENERATION DE LA PAGE                                         *
      ******************************************************************
       GENERER-PAGE.
           MOVE "N" TO WS-FIN
           MOVE ZERO TO WS-NO-LIGNE
           PERFORM VIDER-PORTEE-LOCALE
           OPEN INPUT F-PAGE
           IF WS-ST-PAGE NOT = "00"
               MOVE "templates/page.tpl" TO WS-DIRECTIVE
               PERFORM ARRET-FICHIER-INTROUVABLE
           END-IF
           OPEN OUTPUT F-SORTIE
           PERFORM UNTIL WS-EST-FIN
               READ F-PAGE
                   AT END
                       MOVE "Y" TO WS-FIN
                   NOT AT END
                       PERFORM TRAITER-LIGNE-PAGE
               END-READ
           END-PERFORM
           CLOSE F-PAGE
           CLOSE F-SORTIE.
      *
      *    UNE DIRECTIVE OCCUPE SA LIGNE A ELLE SEULE. TOUTE AUTRE
      *    LIGNE PART AU RENDU ORDINAIRE.
       TRAITER-LIGNE-PAGE.
           ADD 1 TO WS-NO-LIGNE
           MOVE FUNCTION TRIM(PAGE-LIGNE) TO WS-DIRECTIVE
           EVALUATE WS-DIRECTIVE
               WHEN "{{@STYLE}}"
                   PERFORM INJECTER-FEUILLE-DE-STYLE
               WHEN OTHER
                   MOVE PAGE-LIGNE TO WS-LIGNE-RENDUE
                   MOVE "page.tpl" TO WS-SECTION-COUR
                   PERFORM RENDRE-ET-ECRIRE
           END-EVALUATE.
      *
      *    LE CSS EST RECOPIE SANS PASSER PAR RENDER : IL CONTIENT DES
      *    ACCOLADES EN PAGAILLE, QUE LE MOTEUR PRENDRAIT POUR DES
      *    MARQUEURS. C EST UNE COPIE, PAS UN RENDU.
       INJECTER-FEUILLE-DE-STYLE.
           MOVE "N" TO WS-FIN-DAT
           OPEN INPUT F-CSS
           IF WS-ST-CSS NOT = "00"
               MOVE "src/style.css" TO WS-DIRECTIVE
               PERFORM ARRET-FICHIER-INTROUVABLE
           END-IF
           PERFORM UNTIL WS-DAT-FINI
               READ F-CSS
                   AT END
                       MOVE "Y" TO WS-FIN-DAT
                   NOT AT END
                       MOVE CSS-LIGNE TO SORTIE-LIGNE
                       WRITE SORTIE-LIGNE
               END-READ
           END-PERFORM
           CLOSE F-CSS
           MOVE "N" TO WS-FIN-DAT.
      *
      ******************************************************************
      *  RENDU D UNE LIGNE ET ECRITURE                                 *
      ******************************************************************
       RENDRE-ET-ECRIRE.
           PERFORM CALCULER-CLES-VISIBLES
           CALL "RENDER" USING WS-NB-VISIBLES DICT-TABLE
                               WS-LIGNE-RENDUE SORTIE-LIGNE
                               WS-CODE-RENDER WS-CLE-FAUTIVE
           IF WS-CODE-RENDER NOT = ZERO
               PERFORM ARRET-ERREUR-DE-RENDU
           END-IF
           WRITE SORTIE-LIGNE.
      *
      *    LA PORTEE VISIBLE COUVRE TOUJOURS LES 40 EMPLACEMENTS
      *    LOCAUX, MEME INOCCUPES : UN EMPLACEMENT VIDE A UNE CLE
      *    BLANCHE, ET RENDER REFUSE DEJA LES CLES VIDES, DONC AUCUNE
      *    RECHERCHE NE PEUT TOMBER DESSUS PAR ACCIDENT.
       CALCULER-CLES-VISIBLES.
           COMPUTE WS-NB-VISIBLES = MAX-LOCALES + WS-NB-GLOBALES.
      *
       VIDER-PORTEE-LOCALE.
           PERFORM VARYING WS-IDX-BLOC FROM 1 BY 1
                   UNTIL WS-IDX-BLOC > MAX-LOCALES
               MOVE SPACES TO DICT-CLE(WS-IDX-BLOC)
               MOVE SPACES TO DICT-VALEUR(WS-IDX-BLOC)
           END-PERFORM
           MOVE ZERO TO WS-NB-LOCALES.
      *
       RANGER-CLE-LOCALE.
           IF WS-NB-LOCALES >= MAX-LOCALES
               DISPLAY "BUILDSITE : TROP DE CHAMPS DANS UN "
                       "ENREGISTREMENT DE " WS-SECTION-COUR
               STOP RUN RETURNING 4
           END-IF
           ADD 1 TO WS-NB-LOCALES
           MOVE WS-CLE-COURANTE
               TO DICT-CLE(WS-NB-LOCALES)
           MOVE WS-VALEUR-COURANTE
               TO DICT-VALEUR(WS-NB-LOCALES).
      *
      ******************************************************************
      *  ARRETS EXPLICITES                                             *
      ******************************************************************
       ARRET-FICHIER-INTROUVABLE.
           DISPLAY "BUILDSITE : FICHIER ILLISIBLE -> "
                   FUNCTION TRIM(WS-DIRECTIVE)
           DISPLAY "  LANCER LE BUILD DEPUIS LA RACINE DU DEPOT."
           STOP RUN RETURNING 2.
      *
      *    LE MESSAGE NOMME LA SECTION ET LA CLE : SANS CA, CHERCHER
      *    UNE CLE MANQUANTE DANS QUATRE FICHIERS DE CONTENU EST UNE
      *    PERTE DE TEMPS PURE.
       ARRET-ERREUR-DE-RENDU.
           DISPLAY " "
           DISPLAY "BUILDSITE : ECHEC DU RENDU DANS " WS-SECTION-COUR
           EVALUATE WS-CODE-RENDER
               WHEN 95
                   DISPLAY "  LIGNE DE SORTIE TROP LONGUE, CLE "
                           FUNCTION TRIM(WS-CLE-FAUTIVE)
               WHEN 96
                   DISPLAY "  NOM DE CLE AU-DELA DE 40 CARACTERES : "
                           FUNCTION TRIM(WS-CLE-FAUTIVE)
               WHEN 97
                   DISPLAY "  MARQUEUR AVEC UN NOM DE CLE VIDE."
               WHEN 98
                   DISPLAY "  MARQUEUR OUVERT PAR {{ ET JAMAIS FERME."
               WHEN 99
                   DISPLAY "  CLE ABSENTE DU CONTENU : "
                           FUNCTION TRIM(WS-CLE-FAUTIVE)
               WHEN OTHER
                   DISPLAY "  CODE INATTENDU " WS-CODE-RENDER
           END-EVALUATE
           DISPLAY "  LIGNE FAUTIVE : "
                   FUNCTION TRIM(WS-LIGNE-RENDUE(1:120))
           STOP RUN RETURNING 1.
      *
       AFFICHER-BILAN.
           DISPLAY "BUILDSITE : " WS-NB-GLOBALES " cles globales.".
