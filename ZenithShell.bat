@echo off
setlocal enabledelayedexpansion


:: --- YONETICI YETKISI KONTROLU ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- GUNCELLEME MOTORU (V27.0) ---
set "current_ver=27.0"
set "ver_url=https://raw.githubusercontent.com/AhmetFarukCullu/ZenithShell/main/version.txt"

echo [!] Guncellemeler kontrol ediliyor...
:: PowerShell ile sessizce sürümü çek
for /f "tokens=*" %%v in ('powershell -command "(New-Object Net.WebClient).DownloadString('%ver_url%').Trim()" 2^>nul') do set "remote_ver=%%v"

if defined remote_ver (
    if "!remote_ver!" NEQ "!current_ver!" (
        echo.
        echo ======================================================
        echo  [!] YENI SURUM BULUNDU: V!remote_ver!
        echo  [!] Su anki Surumunuz: V!current_ver!
        echo ======================================================
        echo  Yeni ozellikler ve kritik yamalar mevcut.
        set /p "guncelle_onay=Simdi indirilsin mi? (E/H): "
        if /i "!guncelle_onay!"=="E" (
            start "" "https://github.com/KULLANICI_ADIN/REPO_ADIN"
            echo [i] Tarayici acildi. Yeni surumu indirip eskisinin uzerine yazin.
            pause & exit
        )
    )
)
:: --- GUNCELLEME MOTORU BITTI ---

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


:: --- DEGISKEN ILKLEME (COKME KORUMASI) ---
set "wifi_name=Bilinmiyor"
set "disk_yuzde=0"
set "disk_bos=0"
set "smart_durum=Kontrol Ediliyor..."

:menu
cls
echo ======================================================
echo           ZENITHSHELL DASHBOARD [V!current_ver!]
echo ======================================================
title ZenithShell Bakim Paneli v13.0 (Hibrit Analiz)
color %tema_kod%

:: --- AG VE DISK VERILERINI TAZELE ---
:: Wi-Fi adını çek (Hızlı sorgu)
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr /r "SSID" ^| findstr /v "BSSID"') do set "wifi_name=%%a"

:: Disk boş alanını GB cinsinden yaklaşık çek
for /f "tokens=*" %%a in ('powershell -command "[math]::round((Get-PSDrive C).Free / 1GB, 1)"') do set "disk_bos=%%a"

:: --- DASHBOARD VERI MOTORU ---
set "used_mem_perc=0"
set "ram_bar=----------"
set "f_mem=0"
set "t_mem=0"

:: RAM Verilerini Çek
for /f "tokens=2 delims==" %%a in ('wmic OS get FreePhysicalMemory /value 2^>nul') do set "f_mem=%%a"
for /f "tokens=2 delims==" %%a in ('wmic OS get TotalVisibleMemorySize /value 2^>nul') do set "t_mem=%%a"

:: Matematiksel hesaplama
if not "%f_mem%"=="0" (
    set /a "used_mem_perc=100 - (f_mem * 100 / t_mem)"
    set /a "bar_index=!used_mem_perc! / 10"
    
    set "bar_fill=##########"
    set "bar_empty=----------"
    
    for /f "delims=" %%i in ("!bar_index!") do (
        set "ram_bar=!bar_fill:~0,%%i!!bar_empty:~%%i,10!"
    )
)

:: --- DURUM KONTROLLERİ ---
set "haftalik_durum=DEVRE DISI"
schtasks /query /tn "SistemBakim_Haftalik" >nul 2>&1 && set "haftalik_durum=AKTIF"
set "acilis_durum=DEVRE DISI"
schtasks /query /tn "SistemBakim_Acilis" >nul 2>&1 && set "acilis_durum=AKTIF"
set "kapat_etiket=KAPALI"
if "!oto_kapat!"=="1" set "kapat_etiket=ACIK"

:: --- GÖRSEL ÇIKTI ---
echo ======================================================
echo           ZENITHSHELL DASHBOARD [V!current_ver!]
echo ======================================================
echo  BELLEK KULLANIMI : [!ram_bar!] !used_mem_perc!%%
echo  DISK BOS ALAN    : [ !disk_bos! GB ]
echo  S.M.A.R.T DURUMU : [%smart_durum%]
echo  AG BAGLANTISI    : %wifi_name%
echo ======================================================
echo.

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
echo  [K] Elite Paket Kur (Format Sonrasi) [I] Donanim Envanter Raporu (Cikti Al)
echo  [M] Mavi Ekran (BSOD) Analizi        [O] Windows Update Onarici
echo  [G] Pil Sagligi ^& Guc Raporu
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
if /i "%secim%"=="O" goto :update_onar
if /i "%secim%"=="M" goto :bsod_analiz
if /i "%secim%"=="L" start notepad.exe "%log_file%" & goto :menu
if /i "%secim%"=="K" goto :toplu_kurulum
if /i "%secim%"=="I" goto :envanter_raporu
if /i "%secim%"=="H" goto :hosts_kalkan
if /i "%secim%"=="G" goto :pil_analiz
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
:: Temizlik bittiginde sesli bildirim verir
call :seslendir "Sistem temizligi tamamlandi. Zenith Shell, bilgisayarinizi ferahlatti."
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



:seslendir
:: Kullanım: call :seslendir "Mesajınız buraya"
powershell -Command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('%~1');"
exit /b



:envanter_raporu
cls
echo ======================================================
echo           ZENITHSHELL ENVANTER RAPORLAMA (V26.9)
echo ======================================================
echo.
echo [!] Sistem verileri toplaniyor, lutfen bekleyin...
echo [!] Bu islem sirasinda ekran bir anlik donabilir.
echo.

set "rf=%USERPROFILE%\Desktop\Sistem_Ozeti.txt"

:: Tek satır, tırnak korumalı PowerShell komutu
powershell -NoProfile -ExecutionPolicy Bypass -Command "$r = @(); $r += '### ZENITHSHELL SISTEM RAPORU ###'; $r += 'Tarih: ' + (Get-Date); $r += '--------------------------'; $r += '[ISLEMCI]'; $r += (Get-CimInstance Win32_Processor).Name; $r += '[BELLEK]'; $r += (Get-CimInstance Win32_PhysicalMemory | Select-Object @{L='GB';E={[math]::round($_.Capacity/1GB,2)}}, Speed | Out-String); $r += '[DISK]'; $r += (Get-CimInstance Win32_DiskDrive | Select-Object Model, Status | Out-String); $r += '--------------------------'; $r | Out-File -FilePath '%rf%' -Encoding utf8"

if %errorlevel% neq 0 (
    echo [X] HATA: PowerShell komutu calistirilamadi!
    echo [!] Yetki sorunu veya PowerShell kisitlamasi olabilir.
    pause
    goto :menu
)

echo.
echo [+] ISLEM TAMAMLANDI!
echo [!] Rapor Masaustunde: Sistem_Ozeti.txt
echo.
call :seslendir "Envanter raporu masaustune kaydedildi."
pause
goto :menu



:bsod_analiz
cls
echo ======================================================
echo           ZENITHSHELL MAVI EKRAN (BSOD) ANALIZI
echo ======================================================
echo.
echo [!] Minidump dosyalari taraniyor...
echo.

:: Minidump klasörü var mı kontrol et
if not exist "C:\Windows\Minidump" (
    echo [X] HATA: Minidump klasoru bulunamadi. 
    echo [!] Sisteminizde daha once Mavi Ekran kaydi olusmamis olabilir.
    pause & goto :menu
)

:: En son dump dosyasını bul ve PowerShell ile analiz et
powershell -Command ^
    "$dumps = Get-ChildItem 'C:\Windows\Minidump\*.dmp' | Sort-Object LastWriteTime -Descending; ^
    if ($dumps.Count -eq 0) { Write-Host '[-] Hicbir cokme dosyasi bulunamadi.'; return }; ^
    $lastDump = $dumps[0]; ^
    Write-Host '[+] En Son Cokme Tarihi: ' $lastDump.LastWriteTime; ^
    Write-Host '[+] Dosya Adi: ' $lastDump.Name; ^
    Write-Host '--------------------------------------------'; ^
    Write-Host '[!] Analiz Ediliyor (Hata Kodu Sorgusu)...'; ^
    $errCode = (Get-CimInstance -ClassName Win32_Thread | Where-Object { $_.ThreadState -eq 5 } | Select-Object -First 1).WaitReason; ^
    if (!$errCode) { Write-Host '[i] Spesifik hata kodu yakalanamadi. Genellikle Donanim veya Surucu (Driver) kaynaklidir.' } ^
    else { Write-Host '[!] Muhtemel Neden Kodu: ' $errCode }; ^
    Write-Host '--------------------------------------------'; ^
    Write-Host '[TAVSIYE]: Mavi ekran genellikle ekran karti surucusu veya RAM arizasindan kaynaklanir.'; ^
    Write-Host 'Daha detayli analiz icin BlueScreenView aracini kullanmaniz onerilir.'"

echo.
echo [1] Dump Klasorunu Ac (Manuel Inceleme)
echo [0] Ana Menuye Don
echo.
set /p "m_secim=Seciminiz: "
if "%m_secim%"=="1" start explorer.exe "C:\Windows\Minidump"
goto :menu



:update_onar
cls
echo ======================================================
echo           ZENITHSHELL WINDOWS UPDATE ONARICI
echo ======================================================
echo.
echo [!] Kritik servisler durduruluyor...
echo [!] Bu islem birkac dakika surebilir, lutfen beklemeyin.
echo.

:: 1. Servisleri Durdur
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1

echo [+] Güncelleme onbellegi temizleniyor...
:: 2. Eski Güncelleme Dosyalarını Yeniden Adlandır (Yedekle/Sil)
if exist "%SystemRoot%\SoftwareDistribution" (
    ren "%SystemRoot%\SoftwareDistribution" SoftwareDistribution.old >nul 2>&1
)
if exist "%SystemRoot%\System32\catroot2" (
    ren "%SystemRoot%\System32\catroot2" catroot2.old >nul 2>&1
)

echo [+] Kayit defteri ve ağ ayarları sıfırlanıyor...
:: 3. Winsock ve Proxy Sıfırlama
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1

echo [+] Servisler yeniden baslatiliyor...
:: 4. Servisleri Tekrar Başlat
net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1

echo.
echo ======================================================
echo  [OK] WINDOWS UPDATE BASARIYLA SIFIRLANDI!
echo  [!] Lutfen bilgisayarinizi yeniden baslatin ve
echo      Ayarlar > Windows Update kısmından tekrar deneyin.
echo ======================================================
echo.
call :seslendir "Windows guncelleme servisleri onarildi. Yeniden baslatma onerilir."
pause
goto :menu



:pil_analiz
cls
echo ======================================================
echo           ZENITHSHELL PIL SAGLIGI ANALIZI
echo ======================================================
echo.
echo [!] Pil verileri toplaniyor, lutfen bekleyin...
echo.

:: Masaüstüne geçici bir HTML raporu oluştur (Windows standardı)
powercfg /batteryreport /output "%temp%\battery_report.html" >nul 2>&1

:: PowerShell ile verileri çek ve hesapla
powershell -Command ^
    "$report = Get-Content '%temp%\battery_report.html'; ^
    $design = [regex]::Match($report, 'DESIGN CAPACITY.*?([\d,]+) mWh').Groups[1].Value.Replace(',',''); ^
    $full = [regex]::Match($report, 'FULL CHARGE CAPACITY.*?([\d,]+) mWh').Groups[1].Value.Replace(',',''); ^
    if (!$design -or !$full) { Write-Host '[X] HATA: Pil bulunamadi veya sistem masaustu (Desktop).'; return }; ^
    $health = [math]::Round(($full / $design) * 100, 2); ^
    Write-Host '--------------------------------------------'; ^
    Write-Host '[+] Fabrika Kapasitesi : ' $design ' mWh'; ^
    Write-Host '[+] Mevcut Kapasite    : ' $full ' mWh'; ^
    Write-Host '--------------------------------------------'; ^
    if ($health -ge 80) { Write-Host '[DURUM]: MUKEMMEL (%' $health ')' -ForegroundColor Green } ^
    elseif ($health -ge 50) { Write-Host '[DURUM]: ORTA (%' $health ')' -ForegroundColor Yellow } ^
    else { Write-Host '[DURUM]: KRITIK - DEGISTIRILMELI (%' $health ')' -ForegroundColor Red }"

echo.
echo [1] Detayli Pil Raporunu Ac (HTML)
echo [0] Ana Menuye Don
echo.
set /p "p_secim=Seciminiz: "
if "%p_secim%"=="1" start "" "%temp%\battery_report.html"
goto :menu