
<#PSScriptInfo

.VERSION 1.1

.GUID 38d63264-46cf-4c7d-95e8-9e2089e8e8d6

.AUTHOR Suman Bhowmik

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 This script is to 
  1. Dump, purge or dump and Purge all kerberos tickets from a computer. 

#> 
Param()



Function DumpTickets {
foreach ($WMILogonSession in $WMILogonSessions) { 
    $LogonSessionID = '0x' + [Convert]::ToString($WMILogonSession.LogonID, 16)

    for ($i = 0; $i -le $WMILogonSession.Properties.name.count; $i++) {
        if ($WMILogonSession.Properties.name[$i] -match "AuthenticationPackage") {
            $logonAuthType = $WMILogonSession.Properties.value[$i]
        }
    }
    
    foreach ($klistLogonSession in $klistLogonSessions) {
       if ($klistLogonSession -match $LogonSessionID) {
           $klistLogonSession = ($klistLogonSession -split " ")
           $ab = $klistLogonSession[1..($klistLogonSession.Count-2)]
           $logonUserName = $null

            for ($k=0; $k -le $ab.Count; $k++) {$logonUserName = $logonUserName + $ab[$k] + " "}

       } 
    
    }

    'User Name:  ' + $logonUserName >> Tickets.txt
    'Logon Session ID:  ' + $LogonSessionID  >> Tickets.txt
    'Logon Type:   ' + $WMILogonSession.LogonType >> Tickets.txt
    'Authentication Type:  ' + $logonAuthType >> Tickets.txt
    'Tickets in the logon session: ==== '>> Tickets.txt
     klist -li $LogonSessionID tickets >> Tickets.txt
     '

===================================================================================================

' >> Tickets.txt    
}
$TxtPath = (Get-Item .\Tickets.txt).FullName
Write-Host "Ticket information are stored in $($TxtPath)" -ForegroundColor Green

}

Function PurgeTickets {
    Write-Warning "This will delete all chached kerberos tickets."
    $UserInput = Read-Host "Enter Y to continue"

    if ($UserInput -eq "Y") {
        $WMILogonSessions = (gwmi win32_LogonSession)
        foreach ($WMILogonSession in $WMILogonSessions) { 
            $LogonSessionID = '0x' + [Convert]::ToString($WMILogonSession.LogonID, 16)
            $aaa = klist -li $LogonSessionID purge
            "Purged tickets for SessionID $($LogonSessionID)"
        }
    }
}

Write-Host "Gathering Logon session information" -ForegroundColor Green
$WMILogonSessions = (gwmi win32_LogonSession)
$klistLogonSessions = (cmd /c "klist sessions") -split ":" | Where-Object {$_ -match "0x"}
$WMISessionIDs = @()
if ((Test-Path .\Tickets.txt) -eq $true) {Clear-Content Tickets.txt -ErrorAction SilentlyContinue}
Write-Host "Found $($WMILogonSessions.Count) logon sessions" -ForegroundColor Green

[int]$UserInput1 = Read-Host "
Choose one of the options below
1. Purge Tickets
2. Dump tickets
3. Dump tickets and Purge
"


if ($UserInput1 -eq "1") {PurgeTickets}
elseif ($UserInput1 -eq "2") {DumpTickets}
elseif ($UserInput1 -eq "3") {DumpTickets; PurgeTickets}
else {}







