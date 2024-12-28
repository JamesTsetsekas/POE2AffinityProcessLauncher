# USE 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass' & '.\POE2AffinityProcessLauncher.ps1' to run this script
# ABOUT ------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# AUTHOR: Frosthaven
# DISCORD: frosthaven
# DESCRIPTION: This is a powershell script that launches a configured process
# and then sets the affinity for a matching process to utilize whichever cores
# you see fit. Use this and modify it as you please. Run by right clicking and
# choosing "Run with Powershell".
#
# You can also create a shortcut to run this by right clicking the desktop:
# 1. Choose New > Shortcut
# 2. Type in the target box (and change the path to your .ps1 file):
#    powershell.exe -command "& 'C:\A path with spaces\MyScript.ps1'"

# CONFIG -----------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Change these values to match the process you want to launch. The $sleepTime
# value is used to wait for the process to kick start the actual program. Useful
# when the exe you need to launch is not exactly the same as the task that shows
# up in task manager.

# General Config
$exePath = "C:\Program Files (x86)\Steam\steamapps\common\Path of Exile 2\PathOfExileSteam.exe"
$processNameInTaskManager = "PathOfExileSteam"
$sleepTime = 4

# Core Affinity
# I'm including two ways to do this below. The first way will include all
# available cores except the first two by starting the array after core 0 and 1.
# The second way will give more explicit control over EXACTLY which cores you
# want to have active. You can change which you want to enable/disable by
# changing which $enabledCores is commented out with a "#" character.

$coreCount = [Environment]::ProcessorCount
$enabledCores = 2..($coreCount - 1)

# $enabledCores = @(2, 3, 4)

# RUN --------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# This is the main body of the script that uses the above configuration to
# launch the process and attach a new affinity.

# Start --------------------------------
Write-Host "Launching process..."
$process = Start-Process $exePath -PassThru
Start-Sleep -Seconds $sleepTime

# Wait for task ------------------------
$timeout = 10
$elapsedTime = 0
$ActivePID = $null
while ($ActivePID -eq $null -and $elapsedTime -lt $timeout) {
    $processList = Get-Process -Name $processNameInTaskManager -ErrorAction SilentlyContinue
    if ($processList) {
        $ActivePID = $processList.Id
    } else {
        Start-Sleep -Seconds 1
        $elapsedTime++
    }
}

# Set affinity -------------------------
if ($ActivePID -ne $null) {
    Write-Host "Process launched. ActivePID: $ActivePID"
    Write-Host "Configuring affinity bitmask..."

    # Calculate the bitmask based on enabled cores
    $bitmask = 0
    foreach ($core in $enabledCores) {
        $bitmask = $bitmask -bor (1 -shl $core)
    }
    $processHandle = [System.Diagnostics.Process]::GetProcessById($ActivePID)
    $processHandle.ProcessorAffinity = $bitmask

    Write-Host "Processor affinity set:"
    Write-Host " - Enabled cores: $enabledCores"
    Write-Host " - Disabled cores: 0, 1"
}