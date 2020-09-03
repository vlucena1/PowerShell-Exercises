<#
.SYNOPSIS
Copys the group membership of a given user to another user.
Optional flag to skip alarmed groups.

.EXAMPLE
.\Copy-GroupMembership.ps1 -FromUserName jbethelite -ToUserName kbethelite [-SkipAlarmed]
#>

param (
	[Parameter(Mandatory=$true, Position=0)]
	[string]$FromUserName,
	[Parameter(Mandatory=$true, Position=1)]
	[string]$ToUserName,
	[switch]$SkipAlarmed
)

Import-Module "$PSScriptRoot\Modules\Manifest.psd1" -Force

$adsi = New-AdsiSearcher

$fromUserObject = Find-ADUserObject -Username $FromUserName -Searcher $adsi
	if (!$fromUserObject) {
		Write-Log "The user $FromUserName was not found. Please verify the user name." -Type Error
		exit
	}

$toUserObject = Find-ADUserObject -Username $toUserName -Searcher $adsi
	if (!$toUserObject) {
		Write-Log "The user $ToUserName was not found. Please verify the user name." -Type Error
		exit
	}

$groupsToCopy = $fromUserObject.memberOf
$toUserPath = $toUserObject.Path

$groupsToCopy | ForEach-Object {
	try {
		$group = [adsi]"LDAP://$_"
		if ($toUserObject.memberOf -match $_) {
			Write-Log "The user $ToUserName is already a member of the group $($group.cn)."
			return
		}

		if ($SkipAlarmed -and $group.description -match "alarmed") {
			Write-Log "Skipping the group $($group.cn) because it is alarmed." -Type Warning
			return
		}

		$group.Add($toUserPath)
		Write-Log "Added $ToUserName to $($group.cn)." -Type Success
	} catch {
		Write-Log $_ -Type Error
		Write-Log "Could not add $ToUserName to $($group.cn). Please see the error above." -Type Warning
	}
}