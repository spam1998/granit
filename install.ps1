# install-advanced.ps1
$logFile = "instalacja-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $logFile -Append
}

# Sprawdź uprawnienia administratora
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "BLAD: Uruchom skrypt jako Administrator!"
    exit 1
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

Write-Log "===================="
Write-Log "Zainstalowano: $sukces"
Write-Log "Bledy: $bledy"
Write-Log "Log zapisany: $logFile"