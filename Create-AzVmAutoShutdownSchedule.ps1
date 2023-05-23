Import-module Az.Resources
Import-module Az.Compute

$path = "./subscriptions.csv" 

$csv = Import-Csv -path $path

# To find your timezone: Get-TimeZone -ListAvailable | findstr -i "Delhi" or  Get-TimeZone -Name "*Ind*"
#$shutdown_timezone = "W. Europe Standard Time"
$shutdown_timezone = "Romance Standard Time"
$shutdown_time = "2000"

# Iterate through each subscription: 
foreach ($line in $csv) { 
    $properties = $line | Get-Member -MemberType Properties

    $rg_name = $line | Select -ExpandProperty $properties[0].Name
    $subscription_id = $line | Select -ExpandProperty $properties[1].Name
    $subscription_name = $line | Select -ExpandProperty $properties[2].Name
 
    # Write-Host "Setting Context for Subscription : $($subscription_id)"

    Set-AzContext -SubscriptionId $subscription_id

    $vms = Get-AzVM -ResourceGroupName $rg_name
    
    # Iterate through each VM in the AVD RG: 
    foreach ($vm in $vms) {
        # Write-Host $vm.name
        # Write-Host $vm.id 
        $vm = $vm.name
        
        $properties = @{ 
            "status"               = "Enabled";
            "taskType"             = "ComputeVmShutdownTask";
            "dailyRecurrence"      = @{"time" = $shutdown_time };
            "timeZoneId"           = $shutdown_timezone;
            "notificationSettings" = @{
                "status"        = "Disabled";
                "timeInMinutes" = 30
            }
            "targetResourceId"     = (Get-AzVM -ResourceGroupName $rg_name -Name $vm).Id
        }
        $result = New-AzResource -ResourceId ("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzContext).Subscription.Id, $rg_name, $vm) -Location (Get-AzVM -ResourceGroupName $rg_name -Name $vm).Location -Properties $properties -Force

        Write-Host "Applied AutoShutdown on VM: $($vm)"

    }
} 
 