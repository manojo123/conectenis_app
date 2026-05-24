adb start-server | Out-Null
$service = adb mdns services 2>&1 | Select-String '_adb-tls-connect' | Select-Object -First 1
if ($service) {
  $address = ($service.ToString() -split '\s+')[-1]
  adb connect $address
  Write-Host "Connected to $address"
  $devices = adb devices -l 2>&1 | Select-String 'RXGL20BCPVE'
  if ($devices) {
    Write-Host "Flutter device id prefix: adb-RXGL20BCPVE"
    Write-Host "Run 'flutter devices' to see the full wireless device id."
  }
} else {
  Write-Host "No wireless device found. On your phone: Developer options -> Wireless debugging -> ON, then pair/connect."
  exit 1
}
