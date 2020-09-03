<#
.SYNOPSIS
Copys all members of a given group to another group.

.EXAMPLE
.\Copy-GroupMembers.ps1 -FromGroupName BETHEL-DEPT-GROUP1 -ToGroupName BETHEL-DEPT-GROUP2
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$FromGroupName,
	
    [Parameter(Position=1, Mandatory=$true)]
    [string]$ToGroupName
)

Import-Module "$PSScriptRoot\Modules\Manifest.psd1" -Force

$adsi = New-AdsiSearcher

$fromGroupResults = Find-ADGroup -GroupName $FromGroupName -Searcher $adsi
if (!$fromGroupResults) {
    Write-Log "The group $FromGroupName was not found! Please verify the group name." -Type Error
    exit
}

$toGroupResults = Find-ADGroup -GroupName $ToGroupName -Searcher $adsi
if (!$toGroupResults) {
    Write-Log "The group $ToGroupName was not found! Please verify the group name." -Type Error
    exit
}

$groupMembers = Find-ADGroupMember -GroupName $FromGroupName -Searcher $adsi
$count = 1
$groupMembers | ForEach-Object {
    Show-Progress -Message "Adding Group Members..." -Object $groupMembers -Iteration $count -Status "Adding $_"
    Add-ADGroupMember -Member $_ -AddToGroupName $ToGroupName
    $count++
}