      ******************************************************************
      *  RENDER - SUBSTITUTION DES MARQUEURS D UNE LIGNE DE GABARIT    *
      *                                                                *
      *  DEUX FORMES DE MARQUEURS :                                    *
      *    {{CLE}}   LA VALEUR EST ECHAPPEE AVANT D ETRE INSEREE.      *
      *              C EST LE CAS PAR DEFAUT, DONC LE CAS SUR.         *
      *    {{&CLE}}  LA VALEUR EST INSEREE TELLE QUELLE. RESERVE AUX   *
      *              FRAGMENTS DEJA FORMES EN HTML. L ESPERLUETTE      *
      *              REND CE CHOIX VISIBLE A LA LECTURE DU GABARIT.    *
      *                                                                *
      *  CODES RETOUR :                                                *
      *    0   SUCCES                                                  *
      *    99  CLE ABSENTE DU DICTIONNAIRE                             *
      *                                                                *
      *  PRINCIPE DIRECTEUR : TOUTE ANOMALIE ARRETE LE RENDU ET        *
      *  REMONTE UN CODE. AUCUNE N EST RATTRAPEE EN SILENCE. UNE PAGE  *
      *  A MOITIE JUSTE EST PIRE QU UNE COMPILATION QUI ECHOUE, PARCE  *
      *  QU ELLE SE PUBLIE SANS QUE PERSONNE NE REGARDE.               *
      *                                                                *
      *  NOTE UTF-8 : LES DELIMITEURS { } & SONT TOUS EN ASCII, DONC   *
      *  SOUS X'80'. LE BALAYAGE OCTET PAR OCTET NE PEUT PAS COUPER    *
      *  UN CARACTERE ACCENTUE EN DEUX.                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. RENDER.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LG-ENTREE      PIC 9(4) VALUE ZERO.
       01  WS-LG-SORTIE      PIC 9(4) VALUE ZERO.
       01  WS-POS            PIC 9(4) VALUE ZERO.
       01  WS-SCAN           PIC 9(4) VALUE ZERO.
       01  WS-POS-FERMETURE  PIC 9(4) VALUE ZERO.
       01  WS-DEBUT-CLE      PIC 9(4) VALUE ZERO.
       01  WS-LG-CLE         PIC 9(4) VALUE ZERO.
       01  WS-LG-VALEUR      PIC 9(4) VALUE ZERO.
       01  WS-CODE-DICT      PIC 9(2) VALUE ZERO.
       01  WS-BRUT           PIC X    VALUE "N".
           88  WS-EST-BRUT    VALUE "Y".
       01  WS-CLE            PIC X(40)   VALUE SPACES.
       01  WS-VALEUR         PIC X(700)  VALUE SPACES.
       01  WS-ECHAPPEE       PIC X(4200) VALUE SPACES.
      *
       LINKAGE SECTION.
       01  LK-NB-ENTREES     PIC 9(4).
       COPY "dicttab.cpy".
       01  LK-LIGNE-ENTREE   PIC X(2000).
       01  LK-LIGNE-SORTIE   PIC X(6000).
       01  LK-CODE-RETOUR    PIC 9(2).
           88  LK-OK              VALUE 0.
           88  LK-CLE-INCONNUE    VALUE 99.
       01  LK-CLE-FAUTIVE    PIC X(40).
      *
       PROCEDURE DIVISION USING LK-NB-ENTREES DICT-TABLE
                                LK-LIGNE-ENTREE LK-LIGNE-SORTIE
                                LK-CODE-RETOUR LK-CLE-FAUTIVE.
      *
       PRINCIPAL.
           PERFORM INITIALISER
           PERFORM UNTIL WS-POS > WS-LG-ENTREE OR NOT LK-OK
               IF WS-POS < WS-LG-ENTREE
                       AND LK-LIGNE-ENTREE(WS-POS:1) = "{"
                       AND LK-LIGNE-ENTREE(WS-POS + 1:1) = "{"
                   PERFORM TRAITER-MARQUEUR
               ELSE
                   PERFORM COPIER-CARACTERE
               END-IF
           END-PERFORM
           GOBACK.
      *
       INITIALISER.
           PERFORM CALCULER-LONGUEUR-ENTREE
           MOVE SPACES TO LK-LIGNE-SORTIE
           MOVE SPACES TO LK-CLE-FAUTIVE
           MOVE ZERO   TO WS-LG-SORTIE
           MOVE 1      TO WS-POS
           SET LK-OK TO TRUE.
      *
       CALCULER-LONGUEUR-ENTREE.
           MOVE 2000 TO WS-LG-ENTREE
           PERFORM UNTIL WS-LG-ENTREE = ZERO
                   OR LK-LIGNE-ENTREE(WS-LG-ENTREE:1) NOT = SPACE
               SUBTRACT 1 FROM WS-LG-ENTREE
           END-PERFORM.
      *
       COPIER-CARACTERE.
           ADD 1 TO WS-LG-SORTIE
           MOVE LK-LIGNE-ENTREE(WS-POS:1)
               TO LK-LIGNE-SORTIE(WS-LG-SORTIE:1)
           ADD 1 TO WS-POS.
      *
      *    TRAITE LE "{{" REPERE EN WS-POS : LOCALISE SA FERMETURE,
      *    RESOUT LA CLE QU IL ENCADRE, PUIS SAUTE APRES LE MARQUEUR.
       TRAITER-MARQUEUR.
           PERFORM CHERCHER-FERMETURE
           IF WS-POS-FERMETURE = ZERO
               PERFORM COPIER-CARACTERE
               EXIT PARAGRAPH
           END-IF
           PERFORM EXTRAIRE-NOM-CLE
           PERFORM RESOUDRE-CLE
           IF NOT LK-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM INSERER-VALEUR
           COMPUTE WS-POS = WS-POS-FERMETURE + 2.
      *
       CHERCHER-FERMETURE.
           MOVE ZERO TO WS-POS-FERMETURE
           COMPUTE WS-SCAN = WS-POS + 2
           PERFORM UNTIL WS-SCAN > WS-LG-ENTREE - 1
                   OR WS-POS-FERMETURE NOT = ZERO
               IF LK-LIGNE-ENTREE(WS-SCAN:1) = "}"
                       AND LK-LIGNE-ENTREE(WS-SCAN + 1:1) = "}"
                   MOVE WS-SCAN TO WS-POS-FERMETURE
               END-IF
               ADD 1 TO WS-SCAN
           END-PERFORM.
      *
      *    UNE ESPERLUETTE JUSTE APRES "{{" DEMANDE LA VALEUR BRUTE.
      *    UNE CLE VIDE OU TROP LONGUE EST REFUSEE PLUTOT QUE TRONQUEE :
      *    UNE TRONCATURE SILENCIEUSE CHERCHERAIT UNE AUTRE CLE QUE
      *    CELLE ECRITE DANS LE GABARIT, ET LE DIRAIT A PERSONNE.
       EXTRAIRE-NOM-CLE.
           MOVE "N" TO WS-BRUT
           COMPUTE WS-DEBUT-CLE = WS-POS + 2
           IF LK-LIGNE-ENTREE(WS-DEBUT-CLE:1) = "&"
               MOVE "Y" TO WS-BRUT
               ADD 1 TO WS-DEBUT-CLE
           END-IF
           COMPUTE WS-LG-CLE = WS-POS-FERMETURE - WS-DEBUT-CLE
           IF WS-LG-CLE > 40
               MOVE 40 TO WS-LG-CLE
           END-IF
           MOVE SPACES TO WS-CLE
           IF WS-LG-CLE > 0
               MOVE LK-LIGNE-ENTREE(WS-DEBUT-CLE:WS-LG-CLE)
                   TO WS-CLE
           END-IF.
      *
       RESOUDRE-CLE.
           CALL "DICTGET" USING LK-NB-ENTREES DICT-TABLE WS-CLE
                                WS-VALEUR WS-CODE-DICT
           IF WS-CODE-DICT NOT = ZERO
               SET LK-CLE-INCONNUE TO TRUE
               MOVE WS-CLE TO LK-CLE-FAUTIVE
           END-IF.
      *
       INSERER-VALEUR.
           IF WS-EST-BRUT
               PERFORM CALCULER-LONGUEUR-VALEUR
               PERFORM AJOUTER-VALEUR-BRUTE
           ELSE
               CALL "HTMLESC" USING WS-VALEUR WS-ECHAPPEE
               PERFORM CALCULER-LONGUEUR-ECHAPPEE
               PERFORM AJOUTER-VALEUR-ECHAPPEE
           END-IF.
      *
       CALCULER-LONGUEUR-VALEUR.
           MOVE 700 TO WS-LG-VALEUR
           PERFORM UNTIL WS-LG-VALEUR = ZERO
                   OR WS-VALEUR(WS-LG-VALEUR:1) NOT = SPACE
               SUBTRACT 1 FROM WS-LG-VALEUR
           END-PERFORM.
      *
       CALCULER-LONGUEUR-ECHAPPEE.
           MOVE 4200 TO WS-LG-VALEUR
           PERFORM UNTIL WS-LG-VALEUR = ZERO
                   OR WS-ECHAPPEE(WS-LG-VALEUR:1) NOT = SPACE
               SUBTRACT 1 FROM WS-LG-VALEUR
           END-PERFORM.
      *
       AJOUTER-VALEUR-BRUTE.
           IF WS-LG-VALEUR = ZERO
               EXIT PARAGRAPH
           END-IF
           MOVE WS-VALEUR(1:WS-LG-VALEUR)
               TO LK-LIGNE-SORTIE(WS-LG-SORTIE + 1:WS-LG-VALEUR)
           ADD WS-LG-VALEUR TO WS-LG-SORTIE.
      *
       AJOUTER-VALEUR-ECHAPPEE.
           IF WS-LG-VALEUR = ZERO
               EXIT PARAGRAPH
           END-IF
           MOVE WS-ECHAPPEE(1:WS-LG-VALEUR)
               TO LK-LIGNE-SORTIE(WS-LG-SORTIE + 1:WS-LG-VALEUR)
           ADD WS-LG-VALEUR TO WS-LG-SORTIE.
