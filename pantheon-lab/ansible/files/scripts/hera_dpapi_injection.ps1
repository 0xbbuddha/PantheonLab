# Script d'injection des credentials DPAPI pour Hera
# Destiné à être exécuté par une tâche planifiée

param(
    [string]$Target = "pantheon.god",
    [string]$Username = "hera",
    [string]$Password = "Qu33n0fG0ds!2025",
    [string]$LogFile = "C:\Windows\Temp\hera-dpapi.log"
)

# Fonction de logging
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logEntry -Force
    Write-Output $logEntry
}

try {
    Write-Log "Début de l'injection des credentials DPAPI pour Hera"
    
    # Vérifier l'utilisateur actuel
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Log "Utilisateur actuel: $currentUser"
    
    # Exécuter la commande cmdkey
    Write-Log "Exécution de cmdkey pour $Target avec l'utilisateur $Username"
    $result = & cmdkey /add:$Target /user:$Username /pass:$Password 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ Commande cmdkey exécutée avec succès: $result"
        
        # Vérifier que le credential a été ajouté
        $list = & cmdkey /list 2>&1
        if ($list -match $Target) {
            Write-Log "✅ Credential $Target confirmé dans la liste"
        } else {
            Write-Log "⚠️  Credential $Target non trouvé dans la liste"
        }
    } else {
        Write-Log "❌ Échec de cmdkey (code: $LASTEXITCODE): $result"
        exit $LASTEXITCODE
    }
    
    # Vérifier les fichiers DPAPI
    $credPath = "$env:APPDATA\Microsoft\Credentials"
    if (Test-Path $credPath) {
        $credFiles = Get-ChildItem $credPath -ErrorAction SilentlyContinue
        Write-Log "Fichiers credentials DPAPI trouvés: $($credFiles.Count)"
    } else {
        Write-Log "⚠️  Répertoire credentials DPAPI non trouvé: $credPath"
    }
    
    Write-Log "✅ Injection DPAPI terminée avec succès"
    exit 0
    
} catch {
    Write-Log "❌ Erreur lors de l'injection DPAPI: $($_.Exception.Message)"
    Write-Log "Stack trace: $($_.Exception.StackTrace)"
    exit 1
} 