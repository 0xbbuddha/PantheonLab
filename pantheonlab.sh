#!/usr/bin/env bash

set -e

# Vérifier si le mode debug est activé
DEBUG=0
for arg in "$@"; do
    if [ "$arg" = "--debug" ]; then
        DEBUG=1
    fi
done

# Détecter si le script est lancé depuis un terminal interactif
if [ -t 1 ]; then
    # Si le venv existe déjà, ne pas refaire l'installation
    if [ -d ".venv" ]; then
        echo "[+] L'environnement virtuel .venv existe déjà."
        echo "[+] Lancement de l'interface PantheonLab..."
        python3 pantheonlab.py
        exit 0
    fi
    # Mode interactif : création du venv et install pip/ansible
    echo "[+] Création/activation de l'environnement virtuel Python..."
    python3 -m venv .venv
    source .venv/bin/activate

    # Installer les dépendances pip
    if [ -f requirements.txt ]; then
        echo "[+] Installation des dépendances Python (requirements.txt)..."
        if [ $DEBUG -eq 1 ]; then
            pip install --upgrade pip
            pip install -r requirements.txt
        else
            pip install --upgrade pip > /dev/null 2>&1
            pip install -r requirements.txt > /dev/null 2>&1
        fi
    else
        echo "[!] requirements.txt introuvable, installation des dépendances Python ignorée."
    fi

    # Installer les collections Ansible nécessaires
    if [ -f requirements.yml ]; then
        echo "[+] Installation des collections Ansible depuis requirements.yml..."
        if [ $DEBUG -eq 1 ]; then
            ansible-galaxy collection install -r requirements.yml
        else
            ansible-galaxy collection install -r requirements.yml > /dev/null 2>&1
        fi
    else
        echo "[!] requirements.yml introuvable, installation des collections Ansible ignorée."
    fi

    # Lancer l'interface Python après installation
    echo "[+] Lancement de l'interface PantheonLab..."
    python3 pantheonlab.py
    deactivate
    exit 0
fi 
