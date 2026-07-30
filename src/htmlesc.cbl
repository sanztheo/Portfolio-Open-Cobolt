      ******************************************************************
      *  HTMLESC - ECHAPPEMENT DES CARACTERES SIGNIFICATIFS EN HTML    *
      *                                                                *
      *  ROLE   : TRANSFORME  &  <  >  "  EN LEURS ENTITES HTML.       *
      *  ENTREE : LK-ESC-ENTREE, TEXTE BRUT                            *
      *  SORTIE : LK-ESC-SORTIE, TEXTE SUR                             *
      *                                                                *
      *  POURQUOI UN MODULE A PART : L ECHAPPEMENT EST LA SEULE        *
      *  BARRIERE ENTRE UNE DONNEE DE CONTENU ET LE HTML PRODUIT. S IL *
      *  ETAIT RECOPIE A CHAQUE ENDROIT QUI EN A BESOIN, IL SUFFIRAIT  *
      *  D UNE COPIE OUBLIEE POUR OUVRIR UNE INJECTION. ICI IL EXISTE  *
      *  EN UN SEUL EXEMPLAIRE, ET IL EST TESTE UNITAIREMENT.          *
      *                                                                *
      *  NOTE UTF-8 : CE MODULE TRAVAILLE OCTET PAR OCTET. LES QUATRE  *
      *  CARACTERES RECHERCHES SONT TOUS EN DESSOUS DE X'80', ALORS    *
      *  QUE CHAQUE OCTET D UNE SEQUENCE UTF-8 MULTI-OCTETS VAUT X'80' *
      *  OU PLUS. UN OCTET ACCENTUE NE PEUT DONC JAMAIS ETRE CONFONDU  *
      *  AVEC UN DELIMITEUR : LES ACCENTS TRAVERSENT INTACTS.          *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTMLESC.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LG-ENTREE      PIC 9(4) VALUE ZERO.
       01  WS-LG-SORTIE      PIC 9(4) VALUE ZERO.
       01  WS-POS            PIC 9(4) VALUE ZERO.
       01  WS-CAR            PIC X    VALUE SPACE.
       01  WS-REMPLACEMENT   PIC X(6) VALUE SPACES.
       01  WS-LG-REMPL       PIC 9(1) VALUE ZERO.
      *
       LINKAGE SECTION.
       01  LK-ESC-ENTREE     PIC X(700).
      *    PIRE CAS : LES 700 OCTETS SONT DES GUILLEMETS, SOIT LE
      *    REMPLACEMENT LE PLUS LONG A 6 OCTETS. 700 * 6 = 4200.
       01  LK-ESC-SORTIE     PIC X(4200).
      *
       PROCEDURE DIVISION USING LK-ESC-ENTREE LK-ESC-SORTIE.
      *
       PRINCIPAL.
           PERFORM CALCULER-LONGUEUR-ENTREE
           MOVE SPACES TO LK-ESC-SORTIE
           MOVE ZERO   TO WS-LG-SORTIE
           PERFORM VARYING WS-POS FROM 1 BY 1
                   UNTIL WS-POS > WS-LG-ENTREE
               MOVE LK-ESC-ENTREE(WS-POS:1) TO WS-CAR
               PERFORM CHOISIR-REMPLACEMENT
               PERFORM AJOUTER-REMPLACEMENT
           END-PERFORM
           GOBACK.
      *
      *    UN CHAMP PIC X EST COMPLETE PAR DES ESPACES A DROITE : LA
      *    LONGUEUR UTILE S ARRETE AU DERNIER CARACTERE NON BLANC.
      *    CONSEQUENCE ASSUMEE : UNE VALEUR NE PEUT PAS SE TERMINER
      *    PAR UN ESPACE SIGNIFICATIF, CE QUI EST SANS IMPORTANCE EN
      *    HTML OU LES ESPACES DE FIN SONT DE TOUTE FACON REDUITS.
       CALCULER-LONGUEUR-ENTREE.
           MOVE 700 TO WS-LG-ENTREE
           PERFORM UNTIL WS-LG-ENTREE = ZERO
                   OR LK-ESC-ENTREE(WS-LG-ENTREE:1) NOT = SPACE
               SUBTRACT 1 FROM WS-LG-ENTREE
           END-PERFORM.
      *
       CHOISIR-REMPLACEMENT.
           EVALUATE WS-CAR
               WHEN "&"
                   MOVE "&amp;"  TO WS-REMPLACEMENT
                   MOVE 5        TO WS-LG-REMPL
               WHEN "<"
                   MOVE "&lt;"   TO WS-REMPLACEMENT
                   MOVE 4        TO WS-LG-REMPL
               WHEN ">"
                   MOVE "&gt;"   TO WS-REMPLACEMENT
                   MOVE 4        TO WS-LG-REMPL
               WHEN QUOTE
                   MOVE "&quot;" TO WS-REMPLACEMENT
                   MOVE 6        TO WS-LG-REMPL
               WHEN OTHER
                   MOVE WS-CAR   TO WS-REMPLACEMENT
                   MOVE 1        TO WS-LG-REMPL
           END-EVALUATE.
      *
      *    GARDE-FOU DE DEBORDEMENT : ON REFUSE D ECRIRE AU-DELA DE LA
      *    TAILLE DECLAREE PLUTOT QUE DE CORROMPRE LA MEMOIRE VOISINE.
      *    LE DEPASSEMENT EST SIGNALE ET LE TRAITEMENT S ARRETE : UNE
      *    TRONCATURE SILENCIEUSE PRODUIRAIT DU HTML INVALIDE SANS QUE
      *    PERSONNE NE LE SACHE.
       AJOUTER-REMPLACEMENT.
           IF WS-LG-SORTIE + WS-LG-REMPL > 4200
               DISPLAY "HTMLESC : DEBORDEMENT, TEXTE TROP LONG "
                       "APRES ECHAPPEMENT."
               MOVE WS-LG-ENTREE TO WS-POS
               STOP RUN RETURNING 2
           END-IF
           MOVE WS-REMPLACEMENT(1:WS-LG-REMPL)
               TO LK-ESC-SORTIE(WS-LG-SORTIE + 1:WS-LG-REMPL)
           ADD WS-LG-REMPL TO WS-LG-SORTIE.
