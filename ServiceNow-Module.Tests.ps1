$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultsFile = "$here\ServiceNow-Module.Pester.Defaults.json"

# Load defaults from file (merging into $global:ServiceNowPesterTestDefaults
if(Test-Path $DefaultsFile){
    $defaults = if($global:ServiceNowPesterTestDefaults){$global:ServiceNowPesterTestDefaults}else{@{}};
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | %{$defaults."$($_.Name)" = $_.Value}
    
    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:ServiceNowPesterTestDefaults = $defaults
}else{
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values";
    
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory = 'Internal'
        TestUserGroup = 'e9e9a2406f4c35001855fa0dba3ee4f3'
    } | ConvertTo-Json | Set-Content $DefaultsFile
    return;
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module ServiceNow-Module -ErrorAction SilentlyContinue
Import-Module $here\ServiceNow-Module.psd1   

Describe "ServiceNow-Module" {
    
    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $defaults.ServiceNowURL -Credentials $defaults.Creds | Should be $true
    }

    It "New-ServiceNowIncident (and by extension New-ServiceNowTableEntry) works" {
        $TestTicket = New-ServiceNowIncident -ShortDescription "Testing with Pester" `
            -Description "Long description" -AssignmentGroup $defaults.TestUserGroup `
            -Category $defaults.TestCategory -SubCategory $Defaults.TestSubcategory `
            -Comment "Comment" -ConfigurationItem $defaults.TestConfigurationItem `
            -Caller $defaults.TestUser `

        $TestTicket.short_description | Should be "Testing with Pester"
    }

    It "Get-ServiceNowTable works" {
        # There should be one or more incidents returned
        (Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at').Count -gt 0  | Should Match $true
    }

    It "Get-ServiceNowIncident works" {
        # There should be one or more incidents returned
        (Get-ServiceNowIncident).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowUserGroup works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUserGroup).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowUser works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUser).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowConfigurationItem works" {
        # There should be one or more configuration items returned
        (Get-ServiceNowConfigurationItem).Count -gt 0 | Should Match $true
    }
}