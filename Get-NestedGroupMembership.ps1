<#
.SYNOPSIS
Lists all groups that the given user/group/computer is a member of, including parents of nested groups. Option to save the information to a file.

.EXAMPLE
.\Get-NestedGroupMembership.ps1 -Identifier BETHEL-DEPT-Group|jbethelite|US2UA0000XXX -Type Group|User|Computer [-CSVPath C:\Path\To\CSV.csv]
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Identifier,
    [Parameter(Position=1, Mandatory=$true)]
    [ValidateSet("User","Group","Computer")]
    [string]$Type,
    [string]$CSVPath = $null
)

Import-Module "$PSScriptRoot\Modules\Manifest.psd1" -Force

function Get-GroupMembership {
    param (
        [string]$GroupDN,
        [int]$NestLevel = 0
    )

    $group = [adsi]"LDAP://$GroupDN"
    $groupName = $group.cn
    if ($CSVPath) {
        ("," * $NestLevel) + $groupName | Out-File -FilePath $CSVPath -Encoding ascii -Append
    } else {
        ("  " * $NestLevel) + $groupName | Write-Host
    }

    $NestLevel++
    $group.memberOf | ForEach-Object {
        Get-GroupMembership -GroupDN $_ -NestLevel $NestLevel
    }
}

$property = $adSearchObjectProperty.$Type
$result = Search-AD -Filter "(&(objectClass=$Type)($property=$Identifier))"
if (!$result) {
    Write-Log "The $Type $Identifier was not found. Please verify the name and type." -Type Error
    exit
}

Get-GroupMembership -GroupDN $result.Properties.distinguishedname