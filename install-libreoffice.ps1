# install-libreoffice.ps1
$logFile = "instalacja-office-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Zmienna z linkiem do instalatora ZWCAD (Wklej tutaj link bezpośredni z SharePointa)
# Uwaga: Linki SharePoint często wymagają dodania "?download=1" na końcu, aby pobieranie ruszyło automatycznie.
$zwcadInstallerUrl = "https://pbgranitspzoo.sharepoint.com/:u:/s/ExternPublic/IQBpZY3soFxSQ60YhTWirqQdAVDwbGhE4XKruybmuC4NuEg?download=1"

$sukces = 0
$bledy = 0

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
}

# 1. Sprawdź uprawnienia administratora
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "BLAD: Uruchom skrypt jako Administrator!"
    exit 1
}

Write-Log "Rozpoczynam instalacje oprogramowania Granit (Wersja z LibreOffice)..."

# 2. Usuwanie niechcianych programów (np. McAfee)
$niechcianeProgramy = @("*McAfee*") # Dodaj tutaj inne wzorce nazw
foreach ($wzorzec in $niechcianeProgramy) {
    Write-Log "Szukam programow pasujacych do wzorca: $wzorzec"
    Get-Package -ErrorAction SilentlyContinue | Where-Object {$_.Name -like $wzorzec} | ForEach-Object {
        $nazwa = $_.Name
        Write-Log "Usuwam: $nazwa"
        try {
            Uninstall-Package -Name $nazwa -Force -ErrorAction Stop
            Write-Log "USUNIETO: $nazwa"
        } catch {
            Write-Log "BLAD USWANIA: $nazwa - $_"
        }
    }
}

# 3. Instalacja Chocolatey jeśli nie ma
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Instaluje Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $chocoInstallScript = "$env:TEMP\install_choco.ps1"
    (New-Object System.Net.WebClient).DownloadFile('https://community.chocolatey.org/install.ps1', $chocoInstallScript)
    & $chocoInstallScript
    Remove-Item $chocoInstallScript -Force -ErrorAction SilentlyContinue
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}

# 4. Instalacja standardowych programów przez Chocolatey
$programy = @(
    "googlechrome",
    "firefox",
    "brave",
    "7zip",
    "adobereader",
    "anydesk",
    "libreoffice-still"
)

foreach ($program in $programy) {
    Write-Log "Instaluje: $program"
    $cmdOutput = choco install $program -y 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $program"
        $sukces++
    } else {
        Write-Log "BLAD: $program - $cmdOutput"
        $bledy++
    }
}

# 5. Instalacja ZWCAD (jeśli podano link)
if (-not [string]::IsNullOrWhiteSpace($zwcadInstallerUrl)) {
    Write-Log "Pobieram instalator ZWCAD..."
    $installerPath = "$env:TEMP\zwcad_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $zwcadInstallerUrl -OutFile $installerPath -ErrorAction Stop
        Write-Log "Pobrano instalator. Rozpoczynam instalację..."
        
        # Typowe dla InstallShield: /S /v"/qn"
        $installArgs = "/S" 
        
        Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -NoNewWindow
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "OK: ZWCAD"
            $sukces++
        } else {
            Write-Log "BLAD: ZWCAD (kod wyjscia: $LASTEXITCODE)"
            $bledy++
        }
    } catch {
        Write-Log "BLAD: Nie udalo sie pobrac lub zainstalowac ZWCAD. Szczegoly: $_"
        $bledy++
    } finally {
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

# 6. Instalacja ESET NOD32 Antivirus (Live Installer)
Write-Log "Pobieram: ESET NOD32 Antivirus"
$esetUrl = "https://download.eset.com/com/eset/apps/home/eav/windows/latest/eset_nod32_antivirus_live_installer.exe"
$esetInstaller = "$env:TEMP\eset_nod32_live_installer.exe"

try {
    Invoke-WebRequest -Uri $esetUrl -OutFile $esetInstaller -ErrorAction Stop
    Write-Log "Pobrano instalator ESET. Rozpoczynam cicha instalacje..."
    
    $esetArgs = "--silent --accepteula"
    
    Start-Process -FilePath $esetInstaller -ArgumentList $esetArgs -Wait -NoNewWindow
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: ESET NOD32 Antivirus"
        $sukces++
    } else {
        Write-Log "BLAD: ESET NOD32 Antivirus (kod wyjscia: $LASTEXITCODE)"
        $bledy++
    }
} catch {
    Write-Log "BLAD: Nie udalo sie pobrac lub zainstalowac ESET. Szczegoly: $_"
    $bledy++
} finally {
    if (Test-Path $esetInstaller) {
        Remove-Item $esetInstaller -Force
    }
}

# 7. Instalacja OpenVPN przez Chocolatey
Write-Log "Instaluje: OpenVPN (Chocolatey)"
$openVpnArgs = "ADDLOCAL=OpenVPN.Service,Drivers,Drivers.Wintun,Drivers.TAPWindows6"
$cmdOutput = choco install openvpn --version 2.5.6 -y --install-arguments "'$openVpnArgs'" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Log "OK: OpenVPN"
    $sukces++
} else {
    Write-Log "BLAD: OpenVPN - $cmdOutput"
    $bledy++
}

# 8. Konfiguracja Windows Update w rejestrze
Write-Log "Konfiguruje ustawienia Windows Update w rejestrze..."
$registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

try {
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $registryPath -Name "AllowMUUpdateService" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $registryPath -Name "IsExpedited" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $registryPath -Name "RestartNotificationsAllowed2" -Value 1 -Type DWord -Force
    
    Write-Log "OK: Konfiguracja Windows Update zakonczona pomyslnie."
} catch {
    Write-Log "BLAD: Nie udalo sie skonfigurowac rejestru dla Windows Update. Szczegoly: $_"
}

Write-Log "===================="
Write-Log "Zainstalowano: $sukces"
Write-Log "Bledy: $bledy"
Write-Log "Log zapisany: $logFile"
