#!/bin/bash

# Se placer dans le bon dossier (optionnel, si tu le places ailleurs)
cd "$(dirname "$0")"

# Boucle sur tous les fichiers .png du répertoire courant (non récursif)
for file in *.png; do
  # Ignore les fichiers déjà préfixés
  if [[ "$file" != img_*.png ]]; then
    mv "$file" "img_$file"
    echo "Renommé: $file -> img_$file"
  fi
done

