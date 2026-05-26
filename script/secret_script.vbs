Dim fso, currentFolder, shell
Set fso = CreateObject("Scripting.FileSystemObject")

' Hitta automatiskt vilken mapp denna VBS-fil ligger i
currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)

' Starta PowerShell osynligt och be den köra sync.ps1 från samma mapp
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & currentFolder & "\script.ps1""", 0, False