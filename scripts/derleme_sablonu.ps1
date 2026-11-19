$Root = $(if($env:VT_ROOT){$env:VT_ROOT}else{(Resolve-Path (Join-Path $PSScriptRoot '..')).Path})
$ErrorActionPreference='Stop'
# DERLEME SABLONU (MAINTAINER ARACI): yamali stable-diffusion.cpp agacini derler; GPU bosken (sd-cli calismiyorken) calistir.
# Gerekenler: VT_ENGINE_SRC (icinde src\, build\ ve derle.cmd olan klasor); derle.cmd icin scripts\derle_ornek.cmd ornegine bak (VT_VCVARS tanimla).
# Yamalar: patches\SERIES.txt sirasiyla (0001-0018, hepsi varsayilan kapali). Once bin yedegi (bin_yedek), sonra derle.cmd.
$d=$(if($env:VT_ENGINE_SRC){$env:VT_ENGINE_SRC}else{throw 'VT_ENGINE_SRC tanimli degil (stable-diffusion.cpp kaynak/derleme klasoru)'}); $ev="$Root\runs\olaylar.txt"
$E2="$Root\runs\E2"
New-Item -ItemType Directory -Force "$Root\runs" | Out-Null
if(-not (Test-Path "$d\derle.cmd")){ Write-Error "derle.cmd yok: $d\derle.cmd (scripts\derle_ornek.cmd dosyasini oraya kopyalayip duzenle; ya da docs\KURULUM.md'deki iki cmake komutunu elle calistir)"; exit 2 }
function Yaz($m){ $fs=[IO.File]::Open($ev,'Append','Write','ReadWrite'); $by=(New-Object Text.UTF8Encoding($false)).GetBytes((Get-Date -Format 'HH:mm:ss')+' | '+$m+"`r`n"); $fs.Write($by,0,$by.Length); $fs.Close() }
function Oku($f){ if(-not (Test-Path $f)){ return '' }; $fs=[IO.File]::Open($f,'Open','Read','ReadWrite'); $sr=New-Object IO.StreamReader($fs); $t=$sr.ReadToEnd(); $sr.Close(); $fs.Close(); return $t }
if(Get-Process sd-cli -ErrorAction SilentlyContinue){ Yaz 'DERLEME HATA: sd-cli calisiyor, derleme baslamadi'; exit 1 }
if(-not (Test-Path "$d\bin_yedek")){ Copy-Item "$d\build\bin" "$d\bin_yedek" -Recurse -Force; Yaz 'DERLEME yedek: bin_yedek' }
Remove-Item "$d\derle_bitti.txt" -Force -ErrorAction SilentlyContinue
Yaz 'DERLEME basliyor (derle.cmd -j 2: birlesik yapi)'
$t=Get-Date
$p=Start-Process -FilePath cmd.exe -ArgumentList '/c',"$d\derle.cmd" -WindowStyle Hidden -PassThru
# -Wait KULLANMA (vctip.exe cocugu asili tutar, 6 dk kayip): derle_bitti.txt yokla, tavan 90 dk
$son=(Get-Date).AddMinutes(90); while((Get-Date) -lt $son -and -not (Test-Path "$d\derle_bitti.txt")){ Start-Sleep -Seconds 10 }
$sn=[int]((Get-Date)-$t).TotalSeconds; Get-Process vctip -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
$l=''; if(Test-Path "$d\derle_bitti.txt"){ $l=(Get-Content "$d\derle_bitti.txt" -TotalCount 1) }
if($l -eq "BASARILI"){ $dl="$d\build\bin\stable-diffusion.dll"; Yaz ("DERLEME ikili: {0} sha {1}" -f (Get-Item $dl).LastWriteTime.ToString("MM-dd HH:mm:ss"),(Get-FileHash $dl).Hash.Substring(0,16)); Yaz "DERLEME BITTI: cikis=0 sure=$sn sn (0007,0009,0010 hazir; sirada B56H bayt kapisi)"; exit 0 }
Yaz "DERLEME HATA: sure=$sn sn derle_bitti='$l' log=$d\derle.log"; exit 1

