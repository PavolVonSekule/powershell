    <#
        .SYNOPSIS
        Function to report on SPO subfolder structure from given URL.

        .DESCRIPTION
        Function will report on SharePoint Online document library folder/subfolder structure from any URL proivided.

        .INPUTS
        You need to modify all input variables:
        $adminUPN
        $clientid
        $siteUrl

        .EXAMPLE
        PS> Get-SPOSubfolders -folderURL "https://yourDev.sharepoint.com/sites/your_site/Shared%20Documents/Forms/AllItems.aspx"
        
        .EXAMPLE
        PS> Get-SPOSubfolders -folderURL "https://yourDev.sharepoint.com/sites/your_site/Shared%20Documents/Forms/AllItems.aspx?newTargetListUrl=%2Fsites%2Ftest%5Fyour%5Fteam%2FShared%20Documents&viewpath=%2Fsites%2Ftest%5Fyour%5Fteam%2FShared%20Documents%2FForms%2FAllItems%2Easpx&viewid=e8cdc55d-9dfd-43f6-835d-a496cc056539"


        .LINK
        URL: https://github.com/PavolVonSekule/powershell/blob/main/PnP_SPO_Get-Subfolders.ps1

    #>

$adminUPN = ""
$clientid = ""
$credentials = Get-Credential -UserName $adminUPN -Message "Type the password."

$siteUrl = "https://myDev.sharepoint.com/sites/test_site"

# Connect to the SharePoint Online site
$con1 = Connect-PnPOnline -Url $siteUrl -Credentials $credentials -ClientId $clientid -ReturnConnection


Function Get-SPOSubfolders {
    [CmdletBinding()]
        param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$folderURL
    )

    process {

            If($folderURL -like "*.sharepoint.com*"){

                $unescapedString = [System.Uri]::UnescapeDataString($folderURL)
                $remove = "/Forms/AllItems.aspx"

                If($folderURL -like "*aspx&id*" -or $folderURL -like "*aspx?id*"){

                    # Use regex to trim path before "id=" and after "&viewid="
                    $regexPattern = ".*id=(.*)&viewid=.*"
                    $folderPathR = [regex]::Replace($unescapedString, $regexPattern, '$1')
                    $segments = $folderPathR -split "/"
                    $folderPath = ($segments[3..($segments.Length - 1)] -join "/")
                }
                ElseIf($folderURL -like "*aspx&viewid*"){

                    # Use regex to trim path before &viewpath= and after &viewid=
                    $regexPattern = ".*&viewpath=([^&]+)&viewid=.*"
                    $folderPathR = [regex]::Replace($unescapedString, $regexPattern, '$1')
                    $segments = $folderPathR -split "/"
                    $folderPath = ($segments[3..($segments.Length - 1)] -join "/").Replace($remove, "")
                }
                ElseIf($folderURL -like "*/Forms*" -and $folderURL -notlike "*viewid*"){

                    $segments = $unescapedString -split "/"
                    $folderPath = ($segments[5..($segments.Length - 1)] -join "/").Replace($remove, "")
                }
                ElseIf($folderURL -like "*/Forms*" -and $folderURL -like "*viewid*" -and $folderURL -notlike "*newTargetList*"){

                    # Use regex to remove everything after and including ?viewid
                    $regexPattern = "^(.*?)\?viewid.*"
                    $folderPathR = [regex]::Replace($unescapedString, $regexPattern, '$1')
                    $segments = $folderPathR -split "/"
                    $folderPath = ($segments[5..($segments.Length - 1)] -join "/").Replace($remove, "")
                    }

                    $siteUrl = (($unescapedString -split "/")[0..4] -join "/")
                    Write-Host "Folder extracted from URL: " -ForegroundColor Yellow
                    Write-Host $folderPath -ForegroundColor Green
         }
                Else{
                    Write-Host "folderURL not in correct format" -ForegroundColor Red
                }

        # Initialize hashtable to store folder paths and their levels
        $folderQueue = @([PSCustomObject]@{Path = $folderPath; Level = 1})
        $ReportFolders = @()

        # Loop through folders recursively
        while ($folderQueue.Count -gt 0) {
            $currentFolder = $folderQueue[0]
            $folderQueue = $folderQueue[1..$folderQueue.Count]

            Try{
                $subFolders = Get-PnPFolderItem -FolderSiteRelativeUrl $currentFolder.Path -ItemType Folder -Connection $con1
            }
            Catch{
                Write-Host "An issue happened when trying to fetch the folder with exception" $_.exception
            }

            foreach ($subFolder in $subFolders) {

                $subFolderPath = "$($currentFolder.Path)/$($subFolder.Name)"

                If (-not ($subFolder.ListItemAllFields.FieldValues["IsHidden"])) {
                    If ($subFolderPath -notlike "*/Forms*"){ #excludes the hidden Forms folder
                
                        $shortenBy = ($subFolder.Name).Length + 1
                        $ParentFolderSiteRelativeURL = $subFolderPath.Substring(0, $subFolderPath.Length - $shortenBy)
                        
                        $ReportFoldersObject = [PSCustomObject]@{  
                        Level = [int]$currentFolder.Level
                        FolderName = $subFolder.Name
                        Path = $subFolderPath
                        ParentFolder = $ParentFolderSiteRelativeURL
                        }
                       $shortenBy = ""
                       $ReportFolders += $ReportFoldersObject
                    }
                }
                # Add subfolder to the queue
                $folderQueue += [PSCustomObject]@{Path = $subFolderPath; Level = ($currentFolder.Level + 1)}

            }
        }
    
    $ReportFoldersSorted = $ReportFolders | Sort-Object Level -Descending
    $ReportFoldersSorted | Select Level,FolderName,Path

    }
}


# Disconnect from the SharePoint Online site
Disconnect-PnPOnline


