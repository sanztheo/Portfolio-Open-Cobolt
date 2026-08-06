#!/usr/bin/env bash
#
# Tests d'integration du generateur.
#
# Les tests unitaires COBOL (tests/testunit.cbl) verifient les modules un par
# un. Ceux-ci verifient le programme entier face a des fichiers de contenu
# volontairement casses : ils repondent a la question "que se passe-t-il quand
# quelqu'un se trompe en editant le contenu ?".
#
# Chaque cas ci-dessous correspond a un defaut qui a reellement existe et qui
# passait inapercu : le generateur rendait succes avec une page fausse.

set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BAC="$(mktemp -d)"
trap 'rm -rf "$BAC"' EXIT

REUSSIS=0
ECHOUES=0

# Chaque cas travaille sur une copie intacte du depot : un test ne peut pas
# polluer le suivant, ni le depot de travail.
preparer() {
  rm -rf "$BAC/essai"
  mkdir -p "$BAC/essai"
  cp -R "$RACINE/content" "$RACINE/templates" "$RACINE/src" "$BAC/essai/"
  mkdir -p "$BAC/essai/dist"
  cp "$RACINE/build/buildsite" "$BAC/essai/buildsite"
}

verifier() {
  local intitule="$1" attendu="$2" obtenu="$3"
  if [ "$attendu" = "$obtenu" ]; then
    echo "  OK   $intitule"
    REUSSIS=$((REUSSIS + 1))
  else
    echo "  ECHEC $intitule : code $obtenu, attendu $attendu"
    ECHOUES=$((ECHOUES + 1))
  fi
}

echo "--- TESTS D INTEGRATION DU GENERATEUR ---"

# --- Cas nominal -------------------------------------------------------------
preparer
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "contenu intact : le site se genere" 0 $?

# --- Cle absente du contenu --------------------------------------------------
# Le gabarit reclame une cle que le contenu ne fournit plus.
preparer
sed -i.bak 's/^SITE_TITRE/SITE_TITRZ/' "$BAC/essai/content/site.dat"
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "cle absente : refus" 1 $?

# --- Valeur plus longue que l'enregistrement ---------------------------------
# Le reste de la ligne devenait une cle inventee, sans un mot.
preparer
python3 - "$BAC/essai/content/site.dat" <<'PY'
import sys
chemin = sys.argv[1]
with open(chemin, "a", encoding="utf-8") as f:
    f.write("CLE_DEBORDANTE".ljust(40) + "X" * 900 + "\n")
PY
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "ligne trop longue : refus" 6 $?

# --- Gabarit de page vide ----------------------------------------------------
# Produisait une page de zero octet en annoncant un succes.
preparer
: > "$BAC/essai/templates/page.tpl"
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "gabarit vide : refus" 7 $?

# --- Marqueur jamais ferme ---------------------------------------------------
preparer
printf '<p>{{SITE_TITRE</p>\n' >> "$BAC/essai/templates/page.tpl"
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "marqueur non ferme : refus" 1 $?

# --- Fichier de contenu manquant ---------------------------------------------
preparer
rm "$BAC/essai/content/projets.dat"
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
verifier "fichier manquant : refus" 2 $?

# --- La page valide survit a un rendu qui echoue -----------------------------
# Le generateur ecrivait directement dans la page finale : un echec a mi-course
# laissait un HTML tronque a la place du site qui marchait.
preparer
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 && mv dist/index.html.part dist/index.html )
AVANT=$(wc -c < "$BAC/essai/dist/index.html" | tr -d ' ')
sed -i.bak 's/^P_TITRE /P_TITREZ/' "$BAC/essai/content/projets.dat"
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 )
APRES=$(wc -c < "$BAC/essai/dist/index.html" | tr -d ' ')
verifier "rendu en echec : la page valide est preservee" "$AVANT" "$APRES"

# --- Une valeur de contenu ne peut pas injecter de HTML ----------------------
preparer
python3 - "$BAC/essai/content/site.dat" <<'PY'
import sys
chemin = sys.argv[1]
lignes = open(chemin, encoding="utf-8").read().splitlines(True)
sortie = []
for ligne in lignes:
    if ligne.startswith("NOM"):
        ligne = "NOM".ljust(40) + "<script>alert(1)</script>\n"
    sortie.append(ligne)
open(chemin, "w", encoding="utf-8").writelines(sortie)
PY
( cd "$BAC/essai" && ./buildsite >/dev/null 2>&1 && mv dist/index.html.part dist/index.html )
if grep -q '<script>alert(1)</script>' "$BAC/essai/dist/index.html"; then
  echo "  ECHEC injection HTML : la balise est passee telle quelle"
  ECHOUES=$((ECHOUES + 1))
elif grep -q '&lt;script&gt;alert(1)&lt;/script&gt;' "$BAC/essai/dist/index.html"; then
  echo "  OK   valeur de contenu : le HTML est echappe"
  REUSSIS=$((REUSSIS + 1))
else
  echo "  ECHEC injection HTML : ni brut ni echappe, resultat inattendu"
  ECHOUES=$((ECHOUES + 1))
fi

echo "--- BILAN : $REUSSIS reussis, $ECHOUES echoues ---"
[ "$ECHOUES" -eq 0 ]
