# Bu dosya donanım sensörlerinden sıcaklık bilgisini okur.
$dllPath = "$PSScriptRoot\LibreHardwareMonitorLib.dll"

# Eğer DLL dosyası klasörde yoksa hata verme, "DLL_YOK" yaz.
if (!(Test-Path $dllPath)) {
    Write-Output "DLL_YOK"
    exit
}

# Donanım kütüphanesini PowerShell'e tanıt.
Add-Type -Path $dllPath

# Donanım izleme motorunu başlat.
$pc = New-Object LibreHardwareMonitor.Hardware.Computer
$pc.IsCpuEnabled = $true
$pc.Open()

# İşlemci (CPU) sıcaklığını bulana kadar donanımları tara.
$cpuTemp = "N/A"
foreach ($hw in $pc.Hardware) {
    if ($hw.HardwareType -eq "Cpu") {
        $hw.Update()
        foreach ($sensor in $hw.Sensors) {
            # Sıcaklık sensörünü ve ana paket sıcaklığını bul.
            if ($sensor.SensorType -eq "Temperature" -and ($sensor.Name -like "*Package*" -or $sensor.Name -like "*Core*")) {
                $cpuTemp = [math]::Round($sensor.Value, 1)
                break
            }
        }
    }
}

$pc.Close()
# Bulunan sıcaklığı ekrana (Batch dosyasına) gönder.
Write-Output $cpuTemp