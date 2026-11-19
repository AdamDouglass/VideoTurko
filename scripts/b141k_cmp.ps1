$Root = $(if($env:VT_ROOT){$env:VT_ROOT}else{(Resolve-Path (Join-Path $PSScriptRoot '..')).Path})
# B141K karsilastirma: P6_141 birebir komut + yeni kirpma bayraklari -> latent sha256 == P5_141_latent.bin mi? karar olaylar'a (BAYT_AYNI/FARKLI). Cikis her durumda 0 (zincir durmasin).
$p="$Root\runs"; $ev="$p\olaylar.txt"
function Yaz($m){ $s="{0} | {1}" -f (Get-Date -Format "HH:mm:ss"),$m; foreach($k in 1..8){ try{ $fs=[IO.File]::Open($ev,"Append","Write","ReadWrite"); $by=(New-Object Text.UTF8Encoding($false)).GetBytes($s+"`r`n"); $fs.Write($by,0,$by.Length); $fs.Close(); break }catch{ Start-Sleep -Milliseconds 400 } } }
$a="$p\P5_141_latent.bin"; $b="$p\B141K_latent.bin"
if(-not (Test-Path $a)){ Yaz "B141K KARSILASTIRMA YAPILAMADI: referans yok ($a)"; exit 0 }
if(-not (Test-Path $b)){ Yaz "B141K KARSILASTIRMA YAPILAMADI: yeni latent yok ($b)"; exit 0 }
$ha=(Get-FileHash $a -Algorithm SHA256).Hash; $hb=(Get-FileHash $b -Algorithm SHA256).Hash
if($ha -eq $hb){ Yaz "B141K BAYT_AYNI: latent sha256 P5_141_latent.bin == B141K_latent.bin ($($ha.Substring(0,16))) | 141 karede yeni kirpma bayraklari referansla bayt ayni" } else { Yaz "B141K BAYT_FARKLI: P5_141 $($ha.Substring(0,16)) vs B141K $($hb.Substring(0,16)) | kirpma yamalari 141 karede baytsal FARKLI: uretim satirlari durdurulmali, a2/operator bildir" }
exit 0
