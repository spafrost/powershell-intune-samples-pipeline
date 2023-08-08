<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

# Get parameters for authentication from pipeline passed parameters
param(
    [Parameter(Mandatory=$True)]
    [string]$ApplicationID,
    [Parameter(Mandatory=$True)]
    [string]$ApplicationSecret,
    [Parameter(Mandatory=$True)]
    [string]$TenantID,
    [Parameter(Mandatory=$True)]
    [string]$ExportPath
)

# Add environment variables to be used by Connect-MgGraph.
$Env:AZURE_CLIENT_ID = $ApplicationID #application id of the client app
$Env:AZURE_TENANT_ID = $TenantID #Id of your tenant
$Env:AZURE_CLIENT_SECRET = $ApplicationSecret #secret of the client app

# Tell Connect-MgGraph to use your environment variables.
Connect-MgGraph -EnvironmentVariable​

####################################################

Function Get-ManagedAppAppConfigPolicy(){

<#
.SYNOPSIS
This function is used to get app configuration policies for managed apps from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any app configuration policy for managed apps
.EXAMPLE
Get-ManagedAppAppConfigPolicy
Returns any app configuration policy for managed apps configured in Intune
.NOTES
NAME: Get-ManagedAppAppConfigPolicy
#>

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/targetedManagedAppConfigurations?`$expand=apps"
    
   try{
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-MgGraphRequest -Uri $uri -Method Get).Value 
        
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-ManagedDeviceAppConfigPolicy(){

<#
.SYNOPSIS
This function is used to get app configuration policies for managed devices from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any app configuration policy for managed devices
.EXAMPLE
Get-ManagedDeviceAppConfigPolicy
Returns any app configuration policy for managed devices configured in Intune
.NOTES
NAME: Get-ManagedDeviceAppConfigPolicy
#>

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileAppConfigurations"

   try{
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value 
        
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-AppBundleID(){

<#
.SYNOPSIS
This function is used to get an app bundle ID from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets the app bundle ID for the specified app GUID
.EXAMPLE
Get-AppBundleID -guid 
Returns the bundle ID for the specified app GUID in Intune
.NOTES
NAME: Get-AppBundleID
#>

param (

$GUID

)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps?`$filter=id eq '$GUID'"

   try{
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
        
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Export-JSONData(){

<#
.SYNOPSIS
This function is used to export JSON data returned from Graph
.DESCRIPTION
This function is used to export JSON data returned from Graph
.EXAMPLE
Export-JSONData -JSON $JSON
Export the JSON inputted on the function
.NOTES
NAME: Export-JSONData
#>

param (

$JSON,
$ExportPath,
$bundleID

)


    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON..." -f Red

        }

        elseif(!$ExportPath){

        write-host "No export path parameter set, please provide a path to export the file" -f Red

        }

        elseif(!(Test-Path $ExportPath)){

        write-host "$ExportPath doesn't exist, can't export JSON Data" -f Red

        }

        else {

        $JSON1 = ConvertTo-Json $JSON -Depth 5

        $JSON_Convert = $JSON1 | ConvertFrom-Json

        $displayName = $JSON_Convert.displayName

        # Updating display name to follow file naming conventions - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
        $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"

        $Properties = ($JSON_Convert | Get-Member | ? { $_.MemberType -eq "NoteProperty" }).Name

            
            $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + "1.json"

            $Object = New-Object System.Object

                foreach($Property in $Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property

                }

                If($bundleID)
                {

                    $Object | Add-Member -MemberType NoteProperty -name "bundleID" -Value $bundleID

                }

            write-host "Export Path:" "$ExportPath"
        
            $object | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
            write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan
            
        }

    }

    catch {

    $_.Exception

    }

}

####################################################

   
####################################################


    # If the directory path doesn't exist prompt user to create the directory
    $ExportPath = $ExportPath.replace('"','')

    if(!(Test-Path "$ExportPath")){

    Write-Host
    Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow

    $Confirm = read-host

        if($Confirm -eq "y" -or $Confirm -eq "Y"){

        new-item -ItemType Directory -Path "$ExportPath" | Out-Null
        Write-Host

        }

        else {

        Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
        Write-Host
        break

        }

    }

Write-Host

####################################################


Write-Host "----------------------------------------------------"
Write-Host

 $managedAppAppConfigPolicies = Get-ManagedAppAppConfigPolicy

    foreach($policy in $managedAppAppConfigPolicies){

    write-host "(Managed App) App Configuration Policy:"$policy.displayName -f Yellow
    Export-JSONData -JSON $policy -ExportPath "$ExportPath"
    Write-Host

    }

$managedDeviceAppConfigPolicies = Get-ManagedDeviceAppConfigPolicy

    foreach($policy in $managedDeviceAppConfigPolicies){

    write-host "(Managed Device) App Configuration  Policy:"$policy.displayName -f Yellow
    
        #If this is an Managed Device App Config for iOS, lookup the bundleID to support importing to a different tenant
        If($policy.'@odata.type' -eq "#microsoft.graph.iosMobileAppConfiguration"){

            $bundleID = Get-AppBundleID -GUID $policy.targetedMobileApps
            Export-JSONData -JSON $policy -ExportPath "$ExportPath" -bundleID $bundleID.bundleID
            Write-Host

        }
    

        Else{

            Export-JSONData -JSON $policy -ExportPath "$ExportPath"
            Write-Host

        }

    }

