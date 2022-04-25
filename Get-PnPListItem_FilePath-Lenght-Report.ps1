# https://github.com/PavolVonSekule/powershell/edit/main/Get-PnPListItem_FilePath-Lenght-Report.ps1
# A script to create a report on file path length in particular document library above $limit

#Set Variables
$SiteURL= "https://YOURtenant.sharepoint.com/sites/site1"
$ListName="Documents"
$limit = 200 #characters

$tPath = "https://" + ($SiteURL).split("/")[2]
$tPathL = $tpath.Length
$l = [int]$limit - [int]$tpath.Length

$logPath = "C:\Temp\Reports\FilePath-Lenght-Report_$($ListName)_$(Get-Date -f yyyy-MM-dd).csv"
$header = "Library" + ";"  +  "FileName" + ";"  +  "PathLenght"  + ";"  +  "FilePath"
$arrReport=@()


#Connect to PnP Online
$cred = Get-Credential
Connect-PnPOnline -Url $SiteURL -Credentials $cred
 
#Get All Files from the document library
$ListItems1 = Get-PnPListItem -List $ListName -PageSize 500 | Where {$_.FileSystemObjectType -like "File" -AND ($_.FieldValues['FileRef']).Length -gt [int]$l} | Select FieldValues
$ListItemsTotal = $ListItems1.count

#Loop through All Files
ForEach($Item in $ListItems1)
{
    $length = [int]($Item.FieldValues['FileRef']).Length + [int]$tPathL + 1
    $fPath = $tPath + $Item.FieldValues['FileRef']
    $reportLine = $ListName + ";" + $Item.FieldValues['FileLeafRef'] + ";" + $length + ";" + $fPath
    $arrReport+=$reportLine

    $length = ""
    $fPath = ""
    Write-Progress -activity "Processing $($ListItemsTotal)" -status $arrReport.Count
}

#Write the report
Add-Content -Path $logPath -Value $header
Add-Content -Path $logPath -Value $arrReport
