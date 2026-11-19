<#
Model indirici / dogrulayici (VideoTurko). Yalniz scripts/modeller.json icindeki commit-sabit adres + boyut + sha256.
Models downloader/verifier: pinned commit URLs + size + sha256 only. Weights are NOT distributed by this repo.

  -Kuru          (varsayilan) yalniz rapor: disk, var/yok, boyut. Indirmez, hash hesaplamaz. / report only
  -Dogrula       mevcut dosyalarin boyut + sha256'sini denetler (uzun surer: ~31 GB okunur). / verify only
  -Baslat        eksik/bozuk dosyalari indirir (.part + Range devam). -LisansKabul gerekir. / download
  -LisansKabul E (ya da Y)  docs/LISANS_KABUL.txt gosterildikten sonra kabul: TR "E" / EN "Y".
                 Kabul <Hedef>\.lisans_kabul.txt dosyasina yazilir. Parametresiz -Baslat metni gosterir ve DURUR (cikis 2).
  -Hedef         model klasoru (varsayilan E:\minimax_h3\model). Diskte >= 32 GiB bos (-MinBosGiB).
Durdurma: <Hedef>\DUR ya da bu betigin yanindaki DUR dosyasi olusturulursa indirme temiz durur, DURDU yazar; .part korunur,
yeniden -Baslat kaldigi yerden surer. Pencere acmaz; gizli calistirmak icin:
  Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-File','modelleri_indir.ps1','-Baslat','-LisansKabul','E'
Cikis kodu: 0 tamam, 1 hata/eksik, 2 lisans kabul gerekli, 3 disk yetersiz, 4 DURDU.
#>
param(
    [switch]$Kuru,
    [switch]$Dogrula,
    [switch]$Baslat,
    [string]$LisansKabul = '',
    [string]$Hedef = 'E:\minimax_h3\model',
    [string]$Kayit = (Join-Path $PSScriptRoot 'modeller.json'),
    [string]$LisansDosya = (Join-Path $PSScriptRoot '..\docs\LISANS_KABUL.txt'),
    [double]$MinBosGiB = 32
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ($Baslat -or $Dogrula)) { $Kuru = $true }

$izinliSonek = @('huggingface.co', 'hf.co')   # yonlendirme icin izinli ana alanlar (alt alanlariyla)

function Sha256([string]$yol) { (Get-FileHash -Algorithm SHA256 -LiteralPath $yol).Hash.ToLower() }

function Guvenli-Hedef([string]$kok, [string]$goreli) {
    $kokTam = [IO.Path]::GetFullPath($kok).TrimEnd('\') + '\'
    $tam = [IO.Path]::GetFullPath((Join-Path $kok $goreli))
    if (-not $tam.StartsWith($kokTam, [StringComparison]::OrdinalIgnoreCase)) { throw "hedef kok disina cikiyor: $goreli" }
    return $tam
}

function Https-Dogrula([string]$url) {
    $u = [Uri]$url
    if ($u.Scheme -ne 'https') { throw "yalniz https: $url" }
    $ok = $false
    foreach ($s in $izinliSonek) { if ($u.Host -eq $s -or $u.Host.EndsWith('.' + $s)) { $ok = $true } }
    if (-not $ok) { throw "izinli olmayan alan: $($u.Host)" }
}

function Dur-Var { (Test-Path -LiteralPath (Join-Path $Hedef 'DUR')) -or (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'DUR')) }

function Bos-GiB([string]$yol) {
    $kok = [IO.Path]::GetPathRoot([IO.Path]::GetFullPath($yol))
    $d = New-Object IO.DriveInfo($kok)
    return [math]::Round($d.AvailableFreeSpace / 1GB, 1)
}

function Iste([string]$url, [long]$baslangic) {
    # yonlendirmeyi elle izle (her adim https + izinli alan), Range ile ac
    $adres = $url
    for ($i = 0; $i -lt 6; $i++) {
        Https-Dogrula $adres
        $r = [Net.HttpWebRequest]::Create($adres)
        $r.AllowAutoRedirect = $false
        $r.UserAgent = 'VideoTurko-modelleri-indir'
        $r.Timeout = 60000
        $r.ReadWriteTimeout = 60000
        if ($baslangic -gt 0) { $r.AddRange([long]$baslangic) }
        try { $resp = $r.GetResponse() }
        catch [Net.WebException] {
            $resp = $_.Exception.Response
            if ($null -eq $resp) { throw }
        }
        $kod = [int]$resp.StatusCode
        if ($kod -ge 300 -and $kod -lt 400) {
            $adres = ([Uri]::new([Uri]$adres, $resp.Headers['Location'])).AbsoluteUri
            $resp.Close()
            continue
        }
        if ($kod -ne 200 -and $kod -ne 206) { $resp.Close(); throw "HTTP $kod : $adres" }
        return $resp
    }
    throw "cok fazla yonlendirme: $url"
}

function Indir($k, [string]$hedefYol, [string]$Sha256Beklenen) {
    if ([string]::IsNullOrWhiteSpace($Sha256Beklenen) -or $Sha256Beklenen.Length -ne 64) { throw "sha256 sabiti yok/gecersiz: $($k.hedef) (indirme reddedildi)" }
    $part = "$hedefYol.part"
    $boyut = [long]$k.boyut
    $var = 0L
    if (Test-Path -LiteralPath $part) {
        $var = (Get-Item -LiteralPath $part).Length
        if ($var -gt $boyut) {
            Remove-Item -LiteralPath $part -Force
            Write-Warning "bozuk .part (beklenenden buyuk) silindi: $(Split-Path $part -Leaf); bastan iner"
            $var = 0L
        }
    }
    if ($var -lt $boyut) {
        $resp = Iste $k.url $var
        $kod = [int]$resp.StatusCode
        $mod = [IO.FileMode]::Append
        if ($var -gt 0 -and $kod -ne 206) { $mod = [IO.FileMode]::Create; $var = 0L; Write-Warning 'sunucu Range kabul etmedi; bastan iniyor' }
        elseif ($var -eq 0) { $mod = [IO.FileMode]::Create }
        $akis = $resp.GetResponseStream()
        $fs = New-Object IO.FileStream($part, $mod, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        try {
            $tampon = New-Object byte[] (4MB)
            $toplam = $var
            $sonYuzde = -1
            while ($true) {
                if (Dur-Var) {
                    $fs.Flush(); $fs.Close(); $resp.Close()
                    Write-Host 'DURDU (DUR dosyasi bulundu); .part korundu, -Baslat ile devam eder'
                    exit 4
                }
                $n = $akis.Read($tampon, 0, $tampon.Length)
                if ($n -le 0) { break }
                $fs.Write($tampon, 0, $n)
                $toplam += $n
                $y = [int](100 * $toplam / $boyut)
                if ($y -ne $sonYuzde -and ($y % 5) -eq 0) { Write-Host ("  {0}: %{1} ({2:N0} / {3:N0} bayt)" -f $k.adim, $y, $toplam, $boyut); $sonYuzde = $y }
            }
        } finally { $fs.Close(); $resp.Close() }
    }
    $son = (Get-Item -LiteralPath $part).Length
    if ($son -ne $boyut) {
        Write-Warning "indirme eksik kaldi ($son / $boyut); .part korundu, -Baslat ile devam et"
        return $false
    }
    Write-Host "  $($k.adim): sha256 hesaplaniyor (birkac dk)..."
    $h = Sha256 $part
    if ($h -ne $Sha256Beklenen) {
        Remove-Item -LiteralPath $part -Force
        Write-Warning "sha256 TUTMADI, bozuk .part silindi: $($k.hedef) | beklenen $Sha256Beklenen | gelen $h | Yeniden -Baslat ile temiz iner."
        return $false
    }
    if (Test-Path -LiteralPath $hedefYol) { Remove-Item -LiteralPath $hedefYol -Force }
    Move-Item -LiteralPath $part -Destination $hedefYol
    Write-Host "  $($k.adim): TAMAM, sha256 dogru"
    return $true
}

# ---- ana akis ----
$liste = (Get-Content -Raw -LiteralPath $Kayit -Encoding UTF8 | ConvertFrom-Json)
$dosyalar = @($liste.dosyalar)
$toplamBayt = ($dosyalar | ForEach-Object { [long]$_.boyut } | Measure-Object -Sum).Sum
Write-Output ("Hedef: {0} | dosya: {1} | toplam: {2:N2} GiB" -f $Hedef, $dosyalar.Count, ($toplamBayt / 1GB))

$bos = $null
try { $bos = Bos-GiB $Hedef } catch { }
$eksikBayt = 0L
$durum = @()
foreach ($k in $dosyalar) {
    $yol = Guvenli-Hedef $Hedef $k.hedef
    $boyut = [long]$k.boyut
    $d = 'YOK'
    if (Test-Path -LiteralPath $yol) {
        $len = (Get-Item -LiteralPath $yol).Length
        if ($len -ne $boyut) { $d = "BOYUT_YANLIS ($len)"; $eksikBayt += $boyut }
        elseif ($Dogrula) {
            Write-Output "  dogrulaniyor: $($k.hedef) ..."
            if ((Sha256 $yol) -eq $k.sha256) { $d = 'TAMAM (boyut+sha256)' } else { $d = 'SHA256_YANLIS'; $eksikBayt += $boyut }
        } else { $d = 'VAR (boyut dogru; hash icin -Dogrula)' }
    } elseif (Test-Path -LiteralPath "$yol.part") {
        $plen = (Get-Item -LiteralPath "$yol.part").Length
        $d = "YARIM (.part {0:N0} / {1:N0})" -f $plen, $boyut
        $eksikBayt += [math]::Max(0, $boyut - $plen)
    } else { $eksikBayt += $boyut }
    $durum += [pscustomobject]@{ adim = $k.adim; dosya = $k.hedef; durum = $d }
    Write-Output ("  {0,-10} {1,-52} {2}" -f $k.adim, $k.hedef, $d)
}
$eksikGiB = [math]::Round($eksikBayt / 1GB, 2)
$bosYaz = '?'
if ($null -ne $bos) { $bosYaz = $bos }
Write-Output ("Eksik/indirilecek: {0} GiB | bos disk: {1} GiB | gereken en az: {2} GiB" -f $eksikGiB, $bosYaz, $MinBosGiB)

$tamam = ($durum | Where-Object { $_.durum -notlike 'TAMAM*' -and $_.durum -notlike 'VAR*' }).Count -eq 0
if (-not $Baslat) {
    if ($tamam) { Write-Output 'HAZIR (dosyalar var)'; exit 0 }
    Write-Output 'EKSIK: indirmek icin -Baslat -LisansKabul E'
    exit 1
}

# ---- indirme kapilari ----
if ($tamam) { Write-Output 'Tum dosyalar zaten var ve boyutlari dogru. Hash icin -Dogrula.'; exit 0 }
if ($null -ne $bos -and $eksikGiB -gt 0 -and $bos -lt $MinBosGiB) {
    Write-Output "DISK YETERSIZ: bos $bos GiB < gereken $MinBosGiB GiB. Indirme baslamadi."
    exit 3
}
if ($LisansKabul -notin @('E', 'e', 'Y', 'y')) {
    Write-Output ''
    if (Test-Path -LiteralPath $LisansDosya) { Get-Content -LiteralPath $LisansDosya -Encoding UTF8 | Write-Output }
    else { Write-Output ("Lisans: MiniMax H3 Community License: " + $liste.lisans_metni) }
    Write-Output ''
    Write-Output 'Okuyup kabul ediyorsaniz ayni komutu "-LisansKabul E" (TR) ya da "-LisansKabul Y" (EN) ile tekrar calistirin. Indirme BASLAMADI.'
    exit 2
}
if (-not (Test-Path -LiteralPath $Hedef)) { New-Item -ItemType Directory -Path $Hedef -Force | Out-Null }
Set-Content -LiteralPath (Join-Path $Hedef '.lisans_kabul.txt') -Encoding UTF8 -Value ("kabul ({0}): {1}`nmetin: {2}" -f $LisansKabul.ToUpper(), (Get-Date -Format 'yyyy-MM-dd HH:mm'), $liste.lisans_metni)

$hata = $false
$indirilen = 0
$atlanan = 0
foreach ($k in $dosyalar) {
    $yol = Guvenli-Hedef $Hedef $k.hedef
    if ((Test-Path -LiteralPath $yol) -and ((Get-Item -LiteralPath $yol).Length -eq [long]$k.boyut)) { Write-Output "  atlandi (var, YALNIZ boyutla kontrol edildi): $($k.adim)"; $atlanan++; continue }
    Write-Output "Indiriliyor: $($k.ad)"
    # Not (bekci sahte pozitif): sha256 Indir() icinde, indirme biter bitmez, satir ~130-134'te Get-FileHash ile modeller.json sabitine karsi dogrulanir; sabit bos ise Indir reddeder.
    $beklenenSha = $k.sha256
    if (Indir $k $yol -Sha256Beklenen $beklenenSha) { $indirilen++ } else { $hata = $true }
}
if ($hata) { Write-Output 'EKSIK/HATA: yukaridaki uyarilara bak. Yarim .part varsa -Baslat kaldigi yerden surer; sha256 tutmayip silinen dosya BASTAN iner.'; exit 1 }
Write-Output ('HAZIR: {0} dosya indirildi (sha256 dogrulandi), {1} dosya var oldugu icin atlandi (yalniz boyut kontrolu; tam dogrulama: -Dogrula)' -f $indirilen, $atlanan)
exit 0
