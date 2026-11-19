param([Parameter(Mandatory)][string]$Dizin, [Parameter(Mandatory)][string]$Ad, [Parameter(Mandatory)][int]$Kare, [switch]$DokuNorm)
$Root = $(if($env:VT_ROOT){$env:VT_ROOT}else{(Resolve-Path (Join-Path $PSScriptRoot '..')).Path})

# URETIM_KAPI: genel CPU gorsel kapi; parametreler Dizin, Ad, Kare (beklenen kare sayisi). gurultu <= 1,5 VE orta akis > 0,05 VE kare sayisi = Kare ise GECER; degilse RED (olaylar, cikis 1). Pafta 12 kare: select mod(n,ceil(Kare/12)).
$p=$Root; $d=$(if([IO.Path]::IsPathRooted($Dizin)){$Dizin}else{Join-Path "$p\runs" $Dizin}); $ev="$p\runs\olaylar.txt"
function Yaz($m){ $s="{0} | {1}" -f (Get-Date -Format "HH:mm:ss"),$m; foreach($k in 1..8){ try{ $fs=[IO.File]::Open($ev,"Append","Write","ReadWrite"); $by=(New-Object Text.UTF8Encoding($false)).GetBytes($s+"`r`n"); $fs.Write($by,0,$by.Length); $fs.Close(); break }catch{ Start-Sleep -Milliseconds 400 } } }
$avi="$d\$Ad.avi"; if(-not (Test-Path $avi) -and (Test-Path "$d\${Ad}l.avi")){ $avi="$d\${Ad}l.avi" }
if(-not (Test-Path $avi)){ Yaz "KAPI RED: avi yok ($d)"; exit 1 }
foreach($lg in "ham_out_$Ad.txt","ham_err_$Ad.txt"){ $lp="$d\$lg"; if(Test-Path $lp){ if(Select-String -Path $lp -Pattern 'temporal tiling|retrying with|vae decode compute failed' -Quiet){ Yaz "KAPI RED: $lg icinde karolu VAE yedegi/VAE hatasi (K-17: karolu cikti gecersiz); video kullanilmaz"; exit 1 } } }
$py=$(if($env:VT_PYTHON){$env:VT_PYTHON}else{'python'})
$o = & $py -I "$PSScriptRoot\dikis_denetim.py" $avi 2>&1 | Out-String
$t=($o -replace '\s+',' ').Trim()
$m=[regex]::Match($o,'kare=(\d+) gurultu=([0-9.]+).*?orta akis=([0-9.]+)')
if(-not $m.Success){ Yaz "KAPI RED: dikis_denetim cikti ayristirilamadi: $($t.Substring(0,[Math]::Min(200,$t.Length)))"; exit 1 }
$kare=[int]$m.Groups[1].Value; $gur=[double]::Parse($m.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture); $ak=[double]::Parse($m.Groups[3].Value,[Globalization.CultureInfo]::InvariantCulture)
& $(if($env:VT_FFMPEG){$env:VT_FFMPEG}else{'ffmpeg'}) -v error -y -i $avi -vf "select='not(mod(n,$([int][Math]::Ceiling($Kare/12))))',scale=320:-1,tile=4x3" -frames:v 1 "$d\pafta_$Ad.png"
if($DokuNorm){ $dn = (& $py -I "$PSScriptRoot\doku_norm.py" $avi 2>&1 | Out-String).Trim(); Yaz "DOKU_NORM (bilgi, kapi degil): $dn" }
$ok = ($kare -eq $Kare) -and ($gur -le 1.5) -and ($ak -gt 0.05)
if($ok){ Yaz "KAPI GECTI: kare=$kare gurultu=$gur orta_akis=$ak pafta=$d\pafta_$Ad.png"; exit 0 }
Yaz "KAPI RED: kare=$kare (beklenen $Kare) gurultu=$gur (<=1,5) orta_akis=$ak (>0,05); gonderim gitmez; pafta=$d\pafta_$Ad.png"; exit 1
