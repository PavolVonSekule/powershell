#Connect to the site
Connect-PnPOnline -Url https://YOURtenant.sharepoint.com/sites/site1

#Set Variables
$LibName = "Documents"

$i=0
$p=0

#Get all list items in batches
$ListItems = Get-PnPListItem -List $LibName -PageSize 500


#Iterate through each list item
ForEach($ListItem in $ListItems)
{
    #Check if the Item has unique permissions
    $HasUniquePermissions = Get-PnPProperty -ClientObject $ListItem -Property "HasUniqueRoleAssignments"
    $p++

    If($HasUniquePermissions)
    {       
      $i++
      Set-PnPListItemPermission -List $LibName -Identity $ListItem.ID -InheritPermissions
      
    }
          #Write progress
          $complete = [math]::Round(($p/$ListItems.count*100),3)
          Write-Progress -Activity "Processing items" -Status "$i fixed and $complete% processed" -PercentComplete $complete
}

Write-Host "completed with $i items fixed"

Disconnect-PnPOnline