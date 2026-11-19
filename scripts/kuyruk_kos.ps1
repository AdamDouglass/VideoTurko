# kuyruk_kos.ps1 (kuyruk kosucusu)
# Tek kalici kuyruk kosucusu. Istemci yalniz kuyruk.txt'ye SATIR EKLER; kosucu sirayla kosar, BITTI/HATA yazar, hatada DURMAZ.
# Satir (kuyruk\kuyruk.txt, ekleme-yalniz):   id | komut | bagimlilik (id ya da -) | [BEKLIYOR ya da ozet=<dosya>] | [kabul komutu: kosucu yok sayar, operator kullanir]
#   komut      : bir powershell komut satiri. GPU isi ise komutun kendisi kilidi cagirir (kaynak_kilidi.py calistir --kaynak gpu ...).
#   4. sutun "ozet=<dosya>" ise: dosya doluysa ve 'neden=bitti' icermiyorsa cikis kodu 0 olsa da HATA sayilir (sik_hatalar #12: bos cikis kodu).
# Durum kuyruk.txt'de DEGIL ayri dosyada: <Dizin>\kuyruk_durum.txt  ("id | DURUM | saat | not"; DURUM: KOSUYOR BITTI HATA ATLANDI). Sebep:
#   ajanlar kuyruk.txt'ye ekleme yaparken kosucu ayni dosyayi yeniden yazarsa yaris olur (toplanti K1 "durum" sutunu bu dosyaya tasindi).
# Kalp atisi (K2): her 30 sn <Dizin>\kalp.txt (deney id, alt surec PID, saat) + ortak\panel.txt tek satir.
# DUR_TA proje kokunde olusursa her satir basinda ve bekleme dongusunde DURDU yazip cikar; yeniden baslatinca BITTI/HATA/ATLANDI satirlarini atlar.
# Hicbir dosyayi SILMEZ. Gizli pencere. Tek ornek: <Dizin>\kuyruk_kos.pid.
# Kullanim:  powershell -NoProfile -WindowStyle Hidden -File kuyruk_kos.ps1 [-Dizin <klasor>] [-BitinceCik] [-Kuru]
param(
  [string]$Dizin = "$Root\runs\kuyruk",
  [string]$OlayDosyasi = "$Root\runs\olaylar.txt",
  [string]$Panel = "$Root\ortak\panel.txt",
  [string]$Yedek = "$Root\ortak\hazir_yedek.txt",
  [int]$YedekBostaDk = 10,
  [switch]$BitinceCik,
  [switch]$Kuru
)
$ErrorActionPreference = 'Continue'
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
$p = "$Root"
. "$p\src\araclar\oku_paylasimli.ps1"
$sdAdi = $(if ($env:KOS_SDCLI_ADI) { $env:KOS_SDCLI_ADI } else { 'sd-cli' }); $sonSiraOlay = Get-Date; $kuyruk = "$Dizin\kuyruk.txt"; $durumDs = "$Dizin\kuyruk_durum.txt"; $kalp = "$Dizin\kalp.txt"; $pidDs = "$Dizin\kuyruk_kos.pid"; $olay = $OlayDosyasi
New-Item -ItemType Directory -Force $Dizin | Out-Null

function Yaz-Satir($dosya, $metin) { $by = (New-Object Text.UTF8Encoding($false)).GetBytes($metin + "`r`n"); foreach ($k in 1..8) { try { $fs = [IO.File]::Open($dosya, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]"ReadWrite,Delete"); $fs.Write($by, 0, $by.Length); $fs.Close(); return } catch { Start-Sleep -Milliseconds 300 } } try { Set-Content -LiteralPath $Panel ("YAZMA_HATA {0} {1}" -f (Get-Date -Format "HH:mm:ss"), $dosya) -ErrorAction SilentlyContinue } catch {} }  # operator 00:30: sessiz kayip yok
function Olay($m) { Yaz-Satir $olay ("{0} | {1}" -f (Get-Date -Format 'HH:mm:ss'), $m) }
function Durum-Yaz($id, $d, $not) { Yaz-Satir $durumDs ("{0} | {1} | {2} | {3}" -f $id, $d, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $not) }
function Durumlar() {
  $h = @{}; $t = if (Test-Path $durumDs) { Oku-Paylasimli $durumDs } else { '' }
  foreach ($l in ($t -split "`r?`n")) { $a = $l -split '\s\|\s'; if ($a.Count -ge 2 -and $a[0].Trim()) { $h[$a[0].Trim()] = $a[1].Trim() } }
  return $h }
function Satirlar() {
  $t = if (Test-Path $kuyruk) { Oku-Paylasimli $kuyruk } else { $null }
  if ($null -eq $t) { return @() }
  $r = @(); $no = 0; foreach ($l in ($t -split "`r?`n")) { $no++; $l = $l.TrimStart([char]0xFEFF); if (-not $l.Trim() -or $l.TrimStart().StartsWith('#')) { continue }
    $a = $l -split '\s\|\s'; if ($a.Count -lt 2) { continue }
    $r += [pscustomobject]@{ no = $no; kol = $a.Count; d4 = $(if ($a.Count -ge 4) { $a[3].Trim() } else { '' }); id = $a[0].Trim(); komut = $a[1].Trim(); bag = $(if ($a.Count -ge 3) { $a[2].Trim() } else { '-' }); ozet = $(if ($a.Count -ge 4 -and $a[3].Trim() -like 'ozet=*') { $a[3].Trim().Substring(5) } else { '' }); beklenenHata = ($a.Count -ge 5 -and $a[4].Trim() -eq 'beklenen_hata') } }
  return $r }
function Panel-Yaz($m) { foreach ($k in 1..5) { try { Set-Content -LiteralPath $Panel $m -Encoding utf8 -ErrorAction Stop; return } catch { Start-Sleep -Milliseconds 200 } } }
function Kalp($id, $pid2) { foreach ($k in 1..5) { try { Set-Content -LiteralPath $kalp ("{0} | {1} | pid {2}" -f $id, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $pid2) -ErrorAction Stop; return } catch { Start-Sleep -Milliseconds 200 } } }
# operator 01:30 (yonetici): kuyruk dogrulama. Hata varsa KUYRUK_HATA yazilir ve HICBIR satir baslatilmaz (DERLEME4 ad cakismasi: durum alani eksik satir
# sessizce atlandi, bagimli B56H derlemesiz kostu). 1) ayni id iki kez (baslangicta var olanlar KUYRUK_UYARI, yeni olanlar HATA); 2) durumu olmayan satirda
# durum alani (4. sutun) yok ya da 'BEKLIYOR' / 'ozet=...' degil; 3) bagimlilik dosyada olmayan id'ye isaret ediyor (bagimli is baglandigi satirin BITTI'si olmadan baslamaz zaten; id tekil olunca yanlis BITTI okunmaz).
$script:baslangicDup = @{}
function Kuyruk-Hatalari($sat, $dur) {
  $h = @(); $say = @{}; foreach ($s in $sat) { if ($say.ContainsKey($s.id)) { $say[$s.id] += @($s.no) } else { $say[$s.id] = @($s.no) } }
  foreach ($k in $say.Keys) { if ($say[$k].Count -gt 1 -and -not $script:baslangicDup.ContainsKey($k)) { $h += ("ayni ad {0} kez: {1} (satir {2})" -f $say[$k].Count, $k, ($say[$k] -join ',')) } }
  foreach ($s in $sat) {
    if (-not $dur.ContainsKey($s.id)) {
      if ($s.kol -lt 4) { $h += ("durum alani eksik: {0} (satir {1}, sutun {2}; 4. sutun BEKLIYOR ya da ozet=... olmali)" -f $s.id, $s.no, $s.kol) }
      elseif ($s.d4 -ne 'BEKLIYOR' -and $s.d4 -notlike 'ozet=*') { $h += ("durum alani gecersiz: {0} (satir {1}, '{2}')" -f $s.id, $s.no, $s.d4) }
      if ($s.bag -ne '-' -and $s.bag -ne '' -and -not $say.ContainsKey($s.bag)) { $h += ("bagimlilik yok: {0} -> {1} (satir {2})" -f $s.id, $s.bag, $s.no) }
    } }
  return $h }
# operator 09:58 (#25): sd-cli disindaki kisa satirlar (kapi betikleri p*_kapi.ps1 vb.) da canli olabilir; devralmada HATA yazmadan once bekle.
function Cocuk-Canli($ids, $sat) {
  $r = @()
  foreach ($id in $ids) {
    $s = @($sat | Where-Object { $_.id -eq $id }) | Select-Object -First 1; if (-not $s) { continue }
    $tok = @($s.komut -split '\s+' | Where-Object { $_ -like '*.ps1' -or $_ -like '*.py' }) | Select-Object -Last 1; if (-not $tok) { continue }
    $ad = [IO.Path]::GetFileName($tok)
    $r += @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessId -ne $PID -and $_.Name -match 'powershell|python' -and $_.CommandLine -and $_.CommandLine.Contains($ad) -and $_.CommandLine -notmatch 'kuyruk_kos' })
  }
  return $r }
function Yedek-Ekle($sat, $dur) {
  # yedek havuz (yonetici onayi 2026-11-19): yalniz onayli hazir_yedek.txt; GPU >=YedekBostaDk dk bos, DUR_TA yok, son 10 dk HATA yok, kuyrukta bekleyen yok, id kuyrukta yok; en cok 1 satir
  if (-not (Test-Path $Yedek)) { return }
  if (((Get-Date) - $bostaBas).TotalMinutes -lt $YedekBostaDk) { return }
  if (Test-Path "$p\DUR_TA") { return }
  if (@(Bekleyen $sat $dur).Count -gt 0) { return }
  if (@(Get-Process -Name $sdAdi -ErrorAction SilentlyContinue).Count -gt 0) { return }
  $dt = Oku-Paylasimli $durumDs
  foreach ($l in ($dt -split "`r?`n")) { $a = $l -split '\s\|\s'; if ($a.Count -ge 3 -and $a[1].Trim() -eq 'HATA') { $z = [datetime]::MinValue; if ([datetime]::TryParse($a[2].Trim(), [ref]$z) -and ((Get-Date) - $z).TotalMinutes -lt 10) { return } } }
  $var = @{}; foreach ($x in $sat) { $var[$x.id] = 1 }
  foreach ($l in ((Oku-Paylasimli $Yedek) -split "`r?`n")) { $l = $l.TrimStart([char]0xFEFF); if (-not $l.Trim() -or $l.TrimStart().StartsWith('#')) { continue }
    $a = $l -split '\s\|\s'; if ($a.Count -lt 4) { continue }; $id = $a[0].Trim(); if ($var.ContainsKey($id) -or $dur.ContainsKey($id)) { continue }
    if ($Kuru) { Olay "YEDEK_HAVUZ (kuru): $id eklenecekti"; return }
    Yaz-Satir $kuyruk $l.TrimEnd(); Olay "YEDEK_HAVUZ: $id basliyor (GPU bosta, onayli hazir_yedek.txt)"; return }
}
function Tekrar-Id-Kontrol($sat, $dur) {
  # operator istegi 2026-11-19: satirin KENDI id'si durumda BITTI/HATA/ATLANDI iken komut metni o id'nin son KOSUYOR kaydindan farkliysa = id yeniden kullanilmis (eski sonuc yeni sanilir, kosmaz): KUYRUK_HATA bir kez yaz
  if (-not $script:tekrarYazildi) { $script:tekrarYazildi = @{} }
  $t = if (Test-Path $durumDs) { Oku-Paylasimli $durumDs } else { '' }; $son = @{}
  foreach ($l in ($t -split "`r?`n")) { $a = $l -split '\s\|\s', 4; if ($a.Count -ge 4 -and $a[1].Trim() -eq 'KOSUYOR') { $son[$a[0].Trim()] = $a[3].Trim() } }
  foreach ($x in $sat) {
    $d = $dur[$x.id]; if ($d -notin @('BITTI', 'HATA', 'ATLANDI')) { continue }
    if ($son.ContainsKey($x.id) -and $son[$x.id] -ne $x.komut -and -not $script:tekrarYazildi.ContainsKey($x.id)) {
      $script:tekrarYazildi[$x.id] = $true
      Olay ("KUYRUK_HATA: {0} tekrar kullanilmis (durum {1} ama satirin komutu o kosudakinden FARKLI); satir CALISMAZ, bagimlilari eski sonucu gorur: yeni id ile ekle" -f $x.id, $d) } }
}
function Tavan-Kontrol($sat, $dur) {
  # ders #27: hiz_kos3 satirinda -TavanDk yoksa varsayilan 50 dk uzun kosuyu keser; bekleyen satir icin bir kez KUYRUK_UYARI
  if (-not $script:tavanYazildi) { $script:tavanYazildi = @{} }
  foreach ($x in (Bekleyen $sat $dur)) {
    if ($x.komut -match 'hiz_kos3' -and $x.komut -notmatch '-TavanDk' -and -not $script:tavanYazildi.ContainsKey($x.id)) {
      $script:tavanYazildi[$x.id] = $true
      Olay ("KUYRUK_UYARI: {0} satirinda -TavanDk YOK (hiz_kos3 varsayilani 50 dk uzun kosuyu keser; tahmin x 1,4 yaz)" -f $x.id) } }
}
function Bekleyen($sat, $dur) { return @($sat | ? { -not $dur.ContainsKey($_.id) }) }

if ($Kuru) { "KURU: dizin=$Dizin satir=$((Satirlar).Count) durum=$((Durumlar).Count) panel=$Panel"; exit 0 }
# tek ornek
if (Test-Path $pidDs) { $eski = (Get-Content $pidDs -ErrorAction SilentlyContinue | Select -First 1); if ($eski -and (Get-Process -Id ([int]$eski) -ErrorAction SilentlyContinue)) { "RET: kuyruk kosucusu zaten calisiyor (PID $eski)"; exit 2 } }
Set-Content $pidDs $PID
Olay "KUYRUK KOSUCUSU basladi (PID $PID)"
# onceki kosucu olduyse KOSUYOR kalmis satirlari yarim say (sessizce atlanmasin)
$dd = Durumlar; $yarim = @($dd.Keys | Where-Object { $dd[$_] -eq 'KOSUYOR' }); $canli0 = @(Get-Process -Name $sdAdi -ErrorAction SilentlyContinue)
$cocuk0 = @(Cocuk-Canli $yarim (Satirlar))
if ($yarim.Count -gt 0 -and $cocuk0.Count -gt 0 -and $canli0.Count -eq 0) {
  Olay ("KOSUYOR (devralindi cocuk surec pid {0}): {1} satiri icin kapi/kisa betik bekleniyor, HATA yazilmadi" -f $cocuk0[0].ProcessId, ($yarim -join ','))
  while (@(Cocuk-Canli $yarim (Satirlar)).Count -gt 0) { if (Test-Path "$p\DUR_TA") { break }; Kalp ('DEVRALINDI-' + ($yarim -join ',')) $cocuk0[0].ProcessId; Start-Sleep -Seconds 5 }
  Olay ("DEVRALINDI bitti: {0} icin cocuk surec sona erdi; sonuc yazilmadi (BITTI/HATA satirini operator yazsin; bagimli satirlar bekler, ZINCIR DUSMEZ)" -f ($yarim -join ','))
} elseif ($yarim.Count -gt 0 -and $canli0.Count -gt 0) {
  # operator 00:30 (operator istegi): yeniden baslatmada canli sd-cli varsa ikinci kopya BASLATMA, durum dosyasini yeniden yazma; bitmesini bekle
  Olay ("KOSUYOR (devralindi pid {0}): {1} satiri icin canli sd-cli bekleniyor, durum yeniden yazilmadi" -f $canli0[0].Id, ($yarim -join ','))
  while (@(Get-Process -Name $sdAdi -ErrorAction SilentlyContinue).Count -gt 0) { if (Test-Path "$p\DUR_TA") { break }; Kalp ('DEVRALINDI-' + ($yarim -join ',')) $canli0[0].Id; Panel-Yaz ("DEVRALINDI canli sd-cli pid {0} | {1} | kalp {2}" -f $canli0[0].Id, ($yarim -join ','), (Get-Date -Format 'HH:mm:ss')); Start-Sleep -Seconds 10 }
  Olay ("DEVRALINDI bitti: {0} icin sd-cli sona erdi; sonuc yazilmadi (BITTI/HATA satirini operator yazsin; bagimli satirlar bekler)" -f ($yarim -join ','))
} else {
  foreach ($k in $yarim) { Durum-Yaz $k 'HATA' 'kosucu yeniden basladi, onceki kosu yarim kaldi'; Olay "$k HATA: kosucu yeniden basladi, onceki kosu yarim (yeniden denemek icin yeni id ile satir ekle)" }
}
$bostaBas = Get-Date; $sonKalp = [datetime]::MinValue; $sonKuyrukHata = ''; $sonKuyrukHataZ = [datetime]::MinValue
# baslangicta var olan tekrar adlari gecmis sayilir (UYARI); yalniz yeni tekrar KUYRUK_HATA verir
$bs = Satirlar; $sy = @{}; foreach ($s in $bs) { if ($sy.ContainsKey($s.id)) { $sy[$s.id]++ } else { $sy[$s.id] = 1 } }
foreach ($k in $sy.Keys) { if ($sy[$k] -gt 1) { $script:baslangicDup[$k] = $true; Olay ("KUYRUK_UYARI: baslangicta ayni ad {0} kez: {1} (gecmis kayit; yeni tekrar KUYRUK_HATA verir)" -f $sy[$k], $k) } }
while ($true) {
  if (Test-Path "$p\DUR_TA") { Olay "DURDU: kuyruk kosucusu DUR_TA gordu"; Durum-Yaz '-' 'DURDU' 'DUR_TA'; break }
  $sat = Satirlar; $dur = Durumlar
  Tekrar-Id-Kontrol $sat $dur
  Tavan-Kontrol $sat $dur
  $kh = @(Kuyruk-Hatalari $sat $dur)
  if ($kh.Count -gt 0) {
    $khOz = $kh -join ' ; '
    if ($khOz -ne $sonKuyrukHata -or ((Get-Date) - $sonKuyrukHataZ).TotalSeconds -ge 300) { $sonKuyrukHata = $khOz; $sonKuyrukHataZ = Get-Date; Olay ("KUYRUK_HATA: {0} | satir baslatilmiyor; operator kuyrugu duzeltene kadar bekleniyor" -f $khOz) }
    Panel-Yaz ("KUYRUK_HATA {0} | kalp {1}" -f $khOz, (Get-Date -Format 'HH:mm:ss')); Kalp 'KUYRUK_HATA' 0
    if (Test-Path "$p\DUR_TA") { Olay "DURDU: kuyruk kosucusu DUR_TA gordu"; Durum-Yaz '-' 'DURDU' 'DUR_TA'; break }
    Start-Sleep -Seconds 10; continue }
  $sonKuyrukHata = ''
  # siradaki: durumu olmayan ve bagimliligi BITTI olan ilk satir; bagimli oldugu HATA/ATLANDI ise ATLANDI
  $sec = $null
  foreach ($s in (Bekleyen $sat $dur)) {
    if ($s.bag -eq '-' -or $s.bag -eq '') { $sec = $s; break }
    $bd = $dur[$s.bag]
    if ($bd -eq 'BITTI') { $sec = $s; break }
    if ($bd -eq 'HATA' -or $bd -eq 'ATLANDI') { Durum-Yaz $s.id 'ATLANDI' "bagimlilik $($s.bag) $bd"; Olay "KUYRUK_ZINCIR_DUSTU: $($s.id) ATLANDI (bagimlilik $($s.bag) $bd); zinciri kurtarmak icin yeni id ile satir ekle"; $dur[$s.id] = 'ATLANDI'; continue }
  }
  if (-not $sec) {
    if (((Get-Date) - $sonKalp).TotalSeconds -ge 30) { $sonKalp = Get-Date; $b = [int]((Get-Date) - $bostaBas).TotalMinutes
      Panel-Yaz ("BOSTA {0} dk | kuyruk: {1} BEKLIYOR | kalp {2}" -f $b, (@(Bekleyen $sat $dur)).Count, (Get-Date -Format 'HH:mm:ss')); Kalp 'BOSTA' 0 }
    if (((Get-Date) - $sonSiraOlay).TotalSeconds -ge 300) { $sonSiraOlay = Get-Date; $bk = (@(Bekleyen $sat $dur)).Count; Olay ("SIRA_BITTI: calisacak satir yok (bekleyen={0}, bagimliligi bekleyen/dusen dahil), bosta {1} dk | YONETICI/operator: kuyruga is ekle" -f $bk, [int]((Get-Date) - $bostaBas).TotalMinutes) }
    Yedek-Ekle $sat $dur
    if ($BitinceCik -and (@(Bekleyen $sat $dur)).Count -eq 0) { Olay "KUYRUK BOS, cikiliyor (-BitinceCik)"; break }
    Start-Sleep -Seconds 10; continue }
  # operator 00:30 (operator istegi): canli sd-cli ya da GPU kilidi varsa ikinci kopya BASLATMA; bitmesini bekle, durum dosyasini yeniden yazma
  $canli = @(Get-Process -Name $sdAdi -ErrorAction SilentlyContinue)
  if ($canli.Count -gt 0) {
    Olay ("BEKLE: canli sd-cli pid {0} var, {1} baslatilmadi (devralindi: bitmesi bekleniyor, ikinci kopya yok)" -f $canli[0].Id, $sec.id)
    while (@(Get-Process -Name $sdAdi -ErrorAction SilentlyContinue).Count -gt 0) {
      if (Test-Path "$p\DUR_TA") { break }
      Kalp ('BEKLE-' + $sec.id) $canli[0].Id; Panel-Yaz ("BEKLE canli sd-cli pid {0} | siradaki {1} | kalp {2}" -f $canli[0].Id, $sec.id, (Get-Date -Format 'HH:mm:ss')); Start-Sleep -Seconds 10 }
    Olay ("BEKLE bitti: canli sd-cli kalmadi, {0} yeniden degerlendirilecek" -f $sec.id)
    continue
  }
  Durum-Yaz $sec.id 'KOSUYOR' $sec.komut; Olay "$($sec.id) basliyor"
  $kalan = (@(Bekleyen $sat $dur)).Count - 1; if ($kalan -lt 2) { Olay ("KUYRUK_AZ: {0} basladi, geriye {1} bekleyen satir kaldi (<2): GPU bosalmadan satir ekle" -f $sec.id, $kalan) }
  $t0 = Get-Date
  $sp = Start-Process powershell -ArgumentList @('-NoProfile', '-WindowStyle', 'Hidden', '-Command', $sec.komut) -WindowStyle Hidden -PassThru
  while (-not $sp.HasExited) {
    Kalp $sec.id $sp.Id
    Panel-Yaz ("KOSUYOR {0} pid {1} | {2} dk | kalp {3}" -f $sec.id, $sp.Id, [int]((Get-Date) - $t0).TotalMinutes, (Get-Date -Format 'HH:mm:ss'))
    $sonKalp = Get-Date
    for ($i = 0; $i -lt 30 -and -not $sp.HasExited; $i++) { Start-Sleep -Seconds 1 }
    if (Test-Path "$p\DUR_TA") { Olay "$($sec.id) DUR_TA goruldu; alt surec kendi korkuluguyla durur, bekleniyor (en cok 5 dk)"; $sp.WaitForExit(300000) | Out-Null; break }
  }
  $ec = if ($sp.HasExited) { $sp.ExitCode } else { '?' }
  $sn = [int]((Get-Date) - $t0).TotalSeconds; $ok = ($ec -eq 0)
  $ozetMetin = ''
  # ozet 'neden=bitti' ya da 'neden=DUR: adim N tamam (profil)' (adim sondasinin BASARILI bitisi, operator 01:50) ise basarili; ham log taramasi asagida [E] varsa yine HATA yapar
  if ($sec.ozet) { $ot = if (Test-Path $sec.ozet) { Oku-Paylasimli $sec.ozet } else { $null }; $ozetMetin = (($ot -replace '\s+', ' ')).Trim(); if ($ozetMetin -notmatch 'neden=(bitti|DUR: adim \d+ tamam)') { $ok = $false } }
  # ham log taramasi (yanlis yesil onlemi): ozet_<ad>.txt yaninda ham_out_<ad>.txt / ham_err_<ad>.txt; '[E]', 'compute failed', 'ALLOC_FAILED', 'cudaMalloc' -> HATA.
  # 'cannot make enough memory' kapi mesaji tek basina HATA degil (desen listesinde yok). Beklenen-hata probu: 5. sutun 'beklenen_hata' -> tarama kapali, notta etiketlenir.
  if ($ok -and $sec.ozet -and ($sec.ozet -match '[\\/]ozet_([^\\/]+)\.txt$')) {
    $ad = $Matches[1]; $dz = Split-Path -Parent $sec.ozet; $bulgu = ''
    foreach ($hf in @("ham_out_$ad.txt", "ham_err_$ad.txt")) { $yol = Join-Path $dz $hf
      if (Test-Path -LiteralPath $yol) { $ht = (Oku-Paylasimli $yol) -replace "`0", ''
        $m = [regex]::Match($ht, '(?m)^.*(\[E\]|compute failed|ALLOC_FAILED|cudaMalloc).*$'); if ($m.Success) { $bulgu = "$hf : " + $m.Value.Trim().Substring(0, [Math]::Min(120, $m.Value.Trim().Length)); break } } }
    if ($bulgu) { if ($sec.beklenenHata) { $ozetMetin += " | HAM-LOG-HATA (beklenen_hata, BITTI kalir): $bulgu" } else { $ok = $false; $ozetMetin += " | HAM-LOG-HATA: $bulgu" } }
  }
  if ($ok) { Durum-Yaz $sec.id 'BITTI' "cikis=$ec sure=${sn}sn"; Olay "$($sec.id) BITTI: cikis=$ec sure=${sn} sn $ozetMetin" }
  else { Durum-Yaz $sec.id 'HATA' "cikis=$ec sure=${sn}sn"; Olay "$($sec.id) HATA: cikis=$ec sure=${sn} sn $ozetMetin | kuyruk durmaz, siradakine gecilir" }
  $bostaBas = Get-Date; $sonSiraOlay = Get-Date
  $kalan2 = (@(Bekleyen (Satirlar) (Durumlar))).Count; if ($kalan2 -eq 0) { Olay "SIRA_BITTI: $($sec.id) bitti, kuyrukta bekleyen satir YOK, GPU bosa dusuyor" } elseif ($kalan2 -lt 2) { Olay "KUYRUK_AZ: $($sec.id) bitti, bekleyen=$kalan2 (<2)" }
}
Remove-Item -LiteralPath $pidDs -ErrorAction SilentlyContinue


