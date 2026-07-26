      ******************************************************************
      *  DICTTAB - TABLE DICTIONNAIRE PARTAGEE                         *
      *                                                                *
      *  UNE SEULE SOURCE DE VERITE POUR LA DISPOSITION MEMOIRE DU     *
      *  DICTIONNAIRE. RECOPIEE PAR BUILDSITE (LE PROPRIETAIRE, EN     *
      *  WORKING-STORAGE) ET PAR DICTGET / RENDER (LES RECEVEURS, EN   *
      *  LINKAGE SECTION).                                             *
      *                                                                *
      *  POURQUOI UN COPYBOOK : SI L APPELANT ET L APPELE DECLARENT    *
      *  CHACUN LEUR VERSION DE LA TABLE, UN ECART D UN SEUL OCTET     *
      *  DECALE TOUTE LA LECTURE SANS QUE RIEN NE PLANTE. LE COPYBOOK  *
      *  REND CE DESACCORD IMPOSSIBLE.                                 *
      ******************************************************************
       01  DICT-TABLE.
           05  DICT-ENTREE OCCURS 240 TIMES.
               10  DICT-CLE     PIC X(40).
               10  DICT-VALEUR  PIC X(700).
