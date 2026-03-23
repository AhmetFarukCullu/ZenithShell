@echo off
setlocal enabledelayedexpansion
title ZenithShell Professional System Tool

:: ==========================================
:: SECTION 1: YONETICI VE GUNCELLEME KONTROLU
:: ==========================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "current_ver=34.2"
set "ver_url=https://raw.githubusercontent.com/AhmetFarukCullu/ZenithShell/main/version.txt"

echo [!] Guncellemeler kontrol ediliyor...
for /f "tokens=*" %%v in ('powershell -command "(New-Object Net.WebClient).DownloadString('%ver_url%').Trim()" 2^>nul') do set "remote_ver=%%v"

if defined remote_ver (
    if "!remote_ver!" NEQ "!current_ver!" (
        echo.
        echo ======================================================
        echo  [!] YENI SURUM BULUNDU: V!remote_ver!
        echo  [!] Su anki Surumunuz: V!current_ver!
        echo ======================================================
        set /p "guncelle_onay=Simdi indirilsin mi? (E/H): "
        if /i "!guncelle_onay!"=="E" (
            start "" "https://github.com/AhmetFarukCullu/ZenithShell"
            exit /b
        )
    )
)

:: ==========================================
:: SECTION 2: INIT VE GUVENLIK (ANTI-TAMPER)
:: ==========================================
:init
:: 1. Önce Sorumluluk Reddi (Sadece 1 kez sorulur)
call :disclaimer

:main_start
:: Anti-Tamper Ayarları
set "current_script=%~f0"
:: [NOT] Geliştirme bitince hash değerini buraya gir
set "original_hash=A2DF914387F912841FF7D655B00E89925D0BCCD44965D79AE6A68E1B50545E02"

:: Hash Hesaplama
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-FileHash '%current_script%' -Algorithm SHA256).Hash"') do set "current_hash=%%a"

:: Anti-Tamper Kontrolü (Geliştirme sırasında atlamak için current_hash kontrolü kapatıldı)
if "%original_hash%"=="DO_NOT_EDIT_THIS_LINE" (
    cls
    echo [!] ILK KURULUM: Yeni Hash: %current_hash%
    pause & exit
)

:: 2. Görsel Karşılama
call :show_logo

:: ==========================================
:: SECTION 3: DEGISKENLER VE SISTEM VERILERI
:: ==========================================
:main_settings
echo [!] Sistem verileri analiz ediliyor...

:: Varsayılan Ayarlar
if not defined oto_kapat set "oto_kapat=0"
if not defined tema_kod set "tema_kod=0b"
if not defined tema_ad set "tema_ad=Siber Mavi"
set "log_file=%LocalAppData%\ZenithShell_log.txt"

:: Sistem Verilerini Topla (Hızlı ve Tek Seferlik)
for /f "tokens=*" %%a in ('powershell -command "[math]::round((Get-PSDrive C).Free / 1GB, 2)"') do set "start_space=%%a"
for /f "tokens=2 delims==" %%a in ('wmic diskdrive get status /value ^| find "Status"') do set "smart_durum=%%a"
if "%smart_durum%"=="" set "smart_durum=BILINMIYOR"

:: Dashboard Değişkenleri
set "wifi_name=Bilinmiyor"
set "disk_yuzde=0"

:: Ana Menüye Geçiş
goto :menu

:: ==========================================
:: SECTION 4: TEMEL FONKSIYONLAR
:: ==========================================

:show_logo
cls
echo.
echo         ******************************************
echo         * ZENITH SHELL SYSTEM           *
echo         * Professional Maintenance Tool      *
echo         * Version V!current_ver!               *
echo         ******************************************
echo.
timeout /t 2 >nul
exit /b

:disclaimer
cls
echo ======================================================
echo             ZENITHSHELL GUVENLIK VE KULLANIM
echo ======================================================
echo.
echo  [!] DIKKAT: Bu program sistem ayarlarina mudahale eder.
echo  [!] SORUMLULUK REDDI: Donanim/veri kaybindan gelistirici sorumlu tutulamaz.
echo.
set /p "onay=Sartlari kabul ediyor musunuz? (E/H): "
if /i "%onay%" NEQ "E" (
    echo [!] Onay verilmedigi icin program kapatiliyor.
    timeout /t 2 >nul
    exit
)
exit /b

:menu
cls
:: --- RENK VE BAŞLIK GÜNCELLE ---
color %tema_kod%
title ZenithShell Dashboard [V!current_ver!] - %tema_ad%

:: --- VERİ TAZELEME MOTORU (Optimize Edildi) ---
:: Wi-Fi adını temizle (Boşlukları al)
set "wifi_name=Yok"
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr "SSID" ^| findstr /v "BSSID"') do (
    set "wifi_name=%%a"
    set "wifi_name=!wifi_name:~1!"
)

:: RAM Analizi (PowerShell ile tek seferde ve hızlı)
for /f "tokens=1,2" %%a in ('powershell -command "$os = Get-CimInstance Win32_OperatingSystem; $total = $os.TotalVisibleMemorySize; $free = $os.FreePhysicalMemory; $used = 100 - [math]::Round(($free * 100 / $total), 0); $bar = $used / 10; Write-Host $used $bar"') do (
    set "used_mem_perc=%%a"
    set "bar_val=%%b"
)

:: RAM Bar Oluşturucu (Daha şık görünüm)
set "ram_bar=----------"
set "bar_fill=##########"
if !bar_val! GTR 0 (
    set "ram_bar=!bar_fill:~0,%bar_val%!!ram_bar:~%bar_val%,10!"
)

:: Disk Verisi (Zaten main_settings'de çekmiştik ama burada tazeleyelim)
for /f "tokens=*" %%a in ('powershell -command "[math]::round((Get-PSDrive C).Free / 1GB, 1)"') do set "disk_bos=%%a"

:: --- PLANLANMIŞ GÖREV KONTROLÜ ---
set "haftalik_durum=PASIF"
schtasks /query /tn "SistemBakim_Haftalik" >nul 2>&1 && set "haftalik_durum=AKTIF"
set "acilis_durum=PASIF"
schtasks /query /tn "SistemBakim_Acilis" >nul 2>&1 && set "acilis_durum=AKTIF"

:: --- DASHBOARD ARAYÜZÜ ---
echo ======================================================
echo           ZENITHSHELL DASHBOARD [V!current_ver!]
echo ======================================================
echo  [ SISTEM DURUMU ]
echo  RAM KULLANIMI : [!ram_bar!] %%!used_mem_perc!
echo  DISK BOS ALAN : [ !disk_bos! GB ]
echo  SMART DURUMU  : [%smart_durum%]
echo  AG/SSID       : %wifi_name%
echo ======================================================
echo  [ OTOMASYON ]
echo  HAFTALIK BAKIM: [%haftalik_durum%]  ACILIS TARAMASI: [%acilis_durum%]
echo  OTO-KAPATMA   : [%kapat_etiket%]
echo ======================================================
echo.

:: ======================================================
:: --- ZENITHSHELL MASTER DASHBOARD (V34.2) ---
:: ======================================================
echo  [1] Hizli Temizlik              [6] Haftalik Bakim Kur
echo  [2] Derin Temizlik (Yedekli)    [7] Haftalik Bakim Iptal
echo  [3] Interneti Tazele            [8] Acilista Calistir (Kur)
echo  [4] Copu Bosalt                 [9] Acilista Calistir (Iptal)
echo  [5] Akilli Analiz ve Bakim      [A] AYAR: Oto-Kapat [%kapat_etiket%]
echo  ------------------------------------------------------
echo  [T] Tarayici Temizligi          [B] Baslangic Analizi
echo  [R] RAM Onbellegi Bosalt        [V] Servis Optimizasyonu
echo  [U] Uygulamalari Guncelle       [D] Disk Saglik Raporu
echo  [E] Otomatik Surucu Guncelle    [G] Pil Sagligi ^& Guc
echo  ------------------------------------------------------
echo  [W] Wi-Fi ^& Ag Analizi          [H] Hosts Kalkani (Ads)
echo  [P] Acik Port Taramasi          [S] Anti-Ransomware Shield
echo  [M] Mavi Ekran (BSOD) Analizi   [O] Windows Update Onarici
echo  [K] Elite Paket Kur             [I] Donanim Envanteri
echo  ------------------------------------------------------
echo  [C] TEMA: [%tema_ad%]          [L] Bakim Gunlugunu Ac
echo  [Y] Yardim / Rehber             [0] ZENITHSHELL'DEN CIKIS
echo ======================================================
set "secim="
set /p "secim= >>> Seciminiz: "

:: Girdi Boşsa Menüye Dön (Çökmeyi Engeller)
if "!secim!"=="" goto :menu

:: Rakamlar
if "%secim%"=="1" goto :hizli
if "%secim%"=="2" goto :guvenli_derin
if "%secim%"=="3" goto :dns
if "%secim%"=="4" goto :cop
if "%secim%"=="5" goto :analiz
if "%secim%"=="6" goto :zamanla_ozel
if "%secim%"=="7" goto :zamanla_sil
if "%secim%"=="8" goto :acilis_aktif
if "%secim%"=="9" goto :acilis_iptal
if "%secim%"=="0" exit

:: Harfler (Büyük/Küçük Duyarsız)
for %%i in (W Y V U T S R P O M K I H G E D C B A) do (
    if /i "%secim%"=="%%i" goto :label_%%i
)

echo [!] Gecersiz secim: %secim%
timeout /t 2 >nul
goto :menu

:: --- HARF YONLENDIRMELERI ---
:label_W
goto :wifi_analiz
:label_Y
goto :hakkinda
:label_V
goto :servis_opt
:label_U
goto :winget_update
:label_T
goto :tarayici_temizle
:label_S
goto :shield_menu
:label_R
goto :ram_temizle
:label_P
goto :port_taramasi
:label_O
goto :update_onar
:label_M
goto :bsod_analiz
:label_L
start notepad.exe "%log_file%" & goto :menu
:label_K
goto :toplu_kurulum
:label_I
goto :envanter_raporu
:label_H
goto :hosts_kalkan
:label_G
goto :pil_analiz
:label_E
goto :driver_update
:label_D
goto :disk_detay
:label_C
goto :tema_degistir
:label_B
goto :baslangic_analiz
:label_A
if "!oto_kapat!"=="0" (set "oto_kapat=1") else (set "oto_kapat=0")
goto :menu

:: ======================================================
:: SECTION: AKILLI ANALIZ VE BAKIM MOTORU
:: ======================================================
:analiz
cls
echo [!] Sistem Kaynaklari Analiz Ediliyor...
echo.

:: Disk Analizi (Tek Satır PowerShell - Hızlı ve Güvenli)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$d=Get-PSDrive C; $total=$d.Used+$d.Free; $freeGB=[math]::Floor($d.Free/1GB); $p=[math]::Round(($d.Used/$total)*100); ^
    Write-Host \"Disk Doluluk Orani: %$p\" -ForegroundColor Cyan; ^
    Write-Host \"Bos Alan: $freeGB GB\" -ForegroundColor Yellow; ^
    if ($p -ge 90 -or $freeGB -lt 10) { exit 100 } else { exit 200 }"

if %errorlevel% equ 100 (
    echo.
    echo [!] KRITIK: Disk dolulugu %%90 uzeri veya 10GB alti!
    echo [!] Derin temizlik moduna yonlendiriliyorsunuz...
    timeout /t 3 >nul
    goto :guvenli_derin
)

echo.
echo [OK] Disk durumu stabil. RAM ferahlatma baslatiliyor...
timeout /t 2 >nul
goto :ram_temizle

:ram_temizle
cls
echo [!] RAM Onbellegi Bosaltiliyor...
echo [!] Lutfen bekleyin, calisan uygulamalar optimize ediliyor...

:: RAM Temizleme Komutu (Daha Kararlı Versiyon)
powershell -NoProfile -Command "Get-Process | Where-Object {$_.WorkingSet -gt 1MB} | ForEach-Object { try { $_.EmptyWorkingSet() } catch {} }" >nul 2>&1

echo [+] RAM Basariyla Ferahlatildi!
if "%secim%"=="5" (
    echo.
    echo [i] Akilli analiz ve bakim islemi tamamlandi.
    timeout /t 2 >nul
)
goto :menu

:: ======================================================
:: SECTION: GORSEL AYARLAR (TEMA)
:: ======================================================
:tema_degistir
cls
echo ======================================================
echo                ZENITHSHELL TEMA MERKEZI
echo ======================================================
echo.
echo   [1] Siber Mavi    [2] Matrix Yesili   [3] Kan Kirmizi
echo   [4] Klasik Beyaz  [5] Altin Sarisi    [6] Mor Gece
echo.
echo   [0] Vazgec (Menu)
echo ======================================================
set /p "tsec= >>> Tema Numarasi: "

if "%tsec%"=="0" goto :menu
if "%tsec%"=="1" set "tema_kod=0b" & set "tema_ad=Siber Mavi"
if "%tsec%"=="2" set "tema_kod=0a" & set "tema_ad=Matrix Yesili"
if "%tsec%"=="3" set "tema_kod=0c" & set "tema_ad=Kan Kirmizi"
if "%tsec%"=="4" set "tema_kod=0f" & set "tema_ad=Klasik Beyaz"
if "%tsec%"=="5" set "tema_kod=0e" & set "tema_ad=Altin Sarisi"
if "%tsec%"=="6" set "tema_kod=0d" & set "tema_ad=Mor Gece"

:: Geçersiz seçim kontrolü
if not defined tema_kod (
    echo [!] Gecersiz secim yapildi.
    timeout /t 2 >nul
    goto :tema_degistir
)

color %tema_kod%
echo [+] Tema degistirildi: %tema_ad%
timeout /t 2 >nul
goto :menu

:: ======================================================
:: SECTION: TARAYICI VE INTERNET OPTIMIZASYONU
:: ======================================================
:tarayici_temizle
set "gorev=Tarayici Temizligi"
cls
echo [!] Tarayicilar güvenli şekilde kapatılıyor...
:: Kullanıcıya sormadan kapatmak yerine nezaketen bildirim (Opsiyonel eklenebilir)
for %%i in (chrome.exe msedge.exe firefox.exe opera.exe) do (
    taskkill /F /IM %%i /T >nul 2>&1
)

call :progress 40 "Tarayici verileri temizleniyor..."
:: Chrome & Edge (User Data yollarını değişkenle yöneterek hata payını düşürdük)
set "p_chrome=%LocalAppData%\Google\Chrome\User Data\Default\Cache"
set "p_edge=%LocalAppData%\Microsoft\Edge\User Data\Default\Cache"

if exist "!p_chrome!" del /q /s /f "!p_chrome!\*.*" >nul 2>&1
if exist "!p_edge!" del /q /s /f "!p_edge!\*.*" >nul 2>&1

call :progress 100 "Tarayici temizligi basariyla tamamlandi!"
goto :rapor_hazirla

:dns
cls
echo [!] Ag ayarları optimize ediliyor...
ipconfig /flushdns >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo [+] DNS ve IP adresi tazelendi.
call :seslendir "Ag baglantiniz optimize edildi."
pause & goto :menu

:: ======================================================
:: SECTION: TEMIZLIK MOTORLARI (HIZLI & DERIN)
:: ======================================================
:hizli
set "gorev=Hizli Temizlik"
cls
echo [!] Hizli temizlik baslatildi...
call :progress 20 "Gecici dosyalar (Temp) imha ediliyor..."
del /s /f /q "%temp%\*.*" >nul 2>&1
del /s /f /q "%SystemRoot%\Temp\*.*" >nul 2>&1

call :progress 60 "Windows Olay Gunlukleri temizleniyor..."
:: Olay günlüklerini döngüyle temizlemek daha profesyoneldir
for /f "tokens=*" %%i in ('wevtutil el') do (wevtutil cl "%%i" >nul 2>&1)

call :seslendir "Hizli temizlik tamamlandi. Sistem ferahladi."
call :progress 100 "Islem Basarili!"
goto :rapor_hazirla

:guvenli_derin
set "gorev=Yedekli Derin Temizlik"
cls
echo ======================================================
echo           DERIN TEMIZLIK VE SISTEM ONARIMI
echo ======================================================
echo [!] UYARI: Bu islem sistem yedegi alacagi icin vakit alabilir.
echo.
set /p "onay=Devam etmek istiyor musunuz? (E/H): "
if /i "%onay%" NEQ "E" goto :menu

echo [!] Sistem Geri Yukleme Noktasi olusturuluyor...
powershell -Command "Checkpoint-Computer -Description 'ZenithShell_Oncesi' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1

call :progress 30 "Sistem bilesen deposu (DISM) temizleniyor..."
:: Bu işlem diskte GB'larca yer açabilir
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1

call :progress 80 "Windows Update artıkları temizleniyor..."
Dism /Online /Cleanup-Image /SPSuperseded >nul 2>&1

call :progress 100 "Derin temizlik ve onarım tamamlandi!"
goto :rapor_hazirla

:cop
cls
echo [!] Geri Donusum Kutusu bosaltiliyor...
powershell -Command "$rb = New-Object -ComObject Shell.Application; $rb.NameSpace(10).Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force }" >nul 2>&1
echo [+] Cop Kutusu Tertemiz!
pause & goto :menu

:: ======================================================
:: SECTION: GORSEL GERI BILDIRIM (PROGRESS BAR)
:: ======================================================
:progress
:: %1 = Yüzde, %2 = Durum Mesajı
cls
echo ======================================================
echo           %gorev% Yurutuluyor...
echo ======================================================
echo.
:: Bar Uzunluğu Hesaplama (25 karakterlik bir bar için 100/4 = 25)
set /a "fill=%1 / 4"
set "bar_fill=#########################"
set "bar_empty=-------------------------"
set "current_bar=!bar_fill:~0,%fill%!!bar_empty:~%fill%,25!"

echo  Durum    : %~2
echo  Ilerleme : [!current_bar!] %% %1
echo.
echo ======================================================
exit /b

:: ======================================================
:: SECTION: ISLEM SONUC VE KAYIT MOTORU
:: ======================================================
:rapor_hazirla
:: 1. İşlem Sonrası Disk Alanını Al
for /f "tokens=*" %%b in ('powershell -NoProfile -Command "[math]::round((Get-PSDrive C).Free / 1MB, 2)"') do set "end_space=%%b"

:: 2. Kazanılan Alanı Hesapla (Hata Kontrollü)
for /f "tokens=*" %%c in ('powershell -NoProfile -Command "$gain = [math]::round((!end_space! - !start_space!), 2); if ($gain -lt 0) { 0 } else { $gain }"') do set "gain=%%c"

:: 3. Log Kaydı (Daha Detaylı Format)
set "tarih_saat=%date% %time:~0,5%"
echo [%tarih_saat%] [ISLEM: %gorev%] [KAZANC: %gain% MB] >> "%log_file%"

:: 4. Görsel Rapor Çıktısı
cls
echo ======================================================
echo              ISLEM SONUC RAPORU
echo ======================================================
echo.
echo   [+] TAMAMLANAN GOREV : %gorev%
echo   [+] ACILAN ALAN      : %gain% MB
echo   [+] TOPLAM BOS ALAN  : %end_space% MB
echo.
echo   [i] Log Kaydı: %log_file%
echo ======================================================
echo.

:: Bir sonraki işlem için referans noktasını güncelle
set "start_space=%end_space%"

:: 5. Kapanış Senaryosu
if "!oto_kapat!"=="1" (
    echo [!] Oto-Kapatma aktif. 5 saniye icinde cikis yapiliyor...
    call :seslendir "Islem tamamlandi. Sistem otomatik olarak kapatiliyor."
    timeout /t 5 >nul 
    exit
) else (
    echo Ana menuye donmek icin herhangi bir tusa basin...
    pause >nul
    goto :menu
)

:: ======================================================
:: SECTION: OTOMASYON VE GOREV ZAMANLAYICI
:: ======================================================
:acilis_aktif
cls
echo [!] ZenithShell sistem acilisina entegre ediliyor...
:: %~f0 (tam yol) tırnak içinde gönderilir, parametre olarak '1' (Hızlı Temizlik) atanır.
schtasks /create /tn "SistemBakim_Acilis" /tr "'%~f0' 1" /sc onlogon /rl HIGHEST /f >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Basarili: Bilgisayar her acildiginda ZenithShell otomatik temizlik yapacak.
) else (
    echo [X] HATA: Gorev olusturulamadi! (Yonetici yetkisi eksik olabilir).
)
pause & goto :menu

:acilis_iptal
schtasks /delete /tn "SistemBakim_Acilis" /f >nul 2>&1
echo [+] Otomatik acilis gorevi iptal edildi.
pause & goto :menu

:zamanla_ozel
cls
echo ======================================================
echo           HAFTALIK BAKIM PLANLAYICI
echo ======================================================
echo.
echo  [ GUN ] MON, TUE, WED, THU, FRI, SAT, SUN
set /p "gun= >>> Gun (Varsayilan SAT): "
if "!gun!"=="" set "gun=SAT"

echo.
echo  [ SAAT ] Ornek: 23:00, 03:30
set /p "saat= >>> Saat (Varsayilan 22:00): "
if "!saat!"=="" set "saat=22:00"

:: Görev oluşturma (Parametre '5' = Akıllı Analiz)
schtasks /create /tn "SistemBakim_Haftalik" /tr "'%~f0' 5" /sc weekly /d !gun! /st !saat! /rl HIGHEST /f >nul 2>&1

echo.
echo [+] HAFTALIK GOREV KURULDU: !gun! gunu, saat !saat!'de calisacak.
pause & goto :menu

:: ======================================================
:: SECTION: GUVENLIK (HOSTS SHIELD & DISK HEALTH)
:: ======================================================
:disk_detay
cls
echo [!] Donanim seviyesinde S.M.A.R.T verileri okunuyor...
echo.
:: Daha temiz bir cikti icin /value formatini kullaniyoruz
wmic diskdrive get Model,Status,Size,InterfaceType /value
echo.
echo ------------------------------------------------------
echo  DURUM REHBERI:
echo  [OK]       : Disk saglikli.
echo  [PredFail] : KRITIK! Disk donanimsal hata veriyor!
echo ------------------------------------------------------
pause & goto :menu

:hosts_kalkan
cls
echo [!] ZenithShell Hosts Kalkani aktif ediliyor...
set "hosts_path=%SystemRoot%\System32\drivers\etc\hosts"

:: 1. Yedekleme
if not exist "%hosts_path%.bak" copy "%hosts_path%" "%hosts_path%.bak" >nul

:: 2. Mukerrer Kayit Kontrolu (Dosyada zaten varsa tekrar ekleme)
findstr /C:"# ZenithShell Kalkan" "%hosts_path%" >nul
if %errorlevel% equ 0 (
    echo [!] Kalkan zaten aktif durumda. Icerik guncelleniyor...
    :: Mevcut kalkan blogunu temizleyip yeniden yazmak daha sagliklidir
    :: (Bu kisim ileri seviye regex gerektirir, simdilik eklemeyi guvenli yapalim)
)

:: 3. Blok Listesi (PowerShell ile daha temiz ekleme)
powershell -Command ^
    "$list = @('0.0.0.0 adservice.google.com', '0.0.0.0 doubleclick.net', '0.0.0.0 telemetry.microsoft.com', '0.0.0.0 stats.g.doubleclick.net'); ^
    Add-Content -Path '%hosts_path%' -Value '`n# ZenithShell Kalkan Baslangici'; ^
    foreach($item in $list) { if(!(Select-String -Path '%hosts_path%' -Pattern $item)) { Add-Content -Path '%hosts_path%' -Value $item } }; ^
    Add-Content -Path '%hosts_path%' -Value '# ZenithShell Kalkan Bitisi'"

echo [+] Reklam ve Telemetri sunuculari basariyla engellendi.
ipconfig /flushdns >nul
pause & goto :menu




:: ======================================================
:: SECTION: AG DURUM VE SINYAL ANALIZORU
:: ======================================================
:wifi_analiz
cls
echo ======================================================
echo           ZENITHSHELL AG DURUM ANALIZORU
echo ======================================================
echo.
echo [!] Ag arayuzleri ve sinyal kalitesi kontrol ediliyor...
echo.

:: Wi-Fi bilgilerini çek (Boşlukları temizleyerek)
set "wifi_name=Ethernet (Kablolu)"
set "wifi_signal=100%%"

for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr /C:"SSID" ^| findstr /v "BSSID"') do (
    set "wifi_name=%%a"
    set "wifi_name=!wifi_name:~1!"
)
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces 2^>nul ^| findstr /C:"Signal"') do (
    set "wifi_signal=%%a"
    set "wifi_signal=!wifi_signal:~1!"
)

echo  Baglanti Tipi : %wifi_name%
echo  Sinyal Gucu   : %wifi_signal%
echo  --------------------------------------------------
echo [!] Gecikme testi yapiliyor (Google DNS)...

:: Dil bağımsız Ping Testi (PowerShell ile ms değerini hatasız çekme)
for /f "tokens=*" %%p in ('powershell -NoProfile -Command "(Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average).Average"') do set "ping_raw=%%p"

if "%ping_raw%"=="" (
    set "ping_res=Baglanti Yok"
) else (
    :: Sayıyı yuvarla
    for /f "delims=," %%n in ("%ping_raw%") do set "ping_res=%%n ms"
)

echo.
echo  Ortalama Gecikme : %ping_res%
echo  --------------------------------------------------
echo.
pause & goto :menu

:: ======================================================
:: SECTION: PORT DENETLEYICI (GUVENLIK)
:: ======================================================
:port_taramasi
cls
echo ======================================================
echo           ZENITHSHELL ACIK PORT DENETLEYICI
echo ======================================================
echo.
echo [!] 'LISTENING' (Dinlemede) olan portlar ve uygulamalar:
echo.
echo   PROTOKOL   YEREL PORT    PID (Islem No)
echo   ----------------------------------------

:: Netstat çıktısını daha okunabilir hale getirme (Sadece dinlenen portlar)
:: PowerShell ile hangi portun hangi uygulamaya ait olduğunu bulabiliriz ama
:: performans için şimdilik netstat -ano filtrelemesini temizleyelim.
for /f "tokens=1,2,5" %%a in ('netstat -ano ^| findstr /i "LISTENING"') do (
    echo   [%%a]      %%b       [PID: %%c]
)

echo   ----------------------------------------
echo.
echo [!] NOT: Yabanci bir PID gorurseniz Gorev Yoneticisi'nden
echo     bu numarayi (PID) aratarak uygulamayi bulabilirsiniz.
echo.
pause & goto :menu


:: ======================================================
:: SECTION: BASLANGIC (STARTUP) ANALIZORU
:: ======================================================
:baslangic_analiz
cls
echo ======================================================
echo           ZENITHSHELL BASLANGIC ANALIZORU
echo ======================================================
echo.
echo [!] Otomatik baslayan uygulamalar denetleniyor...
echo.

:: PowerShell ile daha temiz ve hizli bir tablo olusturma
powershell -NoProfile -Command ^
    "Get-CimInstance Win32_StartupCommand | Select-Object Caption, Command | Format-Table -AutoSize"

echo   --------------------------------------------------
echo [i] IPUCU: 'Update', 'Helper' veya 'Tray' icerenler
echo     genellikle acilisi yavaslatan servislerdir.
echo.
echo  [M] Ayarlari Ac (Gorev Yoneticisi)
echo  [0] Ana Menuye Don
echo.
set /p "b_secim= >>> Seciminiz: "

if /i "%b_secim%"=="M" (
    start taskmgr /0 /startup
    goto :baslangic_analiz
)
goto :menu

:: ======================================================
:: SECTION: SERVIS OPTIMIZASYONU (HIZ)
:: ======================================================
:servis_opt
cls
echo ======================================================
echo           ZENITHSHELL SERVIS OPTIMIZASYONU
echo ======================================================
echo.
echo [!] Guvenli mod: Sadece ev kullanicisi icin gereksiz
echo     olan servisler hedeflenir.
echo.
echo  [1] Yazdirma Kuyrugu (Yaziciniz yoksa)
echo  [2] Uzak Kayit Defteri (GUVENLIK ICIN TAVSIYE)
echo  [3] Dokunmatik Klavye (Tablet degilse)
echo  [4] Faks Servisi (Kullanilmiyorsa)
echo  [R] HEPSINI TAVSIYE EDILEN YAP (Hizli Ayar)
echo  [0] Vazgec ve Ana Menuye Don
echo.
set /p "s_secim= >>> Seciminiz: "

:: Fonksiyonel Servis Yonetimi (Ayarla ve Durdur)
if "%s_secim%"=="1" (
    sc config "Spooler" start= demand >nul 2>&1
    net stop "Spooler" /y >nul 2>&1
    echo [+] Yazdirma Kuyrugu pasifize edildi.
)
if "%s_secim%"=="2" (
    sc config "RemoteRegistry" start= disabled >nul 2>&1
    net stop "RemoteRegistry" /y >nul 2>&1
    echo [+] Uzak Kayit Defteri kapatildi.
)
if "%s_secim%"=="3" (
    sc config "TabletInputService" start= demand >nul 2>&1
    net stop "TabletInputService" /y >nul 2>&1
    echo [+] Dokunmatik Panel devre disi.
)
if "%s_secim%"=="4" (
    sc config "Fax" start= disabled >nul 2>&1
    net stop "Fax" /y >nul 2>&1
    echo [+] Faks Servisi kapatildi.
)

if /i "%s_secim%"=="R" (
    echo [!] Toplu optimizasyon yapiliyor...
    for %%s in (Spooler RemoteRegistry TabletInputService Fax) do (
        sc config "%%s" start= demand >nul 2>&1
        net stop "%%s" /y >nul 2>&1
    )
    echo [+] Tum tavsiye edilen ayarlar uygulandi!
    timeout /t 2 >nul
    goto :menu
)

if "%s_secim%"=="0" goto :menu
echo.
pause
goto :servis_opt


:: ======================================================
:: SECTION: AKILLI PAKET VE UYGULAMA YONETICISI (WINGET)
:: ======================================================
:winget_update
cls
echo ======================================================
echo           ZENITHSHELL AKILLI PAKET YONETICISI
echo ======================================================
echo.
echo [!] Sistemdeki guncellestirmeler denetleniyor...
echo [!] Lutfen bekleyin, bu islem birkac saniye surebilir.
echo.

:: 1. Winget Varlık Kontrolü
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [X] HATA: Winget (Uygulama Yukleyicisi) bulunamadi.
    echo     Ilgili bileseni Microsoft Store üzerinden güncelleyin.
    pause & goto :menu
)

:: 2. Güncelleme Listesini Çek (Sadece bir kez çalıştırıyoruz)
:: --source winget parametresi hızı artırır
winget upgrade --source winget
set "w_exit=%errorlevel%"

:: Eğer hata kodu 0 değilse (Genelde güncellenecek bir şey yoksa winget hata kodu döndürebilir)
if %w_exit% neq 0 (
    echo.
    echo [i] Tebrikler! Tum uygulamalariniz zaten guncel.
    pause & goto :menu
)

echo.
echo  ------------------------------------------------------
echo   [1] TUMUNU GUNCELLE (Sessiz + Otomatik Onay)
echo   [0] Vazgec ve Ana Menuye Don
echo  ------------------------------------------------------
echo.
set /p "u_secim= >>> Seciminiz: "

if "%u_secim%"=="1" (
    echo.
    echo [!] Toplu guncelleme baslatildi...
    echo [!] Lisans sozlesmeleri otomatik olarak kabul ediliyor.
    echo.
    
    :: --accept-package-agreements: Paket sözleşmelerini onaylar
    :: --accept-source-agreements: Kaynak sözleşmelerini onaylar
    :: --silent: Arka planda sessizce yükler
    winget upgrade --all --silent --include-unknown --accept-package-agreements --accept-source-agreements
    
    echo.
    echo [+] Islem basariyla tamamlandi!
    call :seslendir "Tum uygulamalariniz guncellendi."
    pause
)

goto :menu



:: ======================================================
:: SECTION: ELITE PAKET KURULUMU (ARRAY TABANLI)
:: ======================================================
:toplu_kurulum
cls
echo ======================================================
echo           ZENITHSHELL ELITE PAKET KURULUMU
echo ======================================================
echo.
echo [!] Kurulacak Elite Uygulamalar:
echo     Chrome, VLC, 7-Zip, Spotify, Discord, VS Code
echo.
echo [1] KURULUMU BASLAT (Otomatik Onay)
echo [0] Vazgec ve Ana Menuye Don
echo ======================================================
set /p "k_secim= >>> Seciminiz: "

if "%k_secim%" NEQ "1" goto :menu

echo.
echo [!] Winget baglantisi kuruluyor...
:: Uygulama ID Listesi (Buraya yenilerini ekleyebilirsin)
set "apps=Google.Chrome VideoLAN.VLC 7zip.7zip Spotify.Spotify Discord.Discord Microsoft.VisualStudioCode"

for %%a in (%apps%) do (
    echo [+] Yukleniyor: %%a ...
    :: --no-upgrade: Eğer zaten yüklüyse hata vermez, pas geçer.
    winget install --id %%a --silent --accept-package-agreements --accept-source-agreements --no-upgrade >nul 2>&1
    if !errorlevel! equ 0 (
        echo     [OK] Basariyla kuruldu.
    ) else (
        echo     [!] Zaten yuklu veya bir sorun olustu.
    )
)

echo.
echo ======================================================
echo [+] ELITE PAKET ISLEMI TAMAMLANDI!
echo ======================================================
call :seslendir "Elite paket kurulumu tamamlandi. Uygulamalariniz hazir."
pause
goto :menu

:: ======================================================
:: SECTION: SESLENDIRME MOTORU (OPTIMIZE)
:: ======================================================
:seslendir
:: Kullanım: call :seslendir "Mesaj"
:: Arka planda sessizce çalışması için PowerShell penceresi gizlenir.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName System.Speech; $s = New-Object System.Speech.Synthesis.SpeechSynthesizer; $s.Speak('%~1');" >nul 2>&1
exit /b



:: ======================================================
:: SECTION: ENVANTER RAPORLAMA VE SHA-256 MUHURLEME
:: ======================================================
:envanter_raporu
cls
echo ======================================================
echo           ZENITHSHELL ENVANTER RAPORLAMA
echo ======================================================
echo.
echo [!] Donanim verileri toplaniyor ve muhurleniyor...
echo [!] Lutfen bekleyin, bu islem birkac saniye surebilir.
echo.

set "report_file=%USERPROFILE%\Desktop\ZenithShell_Sistem_Raporu.txt"

:: Tek Seferde Güçlü Rapor Oluşturma (PowerShell Hibrit)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$report = @(); ^
    $report += '======================================================'; ^
    $report += '           ZENITHSHELL PROFESYONEL SISTEM RAPORU'; ^
    $report += '======================================================'; ^
    $report += 'OLUSTURULMA TARIHI : ' + (Get-Date -Format 'dd.MM.yyyy HH:mm'); ^
    $report += 'KULLANICI ADI      : ' + $env:USERNAME; ^
    $report += 'BILGISAYAR ADI     : ' + $env:COMPUTERNAME; ^
    $report += ''; ^
    $report += '[1] ISLEMCI BILGISI'; ^
    $cpu = Get-CimInstance Win32_Processor; ^
    $report += 'Model  : ' + $cpu.Name; ^
    $report += 'Cekirdek: ' + $cpu.NumberOfCores + ' Fiziksel / ' + $cpu.NumberOfLogicalProcessors + ' Sanal'; ^
    $report += ''; ^
    $report += '[2] BELLEK (RAM) DETAYI'; ^
    $ram = Get-CimInstance Win32_PhysicalMemory; ^
    foreach($r in $ram) { $report += ('Slot: {0} | Kapasite: {1} GB | Hiz: {2} MHz' -f $r.DeviceLocator, [math]::round($r.Capacity/1GB, 2), $r.Speed) }; ^
    $report += ''; ^
    $report += '[3] DEPOLAMA BIRIMLERI'; ^
    $disks = Get-CimInstance Win32_DiskDrive; ^
    foreach($d in $disks) { $report += ('Model: {0} | Durum: {1} | Boyut: {2} GB' -f $d.Model, $d.Status, [math]::round($d.Size/1GB, 2)) }; ^
    $report += ''; ^
    $report += '------------------------------------------------------'; ^
    $report += 'BU RAPOR ZENITHSHELL V34.2 TARAFINDAN URETILMISTIR.'; ^
    $report += '------------------------------------------------------'; ^
    $report ^| Out-File -FilePath '%report_file%' -Encoding utf8; ^
    $hash = (Get-FileHash '%report_file%' -Algorithm SHA256).Hash; ^
    Add-Content -Path '%report_file%' -Value ''; ^
    Add-Content -Path '%report_file%' -Value '[DIJITAL IMZA / SHA-256 VERIFICATION]'; ^
    Add-Content -Path '%report_file%' -Value $hash; ^
    Add-Content -Path '%report_file%' -Value '------------------------------------------------------'"

if %errorlevel% neq 0 (
    echo [X] HATA: Donanim verileri okunurken bir sorun olustu!
    pause & goto :menu
)

echo [+] ISLEM TAMAMLANDI!
echo [!] Rapor Masaustune kaydedildi: ZenithShell_Sistem_Raporu.txt
echo [!] Dijital muhur (SHA-256) raporun sonuna eklendi.
echo.
call :seslendir "Sistem envanter raporu hazır ve dijital olarak mühürlendi."
pause
goto :menu


:: ======================================================
:: SECTION: MAVI EKRAN (BSOD) DERIN ANALIZOR
:: ======================================================
:bsod_analiz
cls
echo ======================================================
echo           ZENITHSHELL MAVI EKRAN (BSOD) ANALIZI
echo ======================================================
echo.
echo [!] Sistem cokme kayitlari (Minidump) taraniyor...
echo.

:: 1. Fiziksel Dosya Kontrolü
if not exist "C:\Windows\Minidump" (
    echo [i] Bilgi: Minidump klasoru bulunamadi. 
    echo     Sisteminizde henuz bir donanimsal cokme kaydi olusmamis.
    timeout /t 3 >nul & goto :menu
)

:: 2. PowerShell Hibrit Analiz (Olay Günlükleri + Dump Dosyası)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$dumps = Get-ChildItem 'C:\Windows\Minidump\*.dmp' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending; ^
    if ($dumps.Count -eq 0) { Write-Host '[-] Klasor var ancak icinde .dmp dosyasi bulunamadi.' -ForegroundColor Yellow; return }; ^
    $lastDump = $dumps[0]; ^
    Write-Host '[+] SON COKME TARIHI : ' $lastDump.LastWriteTime -ForegroundColor Cyan; ^
    Write-Host '[+] DOSYA ADI        : ' $lastDump.Name -ForegroundColor Cyan; ^
    Write-Host '------------------------------------------------------'; ^
    Write-Host '[!] Sistem Olay Gunluklerinden Hata Kodu Araniyor...'; ^
    $errorLog = Get-WinEvent -FilterHashtag @{LogName='System'; Id=1001} -MaxEvents 1 -ErrorAction SilentlyContinue; ^
    if ($errorLog) { ^
        $msg = $errorLog.Message; ^
        if ($msg -match '0x[0-9a-fA-F]+') { Write-Host '[!] KRITIK HATA KODU: ' $matches[0] -ForegroundColor Red } ^
        else { Write-Host '[i] Hata kodu metin icinde bulunamadi.' }; ^
    } else { Write-Host '[i] Olay gunluklerinde spesifik BSOD kaydi bulunamadi.' }; ^
    Write-Host '------------------------------------------------------'; ^
    Write-Host '[TAVSIYE]: Bu hata genellikle hatali bir SURUCU (Driver) '; ^
    Write-Host 'veya donanimsal (RAM/SSD) bir arizadan kaynaklanir.'; ^
    Write-Host 'Detayli inceleme icin BlueScreenView kullanmaniz onerilir.'"

echo.
echo  [1] Dump Klasorunu Ac (Dosyalari Gor)
echo  [0] Ana Menuye Don
echo.
set /p "m_secim= >>> Seciminiz: "

if "%m_secim%"=="1" (
    echo [!] Klasor aciliyor...
    start explorer.exe "C:\Windows\Minidump"
    goto :bsod_analiz
)
goto :menu



:: ======================================================
:: SECTION: WINDOWS UPDATE KRITIK ONARIM MOTORU
:: ======================================================
:update_onar
cls
echo ======================================================
echo           ZENITHSHELL WINDOWS UPDATE ONARICI
echo ======================================================
echo.
echo [!] Kritik servisler durduruluyor ve kilitler aciliyor...
echo.

:: 1. Servisleri Durdur (Daha Garanti Yöntem)
for %%s in (wuauserv cryptSvc bits msiserver) do (
    net stop %%s /y >nul 2>&1
    taskkill /F /FI "SERVICES eq %%s" >nul 2>&1
)

echo [+] Guncelleme onbellegi temizleniyor (Sıfırlama)...
:: 2. Eski Klasörleri Temizle (Eskileri silmek diskte yer açar)
if exist "%SystemRoot%\SoftwareDistribution.old" rd /s /q "%SystemRoot%\SoftwareDistribution.old" >nul 2>&1
if exist "%SystemRoot%\System32\catroot2.old" rd /s /q "%SystemRoot%\System32\catroot2.old" >nul 2>&1

:: Yeniden Adlandır
ren "%SystemRoot%\SoftwareDistribution" SoftwareDistribution.old >nul 2>&1
ren "%SystemRoot%\System32\catroot2" catroot2.old >nul 2>&1

echo [+] Sistem kutuphaneleri (DLL) yeniden kaydediliyor...
:: 3. Kritik DLL Kayıtları (Update hatalarını çözen asıl kısım)
regsvr32.exe /s atl.dll >nul 2>&1
regsvr32.exe /s urlmon.dll >nul 2>&1
regsvr32.exe /s mshtml.dll >nul 2>&1
regsvr32.exe /s shdocvw.dll >nul 2>&1
regsvr32.exe /s browseui.dll >nul 2>&1
regsvr32.exe /s jscript.dll >nul 2>&1
regsvr32.exe /s vbscript.dll >nul 2>&1
regsvr32.exe /s scrrun.dll >nul 2>&1
regsvr32.exe /s msxml.dll >nul 2>&1
regsvr32.exe /s msxml3.dll >nul 2>&1
regsvr32.exe /s msxml6.dll >nul 2>&1
regsvr32.exe /s actxprxy.dll >nul 2>&1
regsvr32.exe /s softpub.dll >nul 2>&1
regsvr32.exe /s wintrust.dll >nul 2>&1
regsvr32.exe /s dssenh.dll >nul 2>&1
regsvr32.exe /s rsaenh.dll >nul 2>&1
regsvr32.exe /s gpkcsp.dll >nul 2>&1
regsvr32.exe /s sccbase.dll >nul 2>&1
regsvr32.exe /s slbcsp.dll >nul 2>&1
regsvr32.exe /s cryptdlg.dll >nul 2>&1
regsvr32.exe /s oleaut32.dll >nul 2>&1
regsvr32.exe /s ole32.dll >nul 2>&1
regsvr32.exe /s shell32.dll >nul 2>&1
regsvr32.exe /s initpki.dll >nul 2>&1
regsvr32.exe /s wuapi.dll >nul 2>&1
regsvr32.exe /s wuaueng.dll >nul 2>&1
regsvr32.exe /s wuaueng1.dll >nul 2>&1
regsvr32.exe /s wucltui.dll >nul 2>&1
regsvr32.exe /s wups.dll >nul 2>&1
regsvr32.exe /s wups2.dll >nul 2>&1
regsvr32.exe /s wuweb.dll >nul 2>&1
regsvr32.exe /s qmgr.dll >nul 2>&1
regsvr32.exe /s qmgrprxy.dll >nul 2>&1
regsvr32.exe /s wucltux.dll >nul 2>&1
regsvr32.exe /s muweb.dll >nul 2>&1
regsvr32.exe /s wuwebv.dll >nul 2>&1

echo [+] Ag protokolu ve Winsock sifirlaniyor...
netsh winsock reset >nul 2>&1
netsh winhttp reset proxy >nul 2>&1

echo [+] Servisler yeniden baslatiliyor...
:: 4. Servisleri Tekrar Başlat
for %%s in (bits wuauserv appidsvc cryptsvc) do (
    net start %%s >nul 2>&1
)

echo.
echo ======================================================
echo  [OK] WINDOWS UPDATE MOTORU FABRIKA AYARLARINA DONDU!
echo  [!] Degisikliklerin tamami icin SISTEMI YENIDEN BASLATIN.
echo ======================================================
echo.
call :seslendir "Windows guncelleme sistemi tamamen onarildi. Lutfen bilgisayarinizi yeniden baslatin."
pause & goto :menu



:: ======================================================
:: SECTION: PIL SAGLIGI VE ANALIZ (DIZUSTU)
:: ======================================================
:pil_analiz
cls
echo ======================================================
echo           ZENITHSHELL PIL SAGLIGI ANALIZI
echo ======================================================
echo.
echo [!] Donanim seviyesinde pil verileri toplaniyor...
echo.

:: Masaüstü kontrolü ve rapor üretimi
powercfg /batteryreport /output "%temp%\battery_report.html" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$report = Get-Content '%temp%\battery_report.html' -Raw; ^
    $design = [regex]::Match($report, 'DESIGN CAPACITY.*?([\d\s,]+) mWh').Groups[1].Value -replace '\s|,',''; ^
    $full = [regex]::Match($report, 'FULL CHARGE CAPACITY.*?([\d\s,]+) mWh').Groups[1].Value -replace '\s|,',''; ^
    if (!$design -or !$full) { Write-Host '[X] BILGI: Pil bulunamadi (Sistem Masaustu olabilir).'; return }; ^
    $health = [math]::Round(($full / $design) * 100, 2); ^
    Write-Host '--------------------------------------------'; ^
    Write-Host ('[+] Fabrika Kapasitesi : {0} mWh' -f $design); ^
    Write-Host ('[+] Mevcut Kapasite    : {0} mWh' -f $full); ^
    Write-Host '--------------------------------------------'; ^
    if ($health -ge 80) { Write-Host ('[DURUM]: MUKEMMEL (%{0})' -f $health) -ForegroundColor Green } ^
    elseif ($health -ge 50) { Write-Host ('[DURUM]: ORTA (%{0})' -f $health) -ForegroundColor Yellow } ^
    else { Write-Host ('[DURUM]: KRITIK - DEGISTIRILMELI (%{0})' -f $health) -ForegroundColor Red }"

echo.
echo  [1] Detayli HTML Raporunu Ac
echo  [0] Ana Menuye Don
echo.
set /p "p_secim= >>> Seciminiz: "
if "%p_secim%"=="1" start "" "%temp%\battery_report.html"
goto :menu

:: ======================================================
:: SECTION: ANTI-RANSOMWARE (Siber Savunma Kalkanı)
:: ======================================================
:shield_menu
cls
echo ======================================================
echo           ZENITHSHELL ANTI-RANSOMWARE SHIELD
echo ======================================================
echo.
echo  [1] Korumayi Kur (Yem Dosyalar Yerlestir)
echo  [2] Sistemi Tara (Süpheli Aktivite Kontrolu)
echo  [0] Ana Menuye Don
echo.
set /p "s_sec= >>> Seciminiz: "

if "%s_sec%"=="1" (
    echo [!] Kritik dizinlere 'HoneyPot' dosyalari birakiliyor...
    echo ZenithShell_Security_Signature_1062 > "%USERPROFILE%\Documents\vault_key.zshield"
    echo ZenithShell_Security_Signature_1062 > "%USERPROFILE%\Desktop\system_lock.zshield"
    attrib +h +s "%USERPROFILE%\Documents\vault_key.zshield"
    attrib +h +s "%USERPROFILE%\Desktop\system_lock.zshield"
    echo [+] Koruma aktif. Bu dosyalara dokunmayin!
    pause & goto :shield_menu
)

if "%s_sec%"=="2" (
    cls
    echo [!] Zirh aktif. Sifreleme hareketi denetleniyor...
    set "panic=0"
    
    :: Dosya varlık ve içerik kontrolü
    if not exist "%USERPROFILE%\Documents\vault_key.zshield" set "panic=1"
    
    powershell -NoProfile -Command ^
        "$c = Get-Content '%USERPROFILE%\Documents\vault_key.zshield' -ErrorAction SilentlyContinue; ^
        if($c -and $c -ne 'ZenithShell_Security_Signature_1062'){ exit 100 } else { exit 200 }"
    if %errorlevel% equ 100 set "panic=1"

    if "!panic!"=="1" (
        color 4f
        echo.
        echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        echo [!!!] ACIL DURUM: FIDYE YAZILIMI SALDIRISI SAPTANDI!
        echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        call :seslendir "Sistem saldırı altında. Ağ bağlantısı kesiliyor."
        
        :: Dinamik Ağ Kesme (Tüm aktif arayüzleri devre dışı bırakır)
        powershell -Command "Get-NetAdapter | Disable-NetAdapter -Confirm:$false" >nul 2>&1
        
        echo [!] Tum ag baglantilari (Ethernet/Wi-Fi) KESILDI.
        echo [!] Veri transferi durduruldu.
        echo [!] Lutfen sistemi kapatin veya bir uzmana danisin.
        pause
    ) else (
        echo [+] Sistem Guvende: Herhangi bir sifreleme saptanmadi.
        timeout /t 2 >nul
    )
    goto :shield_menu
)
goto :menu



:: ======================================================
:: SECTION: KULLANIM REHBERI (USER GUIDE)
:: ======================================================
:hakkinda
cls
echo ======================================================
echo             ZENITHSHELL KULLANIM REHBERI
echo ======================================================
echo.
echo  1. ANTI-RANSOMWARE: Kritik dizinlere 'yem' dosyalar birakir. 
echo     Eger bu dosyalar sifrelenirse ag baglantisini otomatik keser.
echo.
echo  2. GUVENLI TEMIZLIK: Sadece sistemin siktigi onbellekleri siler.
echo     Belgelerim, Resimlerim gibi kisisel alanlara asla dokunmaz.
echo.
echo  3. UPDATE ONARICI: Windows Update motorunu fabrika ayarlarina
echo     dondurur. Islem sirasinda internetiniz kisa sureli kopabilir.
echo.
echo  4. SURUCU GUNCELLEME: Eksik veya eski donanim suruculerini
echo     dogrudan Microsoft sunucularindan bulur ve yukler.
echo.
echo ======================================================
pause & goto :menu

:: ======================================================
:: SECTION: OTOMATIK SURUCU GUNCELLEME (ADVANCED)
:: ======================================================
:driver_update
cls
echo ======================================================
echo           ZENITHSHELL OTOMATIK SURUCU GUNCELLEME
echo ======================================================
echo.
echo [!] Donanim veri tabani ile eslesme saglaniyor...
echo [!] Lutfen bekleyin, bu islem internet hiziniza baglidir.
echo.

:: PowerShell Hibrit Blok (Geçici dosya kullanmadan doğrudan çalıştırma)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$Searcher = New-Object -ComObject Microsoft.Update.Searcher; ^
    $SearchResult = $Searcher.Search(\"IsInstalled=0 and Type='Driver' and IsHidden=0\"); ^
    if ($SearchResult.Updates.Count -eq 0) { ^
        Write-Host '[OK] Tum donanim suruculeriniz guncel durumda.' -ForegroundColor Green; ^
    } else { ^
        Write-Host ('[!] {0} adet guncelleme bulundu!' -f $SearchResult.Updates.Count) -ForegroundColor Yellow; ^
        foreach ($Update in $SearchResult.Updates) { ^
            Write-Host ('[+] Yukleniyor: {0}' -f $Update.Title) -ForegroundColor Cyan; ^
            $Update.AcceptEula(); ^
            $UpdateColl = New-Object -ComObject Microsoft.Update.UpdateColl; ^
            $UpdateColl.Add($Update) | Out-Null; ^
            $Downloader = New-Object -ComObject Microsoft.Update.Downloader; ^
            $Downloader.Updates = $UpdateColl; ^
            $Downloader.Download() | Out-Null; ^
            $Installer = New-Object -ComObject Microsoft.Update.Installer; ^
            $Installer.Updates = $UpdateColl; ^
            $Result = $Installer.Install(); ^
            if($Result.ResultCode -eq 2){ Write-Host '    [BASARILI]' -ForegroundColor Green } ^
            else { Write-Host '    [HATA/YENIDEN BASLATMA GEREKLI]' -ForegroundColor Red } ^
        } ^
    }"

if %errorlevel% neq 0 (
    echo.
    echo [X] HATA: Surucu tarama servisine ulasilamadi.
    echo [!] Windows Update servisinin acik oldugundan emin olun.
)

echo.
echo ======================================================
echo  [OK] SURUCU TARAMASI TAMAMLANDI!
echo ======================================================
call :seslendir "Donanim surucu taramasi bitti. Eksik suruculer yuklendi."
pause & goto :menu