#Commandes powershell qui peuvent s'avérer utilies pour les testes
-------------------------------------------------------------------------------------------------------------------------------------------

#Suprimer un compte utilisateur de l'AD
Remove-ADUser -Identity 'hercule' -Confirm:$false

-------------------------------------------------------------------------------------------------------------------------------------------

# Je ne sais plus ce que fais ce code
# Ob OU object
$ouDN = "OU=OLYMPE,DC=pantheon,DC=god"
$userName = "pantheon\test_dmsa"
$schemaGuid = [GUID] "7b8b558a-93a5-4af7-adca-c017e67f1057" # msDS-GroupManagedServiceAccount

$ou = [ADSI]"LDAP://$ouDN"

$sd = $ou.psbase.ObjectSecurity

# Define Active Directory rights and inheritance flags
$ActiveDirectoryRights = [System.DirectoryServices.ActiveDirectoryRights]::CreateChild
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
$PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
$AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow

# Translate username to security identifier (SID)
$ntAccount = New-Object System.Security.Principal.NTAccount($userName)
$sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])

# Create the access rule for the msDS-GroupManagedServiceAccount class
$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $sid,
    $ActiveDirectoryRights,
    $AccessControlType,
    $schemaGuid,
    $InheritanceType,
    [guid]::Empty
)

$sd.AddAccessRule($ace)
$ou.psbase.ObjectSecurity = $sd
$ou.psbase.CommitChanges()


Write-Output "Permission CreateChild on msDS-GroupManagedServiceAccount delegated to $userName on $ouDN"

-------------------------------------------------------------------------------------------------------------------------------------------

# Crée une kds-root-key avec une data dans le passer
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
# Voir les kds-root-key
Get-KdsRootKey

-------------------------------------------------------------------------------------------------------------------------------------------

# Crée un dmsa
New-ADServiceAccount -Name svc_dmsa -DNSHostName "dc01.pantheon.god" -Path "CN=Users,DC=pantheon,DC=god" CreateDelegatedServiceAccount = $true
$params = @{
 Name = "svc_dmsa"
 DNSHostName = "dc01.pantheon.god" # Nom de la machine au quel il est associer
 CreateDelegatedServiceAccount = $true
 KerberosEncryptionType = "AES256"
}

-------------------------------------------------------------------------------------------------------------------------------------------

# Crée un gmsa (à revoir car incomplet)
$params = @{
  Name = "svc_gmsa"
  DNSHostName = "dc01.pantheon.god"  # Remplace par le FQDN réel du serveur
  KerberosEncryptionType = "AES256"
}
New-ADServiceAccount @params

-------------------------------------------------------------------------------------------------------------------------------------------

# Récupérer les certificat présent dans la banque local
Get-ChildItem -Path Cert:\LocalMachine\My

-------------------------------------------------------------------------------------------------------------------------------------------

$subject = "CN=pantheon-dc01.pantheon.god"
$certs = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq $subject }

foreach ($cert in $certs) {
  Write-Output "Suppression du certificat: $($cert.Thumbprint)"
  Remove-Item -Path "Cert:\LocalMachine\My\$($cert.Thumbprint)" -Force
}


Get-ChildItem -Path Cert:\LocalMachine\My

-------------------------------------------------------------------------------------------------------------------------------------------

#supprimer une OU :
Import-Module ActiveDirectory

$OU = "OU=ENFERS,DC=pantheon,DC=god"

# Get the OU object
$ouObj = Get-ADOrganizationalUnit -Identity $OU -Properties ProtectedFromAccidentalDeletion

if ($ouObj.ProtectedFromAccidentalDeletion) {
    Write-Host "Removing 'Protect from accidental deletion' flag on $OU"
    Set-ADOrganizationalUnit -Identity $OU -ProtectedFromAccidentalDeletion $false
} else {
    Write-Host "'Protect from accidental deletion' flag is NOT set on $OU"
}
Remove-ADOrganizationalUnit -Identity $OU -Recursive -Confirm:$false

-------------------------------------------------------------------------------------------------------------------------------------------

# Liste tous les Rights (privilèges)

-------------------------------------------------------------------------------------------------------------------------------------------

# Liste tous les Extended Rights (controlAccessRight) avec leur GUID
$configNC = (Get-ADRootDSE).ConfigurationNamingContext

Get-ADObject `
  -SearchBase "CN=Extended-Rights,$configNC" `
  -LDAPFilter "(objectClass=controlAccessRight)" `
  -Properties Name, rightsGuid |
  Format-Table Name, rightsGuid -AutoSiz1

-------------------------------------------------------------------------------------------------------------------------------------------

#Receuilleur des infos sur une tache planifier
Get-ScheduledTaskInfo -TaskName "AthenaScript"
# Supprimer une tâche planifier 
Unregister-ScheduledTask -TaskName "AthenaScript" -Confirm:$false

-------------------------------------------------------------------------------------------------------------------------------------------

#  Lister tout les spn d'un domaine 

cls
$search = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
$search.filter = "(servicePrincipalName=*)"

## You can use this to filter for OU's:
## $results = $search.Findall() | `
## ?{ $_.path -like '*OU=whatever,DC=whatever,DC=whatever*' }
$results = $search.Findall()

foreach( $result in $results ) {
  $userEntry = $result.GetDirectoryEntry()
  Write-host "Object Name = " $userEntry.name -backgroundcolor "yellow" -foregroundcolor "black"
  Write-host "DN = " $userEntry.distinguishedName
  Write-host "Object Cat. = " $userEntry.objectCategory
  Write-host "servicePrincipalNames"

  $i=1
  foreach( $SPN in $userEntry.servicePrincipalName ) {
    Write-host "SPN ${i} =$SPN"
    $i+=1
  }
  Write-host ""
}

# Voir les SPN stocker dans l'atribue SPNMappings qui stockes les SPN représenter par l'alias HOST

Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=PANTHEON,DC=GOD" -properties sPNMappings

-------------------------------------------------------------------------------------------------------------------------------------------

# Crée la propriété DisableRestrictedAdmin avec une valeur de 0 pour permettre le pass the hash.
New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name DisableRestrictedAdmin -PropertyType DWord -Value 0
# Crée la propriété DisableRestrictedAdmin avec une valeur de 1.
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name DisableRestrictedAdmin -Value 1
# Crée la propriété DisableRestrictedAdmin avec une valeur de 1.
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Name DisableRestrictedAdmin -Value 0

-------------------------------------------------------------------------------------------------------------------------------------------

#DPAPI
# Crée une paire masterkey/credential
cmdkey /add:pantheon.god /user:hades /pass:"D3@thL0rd!2025"

# Vérifier la présence de cred et d'une masterkey
ls "$env:APPDATA\Microsoft\Credentials" -Fo
ls "$env:APPDATA\Microsoft\Protect" -Fo
ls C:\Users\hades\AppData\Roaming\Microsoft\Credentials\
ls C:\Users\hades\AppData\Roaming\Microsoft\Protect\
#Supprimé les creds et la masterkey
Remove-Item "$env:APPDATA\Microsoft\Protect\*" -Fo
Remove-Item "$env:APPDATA\Microsoft\Credentials\*" -Fo
Remove-Item "C:\Users\hades\AppData\Roaming\Microsoft\Credentials\*" -Fo
Remove-Item "C:\Users\hades\AppData\Roaming\Microsoft\Protect\*" -Fo

-------------------------------------------------------------------------------------------------------------------------------------------
