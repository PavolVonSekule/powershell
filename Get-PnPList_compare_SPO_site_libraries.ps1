$adminUPN = "ADMIN@YOURtenant.com"
$userCredential = Get-Credential -UserName $adminUPN -Message "Type the password."

#Sites to compare
$SourceSiteURL = "https://YOURtenant.sharepoint.com/sites/site1"
$TargetSiteURL = "https://YOURtenant.sharepoint.com/sites/site1_clone"

#Source Library
Connect-PnPOnline -Url $SourceSiteURL -Credentials $userCredential
$LibraryA = Get-PnPList | select Title,Itemcount
Disconnect-PnPOnline

#Destination Library (to compare)
Connect-PnPOnline -Url $TargetSiteURL -Credentials $userCredential
$LibraryB = Get-PnPList | select Title,Itemcount
Disconnect-PnPOnline

#Variables
$AllLibraries = @()


ForEach($PartLibraryA in $LibraryA)
{

    $varA = $PartLibraryA.Title

                ForEach($PartLibraryB in $LibraryB) {
    
                $varB = $PartLibraryB.Title

                    If($varA -eq $varB){
                    $comp = Compare-Object -ReferenceObject $PartLibraryA -DifferenceObject $PartLibraryB -Property ItemCount -IncludeEqual

                    $SiteIndicator = $comp.SideIndicator
                    if ($comp.SideIndicator -eq "==") {$SiteIndicator = "OK"}
                    else {$SiteIndicator = "---mismatch"}
                    
                    $AllLibraries += [PSCustomObject] @{
                                    Library      = $PartLibraryA.Title
                                    SourceItems  = $PartLibraryA.ItemCount
                                    TargetItems  = $PartLibraryB.ItemCount
                                    Status       = $SiteIndicator
                               }
                    }
                }

}

$AllLibraries | ft -AutoSize