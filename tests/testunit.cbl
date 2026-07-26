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
       PROCEDURE DIVISION.
      *
       PRINCIPAL.
           DISPLAY "--- TESTS UNITAIRES DU MOTEUR COBOL ---"
           PERFORM TEST-ESC-CARACTERES-SPECIAUX
           PERFORM TEST-ESC-UTF8-INTACT
           PERFORM TEST-ESC-CHAINE-VIDE
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
