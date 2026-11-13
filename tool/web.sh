#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart tool/content.dart
dart tool/revision.dart
flutter build web --release --no-web-resources-cdn --no-pub "$@"
mkdir -p build/web/content
cp content/*.json build/web/content/
python3 tool/offline.py
cp docs/Trama-diseno.html build/web/diseno.html
cp docs/revision-docente.html build/web/revision-docente.html
