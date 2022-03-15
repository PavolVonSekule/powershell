
#used storage - total
$gsq = Get-SPOGeoStorageQuota -AllLocations | select @{N="GeoUsedStorage";E={[math]::round($_.GeoUsedStorageMB/1048576,2)}}
$us=0
Foreach ($geo in $gsq){
$c=($geo.GeoUsedStorage).ToString()
$us+=$c}

#tenant storage - 2 decimal places
$ts=((Get-SPOGeoStorageQuota).TenantStorageMB)/1048576
$ts_2d = [math]::Round($ts,2)

#used storage % - 2 decimal places
$per = ($us/$ts)*100
$per_2d= "$([math]::round($per,2))"

#definition of function
Function perc {Write-Host "storage used ∑" $us "TB`n             %" $per_2d}

#report
Write-Host "`n     Storage report`n=========================`n$dateUT";
Get-SPOGeoStorageQuota -AllLocations | select GeoLocation,GeoUsedStorageMB,GeoAvailableStorageMB,TenantStorageMB |Format-Table @{N="Geo";E= {$_.GeoLocation}}, `
@{N="GeoUsedStorage";E={"$([math]::round($_.GeoUsedStorageMB/1048576,2)) TB"};a='right'}, `
@{N="GeoAvailableStorage";E={"$([math]::round($_.GeoAvailableStorageMB/1048576,2)) TB"};a='right'}, `
@{N="TenantStorage";E={"$([math]::round($_.TenantStorageMB/1048576,2)) TB"};a='right'};`
perc

