# Script de débogage pour les tâches planifiées DPAPI
# A exécuter en tant qu'Administrateur

param(
    [string]$TaskName = "Hera-DPAPI-Creds"
)

Write-Host "=== Debug Tâche Planifiée : $TaskName ===" -ForegroundColor Cyan

# 1. Informations sur la tâche
Write-Host "`n[1] Informations sur la tâche..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host "✅ Tâche trouvée" -ForegroundColor Green
    Write-Host "   - Nom: $($task.TaskName)" -ForegroundColor White
    Write-Host "   - État: $($task.State)" -ForegroundColor White
    Write-Host "   - Utilisateur: $($task.Principal.UserId)" -ForegroundColor White
    Write-Host "   - Type de logon: $($task.Principal.LogonType)" -ForegroundColor White
    Write-Host "   - Niveau d'exécution: $($task.Principal.RunLevel)" -ForegroundColor White
    Write-Host "   - Dernière exécution: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "   - Résultat: $($taskInfo.LastTaskResult) (0x$('{0:X}' -f $taskInfo.LastTaskResult))" -ForegroundColor White
    Write-Host "   - Prochaine exécution: $($taskInfo.NextRunTime)" -ForegroundColor White
    
} catch {
    Write-Host "❌ Tâche non trouvée: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# 2. Détails des triggers
Write-Host "`n[2] Analyse des triggers..." -ForegroundColor Yellow
$triggers = $task.Triggers
foreach ($trigger in $triggers) {
    Write-Host "   - Type: $($trigger.CimClass.CimClassName)" -ForegroundColor White
    Write-Host "   - Activé: $($trigger.Enabled)" -ForegroundColor White
    if ($trigger.StartBoundary) {
        Write-Host "   - Début: $($trigger.StartBoundary)" -ForegroundColor White
    }
    if ($trigger.Delay) {
        Write-Host "   - Délai: $($trigger.Delay)" -ForegroundColor White
    }
    if ($trigger.UserId) {
        Write-Host "   - Utilisateur: $($trigger.UserId)" -ForegroundColor White
    }
}

# 3. Détails des actions
Write-Host "`n[3] Analyse des actions..." -ForegroundColor Yellow
$actions = $task.Actions
foreach ($action in $actions) {
    Write-Host "   - Exécutable: $($action.Execute)" -ForegroundColor White
    Write-Host "   - Arguments: $($action.Arguments)" -ForegroundColor White
    Write-Host "   - Dossier de travail: $($action.WorkingDirectory)" -ForegroundColor White
}

# 4. Vérification de l'utilisateur
Write-Host "`n[4] Vérification de l'utilisateur..." -ForegroundColor Yellow
$username = $task.Principal.UserId
if ($username) {
    try {
        $user = Get-LocalUser -Name ($username -split '\\')[-1] -ErrorAction Stop
        Write-Host "✅ Utilisateur local trouvé: $($user.Name)" -ForegroundColor Green
        Write-Host "   - Activé: $($user.Enabled)" -ForegroundColor White
        Write-Host "   - Dernière connexion: $($user.LastLogon)" -ForegroundColor White
    } catch {
        Write-Host "⚠️  Utilisateur local non trouvé, vérification domain..." -ForegroundColor Yellow
        try {
            $domainUser = net user ($username -split '\\')[-1] /domain 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Utilisateur domain trouvé" -ForegroundColor Green
            } else {
                Write-Host "❌ Utilisateur domain non trouvé" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Erreur lors de la vérification domain" -ForegroundColor Red
        }
    }
}

# 5. Vérification des droits
Write-Host "`n[5] Vérification des droits utilisateur..." -ForegroundColor Yellow
try {
    $tempFile = "temp_rights.cfg"
    secedit /export /cfg $tempFile /quiet
    $content = Get-Content $tempFile
    $batchLogonRight = $content | Select-String "SeBatchLogonRight"
    $serviceLogonRight = $content | Select-String "SeServiceLogonRight"
    
    if ($batchLogonRight -match ($username -replace '\\', '\\\\')) {
        Write-Host "✅ Droit SeBatchLogonRight accordé" -ForegroundColor Green
    } else {
        Write-Host "❌ Droit SeBatchLogonRight manquant" -ForegroundColor Red
    }
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "⚠️  Impossible de vérifier les droits" -ForegroundColor Yellow
}

# 6. Test de la commande
Write-Host "`n[6] Test de la commande..." -ForegroundColor Yellow
$command = $actions[0].Execute
$arguments = $actions[0].Arguments

Write-Host "   Commande complète: $command $arguments" -ForegroundColor White

# Test d'existence du fichier
if (Test-Path $command) {
    Write-Host "✅ Exécutable trouvé: $command" -ForegroundColor Green
} else {
    Write-Host "❌ Exécutable non trouvé: $command" -ForegroundColor Red
}

# 7. Logs d'événements
Write-Host "`n[7] Recherche dans les logs..." -ForegroundColor Yellow
try {
    $events = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-TaskScheduler/Operational"; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 50 -ErrorAction Stop
    $taskEvents = $events | Where-Object {$_.Message -like "*$TaskName*"}
    
    if ($taskEvents) {
        Write-Host "✅ Événements trouvés pour la tâche:" -ForegroundColor Green
        foreach ($event in $taskEvents | Select-Object -First 5) {
            Write-Host "   - $($event.TimeCreated): ID $($event.Id) - $($event.LevelDisplayName)" -ForegroundColor White
        }
    } else {
        Write-Host "⚠️  Aucun événement récent trouvé pour la tâche" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Impossible de lire les logs: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 8. Solutions recommandées
Write-Host "`n[8] Solutions recommandées..." -ForegroundColor Yellow
Write-Host "   - Exécuter manuellement: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "   - Supprimer et recréer: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "   - Vérifier les credentials: Test avec un autre utilisateur" -ForegroundColor White
Write-Host "   - Redémarrer le service: Restart-Service -Name 'Schedule'" -ForegroundColor White

Write-Host "`n=== Fin du diagnostic ===" -ForegroundColor Cyan 