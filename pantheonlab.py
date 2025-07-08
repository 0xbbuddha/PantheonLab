#!/usr/bin/env python3

import subprocess
import sys
import os
import time
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.text import Text

console = Console()

# ASCII Art pour PantheonLab
ASCII_ART = """
██████╗  █████╗ ███╗   ██╗████████╗██╗  ██╗███████╗ ██████╗ ███╗   ██╗██╗      █████╗ ██████╗ 
██╔══██╗██╔══██╗████╗  ██║╚══██╔══╝██║  ██║██╔════╝██╔═══██╗████╗  ██║██║     ██╔══██╗██╔══██╗
██████╔╝███████║██╔██╗ ██║   ██║   ███████║█████╗  ██║   ██║██╔██╗ ██║██║     ███████║██████╔╝
██╔═══╝ ██╔══██║██║╚██╗██║   ██║   ██╔══██║██╔══╝  ██║   ██║██║╚██╗██║██║     ██╔══██║██╔══██╗
██║     ██║  ██║██║ ╚████║   ██║   ██║  ██║███████╗╚██████╔╝██║ ╚████║███████╗██║  ██║██████╔╝   
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝ 
"""



def print_header():
    """Affiche l'en-tête avec l'ASCII art"""
    console.print(ASCII_ART, style="white")
    console.print("=" * 94, style="cyan")
    console.print()

def check_dependencies():
    """Vérifie les dépendances en exécutant le script shell"""
    console.print("[+] Vérification des dépendances...", style="cyan")
    
    with Progress(
        SpinnerColumn(style="cyan"),
        TextColumn("[cyan]{task.description}"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Analyse en cours...", total=None)
        
        try:
            result = subprocess.run(['./pantheonlab.sh'], capture_output=True, text=True)
            progress.update(task, completed=True)
            
            if result.returncode == 0:
                console.print("[+] Dépendances installées avec succès.", style="green")
                return True
            else:
                console.print("[-] Dépendances manquantes:", style="red")
                console.print(result.stdout, style="white")
                return False
        except Exception as e:
            progress.update(task, completed=True)
            console.print(f"[-] Erreur lors de la vérification: {str(e)}", style="red")
            return False

def launch_lab():
    """Lance le lab en exécutant le script pantheon.sh"""
    console.print("[+] Lancement du lab PantheonLab...", style="cyan")
    
    confirm = input("Confirmer le lancement des VMs? (O/n): ").strip().lower()
    if confirm in ['n', 'no', 'non']:
        console.print("[-] Lancement annulé.", style="yellow")
        return False
    
    try:
        os.chdir('pantheon-lab')
        
        with Progress(
            SpinnerColumn(style="cyan"),
            TextColumn("[cyan]{task.description}"),
            console=console,
            transient=True
        ) as progress:
            task = progress.add_task("Démarrage des machines virtuelles...", total=None)
            
            result = subprocess.run(['./pantheon.sh'], capture_output=True, text=True)
            progress.update(task, completed=True)
            
            if result.returncode == 0:
                console.print("[+] Lab lancé avec succès.", style="green")
                console.print("[+] Les machines virtuelles sont en cours de démarrage.", style="green")
                return True
            else:
                console.print("[-] Erreur lors du lancement du lab:", style="red")
                console.print(result.stderr, style="white")
                return False
    except Exception as e:
        console.print(f"[-] Erreur lors du lancement: {str(e)}", style="red")
        return False

def show_status():
    """Affiche le statut des machines virtuelles"""
    console.print("[+] Récupération du statut des VMs...", style="cyan")
    
    try:
        os.chdir('pantheon-lab')
        
        with Progress(
            SpinnerColumn(style="cyan"),
            TextColumn("[cyan]{task.description}"),
            console=console,
            transient=True
        ) as progress:
            task = progress.add_task("Connexion à Vagrant...", total=None)
            
            result = subprocess.run(['vagrant', 'status'], capture_output=True, text=True)
            progress.update(task, completed=True)
            
            if result.returncode == 0:
                console.print("[+] Statut des machines virtuelles:", style="green")
                console.print("-" * 50, style="cyan")
                console.print(result.stdout, style="white")
            else:
                console.print("[-] Erreur lors de la récupération du statut:", style="red")
                console.print(result.stderr, style="white")
    except Exception as e:
        console.print(f"[-] Erreur: {str(e)}", style="red")

def show_help():
    """Affiche l'aide"""
    console.print("[*] Aide - PantheonLab", style="cyan")
    console.print("-" * 30, style="cyan")
    console.print("[+] 1. Vérifier les dépendances", style="white")
    console.print("    Vérifie que tous les outils nécessaires sont installés", style="white")
    console.print()
    console.print("[+] 2. Lancer le lab", style="white")
    console.print("    Démarre toutes les machines virtuelles et configure l'environnement", style="white")
    console.print()
    console.print("[+] 3. Statut des VMs", style="white")
    console.print("    Affiche l'état actuel des machines virtuelles", style="white")
    console.print()
    console.print("[+] 4. Aide", style="white")
    console.print("    Affiche cette page d'aide", style="white")
    console.print()
    console.print("[+] 5. Quitter", style="white")
    console.print("    Ferme l'application", style="white")
    console.print()
    console.print("[*] Note: Assurez-vous d'avoir suffisamment d'espace disque et de RAM.", style="yellow")

def main():
    """Fonction principale avec menu minimaliste"""
    while True:
        console.clear()
        print_header()
        
        # Menu principal
        console.print("[*] Menu Principal", style="cyan")
        console.print("-" * 20, style="cyan")
        console.print("[+] 1. Vérifier les dépendances", style="white")
        console.print("[+] 2. Lancer le lab", style="white")
        console.print("[+] 3. Statut des VMs", style="white")
        console.print("[+] 4. Aide", style="white")
        console.print("[+] 5. Quitter", style="white")
        console.print()
        
        # Choix de l'utilisateur
        choice = input("[?] Choisissez une option (1-5): ").strip()
        console.print()
        
        if choice == "1":
            check_dependencies()
        elif choice == "2":
            launch_lab()
        elif choice == "3":
            show_status()
        elif choice == "4":
            show_help()
        elif choice == "5":
            confirm = input("Confirmer la sortie? (O/n): ").strip().lower()
            if confirm not in ['n', 'no', 'non']:
                console.print("[+] Au revoir!", style="green")
                break
        else:
            console.print("[-] Option invalide.", style="red")
        
        if choice != "5":
            console.print()
            input("[?] Appuyez sur Entrée pour continuer...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[+] Au revoir!", style="green")
        sys.exit(0) 