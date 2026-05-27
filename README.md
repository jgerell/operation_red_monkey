# Guide: Schemaläggaren för BakgrundsSync

Denna guide beskriver hur du ställer in Windows Schemaläggare för att köra skriptet helt dolt i bakgrunden. Systemet använder `script.vbs` som en osynlig startknapp för att dra igång huvudskriptet (`script.ps1`).

## 1. Skapa uppgiften
1. Öppna **Schemaläggaren** (Task Scheduler) i Windows.
2. Klicka på **Skapa aktivitet...** (Create Task...) i panelen längst till höger. *(Använd inte "Skapa enkel aktivitet").*

## 2. Fliken Allmänt (General)
* **Namn:** Skriv ett passande namn, till exempel `Operation Red Monkey` eller `BakgrundsSync`.
* **Alternativ:** Kryssa i rutan **Dold** (Hidden) längst ner.

## 3. Fliken Utlösare (Triggers)
Här bestämmer vi när skriptet ska starta.
1. Klicka på **Ny...** (New...).
2. I rutan "Börja åtgärden", välj **Vid inloggning** (At log on).
3. Klicka på **OK**.

## 4. Fliken Åtgärder (Actions) 
Detta är det viktigaste steget, där vi pekar på vår osynliga startknapp.
1. Klicka på **Ny...** (New...).
2. **Åtgärd:** Välj "Starta ett program" (Start a program).
3. **Program/skript:** Skriv exakt: 
   `wscript.exe`
4. **Lägg till argument (valfritt):** Skriv in hela sökvägen till din VBS-fil, innesluten i citattecken. Exempel:
   `"C:\Sökväg\Till\Din\Mapp\script.vbs"`
5. Klicka på **OK**.

## 5. Fliken Inställningar (Settings)
Eftersom skriptet är en oändlig loop som ska snurra dygnet runt, måste vi hindra Windows från att stänga av det.
1. Hitta rutan som heter **Stoppa aktiviteten om den körs längre än:** (Stop the task if it runs longer than:).
2. **Bocka ur** denna ruta helt.
3. Klicka på **OK** för att spara hela din nya aktivitet.

## 🚀 Färdigt!
Nu kommer skriptet att starta tyst i bakgrunden varje gång du loggar in på datorn. För att testa det direkt kan du högerklicka på aktiviteten i listan och välja **Kör** (Run).