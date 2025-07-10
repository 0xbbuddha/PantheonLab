# Script de vérification DPAPI Hera
# A exécuter sur les machines Windows du lab

Write-Host "=== Vérification DPAPI Hera ===" -ForegroundColor Cyan

# 1. Vérifier l'existence de la tâche planifiée
Write-Host "`n[1] Vérification de la tâche planifiée..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName "Hera-DPAPI-Creds" -ErrorAction Stop
    Write-Host "✅ Tâche planifiée trouvée: $($task.TaskName)" -ForegroundColor Green
    Write-Host "   - État: $($task.State)" -ForegroundColor White
    Write-Host "   - Utilisateur: $($task.Principal.UserId)" -ForegroundColor White
    
    # Informations sur la dernière exécution
    $taskInfo = Get-ScheduledTaskInfo -TaskName "Hera-DPAPI-Creds"
    Write-Host "   - Dernière exécution: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "   - Résultat: $($taskInfo.LastTaskResult)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Tâche planifiée non trouvée!" -ForegroundColor Red
}

# 2. Vérifier les droits utilisateur
Write-Host "`n[2] Vérification des droits utilisateur..." -ForegroundColor Yellow
try {
    $userRights = & secedit /export /cfg tempfile.cfg /quiet
    $content = Get-Content tempfile.cfg | Select-String "SeBatchLogonRight"
    if ($content -match "PANTHEON\\hera") {
        Write-Host "✅ Droit SeBatchLogonRight accordé à PANTHEON\hera" -ForegroundColor Green
    } else {
        Write-Host "❌ Droit SeBatchLogonRight manquant pour PANTHEON\hera" -ForegroundColor Red
    }
    Remove-Item tempfile.cfg -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️  Impossible de vérifier les droits utilisateur" -ForegroundColor Yellow
}

# 3. Vérifier les credentials stockés (nécessite une session Hera)
Write-Host "`n[3] Vérification des credentials DPAPI..." -ForegroundColor Yellow
Write-Host "   Note: Cette vérification nécessite une session utilisateur Hera" -ForegroundColor Gray

# Vérifier si on est dans une session Hera
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($currentUser -like "*hera*") {
    Write-Host "   Session Hera détectée, vérification des credentials..." -ForegroundColor White
    
    # Lister les credentials
    $cmdkeyOutput = & cmdkey /list 2>&1
    if ($cmdkeyOutput -match "pantheon.god") {
        Write-Host "✅ Credentials pantheon.god trouvés dans cmdkey" -ForegroundColor Green
    } else {
        Write-Host "❌ Credentials pantheon.god non trouvés" -ForegroundColor Red
    }
    
    # Vérifier les fichiers DPAPI
    $credPath = "$env:APPDATA\Microsoft\Credentials"
    $credFiles = Get-ChildItem $credPath -ErrorAction SilentlyContinue
    if ($credFiles) {
        Write-Host "✅ Fichiers credentials DPAPI trouvés: $($credFiles.Count)" -ForegroundColor Green
    } else {
        Write-Host "❌ Aucun fichier credentials DPAPI trouvé" -ForegroundColor Red
    }
} else {
    Write-Host "   Session utilisateur actuel: $currentUser" -ForegroundColor Gray
    Write-Host "   Pour vérifier les credentials DPAPI, connectez-vous en tant que PANTHEON\hera et relancez ce script" -ForegroundColor Gray
}

# 4. Test manuel de la commande
Write-Host "`n[4] Test de création manuelle du credential..." -ForegroundColor Yellow
if ($currentUser -like "*hera*") {
    try {
        & cmdkey /add:pantheon.god /user:hera /pass:Qu33n0fG0ds!2025
        Write-Host "✅ Commande cmdkey exécutée avec succès" -ForegroundColor Green
        
        # Vérifier immédiatement
        $verify = & cmdkey /list:pantheon.god 2>&1
        if ($verify -match "hera") {
            Write-Host "✅ Credential vérifié dans cmdkey" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Erreur lors de l'exécution de cmdkey: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   Nécessite une session PANTHEON\hera pour tester" -ForegroundColor Gray
}

Write-Host "`n=== Fin de la vérification ===" -ForegroundColor Cyan
Write-Host "Pour une vérification complète des credentials DPAPI:" -ForegroundColor White
Write-Host "1. Connectez-vous en RDP en tant que PANTHEON\hera" -ForegroundColor White
Write-Host "2. Exécutez: cmdkey /list" -ForegroundColor White
Write-Host "3. Cherchez l'entrée 'pantheon.god'" -ForegroundColor White 