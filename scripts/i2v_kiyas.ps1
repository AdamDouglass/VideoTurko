$Root = $(if($env:VT_ROOT){$env:VT_ROOT}else{(Resolve-Path (Join-Path $PSScriptRoot '..')).Path})
# operator: i2v bayt kapisi: iki latent (bayraklar ACIK/KAPALI) sha256 + avi sha256 ayni mi
$t="$Root\runs"; $ev="$t\olaylar.txt"
$a="$t\I2VAC_latent.bin"; $b="$t\I2VKA_latent.bin"
$ha=(Get-FileHash $a -Algorithm SHA256).Hash; $hb=(Get-FileHash $b -Algorithm SHA256).Hash
$va=(Get-ChildItem "$t\I2VAC\*.avi"|Select -First 1); $vb=(Get-ChildItem "$t\I2VKA\*.avi"|Select -First 1)
$fa=(Get-FileHash $va.FullName -Algorithm SHA256).Hash; $fb=(Get-FileHash $vb.FullName -Algorithm SHA256).Hash
$lat=($ha -eq $hb); $avi=($fa -eq $fb)
$m=("I2V KAPI: latent_ayni={0} (acik {1} / kapali {2}); avi_ayni={3}; karar={4}" -f $lat,$ha.Substring(0,16),$hb.Substring(0,16),$avi,$(if($lat){"BAYT_AYNI"}else{"FARKLI"}))
$fs=[IO.File]::Open($ev,'Append','Write','ReadWrite'); $by=(New-Object Text.UTF8Encoding($false)).GetBytes((Get-Date -Format 'HH:mm:ss')+' | '+$m+"`r`n"); $fs.Write($by,0,$by.Length); $fs.Close()
if($lat){exit 0}else{exit 1}
