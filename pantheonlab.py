#!/usr/bin/env python3

import subprocess
import sys
import os
import time
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.text import Text
from rich.table import Table
import threading
from rich.live import Live

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
            result = subprocess.run(['./check_requirements.sh'], capture_output=True, text=True)
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
        console.print("[-] Lancement annulé.", style="red")
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
            
            result = subprocess.run(['./pantheonv2.sh'], capture_output=True, text=True)
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

def show_global_status():
    """Affiche le status global des VMs Vagrant avec un joli tableau"""
    console.print("[+] Statut global des VMs (vagrant global-status)", style="cyan")
    try:
        result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
        if result.returncode != 0:
            console.print("[-] Erreur lors de l'exécution de vagrant global-status", style="red")
            console.print(result.stderr, style="white")
            return
        lines = result.stdout.splitlines()
        # Chercher la ligne d'entête et les données
        header_idx = None
        for i, line in enumerate(lines):
            if line.strip().startswith('id') and 'directory' in line:
                header_idx = i
                break
        if header_idx is None:
            console.print("[-] Impossible de parser la sortie de vagrant global-status", style="red")
            return
        # Les données sont entre header_idx+1 et la première ligne vide après
        data_lines = []
        for line in lines[header_idx+1:]:
            if not line.strip():
                break
            data_lines.append(line)
        # Création du tableau
        table = Table(title="Vagrant Global Status", show_lines=True)
        table.add_column("ID", style="bold")
        table.add_column("Name", style="white")
        table.add_column("Provider", style="magenta")
        table.add_column("State", style="bold")
        table.add_column("Directory", style="cyan")
        for line in data_lines:
            # Les colonnes sont séparées par des espaces, mais le path peut contenir des espaces
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            id_, name, provider, state, directory = parts
            # Couleur selon l'état
            if state == 'running':
                state_style = '[green]running[/green]'
            elif state == 'poweroff':
                state_style = '[red]stopped[/red]'
            else:
                state_style = f'[red]{state}[/red]'
            table.add_row(id_, name, provider, state_style, directory)
        if not data_lines:
            console.print("Aucune VM Vagrant trouvée.", style="red")
        else:
            console.print(table)
    except Exception as e:
        console.print(f"[-] Erreur lors de la récupération du status global : {str(e)}", style="red")

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
    console.print("[*] Note: Assurez-vous d'avoir suffisamment d'espace disque et de RAM.", style="red")

def is_lab_fully_running():
    """Retourne True si exactement 3 VMs Vagrant sont en état running, False sinon."""
    try:
        result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
        if result.returncode != 0:
            return False
        lines = result.stdout.splitlines()
        header_idx = None
        for i, line in enumerate(lines):
            if line.strip().startswith('id') and 'directory' in line:
                header_idx = i
                break
        if header_idx is None:
            return False
        running_count = 0
        total_count = 0
        for line in lines[header_idx+1:]:
            if not line.strip():
                break
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            state = parts[3]
            if state == 'running':
                running_count += 1
            total_count += 1
        return running_count == 3 and total_count >= 3
    except Exception:
        return False

def is_any_vm_not_running():
    """Retourne True si au moins une VM existe et n'est pas running."""
    try:
        result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
        if result.returncode != 0:
            return False
        lines = result.stdout.splitlines()
        header_idx = None
        for i, line in enumerate(lines):
            if line.strip().startswith('id') and 'directory' in line:
                header_idx = i
                break
        if header_idx is None:
            return False
        for line in lines[header_idx+1:]:
            if not line.strip():
                break
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            state = parts[3]
            if state != 'running':
                return True
        return False
    except Exception:
        return False

def get_lab_status_message():
    """Retourne le message d'état du lab (str) et la couleur (str)."""
    if is_lab_fully_running():
        return "[LAB EN COURS] Un lab est déjà lancé.", "green"
    elif is_any_vm_not_running():
        return "[ATTENTION] Une ou plusieurs VMs ne sont pas running !", "orange"
    else:
        return "[AUCUN LAB] Aucun lab n'est lancé.", "red"

def main():
    """Fonction principale avec menu minimaliste"""
    # Vérification du status du lab une seule fois au démarrage
    status_message = '[grey]Vérification de l\'état du lab...[/grey]'
    status_color = 'grey'
    def check_status():
        nonlocal status_message, status_color
        msg, col = get_lab_status_message()
        status_message = msg
        status_color = col
    t = threading.Thread(target=check_status)
    t.start()
    with Live("", refresh_per_second=10, console=console) as live:
        while t.is_alive():
            live.update(f"[{status_color}]{status_message}[/{status_color}]")
            time.sleep(0.1)
        live.update(f"[{status_color}]{status_message}[/{status_color}]")
    console.print()

    while True:
        console.clear()
        print_header()
        # Affichage du status du lab (déjà calculé)
        console.print(f"[{status_color}]{status_message}[/{status_color}]")
        console.print()
        # Affichage du menu principal
        console.print("[*] Menu Principal", style="cyan")
        console.print("[+] 1. Vérifier les dépendances", style="white")
        console.print("[+] 2. Lancer le lab", style="white")
        console.print("[+] 3. Statut des VMs", style="white")
        console.print("[+] 4. Statut global des VMs", style="white")
        console.print("[+] 5. Aide", style="white")
        console.print("[+] q. Quitter", style="red")
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
            show_global_status()
        elif choice == "5":
            show_help()
        elif choice == "q":
            console.print("[+] Au revoir!", style="green")
            break
        else:
            console.print("[-] Option invalide.", style="red")
        
        if choice != "q":
            console.print()
            input("[?] Appuyez sur Entrée pour continuer...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[+] Au revoir!", style="green")
        sys.exit(0) 