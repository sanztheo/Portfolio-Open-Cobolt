#!/usr/bin/env bash
#
# Compile le moteur COBOL, lance les tests unitaires, puis genere dist/.
#
# Le script echoue au premier probleme : un warning du compilateur, un test
# rouge ou une cle de contenu manquante arretent la construction. Un site a
# moitie juste se publierait sans que personne ne le remarque.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

MODULES="src/render.cbl src/dictget.cbl src/htmlesc.cbl"
COBFLAGS="-Wall -std=cobol2014 -I src/cpy"
JOURNAL="$(mktemp)"
trap 'rm -f "$JOURNAL"' EXIT

command -v cobc >/dev/null || {
  echo "GnuCOBOL manquant."
  echo "  macOS         : brew install gnucobol"
  echo "  Debian/Ubuntu : sudo apt install gnucobol"
  exit 1
}

# Le linker macOS emet ses propres avertissements, qui ne parlent pas de notre
# code. On ne retient que ceux qui pointent un fichier .cbl ou .cpy.
compiler() {
  local sortie="$1"; shift
  cobc -x $COBFLAGS -o "$sortie" "$@" 2>"$JOURNAL" || {
    cat "$JOURNAL" >&2
    exit 1
  }
  if grep -Eq '\.(cbl|cpy):[0-9]+: warning' "$JOURNAL"; then
    echo "Le compilateur a emis un avertissement :" >&2
    grep -E '\.(cbl|cpy):[0-9]+: warning' "$JOURNAL" >&2
    exit 1
  fi
}

mkdir -p build dist

echo "==> Compilation des tests"
compiler build/testunit tests/testunit.cbl $MODULES

echo "==> Tests unitaires"
./build/testunit

echo "==> Compilation du generateur"
compiler build/buildsite src/buildsite.cbl $MODULES

echo "==> Generation du site"
mkdir -p dist
./build/buildsite

cp -R public/. dist/ 2>/dev/null || true

echo "==> dist/index.html : $(wc -c < dist/index.html | tr -d ' ') octets"
