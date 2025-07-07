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
                    virtualbox) echo "sudo pacman -Syu virtualbox";;
                    ansible) echo "sudo pacman -Syu ansible";;
                    git) echo "sudo pacman -Syu git";;
                    pywinrm) echo "pip install pywinrm --break-system-packages";;
                    *) echo "Voir la documentation officielle pour $dep";;
                esac
            elif command -v apt &> /dev/null; then
                case "$dep" in
                    python3) echo "sudo apt update && sudo apt install -y python3";;
                    pip3) echo "sudo apt update && sudo apt install -y python3-pip";;
                    vagrant) echo "sudo apt update && sudo apt install -y vagrant";;
                    virtualbox) echo "sudo apt update && sudo apt install -y virtualbox";;
                    ansible) echo "sudo apt update && sudo apt install -y ansible";;
                    git) echo "sudo apt update && sudo apt install -y git";;
                    pywinrm) echo "pip3 install pywinrm";;
                    *) echo "Voir la documentation officielle pour $dep";;
                esac
            elif command -v dnf &> /dev/null; then
                case "$dep" in
                    python3) echo "sudo dnf install -y python3";;
                    pip3) echo "sudo dnf install -y python3-pip";;
                    vagrant) echo "sudo dnf install -y vagrant";;
                    virtualbox) echo "sudo dnf install -y VirtualBox";;
                    ansible) echo "sudo dnf install -y ansible";;
                    git) echo "sudo dnf install -y git";;
                    pywinrm) echo "pip3 install pywinrm";;
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
                virtualbox) echo "brew install --cask virtualbox";;
                ansible) echo "brew install ansible";;
                git) echo "brew install git";;
                pywinrm) echo "pip3 install pywinrm";;
                *) echo "Voir la documentation officielle pour $dep";;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows*)
            echo "Sur Windows, téléchargez $dep depuis le site officiel.";;
        *)
            echo "OS non reconnu. Veuillez installer $dep manuellement.";;
    esac
}

# Vérification de la présence de Python 3
if ! command -v python3 &> /dev/null; then
    echo "Python 3 n'est pas installé. Commande suggérée : $(suggest_install python3)"
    exit 1
fi

# Vérification de la présence de pip
if ! command -v pip3 &> /dev/null; then
    echo "pip3 n'est pas installé. Commande suggérée : $(suggest_install pip3)"
    exit 1
fi

# Vérification de la présence de Vagrant
if ! command -v vagrant &> /dev/null; then
    echo "Vagrant n'est pas installé. Commande suggérée : $(suggest_install vagrant)"
    exit 1
fi

# Vérification de la présence de VirtualBox
if ! command -v VBoxManage &> /dev/null; then
    echo "VirtualBox n'est pas installé. Commande suggérée : $(suggest_install virtualbox)"
    exit 1
fi

# Vérification de la présence d'Ansible
if ! command -v ansible &> /dev/null; then
    echo "Ansible n'est pas installé. Commande suggérée : $(suggest_install ansible)"
    exit 1
fi

# Vérification de la présence de git
if ! command -v git &> /dev/null; then
    echo "git n'est pas installé. Commande suggérée : $(suggest_install git)"
    exit 1
fi

# Vérification de la présence de pywinrm (module Python)
if ! python3 -c "import winrm" &> /dev/null; then
    echo "Le module Python 'pywinrm' n'est pas installé. Commande suggérée : $(suggest_install pywinrm)"
    exit 1
fi

echo "Toutes les dépendances requises sont installées." 