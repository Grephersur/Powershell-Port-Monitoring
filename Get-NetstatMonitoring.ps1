<#
.SYNOPSIS
Monitors specific ports using the netstat command and logs the results.

.DESCRIPTION
This script runs the netstat command with the -ano options to monitor specific ports, 
and logs the results to a CSV file. It includes whitelisting and blacklisting of IP addresses.

.PARAMETER Ports
An array of integers specifying the ports to monitor.

.PARAMETER Interval
The number of seconds to wait between each monitoring period.

.PARAMETER Whitelist
An array of strings specifying IP addresses to whitelist.

.PARAMETER Blacklist
An array of strings specifying IP addresses to blacklist.

.NOTES
Author: Christopher Daniele, Information Security Analyst II, Arrowhead Credit Union
Reviewed by AI software for errors and best practices.
License: MIT

Change Log:
    Version 1.0 - Initial version
    Version 1.1 - Added progress bar, countdown timer, and updated comments

Disclaimer:
    This script is provided "as is" without warranty of any kind. Use at your own risk. 
    Neither the author nor the reviewers are responsible for any damage or loss caused 
    by this script.

# To run this script, you may need to change your PowerShell execution policy.
# Here's how you can do that:

# 1. Open a PowerShell session with Administrator privileges.
# 2. Check your current execution policy by running: Get-ExecutionPolicy
# 3. If it's set to Restricted, you might want to change it to RemoteSigned: Set-ExecutionPolicy RemoteSigned
# 4. Confirm the change by running: Get-ExecutionPolicy

# Please be aware that changing the execution policy can expose your system to risk.
# Only run scripts from sources that you trust.


.EXAMPLE
.\Get-NetstatMonitoring.ps1 -Ports (8300..8600) -Interval 10
#>

# Parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,65535)]
    [int[]]$Ports = 8300..8600,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1,3600)]
    [int]$Interval = 10,

    [Parameter(Mandatory=$false)]
    [ValidateScript({$_ -as [ipaddress]})]
    [string[]]$Whitelist = @("10.0.0.1","10.0.0.100"),

    [Parameter(Mandatory=$false)]
    [ValidateScript({$_ -as [ipaddress]})]
    [string[]]$Blacklist = @("192.168.5.10")
)

# Log file path
$LogPath = "C:\Temp\netstat_log_"+(Get-Date -Format "yyyy-MM-dd_HHmmss").ToString()+".csv"

function Get-NetstatResults {
    netstat -ano | Where-Object {$_ -match "($($Ports -join "|"))"}
}

function Start-Monitoring {
    while ($true) {
        try {
            Write-Output "Looking for connections on ports...8300..8600. Please wait. "

            $Results = Get-NetstatResults
    
            if ($Results) {
                Write-Output "`nConnected IP addresses detected!"

                $data = foreach ($result in $Results) {
                    $fields = $result.trim() -split "\s+"
                    $ip = $fields[2]
                    $port = $fields[-1]
                    $procPid = $fields[-2]

                    # Create a custom object for CSV export
                    New-Object PSObject -Property @{
                        IP = $ip
                        Port = $port
                        ProcessID = $procPid
                        Timestamp = Get-Date
                    }

                    if ($Whitelist -contains $ip) {
                        Write-Output "$ip : $port" -ForegroundColor Green
                    } elseif ($Blacklist -contains $ip) {
                        Write-Output "$ip : $port" -ForegroundColor Red 
                    } else {
                        Write-Output "$ip : $port"  
                    }
                }

                # Export to CSV
                $data | Export-Csv -Path $LogPath -NoTypeInformation -Append
            } else {
                Write-Output "`nNo connections detected on monitored ports" -ForegroundColor Yellow
            }

            Write-Output "`nWriting results to log file $LogPath"

            $progress = @{
                Activity = "Waiting for next monitoring period"
                Status = "$Interval seconds remaining"
                PercentComplete = 0
            }

            for ($i = 0; $i -lt $Interval; $i++) {
                Write-Progress @progress
                Start-Sleep -Seconds 1
                $progress.Status = "$($Interval - $i) seconds remaining"
                $progress.PercentComplete = ($i / $Interval) * 100
            }

            Write-Progress @progress -Completed
            Write-Output "Starting next monitoring period in $Interval seconds..."
        } catch {
            Write-Output "An error occurred: $_. Script will resume in $Interval seconds." -ForegroundColor Red
            "An error occurred: $_" | Out-File -Append -FilePath $LogPath
            Start-Sleep -Seconds $Interval
        }
    }
}

# Main
Start-Monitoring
