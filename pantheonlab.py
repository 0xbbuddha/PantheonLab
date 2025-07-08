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
import readline
import shutil
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

EXPECTED_VM_COUNT = 3  # Nombre de VMs attendues pour le lab

def print_header():
    """Affiche l'en-tête avec l'ASCII art"""
    console.print(ASCII_ART, style="navajo_white1")
    console.print("=" * 94, style="navajo_white1")
    console.print()

def check_dependencies():
    """Vérifie les dépendances en exécutant le script shell avec animation spinner"""
    console.print("[+] Vérification des dépendances...", style="cyan")
    with Progress(
        SpinnerColumn(style="orange3"),
        TextColumn("[navajo_white1]Vérification des dépendances...[/navajo_white1]"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Vérification des dépendances...", total=None)
        try:
            result = subprocess.run(['./check_requirements.sh'], capture_output=True, text=True)
            progress.update(task, completed=True)
            if result.returncode == 0:
                console.print("[+] Dépendances installées avec succès.", style="green")
                return True
            else:
                console.print("[-] Dépendances manquantes:", style="red")
                console.print(result.stdout, style="navajo_white1")
                return False
        except Exception as e:
            progress.update(task, completed=True)
            console.print(f"[-] Erreur lors de la vérification: {str(e)}", style="red")
            return False

def launch_lab():
    """Lance le lab en exécutant la commande 'cd pantheon-lab; ./pantheonv2.sh' avec spinner"""
    console.print("[+] Lancement du lab PantheonLab...", style="cyan")
    confirm = input("Confirmer le lancement des VMs? (O/n): ").strip().lower()
    if confirm in ['n', 'no', 'non']:
        console.print("[-] Lancement annulé.", style="red")
        return False
    try:
        with Progress(
            SpinnerColumn(style="orange3"),
            TextColumn("[navajo_white1]Démarrage des machines virtuelles...[/navajo_white1]"),
            console=console,
            transient=True
        ) as progress:
            task = progress.add_task("Démarrage des machines virtuelles...", total=None)
            result = subprocess.run('cd pantheon-lab; ./pantheonv2.sh', shell=True, capture_output=True, text=True)
            progress.update(task, completed=True)
            if result.returncode == 0:
                console.print("[+] Lab lancé avec succès.", style="green")
                console.print("[+] Les machines virtuelles sont en cours de démarrage.", style="green")
                return True
            else:
                console.print("[-] Erreur lors du lancement du lab:", style="red")
                console.print(result.stderr, style="navajo_white1")
                return False
    except Exception as e:
        console.print(f"[-] Erreur lors du lancement: {str(e)}", style="red")
        return False

def show_global_status():
    """Affiche le status global des VMs Vagrant avec un joli tableau et une animation spinner"""
    console.print("[+] Statut global des VMs (vagrant global-status)", style="cyan")
    with Progress(
        SpinnerColumn(style="orange3"),
        TextColumn("[navajo_white1]Récupération du status global des VMs...[/navajo_white1]"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Récupération du status global des VMs...", total=None)
        try:
            result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
            progress.update(task, completed=True)
            if result.returncode != 0:
                console.print("[-] Erreur lors de l'exécution de vagrant global-status", style="red")
                console.print(result.stderr, style="navajo_white1")
                return
            lines = result.stdout.splitlines()
            # Cas où il n'y a aucune VM : Vagrant affiche un message d'information
            if any('There are no active Vagrant environments' in line for line in lines):
                console.print("Aucune VM Vagrant trouvée.", style="red")
                return
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
            # Si les données ressemblent à un message d'information (pas de VM)
            if data_lines and data_lines[0].startswith('There'):
                console.print("Aucune VM Vagrant trouvée.", style="red")
                return
            # Création du tableau
            table = Table(title="Vagrant Global Status", show_lines=True)
            table.add_column("ID", style="bold")
            table.add_column("Name", style="navajo_white1")
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
            progress.update(task, completed=True)
            console.print(f"[-] Erreur lors de la récupération du status global : {str(e)}", style="red")

def show_help():
    """Affiche l'aide"""
    console.print("[*] Aide - PantheonLab", style="cyan")
    console.print("-" * 30, style="cyan")
    console.print("[+] 1. Vérifier les dépendances", style="navajo_white1")
    console.print("    Vérifie que tous les outils nécessaires sont installés", style="navajo_white1")
    console.print()
    console.print("[+] 2. Lancer le lab", style="navajo_white1")
    console.print("    Démarre toutes les machines virtuelles et configure l'environnement", style="navajo_white1")
    console.print()
    console.print("[+] 3. Statut global des VMs", style="navajo_white1")
    console.print("    Affiche le status global des VMs Vagrant", style="navajo_white1")
    console.print()
    console.print("[+] 4. Détruire le lab", style="navajo_white1")
    console.print("    Détruit toutes les VMs du lab", style="navajo_white1")
    console.print()
    console.print("[+] 5. Aide", style="navajo_white1")
    console.print("    Affiche cette page d'aide", style="navajo_white1")
    console.print()
    console.print("[+] q. Quitter", style="red")
    console.print("    Ferme l'application", style="navajo_white1")
    console.print()
    console.print("[*] Note: Assurez-vous d'avoir suffisamment d'espace disque et de RAM.", style="red")

def is_lab_fully_running():
    """Retourne True si exactement 3 VMs Vagrant sont en état running, False sinon."""
    try:
        result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
        if result.returncode != 0:
            return False
        lines = result.stdout.splitlines()
        # Cas où il n'y a aucune VM : Vagrant affiche un message d'information
        if any('There are no active Vagrant environments' in line for line in lines):
            return False
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
            # Si la ligne est un message d'information, on arrête
            if line.startswith('There'):
                return False
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
        # Cas où il n'y a aucune VM : Vagrant affiche un message d'information
        if any('There are no active Vagrant environments' in line for line in lines):
            return False
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
            # Si la ligne est un message d'information, on arrête
            if line.startswith('There'):
                return False
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
    try:
        result = subprocess.run(['vagrant', 'global-status', '--prune'], capture_output=True, text=True)
        if result.returncode != 0:
            return "[AUCUN LAB] Impossible de vérifier l'état du lab.", "red"
        lines = result.stdout.splitlines()
        if any('There are no active Vagrant environments' in line for line in lines):
            return "[AUCUN LAB] Aucun lab n'est lancé.", "red"
        header_idx = None
        for i, line in enumerate(lines):
            if line.strip().startswith('id') and 'directory' in line:
                header_idx = i
                break
        if header_idx is None:
            return "[AUCUN LAB] Aucun lab n'est lancé.", "red"
        running_count = 0
        total_count = 0
        for line in lines[header_idx+1:]:
            if not line.strip():
                break
            if line.startswith('There'):
                break
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            state = parts[3]
            if state == 'running':
                running_count += 1
            total_count += 1
        if total_count == 0:
            return "[AUCUN LAB] Aucun lab n'est lancé.", "red"
        elif total_count < EXPECTED_VM_COUNT:
            return f"[LAB PARTIEL] Seulement {total_count}/{EXPECTED_VM_COUNT} VM(s) détectées.", "yellow"
        elif running_count < EXPECTED_VM_COUNT:
            return f"[LAB PARTIEL] {running_count}/{EXPECTED_VM_COUNT} VM(s) running. Pas toutes les VMs ne sont running.", "yellow"
        else:
            return "[LAB EN COURS] Toutes les VMs sont running.", "green"
    except Exception:
        return "[AUCUN LAB] Erreur lors du check.", "red"

def destroy_lab():
    """Détruit toutes les VMs du lab via vagrant destroy -f dans pantheon-lab/vagrant/ avec spinner"""
    confirm = input("Êtes-vous sûr de vouloir détruire toutes les VMs du lab ? (o/N): ").strip().lower()
    if confirm not in ["o", "oui", "y", "yes"]:
        console.print("[+] Destruction annulée.", style="yellow")
        return
    try:
        with Progress(
            SpinnerColumn(style="orange3"),
            TextColumn("[navajo_white1]Destruction du lab en cours...[/navajo_white1]"),
            console=console,
            transient=True
        ) as progress:
            task = progress.add_task("Destruction du lab en cours...", total=None)
            result = subprocess.run(['vagrant', 'destroy', '-f'], cwd='pantheon-lab/vagrant/', capture_output=True, text=True)
            progress.update(task, completed=True)
            if result.returncode == 0:
                console.print("[+] Lab détruit avec succès.", style="green")
                console.print(result.stdout, style="navajo_white1")
            else:
                console.print("[-] Erreur lors de la destruction du lab.", style="red")
                console.print(result.stderr, style="navajo_white1")
    except Exception as e:
        console.print(f"[-] Exception lors de la destruction : {str(e)}", style="red")

def main():
    """Fonction principale avec menu minimaliste"""
    # Animation de chargement pour la vérification de l'état du lab
    status_message = '[navajo_white1]Vérification de l\'état du lab...[/navajo_white1]'
    status_color = 'navajo_white1'
    def check_status():
        nonlocal status_message, status_color
        msg, col = get_lab_status_message()
        status_message = msg
        status_color = col
    t = threading.Thread(target=check_status)
    t.start()
    with Progress(
        SpinnerColumn(style="orange3"),
        TextColumn("[navajo_white1]Vérification de l'état du lab...[/navajo_white1]"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Vérification de l'état du lab...", total=None)
        while t.is_alive():
            time.sleep(0.1)
        progress.update(task, completed=True)
    # Affiche le résultat du status du lab
    console.print(f"[{status_color}]{status_message}[/{status_color}]")
    console.print()

    while True:
        console.clear()
        print_header()
        console.print(f"[{status_color}]{status_message}[/{status_color}]")
        console.print()
        # Affichage du menu principal (numéros colorés comme le texte)
        console.print("[*] Menu Principal", style="cyan")
        console.print("[+] [navajo_white1]1.[/] Vérifier les dépendances", style="navajo_white1")
        console.print("[+] [navajo_white1]2.[/] Lancer le lab", style="navajo_white1")
        console.print("[+] [navajo_white1]3.[/] Statut global des VMs", style="navajo_white1")
        console.print("[+] [navajo_white1]4.[/] Détruire le lab", style="navajo_white1")
        console.print("[+] [navajo_white1]5.[/] Aide", style="navajo_white1")
        console.print("[+] [navajo_white1]q.[/] Quitter", style="navajo_white1")
        console.print()
        # Choix de l'utilisateur
        choice = input("[?] Choisissez une option (1-5): ").strip()
        console.print()
        if choice == "1":
            check_dependencies()
            input("[?] Appuyez sur Entrée pour continuer...")
            continue
        elif choice == "2":
            launch_lab()
            input("[?] Appuyez sur Entrée pour continuer...")
            continue
        elif choice == "3":
            show_global_status()
            input("[?] Appuyez sur Entrée pour continuer...")
            continue
        elif choice == "4":
            destroy_lab()
            input("[?] Appuyez sur Entrée pour continuer...")
            continue
        elif choice == "5":
            show_help()
            input("[?] Appuyez sur Entrée pour continuer...")
            continue
        elif choice == "q":
            console.print("[+] Au revoir!", style="green")
            break
        else:
            console.print("[-] Option invalide.", style="red")
            input("[?] Appuyez sur Entrée pour continuer...")
            continue

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[+] Au revoir!", style="green")
        sys.exit(0) 