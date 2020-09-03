<#
.SYNOPSIS
Lists all members of a group, including members of nested child groups. Option to save the information to a csv.

.EXAMPLE
.\Get-NestedGroupMembers.ps1 -GroupName BETHEL-DEPT-Group [-GroupsOnly] [-CSVPath C:\Path\To\CSV.csv] 
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string]$GroupName,
    [string]$CSVPath = $null,
    [switch]$GroupsOnly
)

function Get-GroupMembers {
    param (
        [string]$GroupName,
        [int]$NestLevel = 0
    )

    Find-ADGroupMember -GroupName $GroupName -Searcher $searcher | ForEach-Object {
        $member = [adsi]"LDAP://$_"
        $row = $table.NewRow()
        $row.Type = $member.Class
        $row.ParentGroup = $GroupName
        $row.Nesting = $NestLevel
        if ($member.Class -eq "group") {
            $row.UserName = $member.cn.Value
            $table.Rows.Add($row) 
            Get-GroupMembers -GroupName $member.Name -NestLevel ($NestLevel + 1)
        } else {
            if ($GroupsOnly) {
                return
            }

            $row.UserName = $member.samAccountName.Value
            $row.DisplayName = $member.Name.Value
            $table.Rows.Add($row) 
        }    
    }
}

Import-Module "$PSScriptRoot\Modules\Manifest.psd1" -Force

if (!(Find-ADGroup -GroupName $GroupName)) {
    Write-Log "The group $GroupName was not found. Exiting script." -Type Error
    exit
}

$table = New-Object -TypeName System.Data.DataTable
$table.Columns.Add((New-Object -TypeName System.Data.DataColumn UserName,([string])))
$table.Columns.Add((New-Object -TypeName System.Data.DataColumn DisplayName,([string])))
$table.Columns.Add((New-Object -TypeName System.Data.DataColumn Type,([string])))
$table.Columns.Add((New-Object -TypeName System.Data.DataColumn ParentGroup,([string])))
$table.Columns.Add((New-Object -TypeName System.Data.DataColumn Nesting,([string])))
$searcher = New-AdsiSearcher

Get-GroupMembers -GroupName $GroupName

if ($CSVPath) {
    try {
        $table | Export-Csv -Path $CSVPath -NoTypeInformation
        Write-Log "Data has been saved in $CSVPath." -Type Success
    } catch {
        Write-Log $_ -Type Error
        Write-Log "Could not save data to the path $CSVPath. Please see the error above." -Type Warning
    }
} else {
    $table | Format-Table -AutoSize
}