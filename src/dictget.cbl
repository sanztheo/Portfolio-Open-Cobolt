      ******************************************************************
      *  DICTGET - RESOLUTION D UNE CLE DANS LE DICTIONNAIRE           *
      *                                                                *
      *  ENTREE : LK-NB-ENTREES, DICT-TABLE, LK-CLE-DEMANDEE           *
      *  SORTIE : LK-VALEUR-TROUVEE, LK-CODE-RETOUR                    *
      *           0  = TROUVEE                                         *
      *           99 = INCONNUE                                        *
      *                                                                *
      *  POURQUOI UN MODULE A PART : C EST ICI, ET NULLE PART AILLEURS,*
      *  QUE SE JOUE LA REGLE " UNE CLE INCONNUE EST UNE ERREUR, PAS   *
      *  UN BLANC SILENCIEUX ". L ISOLER PERMET DE LA TESTER SEULE,    *
      *  SANS DEPENDRE DE L ANALYSE DES GABARITS.                      *
      *                                                                *
      *  LA RECHERCHE EST SEQUENTIELLE ET RETIENT LA PREMIERE          *
      *  CORRESPONDANCE. CE DETAIL EST VOULU : BUILDSITE RANGE LES     *
      *  CLES LOCALES D UN ENREGISTREMENT AVANT LES CLES GLOBALES DU   *
      *  SITE, DONC UNE CLE LOCALE MASQUE VOLONTAIREMENT SON HOMONYME  *
      *  GLOBAL.                                                       *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DICTGET.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-IDX            PIC 9(4) VALUE ZERO.
      *
       LINKAGE SECTION.
       01  LK-NB-ENTREES     PIC 9(4).
       COPY "dicttab.cpy".
       01  LK-CLE-DEMANDEE   PIC X(40).
       01  LK-VALEUR-TROUVEE PIC X(700).
       01  LK-CODE-RETOUR    PIC 9(2).
           88  LK-TROUVEE     VALUE 0.
           88  LK-INCONNUE    VALUE 99.
      *
       PROCEDURE DIVISION USING LK-NB-ENTREES DICT-TABLE
                                LK-CLE-DEMANDEE LK-VALEUR-TROUVEE
                                LK-CODE-RETOUR.
      *
       PRINCIPAL.
           MOVE SPACES TO LK-VALEUR-TROUVEE
           SET LK-INCONNUE TO TRUE
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > LK-NB-ENTREES
               IF DICT-CLE(WS-IDX) = LK-CLE-DEMANDEE
                   MOVE DICT-VALEUR(WS-IDX) TO LK-VALEUR-TROUVEE
                   SET LK-TROUVEE TO TRUE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           GOBACK.
