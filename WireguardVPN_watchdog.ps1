#This scirps is desingd to keed Wireguard VPN tunnel up and running on my windows computers!

$mypath = $MyInvocation.MyCommand.Path
$mypath = Split-Path $mypath -Parent
$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name
$serviceName = "wireguardtunnel`$$hostname`_Wireguard"
$logfile = "c:\wireguard_watchdog.log"
$wireguardexe = 'C:\Program Files\WireGuard\wireguard.exe'
$wireguardconf = "$mypath\tunnels\$hostname`_Wireguard.conf"

#check if logfile exists
if (!(Test-Path $logfile)) {
    New-Item $logfile > $null
    Write-Output "$(get-date) logfile created" | Out-File $logfile -Append
}

# Check if Wireguard.exe is running (Only if you want to have GUI on).
$process = Get-Process -Name "wireguard" -ErrorAction SilentlyContinue
if ($process) {
    Write-Output "$(get-date) Wireguard.exe is running. Alles OK." | Out-File $logfile -append
} else {
    Write-Output "$(get-date) Wireguard.exe is not running. Starting" | Out-File $logfile -append
    
    #Start a job that starts wireguard.exe
    $job = Start-Job -ScriptBlock {Start-process -FilePath $input} -InputObject $wireguardexe
    
    #Waiting to start wireguard for 30 seconds else timeout and kill the job
    if (wait-job $job -Timeout 30) {
        receive-job $job
        Write-Output "$(Get-Date) $job started. Alles OK." | Out-File $logfile -append}
    else {
        Write-Output "$(Get-Date) $job failed to start after 30 seconds." | Out-File $logfile -append
    }
    
    #Kill the job if it does not start in 30 seconds, else nothing to cleanup
    remove-job $job
}

#Check if service wireguard tunnel service exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Output "$(get-date) Service $servicename exists. Alles OK." | Out-File $logfile -append
} else {
    Write-Output "$(get-date) Service $servicename does not exist. Starting" | Out-File $logfile -append
    Start-process -FilePath $wireguardexe -ArgumentList '/installtunnelservice', $wireguardconf -NoNewWindow -passThru -Wait | Out-Null
    Write-Output "$(get-date) Service $servicename started. Alles OK." | Out-File $logfile -append #assume that it works with no error for now
}

function startservice {

    param (
    $servicename
    )
    $serviceStatus = (Get-Service -Name $serviceName).Status
    
    switch ($serviceStatus) {
        {$_ -eq "Running"} { Write-Output "$(get-date) $servicename service is running. Alles OK." | Out-File $logfile -append}

        {$_ -eq "Stopped"} {
            Write-Output "$(Get-Date) $servicename service is stopped. Starting serviece." | Out-File $logfile -append
            
            $job = start-job -ScriptBlock { param($servicename) Start-service $servicename } -ArgumentList $servicename
            
            if (wait-job $job -Timeout 30) {
                receive-job $job
                Write-Output "$(Get-Date) $servicename service started." | Out-File $logfile -append}
            else {
                Write-Output "$(Get-Date) $servicename service failed to start after 30 seconds." | Out-File $logfile -append
            }
            remove-job $job
        }
                    
        default { Write-Output "Did nothing" }
    }
}

startservice("wireguardtunnel`$$hostname`_Wireguard")