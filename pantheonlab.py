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
import signal
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
DEBUG = '--debug' in sys.argv

def print_header():
    """Affiche l'en-tête avec l'ASCII art"""
    console.print(ASCII_ART, style="navajo_white1")
    console.print("=" * 94, style="navajo_white1")
    console.print()

def check_dependencies():
    """Vérifie les dépendances en exécutant le script shell avec animation spinner et gestion CTRL+C"""
    console.print("[+] Vérification des dépendances...", style="cyan")
    with Progress(
        SpinnerColumn(style="orange3"),
        TextColumn("[navajo_white1]Vérification des dépendances...[/navajo_white1]"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Vérification des dépendances...", total=None)
        try:
            proc = subprocess.Popen(['./check_requirements.sh'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, preexec_fn=os.setsid)
            try:
                stdout, stderr = proc.communicate()
            except KeyboardInterrupt:
                os.killpg(os.getpgid(proc.pid), signal.SIGINT)
                progress.update(task, completed=True)
                console.print("[-] Vérification interrompue par l'utilisateur.", style="yellow")
                return False
            progress.update(task, completed=True)
            if proc.returncode == 0:
                console.print("[+] Dépendances installées avec succès.", style="green")
                return True
            else:
                console.print("[-] Dépendances manquantes:", style="red")
                console.print(stdout.decode(), style="navajo_white1")
                return False
        except Exception as e:
            progress.update(task, completed=True)
            console.print(f"[-] Erreur lors de la vérification: {str(e)}", style="red")
            return False

def launch_lab():
    """Lance le lab en exécutant la commande 'cd pantheon-lab; ./pantheonv2.sh' avec gestion CTRL+C"""
    console.print("[+] Lancement du lab PantheonLab...", style="cyan")
    confirm = input("Confirmer le lancement des VMs? (O/n): ").strip().lower()
    if confirm in ['n', 'no', 'non']:
        console.print("[-] Lancement annulé.", style="red")
        return False
    try:
        if DEBUG:
            proc = subprocess.Popen('cd pantheon-lab; ./pantheonv2.sh', shell=True, preexec_fn=os.setsid)
            try:
                proc.wait()
            except KeyboardInterrupt:
                os.killpg(os.getpgid(proc.pid), signal.SIGINT)
                console.print("[-] Création du lab interrompue par l'utilisateur.", style="yellow")
                return False
            if proc.returncode == 0:
                console.print("[+] Lab lancé avec succès.", style="green")
                console.print("[+] Les machines virtuelles sont en cours de démarrage.", style="green")
                return True
            else:
                console.print("[-] Erreur lors du lancement du lab:", style="red")
                return False
        else:
            with Progress(
                SpinnerColumn(style="orange3"),
                TextColumn("[navajo_white1]Démarrage des machines virtuelles...[/navajo_white1]"),
                console=console,
                transient=True
            ) as progress:
                task = progress.add_task("Démarrage des machines virtuelles...", total=None)
                with open(os.devnull, 'w') as devnull:
                    proc = subprocess.Popen('cd pantheon-lab; ./pantheonv2.sh', shell=True, stdout=devnull, stderr=devnull, preexec_fn=os.setsid)
                    try:
                        proc.wait()
                    except KeyboardInterrupt:
                        os.killpg(os.getpgid(proc.pid), signal.SIGINT)
                        progress.update(task, completed=True)
                        console.print("[-] Création du lab interrompue par l'utilisateur.", style="yellow")
                        return False
                progress.update(task, completed=True)
                if proc.returncode == 0:
                    console.print("[+] Lab lancé avec succès.", style="green")
                    console.print("[+] Les machines virtuelles sont en cours de démarrage.", style="green")
                    return True
                else:
                    console.print("[-] Erreur lors du lancement du lab:", style="red")
                    return False
    except Exception as e:
        console.print(f"[-] Erreur lors du lancement: {str(e)}", style="red")
        return False

def show_global_status():
    """Affiche le status global des VMs Vagrant avec un joli tableau et une animation spinner, gestion CTRL+C"""
    console.print("[+] Statut global des VMs (vagrant global-status)", style="cyan")
    with Progress(
        SpinnerColumn(style="orange3"),
        TextColumn("[navajo_white1]Récupération du status global des VMs...[/navajo_white1]"),
        console=console,
        transient=True
    ) as progress:
        task = progress.add_task("Récupération du status global des VMs...", total=None)
        try:
            proc = subprocess.Popen(['vagrant', 'global-status', '--prune'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, preexec_fn=os.setsid)
            try:
                stdout, stderr = proc.communicate()
            except KeyboardInterrupt:
                os.killpg(os.getpgid(proc.pid), signal.SIGINT)
                progress.update(task, completed=True)
                console.print("[-] Récupération du status interrompue par l'utilisateur.", style="yellow")
                return
            progress.update(task, completed=True)
            if proc.returncode != 0:
                console.print("[-] Erreur lors de l'exécution de vagrant global-status", style="red")
                console.print(stderr.decode(), style="navajo_white1")
                return
            lines = stdout.decode().splitlines()
            if any('There are no active Vagrant environments' in line for line in lines):
                console.print("Aucune VM Vagrant trouvée.", style="red")
                return
            header_idx = None
            for i, line in enumerate(lines):
                if line.strip().startswith('id') and 'directory' in line:
                    header_idx = i
                    break
            if header_idx is None:
                console.print("[-] Impossible de parser la sortie de vagrant global-status", style="red")
                return
            data_lines = []
            for line in lines[header_idx+1:]:
                if not line.strip():
                    break
                data_lines.append(line)
            if data_lines and data_lines[0].startswith('There'):
                console.print("Aucune VM Vagrant trouvée.", style="red")
                return
            table = Table(title="Vagrant Global Status", show_lines=True)
            table.add_column("ID", style="bold")
            table.add_column("Name", style="navajo_white1")
            table.add_column("Provider", style="magenta")
            table.add_column("State", style="bold")
            table.add_column("Directory", style="cyan")
            for line in data_lines:
                parts = line.split(None, 4)
                if len(parts) < 5:
                    continue
                id_, name, provider, state, directory = parts
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

def check_lab_installed():
    """Vérifie si le lab est installé en regardant le dossier .vagrant/machines (3 machines, non vides, pas juste vagrant_cwd)"""
    base_path = os.path.join('pantheon-lab', 'vagrant', '.vagrant', 'machines')
    if not os.path.isdir(base_path):
        console.print(f"[red]STATUS : LAB NON INSTALLE (0/{EXPECTED_VM_COUNT} VM(s) détectées)[/red]")
        return False
    vm_names = [d for d in os.listdir(base_path) if os.path.isdir(os.path.join(base_path, d))]
    if not vm_names:
        console.print(f"[red]STATUS : LAB NON INSTALLE (0/{EXPECTED_VM_COUNT} VM(s) détectées)[/red]")
        return False
    count = 0
    for vm_name in vm_names:
        vm_path = os.path.join(base_path, vm_name)
        subdirs = [d for d in os.listdir(vm_path) if os.path.isdir(os.path.join(vm_path, d))]
        found_valid = False
        for sub in subdirs:
            sub_path = os.path.join(vm_path, sub)
            files = os.listdir(sub_path)
            if not files:
                continue  # sous-dossier vide
            # Si le seul fichier est vagrant_cwd, ce n'est pas valide
            if len(files) == 1 and files[0] == 'vagrant_cwd':
                continue
            found_valid = True
            break
        if found_valid:
            count += 1
    if count == EXPECTED_VM_COUNT:
        console.print("[green]STATUS : LAB INSTALLÉ[/green]")
        return True
    else:
        console.print(f"[red]STATUS : LAB NON INSTALLÉ ({count}/{EXPECTED_VM_COUNT} VM(s) détectées)[/red]")
        return False

def destroy_lab():
    """Détruit toutes les VMs du lab via vagrant destroy -f dans pantheon-lab/vagrant/ avec spinner et gestion CTRL+C"""
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
            proc = subprocess.Popen(['vagrant', 'destroy', '-f'], cwd='pantheon-lab/vagrant/', stdout=subprocess.PIPE, stderr=subprocess.PIPE, preexec_fn=os.setsid)
            try:
                stdout, stderr = proc.communicate()
            except KeyboardInterrupt:
                os.killpg(os.getpgid(proc.pid), signal.SIGINT)
                progress.update(task, completed=True)
                console.print("[-] Destruction interrompue par l'utilisateur.", style="yellow")
                return
            progress.update(task, completed=True)
            if proc.returncode == 0:
                console.print("[+] Lab détruit avec succès.", style="green")
                console.print(stdout.decode(), style="navajo_white1")
            else:
                console.print("[-] Erreur lors de la destruction du lab.", style="red")
                console.print(stderr.decode(), style="navajo_white1")
    except Exception as e:
        console.print(f"[-] Exception lors de la destruction : {str(e)}", style="red")

def main():
    """Fonction principale avec menu minimaliste"""
 

    while True:
        console.clear()
     
        print_header()
        check_lab_installed()

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
