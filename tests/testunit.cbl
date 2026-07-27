      ******************************************************************
      *  TESTUNIT - TESTS UNITAIRES DES MODULES DU MOTEUR              *
      *                                                                *
      *  CHAQUE TEST APPELLE UN MODULE ISOLEMENT AVEC UNE ENTREE       *
      *  CONNUE ET COMPARE LE RESULTAT A LA VALEUR ATTENDUE. LE        *
      *  PROGRAMME REND 1 SI UN SEUL TEST ECHOUE, 0 SINON, POUR QUE    *
      *  build.sh PUISSE S ARRETER DESSUS.                             *
      *                                                                *
      *  LES OCTETS UTF-8 SONT ECRITS EN HEXADECIMAL PLUTOT QU EN      *
      *  CARACTERES ACCENTUES. DEUX RAISONS : LE FICHIER SOURCE RESTE  *
      *  EN ASCII PUR, ET SURTOUT LE TEST DEVIENT EXACT A L OCTET      *
      *  PRES AU LIEU DE DEPENDRE DE L ENCODAGE DE L EDITEUR.          *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTUNIT.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-NB-OK          PIC 9(4) VALUE ZERO.
       01  WS-NB-KO          PIC 9(4) VALUE ZERO.
      *
      *    ----- MATERIEL POUR HTMLESC -----
       01  WS-ESC-ENTREE     PIC X(700)  VALUE SPACES.
       01  WS-ESC-SORTIE     PIC X(4200) VALUE SPACES.
      *
      *    "abc" + U+00E9 (E ACCENT AIGU, OCTETS C3 A9) + "def"
       01  WS-ACCENT.
           05  FILLER        PIC X(3) VALUE "abc".
           05  FILLER        PIC X(2) VALUE X"C3A9".
           05  FILLER        PIC X(3) VALUE "def".
      *
      *    ----- MATERIEL PARTAGE DICTGET / RENDER -----
       01  WS-NB-ENTREES     PIC 9(4) VALUE ZERO.
       COPY "dicttab.cpy".
       01  WS-CLE            PIC X(40)  VALUE SPACES.
       01  WS-VALEUR         PIC X(700) VALUE SPACES.
       01  WS-CODE           PIC 9(2)   VALUE ZERO.
      *
      *    ----- MATERIEL POUR RENDER -----
       01  WS-LIGNE-IN       PIC X(2000) VALUE SPACES.
       01  WS-LIGNE-OUT      PIC X(6000) VALUE SPACES.
       01  WS-CLE-FAUTIVE    PIC X(40)   VALUE SPACES.
      *
       PROCEDURE DIVISION.
      *
       PRINCIPAL.
           DISPLAY "--- TESTS UNITAIRES DU MOTEUR COBOL ---"
           PERFORM TEST-ESC-CARACTERES-SPECIAUX
           PERFORM TEST-ESC-UTF8-INTACT
           PERFORM TEST-ESC-CHAINE-VIDE
           PERFORM PREPARER-DICTIONNAIRE
           PERFORM TEST-DICT-CLE-CONNUE
           PERFORM TEST-DICT-CLE-INCONNUE
           PERFORM TEST-DICT-PORTEE-LOCALE
           PERFORM TEST-RENDER-ECHAPPE-ET-BRUT
           PERFORM TEST-RENDER-SANS-MARQUEUR
           PERFORM TEST-RENDER-DEUX-MARQUEURS
           PERFORM TEST-RENDER-CLE-INCONNUE
           PERFORM AFFICHER-BILAN
           IF WS-NB-KO > ZERO
               STOP RUN RETURNING 1
           END-IF
           STOP RUN RETURNING 0.
      *
      ******************************************************************
      *  HTMLESC                                                       *
      ******************************************************************
       TEST-ESC-CARACTERES-SPECIAUX.
           MOVE SPACES TO WS-ESC-ENTREE
           MOVE "Tom & Jerry <b>x</b>" TO WS-ESC-ENTREE
           CALL "HTMLESC" USING WS-ESC-ENTREE WS-ESC-SORTIE
           IF WS-ESC-SORTIE(1:44) =
               "Tom &amp; Jerry &lt;b&gt;x&lt;/b&gt;"
               PERFORM COMPTER-OK
               DISPLAY "  OK   echappement de & < >"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC echappement : ["
                       FUNCTION TRIM(WS-ESC-SORTIE(1:60)) "]"
           END-IF.
      *
      *    LES OCTETS D UN CARACTERE ACCENTUE VALENT C3 A9, DONC AU
      *    DESSUS DE X'7F'. AUCUN NE PEUT ETRE CONFONDU AVEC & < > OU
      *    LE GUILLEMET : ILS DOIVENT RESSORTIR INCHANGES.
       TEST-ESC-UTF8-INTACT.
           MOVE SPACES     TO WS-ESC-ENTREE
           MOVE WS-ACCENT  TO WS-ESC-ENTREE
           CALL "HTMLESC" USING WS-ESC-ENTREE WS-ESC-SORTIE
           IF WS-ESC-SORTIE(1:8) = WS-ACCENT
               PERFORM COMPTER-OK
               DISPLAY "  OK   octets UTF-8 traverses intacts"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC UTF-8 corrompu par l echappement"
           END-IF.
      *
       TEST-ESC-CHAINE-VIDE.
           MOVE SPACES    TO WS-ESC-ENTREE
           MOVE "residu"  TO WS-ESC-SORTIE
           CALL "HTMLESC" USING WS-ESC-ENTREE WS-ESC-SORTIE
           IF WS-ESC-SORTIE = SPACES
               PERFORM COMPTER-OK
               DISPLAY "  OK   chaine vide"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC chaine vide : sortie non blanchie"
           END-IF.
      *
      ******************************************************************
      *  DICTGET                                                       *
      ******************************************************************
      *    LA DISPOSITION IMITE CELLE DE BUILDSITE : LES EMPLACEMENTS
      *    LOCAUX D ABORD, LES GLOBAUX ENSUITE. LA CLE "TITRE" EXISTE
      *    DANS LES DEUX PORTEES, EXPRES.
       PREPARER-DICTIONNAIRE.
           MOVE SPACES TO DICT-TABLE
           MOVE "TITRE"       TO DICT-CLE(1)
           MOVE "Local"       TO DICT-VALEUR(1)
           MOVE "NOM"         TO DICT-CLE(41)
           MOVE "Theo"        TO DICT-VALEUR(41)
           MOVE "FRAGMENT"    TO DICT-CLE(42)
           MOVE "<b>gras</b>" TO DICT-VALEUR(42)
           MOVE "TITRE"       TO DICT-CLE(43)
           MOVE "Global"      TO DICT-VALEUR(43)
           MOVE 43 TO WS-NB-ENTREES.
      *
       TEST-DICT-CLE-CONNUE.
           MOVE "NOM" TO WS-CLE
           CALL "DICTGET" USING WS-NB-ENTREES DICT-TABLE WS-CLE
                                WS-VALEUR WS-CODE
           IF WS-CODE = ZERO AND FUNCTION TRIM(WS-VALEUR) = "Theo"
               PERFORM COMPTER-OK
               DISPLAY "  OK   resolution d une cle connue"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC cle connue : code " WS-CODE
           END-IF.
      *
       TEST-DICT-CLE-INCONNUE.
           MOVE "ABSENTE" TO WS-CLE
           CALL "DICTGET" USING WS-NB-ENTREES DICT-TABLE WS-CLE
                                WS-VALEUR WS-CODE
           IF WS-CODE = 99
               PERFORM COMPTER-OK
               DISPLAY "  OK   cle inconnue signalee"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC cle inconnue : code " WS-CODE
           END-IF.
      *
      *    LA REGLE DE PORTEE DU GENERATEUR TIENT ENTIEREMENT A CE QUE
      *    DICTGET RETIENNE LA PREMIERE CORRESPONDANCE. CE TEST LA
      *    VERROUILLE : SANS LUI, UNE OPTIMISATION DE LA BOUCLE
      *    POURRAIT INVERSER LA PRIORITE SANS RIEN CASSER D AUTRE.
       TEST-DICT-PORTEE-LOCALE.
           MOVE "TITRE" TO WS-CLE
           CALL "DICTGET" USING WS-NB-ENTREES DICT-TABLE WS-CLE
                                WS-VALEUR WS-CODE
           IF WS-CODE = ZERO AND FUNCTION TRIM(WS-VALEUR) = "Local"
               PERFORM COMPTER-OK
               DISPLAY "  OK   la cle locale masque la globale"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC portee : obtenu ["
                       FUNCTION TRIM(WS-VALEUR) "]"
           END-IF.
      *
      ******************************************************************
      *  RENDER                                                        *
      ******************************************************************
       TEST-RENDER-ECHAPPE-ET-BRUT.
           MOVE "Salut {{NOM}}, voici {{&FRAGMENT}}" TO WS-LIGNE-IN
           PERFORM APPELER-RENDER
           IF WS-CODE = ZERO AND FUNCTION TRIM(WS-LIGNE-OUT) =
               "Salut Theo, voici <b>gras</b>"
               PERFORM COMPTER-OK
               DISPLAY "  OK   marqueur echappe et marqueur brut"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC rendu mixte : ["
                       FUNCTION TRIM(WS-LIGNE-OUT) "]"
           END-IF.
      *
       TEST-RENDER-SANS-MARQUEUR.
           MOVE "<p>Ligne ordinaire</p>" TO WS-LIGNE-IN
           PERFORM APPELER-RENDER
           IF WS-CODE = ZERO AND FUNCTION TRIM(WS-LIGNE-OUT) =
               "<p>Ligne ordinaire</p>"
               PERFORM COMPTER-OK
               DISPLAY "  OK   ligne sans marqueur recopiee"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC ligne sans marqueur alteree"
           END-IF.
      *
       TEST-RENDER-DEUX-MARQUEURS.
           MOVE "{{NOM}}-{{NOM}}" TO WS-LIGNE-IN
           PERFORM APPELER-RENDER
           IF WS-CODE = ZERO AND FUNCTION TRIM(WS-LIGNE-OUT) =
               "Theo-Theo"
               PERFORM COMPTER-OK
               DISPLAY "  OK   deux marqueurs sur la meme ligne"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC deux marqueurs : ["
                       FUNCTION TRIM(WS-LIGNE-OUT) "]"
           END-IF.
      *
       TEST-RENDER-CLE-INCONNUE.
           MOVE "Bonjour {{FANTOME}}" TO WS-LIGNE-IN
           PERFORM APPELER-RENDER
           IF WS-CODE = 99
                   AND FUNCTION TRIM(WS-CLE-FAUTIVE) = "FANTOME"
               PERFORM COMPTER-OK
               DISPLAY "  OK   cle absente refusee et nommee"
           ELSE
               PERFORM COMPTER-KO
               DISPLAY "  ECHEC cle absente : code " WS-CODE
           END-IF.
      *
       APPELER-RENDER.
           MOVE SPACES TO WS-LIGNE-OUT
           MOVE SPACES TO WS-CLE-FAUTIVE
           CALL "RENDER" USING WS-NB-ENTREES DICT-TABLE
                               WS-LIGNE-IN WS-LIGNE-OUT
                               WS-CODE WS-CLE-FAUTIVE
           MOVE SPACES TO WS-LIGNE-IN.
      *
      ******************************************************************
      *  COMPTAGE ET BILAN                                             *
      ******************************************************************
       COMPTER-OK.
           ADD 1 TO WS-NB-OK.
      *
       COMPTER-KO.
           ADD 1 TO WS-NB-KO.
      *
       AFFICHER-BILAN.
           DISPLAY "--- BILAN : " WS-NB-OK " reussis, "
                   WS-NB-KO " echoues ---".
