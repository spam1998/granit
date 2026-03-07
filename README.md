# Skrypt Instalacyjny (Granit Chocolatey)

Ten skrypt automatyzuje instalację oprogramowania na systemie Windows. Dostępne są dwie wersje:

1.  **Wersja Standardowa (`install.ps1`)**:
    *   Przeglądarki: Google Chrome, Firefox, Brave
    *   Narzędzia: 7-Zip, Adobe Reader, AnyDesk
    *   ZWCAD, ESET NOD32, OpenVPN
2.  **Wersja z Office (`install-libreoffice.ps1`)**:
    *   Wszystko co w wersji standardowej + **LibreOffice**

## Uruchomienie skryptu z URL

Wybierz odpowiednią wersję i uruchom polecenie w PowerShellu (jako Administrator):

### 1. Wersja Standardowa
```powershell
irm https://raw.githubusercontent.com/spam1998/granit/refs/heads/main/install.ps1 | iex
```

### 2. Wersja z LibreOffice
```powershell
irm https://raw.githubusercontent.com/spam1998/granit/refs/heads/main/install-libreoffice.ps1 | iex
```

---

## Instrukcja krok po kroku

1. Otwórz menu Start.
2. Wpisz `PowerShell`.
3. Kliknij prawym przyciskiem myszy na "Windows PowerShell" i wybierz **Uruchom jako administrator**.
4. Wklej i uruchom wybrane polecenie powyżej.

**Uwaga:** Powyższe linki wskazują bezpośrednio na najnowszą wersję skryptu w repozytorium GitHub.

## Wymagania

- System operacyjny Windows.
- Uprawnienia Administratora.
- Stabilne połączenie z Internetem.
