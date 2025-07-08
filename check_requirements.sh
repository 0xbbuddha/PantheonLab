#!/usr/bin/env bash

# Détection de l'OS
OS="$(uname -s)"

# Fonction pour détecter si on est sur Arch Linux
is_arch() {
    if command -v pacman &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Fonction pour proposer la bonne commande d'installation
suggest_install() {
    dep="$1"
    case "$OS" in
        Linux*)
            if is_arch; then
                case "$dep" in
                    python3) echo "sudo pacman -Syu python";;
                    pip3) echo "sudo pacman -Syu python-pip";;
                    vagrant) echo "sudo pacman -Syu vagrant";;
                    VBoxManage) echo "sudo pacman -Syu virtualbox";;
                    ansible) echo "sudo pacman -Syu ansible";;
                    git) echo "sudo pacman -Syu git";;
                    *) echo "Voir la documentation officielle pour $dep";;
                esac
            elif command -v apt &> /dev/null; then
                case "$dep" in
                    python3) echo "sudo apt update && sudo apt install -y python3";;
                    pip3) echo "sudo apt update && sudo apt install -y python3-pip";;
                    vagrant) echo "sudo apt update && sudo apt install -y vagrant";;
                    VBoxManage) echo "sudo apt update && sudo apt install -y virtualbox";;
                    ansible) echo "sudo apt update && sudo apt install -y ansible";;
                    git) echo "sudo apt update && sudo apt install -y git";;
                    *) echo "Voir la documentation officielle pour $dep";;
                esac
            elif command -v dnf &> /dev/null; then
                case "$dep" in
                    python3) echo "sudo dnf install -y python3";;
                    pip3) echo "sudo dnf install -y python3-pip";;
                    vagrant) echo "sudo dnf install -y vagrant";;
                    VBoxManage) echo "sudo dnf install -y VirtualBox";;
                    ansible) echo "sudo dnf install -y ansible";;
                    git) echo "sudo dnf install -y git";;
                    *) echo "Voir la documentation officielle pour $dep";;
                esac
            else
                echo "Veuillez installer $dep via votre gestionnaire de paquets."
            fi
            ;;
        Darwin*)
            case "$dep" in
                python3) echo "brew install python3";;
                pip3) echo "brew install python3";;
                vagrant) echo "brew install --cask vagrant";;
                VBoxManage) echo "brew install --cask virtualbox";;
                ansible) echo "brew install ansible";;
                git) echo "brew install git";;
                *) echo "Voir la documentation officielle pour $dep";;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows*)
            echo "Le déployement de ce lab sur Windows n'est pas encore supporté .";;
        *)
            echo "OS non reconnu. Veuillez installer $dep manuellement.";;
    esac
}

# Liste des dépendances à vérifier
REQUIREMENTS=(python3 pip3 vagrant VBoxManage ansible git)

MISSING=()

for dep in "${REQUIREMENTS[@]}"; do
    if [ "$dep" = "VBoxManage" ]; then
        # VBoxManage peut ne pas être dans le PATH, on vérifie aussi dans les chemins courants
        if ! command -v VBoxManage &> /dev/null && \
           [ ! -x "/usr/lib/virtualbox/VBoxManage" ] && \
           [ ! -x "/opt/VirtualBox/VBoxManage" ]; then
            MISSING+=("$dep")
            echo "$dep n'est pas installé. Commande suggérée : $(suggest_install $dep)"
        fi
    else
    if ! command -v "$dep" &> /dev/null; then
            MISSING+=("$dep")
        echo "$dep n'est pas installé. Commande suggérée : $(suggest_install $dep)"
        fi
    fi

done

if [ ${#MISSING[@]} -eq 0 ]; then
echo "Toutes les dépendances requises sont installées." 
    exit 0
else
    echo "\nDépendances manquantes : ${MISSING[*]}"
    exit 1
fi 