#!/usr/bin/env bash

set -e

# Détecter si le script est lancé depuis un terminal interactif
if [ -t 1 ]; then
    # Mode interactif : création du venv et install pip/ansible
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

    # Installer les collections Ansible nécessaires
    if [ -f requirements.yml ]; then
        echo "[+] Installation des collections Ansible depuis requirements.yml..."
        ansible-galaxy collection install -r requirements.yml
    else
        echo "[!] requirements.yml introuvable, installation des collections Ansible ignorée."
    fi
    exit 0
else
    # Mode non interactif : démarrage du lab uniquement
    if [ -f pantheon-lab/pantheonv2.sh ]; then
        echo "[+] Lancement du lab via pantheon-lab/pantheonv2.sh..."
        bash -c 'cd pantheon-lab; ./pantheonv2.sh'
    else
        echo "[!] Le script pantheon-lab/pantheonv2.sh est introuvable."
        exit 1
    fi
fi 
