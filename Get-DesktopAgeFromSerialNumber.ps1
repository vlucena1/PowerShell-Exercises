<#
    .SYNOPSIS

    Get age of machines in branch OU

    .DESCRIPTION

    Lists all computers in a given OU and display age information based on their serial number.
    Note: At the moment, only HP machines are supported

    .EXAMPLE

    Get age for all machines in the Clients IDN OU
    PS> Get-DateFromSerialNumber.ps1 -BranchCode IDN

    .EXAMPLE
    Get all machines in the Clients IDN OU that are older than 5 years
    PS> Get-DateFromSerialNumber.ps1 -BranchCode IDN -MinimumAgeYears 5

#>

param (
    [Parameter(Position = 0, Mandatory = $true)]
    $BranchCode,

    [int]$MinimumAgeYears = 0
)

Import-Module "$PSScriptRoot\Modules\Manifest.psd1" -Force

if (Test-BranchCode -BranchCode $BranchCode) {
    Write-Log -Message "Getting machines from $BranchCode with minimum age of $MinimumAgeYears years"

    Search-AD -Filter "(&(objectclass=computer)(name=*))" -SearchRoot "OU=Clients,OU=$BranchCode,DC=bethel,DC=jw,DC=org" | Foreach-Object { $_.properties.name } | Sort-Object Name | Foreach-Object {
        $ageData = Get-AgeFromSerialNumber -SerialNumber $_
        if ($ageData) {
            if ($ageData.AgeYears -ge $MinimumAgeYears) { 
                Write-Log -Message "$_ -> $($ageData.ProductionYear) $($ageData.ProductionMonthName) ($($ageData.AgeYears) years, $($ageData.AgeMonths) months)"
            }
        } else {
            Write-Log -Message "$_ -> Unable to calculate age" -Type Warning
        }
    }
} else {
    Write-Host "Please use a valid 3-letter branch code. $BranchCode is not valid." -ForegroundColor Red
}