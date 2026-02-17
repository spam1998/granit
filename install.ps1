# install-advanced.ps1
$logFile = "instalacja-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
# Zmienna z linkiem do instalatora ZWCAD (Wklej tutaj link bezpośredni z SharePointa)
# Uwaga: Linki SharePoint często wymagają dodania "?download=1" na końcu, aby pobieranie ruszyło automatycznie.
$zwcadInstallerUrl = "https://pbgranitspzoo.sharepoint.com/:u:/s/ExternPublic/IQBpZY3soFxSQ60YhTWirqQdAVDwbGhE4XKruybmuC4NuEg?e=BJE2JB" 

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
}

# ... (rest of the file remains similar until the end) ...

# Instalacja OpenVPN przez winget (jak zazadano)
Write-Log "Instaluje: OpenVPN (winget)"
$wingetArgs = "install -e --custom ADDLOCAL=OpenVPN.Service,Drivers,Drivers.Wintun,Drivers.TAPWindows6 --id OpenVPNTechnologies.OpenVPN -v 2.5.040"
Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -NoNewWindow
if ($LASTEXITCODE -eq 0) {
    Write-Log "OK: OpenVPN"
    $sukces++
} else {
    Write-Log "BLAD: OpenVPN (kod wyjscia: $LASTEXITCODE)"
    $bledy++
}

# Instalacja ZWCAD (jeśli podano link)
if (-not [string]::IsNullOrWhiteSpace($zwcadInstallerUrl)) {
    Write-Log "Pobieram instalator ZWCAD z podanego linku..."
    $installerPath = "$env:TEMP\zwcad_installer.exe"
    
    try {
        Invoke-WebRequest -Uri $zwcadInstallerUrl -OutFile $installerPath -ErrorAction Stop
        Write-Log "Pobrano instalator. Rozpoczynam instalację..."
        
        # Argumenty cichej instalacji mogą się różnić w zależności od wersji ZWCAD.
        # Typowe dla InstallShield: /S /v"/qn"
        # Typowe dla Inno Setup: /VERYSILENT /SUPPRESSMSGBOXES
        # Tutaj zakładamy standardowy tryb cichy, ale może wymagać dostosowania.
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
} else {
    Write-Log "ZWCAD pominiety (brak linku w zmiennej `$zwcadInstallerUrl`)"
}

# Sprawdź uprawnienia administratora
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "BLAD: Uruchom skrypt jako Administrator!"
    exit 1
}

# Usuwanie niechcianych programów (np. McAfee)
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


# Zainstaluj Chocolatey jeśli nie ma
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Instaluje Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path += ";C:\ProgramData\chocolatey\bin"
}

$programy = @(
    "googlechrome",
    "firefox",
    "brave",
    "7zip",
    "adobereader",
    "anydesk",
    "eset.nod32antivirus"
)

$sukces = 0
$bledy = 0

foreach ($program in $programy) {
    Write-Log "Instaluje: $program"
    $result = choco install $program -y 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $program"
        $sukces++
    } else {
        Write-Log "BLAD: $program - $result"
        $bledy++
    }
}

# Instalacja OpenVPN przez Chocolatey z parametrami (zastepuje winget)
Write-Log "Instaluje: OpenVPN (Chocolatey)"
# Parametry instalatora (MSI) przekazane do Chocolatey
$openVpnArgs = "ADDLOCAL=OpenVPN.Service,Drivers,Drivers.Wintun,Drivers.TAPWindows6"
$result = choco install openvpn --version 2.5.0 -y --install-arguments "'$openVpnArgs'" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Log "OK: OpenVPN"
    $sukces++
} else {
    Write-Log "BLAD: OpenVPN - $result"
    $bledy++
}
Write-Log "===================="
Write-Log "Zainstalowano: $sukces"
Write-Log "Bledy: $bledy"
Write-Log "Log zapisany: $logFile"