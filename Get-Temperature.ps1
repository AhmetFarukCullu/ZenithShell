# Get-Temperature.ps1
function Get-CPU-Temp {
    try {
        # Bazı sistemlerde 'MSAcpi_ThermalZoneTemperature' veriyi verir
        $t = Get-WmiObject -Query "SELECT CurrentTemperature FROM MSAcpi_ThermalZoneTemperature" -Namespace "root\wmi" -ErrorAction Stop
        $tempCelsius = ($t.CurrentTemperature / 10) - 273.15
        return [math]::Round($tempCelsius, 1)
    } catch {
        return "N/A" # Veri alınamazsa
    }
}

$cpuTemp = Get-CPU-Temp
Write-Output $cpuTemp