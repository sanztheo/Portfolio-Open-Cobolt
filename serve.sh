#!/usr/bin/env bash
#
# Construit le site puis le sert en local, pour le regarder dans un navigateur.
#
#   ./serve.sh              construit, puis sert sur le premier port libre a partir de 8000
#   ./serve.sh 3000         impose le port 3000
#   ./serve.sh --sans-build sert dist/ tel quel, sans reconstruire
#
# Ouvrir dist/index.html directement avec file:// fonctionne aussi, mais le
# navigateur y applique des regles differentes : un vrai serveur donne les
# bons types MIME et le meme comportement qu'en ligne.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PORT=""
CONSTRUIRE=1

for arg in "$@"; do
  case "$arg" in
    --sans-build|--no-build) CONSTRUIRE=0 ;;
    ''|*[!0-9]*) echo "Argument non reconnu : $arg" >&2
                 echo "Usage : ./serve.sh [port] [--sans-build]" >&2
                 exit 2 ;;
    *) PORT="$arg" ;;
  esac
done

command -v python3 >/dev/null || {
  echo "python3 est requis pour servir les fichiers." >&2
  exit 1
}

if [ "$CONSTRUIRE" -eq 1 ]; then
  ./build.sh
  echo
fi

[ -f dist/index.html ] || {
  echo "dist/index.html est absent. Lancer ./build.sh d'abord," >&2
  echo "ou relancer sans --sans-build." >&2
  exit 1
}

# Sans port impose, on cherche le premier libre : relancer le script sans avoir
# arrete la fois precedente ne doit pas echouer sur un "Address already in use".
if [ -z "$PORT" ]; then
  for essai in $(seq 8000 8020); do
    if ! nc -z localhost "$essai" 2>/dev/null; then PORT="$essai"; break; fi
  done
  [ -n "$PORT" ] || { echo "Aucun port libre entre 8000 et 8020." >&2; exit 1; }
fi

URL="http://localhost:$PORT"
echo "==> $URL"
echo "    Ctrl+C pour arreter."
echo

# Ouvre le navigateur sans bloquer, puis rend la main au serveur qui tourne au
# premier plan : Ctrl+C l'arrete proprement.
( sleep 1
  if command -v open >/dev/null; then open "$URL"
  elif command -v xdg-open >/dev/null; then xdg-open "$URL" >/dev/null 2>&1
  fi ) &

exec python3 -m http.server "$PORT" --directory dist --bind 127.0.0.1
