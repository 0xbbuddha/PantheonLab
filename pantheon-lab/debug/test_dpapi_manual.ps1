# Script de test manuel pour diagnostiquer le problème DPAPI Hera
# A exécuter en tant qu'Administrateur

Write-Host "=== Test DPAPI Hera - Diagnostic complet ===" -ForegroundColor Cyan

# 1. Vérifier l'existence de l'utilisateur Hera
Write-Host "`n[1] Vérification de l'utilisateur Hera..." -ForegroundColor Yellow
try {
    $domainUser = Get-ADUser -Identity "hera" -Properties PasswordLastSet, Enabled, LastLogonDate
    Write-Host "✅ Utilisateur Hera trouvé dans AD" -ForegroundColor Green
    Write-Host "   - Nom complet: $($domainUser.Name)" -ForegroundColor White
    Write-Host "   - Activé: $($domainUser.Enabled)" -ForegroundColor White
    Write-Host "   - Dernière connexion: $($domainUser.LastLogonDate)" -ForegroundColor White
    Write-Host "   - Mot de passe changé: $($domainUser.PasswordLastSet)" -ForegroundColor White
} catch {
    Write-Host "❌ Utilisateur Hera non trouvé dans AD: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Tester l'authentification avec les credentials
Write-Host "`n[2] Test d'authentification..." -ForegroundColor Yellow
try {
    $username = "PANTHEON\hera"
    $password = "Qu33n0fG0ds!2025"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)
    
    # Test avec Invoke-Command
    $result = Invoke-Command -ComputerName localhost -Credential $credential -ScriptBlock {
        $env:USERNAME
    } -ErrorAction Stop
    
    Write-Host "✅ Authentification réussie: $result" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec de l'authentification: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Tester la commande cmdkey manuellement
Write-Host "`n[3] Test de la commande cmdkey..." -ForegroundColor Yellow
try {
    $result = & cmd.exe /c "cmdkey /add:pantheon.god /user:hera /pass:Qu33n0fG0ds!2025" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Commande cmdkey réussie: $result" -ForegroundColor Green
        
        # Vérifier la liste des credentials
        $list = & cmdkey /list 2>&1
        if ($list -match "pantheon.god") {
            Write-Host "✅ Credential pantheon.god trouvé dans la liste" -ForegroundColor Green
        } else {
            Write-Host "❌ Credential pantheon.god non trouvé dans la liste" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Échec de la commande cmdkey: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur lors de l'exécution de cmdkey: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Créer une tâche planifiée de test simple
Write-Host "`n[4] Création d'une tâche planifiée de test..." -ForegroundColor Yellow
try {
    # Supprimer l'ancienne tâche de test si elle existe
    Unregister-ScheduledTask -TaskName "Test-Hera-Simple" -Confirm:$false -ErrorAction SilentlyContinue
    
    # Créer une tâche simple qui écrit dans un fichier
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo Test-Hera-Simple > C:\Windows\Temp\test-hera.txt"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $principal = New-ScheduledTaskPrincipal -UserId "PANTHEON\hera" -LogonType Password
    
    Register-ScheduledTask -TaskName "Test-Hera-Simple" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Password "Qu33n0fG0ds!2025"
    
    Write-Host "✅ Tâche de test créée" -ForegroundColor Green
    
    # Démarrer la tâche manuellement
    Start-ScheduledTask -TaskName "Test-Hera-Simple"
    Start-Sleep -Seconds 3
    
    # Vérifier le résultat
    $taskInfo = Get-ScheduledTaskInfo -TaskName "Test-Hera-Simple"
    Write-Host "   - Résultat: $($taskInfo.LastTaskResult) (0x$('{0:X}' -f $taskInfo.LastTaskResult))" -ForegroundColor White
    
    if (Test-Path "C:\Windows\Temp\test-hera.txt") {
        Write-Host "✅ Fichier test créé avec succès" -ForegroundColor Green
        $content = Get-Content "C:\Windows\Temp\test-hera.txt"
        Write-Host "   - Contenu: $content" -ForegroundColor White
    } else {
        Write-Host "❌ Fichier test non créé" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erreur lors de la création de la tâche de test: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Tester avec un script PowerShell au lieu de cmd.exe
Write-Host "`n[5] Test avec un script PowerShell..." -ForegroundColor Yellow
try {
    # Créer un script PowerShell temporaire
    $scriptPath = "C:\Windows\Temp\hera-dpapi-test.ps1"
    $scriptContent = @"
try {
    `$result = & cmdkey /add:pantheon.god /user:hera /pass:Qu33n0fG0ds!2025 2>&1
    Write-Output "cmdkey result: `$result" | Out-File -FilePath "C:\Windows\Temp\hera-dpapi-log.txt" -Append
    
    `$list = & cmdkey /list 2>&1
    Write-Output "cmdkey list: `$list" | Out-File -FilePath "C:\Windows\Temp\hera-dpapi-log.txt" -Append
    
    exit 0
} catch {
    Write-Output "Error: `$(`$_.Exception.Message)" | Out-File -FilePath "C:\Windows\Temp\hera-dpapi-log.txt" -Append
    exit 1
}
"@
    
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
    
    # Supprimer l'ancienne tâche
    Unregister-ScheduledTask -TaskName "Test-Hera-PowerShell" -Confirm:$false -ErrorAction SilentlyContinue
    
    # Créer une tâche avec PowerShell
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $scriptPath"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    $principal = New-ScheduledTaskPrincipal -UserId "PANTHEON\hera" -LogonType Password
    
    Register-ScheduledTask -TaskName "Test-Hera-PowerShell" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Password "Qu33n0fG0ds!2025"
    
    # Démarrer la tâche
    Start-ScheduledTask -TaskName "Test-Hera-PowerShell"
    Start-Sleep -Seconds 5
    
    # Vérifier le résultat
    $taskInfo = Get-ScheduledTaskInfo -TaskName "Test-Hera-PowerShell"
    Write-Host "   - Résultat PowerShell: $($taskInfo.LastTaskResult) (0x$('{0:X}' -f $taskInfo.LastTaskResult))" -ForegroundColor White
    
    if (Test-Path "C:\Windows\Temp\hera-dpapi-log.txt") {
        Write-Host "✅ Log PowerShell créé" -ForegroundColor Green
        $logContent = Get-Content "C:\Windows\Temp\hera-dpapi-log.txt"
        Write-Host "   - Log: $logContent" -ForegroundColor White
    } else {
        Write-Host "❌ Log PowerShell non créé" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erreur lors du test PowerShell: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Vérifier les événements dans le Task Scheduler
Write-Host "`n[6] Vérification des événements Task Scheduler..." -ForegroundColor Yellow
try {
    $events = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-TaskScheduler/Operational"; StartTime=(Get-Date).AddHours(-1)} -MaxEvents 20 -ErrorAction Stop
    $heraEvents = $events | Where-Object {$_.Message -like "*Hera*"}
    
    if ($heraEvents) {
        Write-Host "✅ Événements Hera trouvés:" -ForegroundColor Green
        foreach ($event in $heraEvents | Select-Object -First 3) {
            Write-Host "   - $($event.TimeCreated): ID $($event.Id) - $($event.LevelDisplayName)" -ForegroundColor White
            Write-Host "     Message: $($event.Message -split "`n" | Select-Object -First 1)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Aucun événement Hera récent trouvé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Impossible de lire les événements: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Résumé des recommandations ===" -ForegroundColor Cyan
Write-Host "1. Si l'authentification échoue → Vérifier le mot de passe Hera" -ForegroundColor White
Write-Host "2. Si cmdkey fonctionne manuellement → Problème avec la tâche planifiée" -ForegroundColor White
Write-Host "3. Si le test simple fonctionne → Problème avec la commande cmdkey en contexte" -ForegroundColor White
Write-Host "4. Vérifier les logs détaillés dans les événements Windows" -ForegroundColor White 