#!/usr/bin/env bash

set -e

# Créer le venv Python s'il n'existe pas déjà
echo "[+] Création/activation de l'environnement virtuel Python..."
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate

# Installer les dépendances pip
if [ -f requirements.txt ]; then
    echo "[+] Installation des dépendances Python (requirements.txt)..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "[!] requirements.txt introuvable, installation des dépendances Python ignorée."
fi

# Installer les collections Ansible nécessaires (exemple : trippsc2.adcs)
if [ -f requirements.yml ]; then
    echo "[+] Installation des collections Ansible depuis requirements.yml..."
    ansible-galaxy collection install -r requirements.yml
else
    echo "[!] requirements.yml introuvable, installation des collections Ansible ignorée."
fi

# Lancer le script de démarrage du lab
if [ -f pantheon-lab/pantheonv2.sh ]; then
    echo "[+] Lancement du lab via pantheon-lab/pantheonv2.sh..."
    bash pantheon-lab/pantheonv2.sh
else
    echo "[!] Le script pantheon-lab/pantheonv2.sh est introuvable."
    exit 1
fi 