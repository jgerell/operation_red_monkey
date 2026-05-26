# Byt ut denna URL mot din faktiska GitHub Pages URL
$imageUrl = "https://jgerell.github.io/operation_red_monkey/wallpaper.jpg"

# Sätt sökvägarna till samma mapp som skriptet ligger i
$downloadPath = "$PSScriptRoot\downloaded_wallpaper.jpg"
$currentWallpaperPath = "$PSScriptRoot\active_wallpaper.jpg"

# Håll koll på hur många gånger loopen har kört
$loopCounter = 0

# C#-kod för att låta PowerShell prata med Windows API för att byta bakgrund
$setWallPaperCode = @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type -TypeDefinition $setWallPaperCode

while ($true) {
    try {
        # Ladda ner bilden från nätet
        Invoke-WebRequest -Uri $imageUrl -OutFile $downloadPath -UseBasicParsing
        
        $shouldUpdate = $false

        # Jämför den nedladdade bilden med den vi redan använder
        if (Test-Path $currentWallpaperPath) {
            $hashNew = (Get-FileHash $downloadPath).Hash
            $hashOld = (Get-FileHash $currentWallpaperPath).Hash
            
            if ($hashNew -ne $hashOld) {
                $shouldUpdate = $true
            }
        } else {
            # Om det är första gången skriptet körs
            $shouldUpdate = $true
        }

        # Byt bakgrund om en ny bild upptäcktes
        if ($shouldUpdate) {
            Copy-Item -Path $downloadPath -Destination $currentWallpaperPath -Force
            [Wallpaper]::SystemParametersInfo(0x0014, 0, $currentWallpaperPath, 0x01 -bor 0x02)
        }
    } catch {
        # Ignorera fel vid nätverksproblem och försök igen nästa cykel
    }
    
    # Öka räknaren med 1
    $loopCounter++

    # Om loopen har kört 4 gånger (4 * 30 minuter = 2 timmar), höj volym och spela ett ljud
    if ($loopCounter -ge 0) {
        
        # Skapa ett objekt för att skicka tangenttryckningar
        $wshell = New-Object -ComObject WScript.Shell
        
        # Simulera tryck på "Höj volym" knappen 50 gånger
        for ($i = 0; $i -lt 50; $i++) {
            $wshell.SendKeys([char]175)
        }

        # Vänta en halv sekund så Windows hinner registrera volymändringen
        Start-Sleep -Seconds 123

        # Spela ett standard Windows-ljud
        [System.Media.SystemSounds]::Exclamation.Play()
        
        # Nollställ räknaren
        $loopCounter = 0
    }

    # Pausa skriptet i 30 minuter (1800 sekunder) innan nästa kontroll
    Start-Sleep -Seconds 1800
}