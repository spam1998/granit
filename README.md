# Skrypt Instalacyjny (Granit Chocolatey)

Ten skrypt automatyzuje instalację oprogramowania na systemie Windows, w tym:
- Przeglądarki: Google Chrome, Firefox, Brave
- Narzędzia: 7-Zip, Adobe Reader, AnyDesk
- ZWCAD (z SharePoint)
- ESET NOD32 Antivirus
- OpenVPN (konfiguracja TAP/TUN)

## Uruchomienie skryptu z URL

Aby uruchomić ten skrypt bezpośrednio z Internetu, bez konieczności ręcznego pobierania pliku, wykonaj następujące kroki:

1. Otwórz menu Start.
2. Wpisz `PowerShell`.
3. Kliknij prawym przyciskiem myszy na "Windows PowerShell" i wybierz **Uruchom jako administrator**.
4. Wklej i uruchom poniższe polecenie:

### Metoda 1 (Krótsza - PowerShell 3.0+)
```powershell
irm https://raw.githubusercontent.com/spam1998/granit/refs/heads/main/install.ps1 | iex
```

### Metoda 2 (Bardziej kompatybilna)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/spam1998/granit/refs/heads/main/install.ps1'))
```

**Uwaga:** Powyższe linki wskazują bezpośrednio na najnowszą wersję skryptu w repozytorium GitHub.

## Wymagania

- System operacyjny Windows.
- Uprawnienia Administratora.
- Stabilne połączenie z Internetem.
