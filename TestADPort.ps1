<#PSScriptInfo
.VERSION 1.0
.GUID 
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
This script will get the domain controllers from same site and it will test telnet over Necessary ports. 
Static ports - 88;445;389;135
RPC dynamic ports - From 49152 to 65535
#>


$DomainName = Read-Host "Enter Domain Name "
Write-Host "Getting Site information..." -ForegroundColor Yellow
$dsgetDCCommand = 'nltest /dsgetdc:' + $DomainName + ' /force'
$DC = cmd /c $dsgetDCCommand

for ( $i = 0; $i -le $dc.Count; $i++ ) {

    if ($DC[$i] -match "DC: ") {$DCName = (-split $DC[$i])[-1]}
    if ($DC[$i] -match "Dc Site Name: ") {$DCSite = (-split $DC[$i])[-1]}
    if ($DC[$i] -match "Our Site Name: ") {$ClientSite = (-split $DC[$i])[-1]}
}

if ($null -eq $ClientSite) { Write-Warning -Message "Client Site is null. Considering DC site as client site"; $ClientSite = $DCSite}
Write-Host -ForegroundColor Green "
DC Site     : $($DCSite)
Client Site : $($ClientSite)
"

$DCsInSite = @()
$Site = "Site: " + $ClientSite
$DCList = cmd /c 'nltest /dclist:'
$DCList | ForEach-Object {if ($_ -match $Site) {$DCsInSite += (-split $_)[0]} }

@(88;445;389;135;49152..65535) | ForEach-Object { 
    
    foreach ($DCInSite in $DCsInSite) { 
        
        Write-Host -ForegroundColor Yellow "Testing telnet to $($DCInSite) on Port $($_) " 
        
        $Test = Test-NetConnection -ComputerName $DCInSite -Port $_ -WarningAction SilentlyContinue -WarningVariable TestStatPortWarning | Select-Object -Property ComputerName,RemoteAddress, RemotePort, TcpTestSucceeded
        
        Switch ($Test.TcpTestSucceeded) {
            $true {Write-Host -BackgroundColor Green "Success"}
            $false {Write-Host -BackgroundColor Red "Failed"}      
        }

        $Test | Export-Csv -Path .\PortTest.CSV -NoTypeInformation -Append 
    } 
}
