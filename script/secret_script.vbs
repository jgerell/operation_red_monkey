Dim fso, currentFolder, shell
Set fso = CreateObject("Scripting.FileSystemObject")

currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)

Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & currentFolder & "\wrapper.ps1""", 0, False