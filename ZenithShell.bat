@echo off
setlocal enabledelayedexpansion

:: --- YONETICI YETKISI KONTROLU ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:init
:: Varsayılan Ayarlar
if not defined oto_kapat set "oto_kapat=0"
if not defined tema_kod set "tema_kod=0b"
if not defined tema_ad set "tema_ad=Siber Mavi"

set "log_file=%LocalAppData%\ZenithShell_log.txt"
for /f "tokens=*" %%a in ('powershell -command "(Get-PSDrive C).Free"') do set "start_space=%%a"

:: --- DISK SAGLIK SORGUSU ---
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get status /value ^| find "Status"') do set "smart_durum=%%a"
if "%smart_durum%"=="" set "smart_durum=BILINMIYOR"

:menu
cls
title Windows Bakim Paneli v13.0 (Hibrit Analiz)
color %tema_kod%

:: --- DURUM KONTROLLERİ ---
set "haftalik_durum=DEVRE DISI"
schtasks /query /tn "SistemBakim_Haftalik" >nul 2>&1 && set "haftalik_durum=AKTIF"
set "acilis_durum=DEVRE DISI"
schtasks /query /tn "SistemBakim_Acilis" >nul 2>&1 && set "acilis_durum=AKTIF"
set "kapat_etiket=KAPALI"
if "!oto_kapat!"=="1" set "kapat_etiket=ACIK"

echo ======================================================
echo         ZENITHSHELL SISTEM VE ANALIZ MERKEZI
echo ======================================================
echo.
echo  DISK SAGLIGI (S.M.A.R.T): [%smart_durum%]
echo.
echo  [1] Hizli Temizlik                   [6] Haftalik Bakim Kur
echo  [2] Derin Temizlik (Yedekli)         [7] Haftalik Bakim Iptal
echo  [3] Interneti Tazele                 [H] Hosts Kalkanı (Reklam/Zararlı Engelle)
echo  [4] Copu Bosalt                      [9] Acilista Calistir (Iptal)
echo  [5] Akilli Analiz ve Bakim           [A] AYAR: Oto-Kapat [%kapat_etiket%]
echo  [T] Tarayici Temizligi               [C] TEMA: [%tema_ad%]
echo  [R] RAM Onbellegi Bosalt             [D] Disk Saglik Raporu (Detayli)
echo  [L] Bakim Gunlugunu Ac               [8] Acilista Calistir (Kur)
echo  [0] Cikis                            [W] Wi-Fi ^& Ağ Analizi (Anlık)
echo  [P] Acik Port Taramasi (Guvenlik)    [B] Baslangic Analizi (Hizlandirma)
echo  [V] Servis Optimizasyonu (Hiz)       [U] Tum Uygulamalari Guncelle (Winget)
echo  [K] Elite Paket Kur (Format Sonrasi) 
echo.
echo  --- SISTEM DURUMU ---
echo  Haftalik: [%haftalik_durum%]  Acilis: [%acilis_durum%]
echo ======================================================
set /p "secim=Seciminiz: "

if "%secim%"=="1" goto :hizli
if "%secim%"=="2" goto :guvenli_derin
if "%secim%"=="3" goto :dns
if "%secim%"=="4" goto :cop
if "%secim%"=="5" goto :analiz
if "%secim%"=="6" goto :zamanla_ozel
if "%secim%"=="7" goto :zamanla_sil
if "%secim%"=="8" goto :acilis_aktif
if "%secim%"=="9" goto :acilis_iptal
if /i "%secim%"=="W" goto :wifi_analiz
if /i "%secim%"=="V" goto :servis_opt
if /i "%secim%"=="U" goto :winget_update
if /i "%secim%"=="T" goto :tarayici_temizle
if /i "%secim%"=="R" goto :ram_temizle
if /i "%secim%"=="P" goto :port_taramasi
if /i "%secim%"=="L" start notepad.exe "%log_file%" & goto :menu
if /i "%secim%"=="K" goto :toplu_kurulum
if /i "%secim%"=="H" goto :hosts_kalkan
if /i "%secim%"=="D" goto :disk_detay
if /i "%secim%"=="C" goto :tema_degistir
if /i "%secim%"=="B" goto :baslangic_analiz
if /i "%secim%"=="A" (
    if "!oto_kapat!"=="0" (set "oto_kapat=1") else (set "oto_kapat=0")
    goto :menu
)
if "%secim%"=="0" exit
goto :menu

:analiz
cls
echo [!] Disk ve RAM durumu kontrol ediliyor...
echo.
:: PowerShell ile Toplam Boyut, Bos Alan ve Doluluk Yuzdesi hesaplama
powershell -command ^
    "$d = Get-PSDrive C; ^
     $total = [math]::Round($d.Used + $d.Free); ^
     $freeGB = [math]::Floor($d.Free / 1GB); ^
     $percentUsed = [math]::Round(($d.Used / $total) * 100); ^
     Write-Host \"Disk Doluluk Orani: %$percentUsed\"; ^
     Write-Host \"Bos Alan: $freeGB GB\"; ^
     if ($percentUsed -ge 90 -or $freeGB -lt 10) { exit 100 } else { exit 200 }"

set "ps_exit=%errorlevel%"

if "%ps_exit%"=="100" (
    echo.
    echo [!] KRITIK DURUM: Disk dolulugu %%90 uzeri veya 10GB alti!
    echo [!] Otomatik temizlik baslatiliyor...
    timeout /t 3 >nul
    goto :guvenli_derin
) else (
    echo.
    echo [OK] Disk durumu stabil. RAM temizligine geciliyor...
    timeout /t 2 >nul
    goto :ram_temizle
)

:ram_temizle
set "gorev=RAM Optimizasyonu"
cls
echo [!] RAM Onbellegi temizleniyor...
powershell -Command "$p=Get-Process; foreach($pr in $p){try{$pr.EmptyWorkingSet()}catch{}}" >nul 2>&1
echo [+] RAM Ferahlatildi!
if "%secim%"=="5" (
    echo.
    echo Analiz tamamlandi. Ana menuye donuluyor...
    timeout /t 2 >nul
    goto :menu
)
pause & goto :menu

:tema_degistir
cls
echo ======================================================
echo               RENK TEMASI SECIN
echo ======================================================
echo.
echo  [1] Siber Mavi   [2] Matrix Yesili  [3] Kan Kirmizi
echo  [4] Klasik Beyaz [5] Altin Sarisi   [6] Mor Gece
echo.
set /p "tsec=Tema No: "
if "%tsec%"=="1" set "tema_kod=0b" & set "tema_ad=Siber Mavi"
if "%tsec%"=="2" set "tema_kod=0a" & set "tema_ad=Matrix Yesili"
if "%tsec%"=="3" set "tema_kod=0c" & set "tema_ad=Kan Kirmizi"
if "%tsec%"=="4" set "tema_kod=0f" & set "tema_ad=Klasik Beyaz"
if "%tsec%"=="5" set "tema_kod=0e" & set "tema_ad=Altin Sarisi"
if "%tsec%"=="6" set "tema_kod=0d" & set "tema_ad=Mor Gece"
goto :menu

:tarayici_temizle
set "gorev=Tarayici Temizligi"
cls
echo [!] Tarayicilar kapatiliyor ve temizleniyor...
taskkill /F /IM chrome.exe /T >nul 2>&1
taskkill /F /IM msedge.exe /T >nul 2>&1
taskkill /F /IM firefox.exe /T >nul 2>&1
call :progress 50 "Onbellekler siliniyor..."
del /q /s /f "%LocalAppData%\Google\Chrome\User Data\Default\Cache\*.*" >nul 2>&1
del /q /s /f "%LocalAppData%\Microsoft\Edge\User Data\Default\Cache\*.*" >nul 2>&1
call :progress 100 "Tamamlandi!"
goto :rapor_hazirla

:guvenli_derin
set "gorev=Yedekli Derin Temizlik"
cls
echo [!] Geri Yukleme Noktasi olusturuluyor...
powershell -Command "Checkpoint-Computer -Description 'Sistem_Bakim_Oncesi_Yedek' -RestorePointType 'APPLICATION_INSTALL'" >nul 2>&1
goto :derin_islem

:derin_islem
call :progress 40 "Sistem bilesenleri temizleniyor (DISM)..."
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
call :progress 100 "Derin temizlik tamamlandi!"
goto :rapor_hazirla

:hizli
set "gorev=Hizli Temizlik"
call :progress 30 "Gecici dosyalar siliniyor..."
del /s /f /q "%temp%\*.*" >nul 2>&1
wevtutil cl Setup >nul 2>&1
wevtutil cl System >nul 2>&1
wevtutil cl Application >nul 2>&1
call :progress 100 "Islem Tamam!"
goto :rapor_hazirla

:dns
ipconfig /flushdns >nul 2>&1
echo [+] DNS Temizlendi. & pause & goto :menu

:cop
rd /s /q %systemdrive%\$Recycle.Bin >nul 2>&1
echo [+] Cop Kutusu Temizlendi. & pause & goto :menu

:progress
cls
echo ======================================================
echo  %gorev% Yurutuluyor...
echo ======================================================
echo.
set /a "fill=%1 / 4"
set "bar="
for /l %%i in (1,1,%fill%) do set "bar=!bar!#"
echo  Progress: [%bar%] %1%%
echo  Durum   : %~2
echo.
exit /b

:rapor_hazirla
for /f "tokens=*" %%b in ('powershell -command "(Get-PSDrive C).Free"') do set "end_space=%%b"
for /f "tokens=*" %%c in ('powershell -command "$gain = [math]::round(($env:end_space - $env:start_space) / 1MB, 2); if ($gain -lt 0) { 0 } else { $gain }"') do set "gain=%%c"

:: --- LOG KAYDI ---
set "saat=%time:~0,5%"
echo [%date% %saat%] Gorev: %gorev% ^| Kazanilan Alan: %gain% MB >> "%log_file%"

echo ======================================================
echo           ISLEM SONUC RAPORU
echo ======================================================
echo  [+] Acilan Alan: %gain% MB
echo  [i] Kayit '%log_file%' dosyasina eklendi.
echo ======================================================
set "start_space=%end_space%"
if "!oto_kapat!"=="1" (
    echo 5 sn icinde kapaniyor...
    timeout /t 5 >nul & exit
) else (
    echo Ana menuye donmek icin bir tusa basin.
    pause >nul & goto :menu
)

:: --- OTOMASYON FONKSIYONLARI ---
:acilis_aktif
schtasks /create /tn "SistemBakim_Acilis" /tr "'%~f0' 1" /sc onlogon /rl HIGHEST /f >nul 2>&1
pause & goto :menu
:acilis_iptal
schtasks /delete /tn "SistemBakim_Acilis" /f >nul 2>&1
pause & goto :menu
:zamanla_ozel
set /p gun="Gun (MON-SUN): " & if "!gun!"=="" set gun=SAT
set /p saat="Saat (22:00): " & if "!saat!"=="" set saat=22:00
schtasks /create /tn "SistemBakim_Haftalik" /tr "'%~f0' 5" /sc weekly /d !gun! /st !saat! /rl HIGHEST /f >nul 2>&1
pause & goto :menu
:zamanla_sil
schtasks /delete /tn "SistemBakim_Haftalik" /f >nul 2>&1
pause & goto :menu


:disk_detay
cls
echo ======================================================
echo             DETAYLI DISK SAGLIK RAPORU
echo ======================================================
echo.
echo [!] Disk bilgileri ve S.M.A.R.T durumu sorgulaniyor...
echo.
:: Windows'un kendi aracini kullanarak Model, Durum ve Boyut bilgisini cekeriz.
wmic diskdrive get model,status,size /format:list
echo.
echo ------------------------------------------------------
echo  BILGI NOTU:
echo  [OK]       : Disk saglikli, sorun yok.
echo  [PredFail] : DIKKAT! Disk fiziksel hata verdi, verilerini yedekle!
echo ------------------------------------------------------
echo.
echo Ana menuye donmek icin bir tusa basin.
pause >nul
goto :menu


:hosts_kalkan
cls
echo ======================================================
echo           ZENITHSHELL HOSTS KALKANI (V1.0)
echo ======================================================
echo.
echo [!] Bu islem bilinen reklam ve zararli sunuculari engeller.
echo [!] Mevcut Hosts dosyaniz yedeklenecek.
echo.
set "hosts_path=%SystemRoot%\System32\drivers\etc\hosts"

:: 1. Mevcut dosyayı yedekle (Eğer daha önce yedeklenmediyse)
if not exist "%hosts_path%.bak" (
    copy "%hosts_path%" "%hosts_path%.bak" >nul
    echo [+] Orijinal Hosts dosyasi yedeklendi (.bak)
)

:: 2. Reklam/Zararlı IP'leri ekle
echo. >> "%hosts_path%"
echo # ZenithShell Kalkan Baslangici >> "%hosts_path%"
echo 0.0.0.0 adservice.google.com >> "%hosts_path%"
echo 0.0.0.0 doubleclick.net >> "%hosts_path%"
echo 0.0.0.0 telemetry.microsoft.com >> "%hosts_path%"
echo # ZenithShell Kalkan Bitisi >> "%hosts_path%"

echo [+] Reklam ve Telemetri sunuculari engellendi.
echo [+] Internetiniz artik daha temiz.
echo.
ipconfig /flushdns >nul
echo [!] Degisikliklerin aktif olmasi icin DNS temizlendi.
echo.
pause
goto :menu




:wifi_analiz
cls
echo ======================================================
echo           ZENITHSHELL AG DURUM ANALIZORU
echo ======================================================
echo.
echo [!] Ag arayuzleri kontrol ediliyor...
echo.

:: Varsayılan değerler
set "wifi_name=Ethernet (Kablolu)"
set "wifi_signal=---"
set "ping_res=Olculemedi"

:: Wi-Fi bilgilerini çekmeyi dene
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr /r "SSID" ^| findstr /v "BSSID"') do set "wifi_name=%%a"
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr /r "[0-9]%%"') do set "wifi_signal=%%a"

echo  Baglanti Tipi : %wifi_name%
echo  Sinyal Gucu   : %wifi_signal%
echo  --------------------------------------------------
echo [!] Gecikme testi yapiliyor (8.8.8.8)...
echo.

:: Sadece 'Ortalama = Xms' kısmındaki 'Xms' değerini tertemiz alalım
for /f "tokens=3 delims=, " %%i in ('ping -n 2 8.8.8.8 ^| findstr /i "ms"') do (
    for /f "tokens=2 delims==" %%j in ("%%i") do set "ping_res=%%j"
)

:: Eğer yukarıdaki yöntem dile takılırsa, sadece sayıyı ve birimi yakala
if "%ping_res%"=="Olculemedi" (
    for /f "tokens=4 delims== " %%i in ('ping -n 2 8.8.8.8 ^| findstr /i "ms"') do set "ping_res=%%i"
)

echo  Ortalama Gecikme : %ping_res%
echo  --------------------------------------------------
echo.
echo Ana menuye donmek icin bir tusa basin.
pause >nul
goto :menu



:port_taramasi
cls
echo ======================================================
echo           ZENITHSHELL ACIK PORT DENETLEYICI
echo ======================================================
echo.
echo [!] Aktif baglantilar ve acik kapilar taraniyor...
echo [!] LISTENING: Disaridan baglanti bekleyen acik kapilar.
echo.
echo  PROTOKOL   YEREL ADRES          DURUM
echo  --------------------------------------------------

:: Sadece 'LISTENING' (Dinlemede) olan portları filtrele
netstat -ano | findstr /i "LISTENING"

echo  --------------------------------------------------
echo.
echo [i] Eger tanimadiginiz bir port 'LISTENING' durumundaysa,
echo     bu bir arka kapi (backdoor) veya uygulama olabilir.
echo.
echo Ana menuye donmek icin bir tusa basin.
pause >nul
goto :menu



:baslangic_analiz
cls
echo ======================================================
echo           ZENITHSHELL BASLANGIC ANALIZORU
echo ======================================================
echo.
echo [!] Otomatik baslayan uygulamalar listeleniyor...
echo [!] Gereksiz gorduklerinizi Gorev Yoneticisi'nden (Startup) kapatin.
echo.
echo  UYGULAMA ADI          KONUM / KOMUT
echo  --------------------------------------------------

:: Başlangıçta çalışan programları isim ve komut satırı olarak çeker
wmic startup get caption,command /format:table

echo  --------------------------------------------------
echo.
echo [i] IPUCU: 'Update', 'Helper' veya 'Tray' iceren uygulamalar 
echo     genellikle acilisi yavaslatan yan servislerdir.
echo.
echo [M] Baslangic Ayarlarini Ac (Gorev Yoneticisi)
echo [0] Ana Menuye Don
echo.
set /p "b_secim=Seciminiz: "

if /i "%b_secim%"=="M" (
    start taskmgr /0 /startup
    goto :baslangic_analiz
)
goto :menu



:servis_opt
cls
echo ======================================================
echo           ZENITHSHELL SERVIS OPTIMIZASYONU
echo ======================================================
echo.
echo [!] Kritik servisler devre disi birakilmaz, sadece 
echo     ev kullanicilari icin gereksiz olanlar hedeflenir.
echo.
echo  [1] Yazdirma Kuyrugu (Yaziciniz yoksa kapatin)
echo  [2] Uzak Kayit Defteri (Guvenlik icin kapatin)
echo  [3] Dokunmatik Klavye ve Panel (Tablet degilse kapatin)
echo  [4] Faks Servisi (Kullanilmiyorsa kapatin)
echo  [R] HEPSINI TAVSIYE EDILEN YAP (Hizli Ayar)
echo  [0] Vazgec ve Ana Menuye Don
echo.
set /p "s_secim=Seciminiz: "

if "%s_secim%"=="1" sc config "Spooler" start= demand & echo [+] Yazdirma Kuyrugu 'Elle' yapildi.
if "%s_secim%"=="2" sc config "RemoteRegistry" start= disabled & echo [+] Uzak Kayit Defteri Kapatildi.
if "%s_secim%"=="3" sc config "TabletInputService" start= demand & echo [+] Dokunmatik Panel 'Elle' yapildi.
if "%s_secim%"=="4" sc config "Fax" start= disabled & echo [+] Faks Servisi Kapatildi.

if /i "%s_secim%"=="R" (
    echo [!] Hizli optimizasyon yapiliyor...
    sc config "Spooler" start= demand >nul 2>&1
    sc config "RemoteRegistry" start= disabled >nul 2>&1
    sc config "TabletInputService" start= demand >nul 2>&1
    sc config "Fax" start= disabled >nul 2>&1
    echo [+] Tavsiye edilen ayarlar uygulandi!
)

if "%s_secim%"=="0" goto :menu
echo.
pause
goto :servis_opt



:winget_update
cls
echo ======================================================
echo           ZENITHSHELL AKILLI PAKET YONETICISI
echo ======================================================
echo.
echo [!] Sistemdeki uygulamalar kontrol ediliyor...
echo.

:: Winget var mı kontrol et
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] HATA: Winget bu sistemde yuklu degil.
    echo     (Windows 10/11 kullaniyorsaniz Microsoft Store'dan
    echo      'Uygulama Yükleyicisi'ni guncellemelisiniz.)
    pause
    goto :menu
)

:: Güncellenebilir uygulamaları listele
echo [+] Guncellenebilir uygulamalar listeleniyor:
winget upgrade
echo.
echo ------------------------------------------------------
echo  [1] TUMUNU GUNCELLE (Sessiz Mod)
echo  [0] Vazgec ve Ana Menuye Don
echo ------------------------------------------------------
echo.
set /p "u_secim=Seciminiz: "

if "%u_secim%"=="1" (
    echo.
    echo [!] Guncellestirmeler baslatiliyor, lutfen bekleyin...
    winget upgrade --all --include-unknown
    echo.
    echo [+] Islem tamamlandi!
    pause
)

goto :menu



:toplu_kurulum
cls
echo ======================================================
echo           ZENITHSHELL ELITE PAKET KURULUMU
echo ======================================================
echo.
echo [!] Bu paket su uygulamalari icerir:
echo     - Google Chrome (Tarayici)
echo     - VLC Media Player (Video)
echo     - 7-Zip (Arsivleme)
echo     - Spotify (Muzik)
echo     - Discord (Iletisim)
echo     - Visual Studio Code (Yazilim)
echo.
echo [1] KURULUMU BASLAT (Sessiz ve Otomatik)
echo [0] Vazgec ve Ana Menuye Don
echo.
set /p "k_secim=Seciminiz: "

if "%k_secim%"=="1" (
    echo.
    echo [!] Paketler indiriliyor ve kuruluyor...
    echo [!] Lutfen bekleyin, bu islem internet hiziniza baglidir.
    echo.
    
    :: Google Chrome
    echo [+] Chrome kuruluyor...
    winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements >nul
    
    :: VLC
    echo [+] VLC kuruluyor...
    winget install --id VideoLAN.VLC --silent >nul
    
    :: 7-Zip
    echo [+] 7-Zip kuruluyor...
    winget install --id 7zip.7zip --silent >nul
    
    :: Spotify
    echo [+] Spotify kuruluyor...
    winget install --id Spotify.Spotify --silent >nul
    
    :: Discord
    echo [+] Discord kuruluyor...
    winget install --id Discord.Discord --silent >nul

    :: VS Code
    echo [+] VS Code kuruluyor...
    winget install --id Microsoft.VisualStudioCode --silent >nul

    echo.
    echo [+] ELITE PAKET KURULUMU TAMAMLANDI!
    pause
)

goto :menu