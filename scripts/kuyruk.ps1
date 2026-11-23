# VideoTurko kuyruk.ps1: bir klasordeki planlari sirayla uretir, kaldigi yerden devam eder.
# EN: renders every plan folder in order with uret.ps1 and resumes where it stopped.
# Kullanim / usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kuyruk.ps1 -Klasor <ROOT>\planlar -Kare 56 -W 384 -H 672
#   -Kare verilmezse uret.ps1 kendi varsayilanini kullanir (209; -InitImg ile 192) / without -Kare, uret.ps1 picks its own default
#   -Kuru : her plan icin uret.ps1 -Kuru calistirir, GPU kullanmaz, dosya yazmaz / dry run, no GPU, writes nothing
# Plan klasoru: istem.txt (zorunlu), ilk.png|jpg|jpeg (istege bagli), son.png|jpg|jpeg (istege bagli; ilk kare ister).
# Her plana yazilanlar: video.avi, uret.log, kuyruk_sonuc.txt (uret.ps1 cikis kodu).
# Kalite ayarlarina dokunmaz: yalniz uret.ps1'i cagirir. Sonuc 0 (GECTI) ya da 5 (RED, video duruyor, karar kullanicinin) olan plan
# yeniden uretilmez. RED bir plani tekrar uretmek icin o klasordeki kuyruk_sonuc.txt dosyasini silin. -Kare/-W/-H, istem.txt ya da ilk/son
# gorsel degistiyse plan atlanmaz, yeniden uretilir (kuyruk_sonuc.txt ikinci satiri: parametre imzasi).
# Durdurma: <Klasor>\DUR dosyasi; calisan klip bittikten sonra kuyruk durur. Calisan klibi de kesmek icin <VT_ROOT>\DUR (uret.ps1).
# Cikis: 0 = hepsi GECTI ya da atlandi; 5 = hepsi uretildi ama en az biri RED (videoyu izleyin); 1 = en az bir plan hata verdi; 2 = durduruldu; 3 = girdi hatasi; 6 = kalite kapisi calisamiyor.
param(
    [Parameter(Mandatory)][string]$Klasor,
    [int]$Kare = 0,
    [int]$W = 0,
    [int]$H = 0,
    [switch]$Kuru
)
$ErrorActionPreference = 'Continue'
# VT_KUYRUK_URET yalniz testte (VT_KUYRUK_TEST=1) gecerlidir; normal kullanimda hep bu klasordeki uret.ps1 calisir (maintainers, after PR #9).
$Uret = $(if ($env:VT_KUYRUK_URET -and $env:VT_KUYRUK_TEST -eq '1') { $env:VT_KUYRUK_URET } else { Join-Path $PSScriptRoot 'uret.ps1' })
if (-not (Test-Path -LiteralPath $Klasor -PathType Container)) { Write-Output "HATA: klasor yok: $Klasor"; exit 3 }
if (-not (Test-Path -LiteralPath $Uret -PathType Leaf)) { Write-Output "HATA: uret.ps1 bulunamadi"; exit 3 }
if (($W -gt 0) -ne ($H -gt 0)) { Write-Output 'HATA: -W ve -H birlikte verilmeli'; exit 3 }

function Bul-Kare([string]$Dizin, [string]$Ad) {
    foreach ($u in 'png', 'jpg', 'jpeg') {
        $y = Join-Path $Dizin "$Ad.$u"
        if (Test-Path -LiteralPath $y -PathType Leaf) { return $y }
    }
    return $null
}

function DosyaHash([string]$p) {
    if (Get-Command Get-FileHash -ErrorAction SilentlyContinue) {
        return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.Substring(0, 16)
    }
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $fs = [System.IO.File]::OpenRead($p)
        try {
            $bytes = $sha.ComputeHash($fs)
            return (-join ($bytes | ForEach-Object { $_.ToString('x2') })).ToUpper().Substring(0, 16)
        } finally {
            $fs.Dispose()
        }
    } catch {
        return ''
    }
}

$sirala = { [regex]::Replace($_.Name, '\d+', { param($m) $m.Value.PadLeft(8, '0') }) }
$planlar = @(Get-ChildItem -LiteralPath $Klasor -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'istem.txt') } | Sort-Object $sirala)
if ($planlar.Count -eq 0) { Write-Output 'HATA: istem.txt iceren plan klasoru yok'; exit 3 }

$gecti = 0; $red = 0; $hata = 0; $atlandi = 0; $cikis = 0
foreach ($p in $planlar) {
    $d = $p.FullName
    $sonucDosya = Join-Path $d 'kuyruk_sonuc.txt'
    $video = Join-Path $d 'video.avi'
    $imza = "kare=$Kare w=$W h=$H istem=" + (DosyaHash (Join-Path $d 'istem.txt'))
    foreach ($g in @((Bul-Kare $d 'ilk'), (Bul-Kare $d 'son'))) { if ($g) { $imza += ' ' + (Split-Path -Leaf $g) + '=' + (DosyaHash $g) } }
    if (-not $Kuru -and (Test-Path -LiteralPath $sonucDosya) -and (Test-Path -LiteralPath $video)) {
        $eskiSatir = @(Get-Content -LiteralPath $sonucDosya -TotalCount 2)
        $eski = $eskiSatir[0]
        $eskiImza = $(if ($eskiSatir.Count -gt 1) { $eskiSatir[1] } else { '' })
        if (($eski -eq '0' -or $eski -eq '5') -and $eskiImza -eq $imza) { $atlandi++; Write-Output "ATLANDI: $($p.Name) (sonuc $eski)"; continue }
        if ($eski -eq '0' -or $eski -eq '5') { Write-Output "YENIDEN: $($p.Name) (parametre ya da istem degisti)" }
    }
    if (Test-Path -LiteralPath (Join-Path $Klasor 'DUR')) { Write-Output 'DURDU: DUR dosyasi bulundu'; $cikis = 2; break }

    $ilk = Bul-Kare $d 'ilk'; $son = Bul-Kare $d 'son'
    if ($son -and -not $ilk) { Write-Output "HATA: $($p.Name): son kare var, ilk kare yok"; $hata++; continue }
    $arg = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Uret, '-Istem', (Join-Path $d 'istem.txt'), '-Cikti', $video)
    if ($Kare -gt 0) { $arg += @('-Kare', "$Kare") }
    if ($W -gt 0) { $arg += @('-W', "$W", '-H', "$H") }
    if ($ilk) { $arg += @('-InitImg', $ilk) }
    if ($son) { $arg += @('-EndImg', $son) }
    if ($Kuru) {
        & powershell.exe @($arg + '-Kuru')
        $k = $LASTEXITCODE
        if ($k -ne 0) { Write-Output "HATA: $($p.Name): kuru deneme cikis $k"; $hata++ } else { $gecti++ }
        continue
    }

    Remove-Item -LiteralPath $sonucDosya, $video -Force -ErrorAction SilentlyContinue
    Write-Output "BASLADI: $($p.Name)"
    $t0 = Get-Date
    & powershell.exe @arg *>&1 | Out-File -LiteralPath (Join-Path $d 'uret.log') -Encoding utf8
    $k = $LASTEXITCODE
    $dk = [Math]::Round(((Get-Date) - $t0).TotalMinutes, 1)
    if ($k -eq 2) { Write-Output "DURDU: $($p.Name) uretim sirasinda durduruldu"; $cikis = 2; break }
    if ($k -eq 6) { Write-Output "KAPI CALISMADI: $($p.Name) (cikis 6); kuyruk durdu, uret.log dosyasina bakin"; $cikis = 6; break }
    if (($k -eq 0 -or $k -eq 5) -and (Test-Path -LiteralPath $video)) {
        Set-Content -LiteralPath $sonucDosya -Value @("$k", $imza) -Encoding ascii
        if ($k -eq 0) { $gecti++; Write-Output "GECTI: $($p.Name) ($dk dk)" }
        else { $red++; Write-Output "RED: $($p.Name) ($dk dk); video duruyor, izleyip karar verin" }
    } else {
        $hata++; Write-Output "HATA: $($p.Name) cikis $k ($dk dk); uret.log dosyasina bakin, sonraki plana geciliyor"
    }
}
Write-Output "OZET: plan=$($planlar.Count) gecti=$gecti red=$red hata=$hata atlandi=$atlandi"
if ($cikis -ne 0) { exit $cikis }
if ($hata -gt 0) { exit 1 }
if ($red -gt 0) { exit 5 }
exit 0
