@echo off
rem derle_ornek.cmd - ORNEK derleme sarmalayici (maintainer araci). Kendi yollarina gore kopyala/duzenle: <ENGINE_SRC>\derle.cmd olarak koy.
rem Gerekli ortam degiskenleri: VT_ENGINE_SRC (stable-diffusion.cpp kaynak + build kokunu iceren klasor: <VT_ENGINE_SRC>\src, <VT_ENGINE_SRC>\build),
rem VT_VCVARS (vcvars64.bat yolu, ornek: "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat").
rem Cikti: <VT_ENGINE_SRC>\derle_bitti.txt ilk satir BASARILI ya da HATA (derleme_sablonu.ps1 bunu yoklar).
setlocal
if "%VT_ENGINE_SRC%"=="" ( echo VT_ENGINE_SRC tanimli degil & exit /b 2 )
if "%VT_VCVARS%"=="" ( echo VT_VCVARS tanimli degil & exit /b 2 )
del "%VT_ENGINE_SRC%\derle_bitti.txt" 2>nul
call "%VT_VCVARS%" >nul
cmake -S "%VT_ENGINE_SRC%\src" -B "%VT_ENGINE_SRC%\build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DSD_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=61 -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON > "%VT_ENGINE_SRC%\derle.log" 2>&1
if errorlevel 1 ( echo HATA> "%VT_ENGINE_SRC%\derle_bitti.txt" & exit /b 1 )
cmake --build "%VT_ENGINE_SRC%\build" -j 2 >> "%VT_ENGINE_SRC%\derle.log" 2>&1
if errorlevel 1 ( echo HATA> "%VT_ENGINE_SRC%\derle_bitti.txt" & exit /b 1 )
echo BASARILI> "%VT_ENGINE_SRC%\derle_bitti.txt"
endlocal
