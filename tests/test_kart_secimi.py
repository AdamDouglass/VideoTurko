"""Kart tanima ve motor secimi (scripts/kart.ps1 + scripts/kart_tablosu.json): kur.ps1 kartin sinifina gore motoru kendisi secer.
Agsiz, GPU'suz, indirmesiz: sahte kart olcumu (VT_KURU_SAHTE) ve sahte nvidia-smi satirlari. Gercek indirme yolu yerel file:// zip'leriyle (sahte sd-cli) sinanir.
Card detection and engine choice: fake cards only (1050 Ti, 3060 Laptop, 3070, 4060, 5060, AMD, no card); no network, no GPU.

python -B -m unittest tests/test_kart_secimi.py -v"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

KOK = Path(__file__).resolve().parents[1]
SC = KOK / "scripts"
PS = shutil.which("powershell") or "powershell.exe"
TABLO = json.loads((SC / "kart_tablosu.json").read_text(encoding="utf-8"))
SAHTE_TABAN = "ram=16;bos_ram=8;disk=200;vc=yok;python=yok;"
KARTLAR = {   # ad -> (sahte olcum, beklenen motor, beklenen sinif)
    "gtx1050ti": ("gpu=NVIDIA GeForce GTX 1050 Ti;vram=4096;cc=6.1", "release_sm61", "pascal"),
    "rtx3060_laptop": ("gpu=NVIDIA GeForce RTX 3060 Laptop GPU;vram=6144;cc=8.6", "stock_cuda12", "ampere"),
    "rtx3070": ("gpu=NVIDIA GeForce RTX 3070;vram=8192;cc=8.6", "stock_cuda12", "ampere"),
    "rtx4060": ("gpu=NVIDIA GeForce RTX 4060;vram=8188;cc=8.9", "stock_cuda12", "ada"),
    "rtx5060_laptop": ("gpu=NVIDIA GeForce RTX 5060 Laptop GPU;vram=8151;cc=12.0", "stock_cuda12", "blackwell"),
    "rtx2060": ("gpu=NVIDIA GeForce RTX 2060;vram=6144;cc=7.5", "stock_cuda12", "turing_volta"),
    "amd_rx9070xt": ("gpu=yok;amd=AMD Radeon RX 9070 XT", "stock_vulkan", "amd"),
}


def ps(args, env_ek=None, timeout=150):
    env = dict(os.environ)
    for a in ("VT_ROOT", "VT_ENGINE_BIN", "VT_MODEL_DIR", "VT_KURU_SAHTE", "VT_KART_TABLOSU", "VT_MOTOR_URL", "VT_MOTOR_SHA256", "VT_CUDA_URL", "VT_CUDA_SHA256", "GGML_CUDA_CUBLAS_COMPUTE_TYPE", "VT_ATTN_BUDGET"):
        env.pop(a, None)
    env.update(env_ek or {})
    return subprocess.run([PS, "-NoProfile", "-ExecutionPolicy", "Bypass"] + args, capture_output=True, text=True, encoding="utf-8", errors="replace",
                          env=env, timeout=timeout, stdin=subprocess.DEVNULL)


@unittest.skipUnless(sys.platform == "win32", "Windows PowerShell 5.1 gerekir")
class KurKartSecimi(unittest.TestCase):
    def kuru(self, sahte, *ek):
        with tempfile.TemporaryDirectory() as t:
            r = ps(["-File", str(SC / "kur.ps1"), "-Kuru", "-Adim", "kontrol0,motor", *ek],
                   {"VT_ROOT": t, "VT_MODEL_DIR": t + "/model", "VT_KURU_SAHTE": SAHTE_TABAN + sahte})
            yazilan = os.listdir(t)
        return r.returncode, r.stdout + r.stderr, yazilan

    def test_her_kartta_dogru_motor_ve_yan_etkisiz(self):
        for ad, (sahte, motor, sinif) in KARTLAR.items():
            with self.subTest(kart=ad):
                kod, c, yazilan = self.kuru(sahte)
                self.assertEqual(kod, 0, c)
                self.assertIn("Motor secimi: %s (kart sinifi %s;" % (motor, sinif), c)
                self.assertEqual(yazilan, [], "-Kuru hicbir sey yazmamali")
                tanim = TABLO["motorlar"][motor]
                if motor != "release_sm61":
                    for z in tanim["zipler"]:
                        self.assertIn("URL: %s  sha256 %s" % (z["url"], z["sha256"]), c)
                    self.assertIn(tanim["bin"].replace("/", "\\"), c)
                else:   # varsayilan yol: eski release adresleri ve engine\bin aynen
                    self.assertIn("videoturko-motor-0.1.0-win64-cuda12.8-sm61.zip", c)
                    self.assertIn("videoturko-cuda-runtime-12.8-win64.zip", c)
                    self.assertRegex(c, r"-> .*engine\\bin\r?\n")

    def test_gtx1050ti_uyari_yok_digerlerinde_var(self):
        _, c, _ = self.kuru(KARTLAR["gtx1050ti"][0])
        self.assertNotIn("VT-W-GPU-DENENMEDI", c)
        self.assertIn("durum dogrulanmis", c)
        for ad in ("rtx3060_laptop", "rtx5060_laptop", "amd_rx9070xt"):
            _, c, _ = self.kuru(KARTLAR[ad][0])
            self.assertIn("[VT-W-GPU-DENENMEDI]", c, ad)

    def test_kart_yok(self):
        kod, c, _ = self.kuru("gpu=yok")
        self.assertEqual(kod, 3, c)
        self.assertIn("[VT-E-GPU]", c)
        self.assertIn("docs/AMD_ROCM.md", c)

    def test_intel_kartta_otomatik_motor_yok(self):
        kod, c, _ = self.kuru("gpu=Intel(R) Arc(TM) A770")
        self.assertEqual(kod, 3, c)
        self.assertIn("[VT-E-GPU]", c)

    def test_motor_turu_elle(self):
        kod, c, _ = self.kuru(KARTLAR["rtx4060"][0], "-MotorTuru", "release_sm61")   # Ada default is stock since issues #24/#25; release stays selectable
        self.assertEqual(kod, 0, c)
        self.assertIn("Motor secimi: release_sm61 (elle, -MotorTuru)", c)
        kod, c, _ = self.kuru(KARTLAR["rtx3070"][0], "-MotorTuru", "yok_boyle_motor")
        self.assertNotEqual(kod, 0)
        self.assertIn("bilinmeyen -MotorTuru", c)

    def test_yerel_release_zip_release_motoru_sayilir(self):
        _, c, _ = self.kuru(KARTLAR["rtx3070"][0], "-MotorZip", "x.zip", "-CudaZip", "y.zip")
        self.assertIn("Motor secimi: release_sm61 (yerel release zip verildi)", c)


KART_RUNNER = r"""
param($kart, $girdi)
. $kart
$cikti = @()
foreach ($s in (Get-Content -LiteralPath $girdi -Encoding UTF8)) {
    $r = Kart-Satir-Coz $s
    if ($r) { $cikti += [pscustomobject]@{ ad = $r.ad; vram = $r.vram; surucu = $r.surucu; cc = $r.cc; uretici = (Kart-Uretici $r.ad) } } else { $cikti += $null }
}
ConvertTo-Json -InputObject @($cikti) -Compress
"""


@unittest.skipUnless(sys.platform == "win32", "Windows PowerShell 5.1 gerekir")
class SahteNvidiaSmiSatirlari(unittest.TestCase):
    """nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader,nounits cikti bicimleri."""

    def coz(self, satirlar):
        with tempfile.TemporaryDirectory() as t:
            r = Path(t) / "r.ps1"
            r.write_text(KART_RUNNER, encoding="utf-8-sig")
            g = Path(t) / "g.txt"
            g.write_text("\n".join(satirlar), encoding="utf-8")
            p = ps(["-File", str(r), str(SC / "kart.ps1"), str(g)])
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        return json.loads(p.stdout.strip().splitlines()[-1])

    def test_gercek_bicimler(self):
        s = self.coz([
            "NVIDIA GeForce GTX 1050 Ti, 4096, 581.57, 6.1",
            "NVIDIA GeForce RTX 3060 Laptop GPU, 6144, 566.36, 8.6",
            "NVIDIA GeForce RTX 3070, 8192, 610.88, 8.6",
            "NVIDIA GeForce RTX 4060, 8188, 621.24, 8.9",
            "NVIDIA GeForce RTX 5060 Laptop GPU, 8151, 580.00, 12.0",
        ])
        self.assertEqual([x["cc"] for x in s], [6.1, 8.6, 8.6, 8.9, 12.0])
        self.assertEqual([x["vram"] for x in s], [4096, 6144, 8192, 8188, 8151])
        self.assertTrue(all(x["uretici"] == "nvidia" for x in s))
        self.assertEqual(s[1]["ad"], "NVIDIA GeForce RTX 3060 Laptop GPU")

    def test_adda_virgul(self):
        s = self.coz(["Falan, Filan GPU, 4096, 500.00, 7.5"])   # son uc alan vram, surucu, cc; geri kalani ad
        self.assertEqual(s[0]["ad"], "Falan, Filan GPU")
        self.assertEqual(s[0]["cc"], 7.5)
        self.assertEqual(s[0]["vram"], 4096)

    def test_bozuk_satirlar(self):
        s = self.coz(["", "yalniz-bir-alan", "Kart, abc, surucu, ?"])
        self.assertIsNone(s[0])
        self.assertIsNone(s[1])
        self.assertEqual(s[2]["cc"], -1)
        self.assertEqual(s[2]["vram"], -1)

    def test_uretici_adindan(self):
        s = self.coz(["AMD Radeon RX 9070 XT, 16384, 25.1, ", "Intel(R) Arc(TM) A770 Graphics, 16384, 31.0, ", "Radeon RX 7800 XT, 16384, 25.1, "])
        self.assertEqual([x["uretici"] for x in s], ["amd", "diger", "amd"])


@unittest.skipUnless(sys.platform == "win32", "Windows PowerShell 5.1 gerekir")
class UretMotorVeEkAyar(unittest.TestCase):
    """uret.ps1 -Kuru: engine/secili_motor.json ve tablo ek ayari. Varsayilan (json yok) yol bayt-ayni komut uretir."""

    def uret(self, secili, cc, vram="8192", ek=None):
        with tempfile.TemporaryDirectory() as t:
            if secili:
                os.makedirs(os.path.join(t, "engine"))
                Path(t, "engine", "secili_motor.json").write_text(json.dumps(secili), encoding="ascii")
            istem = os.path.join(t, "i.txt")
            Path(istem).write_text("a lake", encoding="ascii")
            env = {"VT_ROOT": t, "VT_GPU_CC": cc, "VT_GPU_VRAM": vram}
            env.update(ek or {})
            r = ps(["-File", str(SC / "uret.ps1"), "-Istem", istem, "-Kuru"], env)
        c = (r.stdout + r.stderr).replace(t, "<ROOT>")
        return r.returncode, re.sub(r"\d{8}-\d{6}", "TS", c)

    def test_json_yok_ile_release_json_ayni(self):
        a = self.uret(None, "6.1", "4096")
        b = self.uret({"motor": "release_sm61", "bin": "engine/bin", "kart_sinifi": "pascal"}, "6.1", "4096")
        self.assertEqual(a, b)
        self.assertEqual(a[0], 0, a)
        self.assertIn("iki_asama=True", a[1])

    def test_stock_motor_tek_surec_ve_f32(self):
        kod, c = self.uret({"motor": "stock_cuda12", "bin": "engine/stock_cuda12/bin", "kart_sinifi": "ampere"}, "8.6")
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=False", c)
        self.assertIn("bilgi: stable-diffusion.cpp stock motoru (stock_cuda12)", c)
        self.assertNotIn("SD_H3_", c)
        self.assertIn("GGML_CUDA_CUBLAS_COMPUTE_TYPE=f32", c)
        self.assertNotIn("VT-W-BLACKWELL", c)
        # kalite ayarlari degismedi
        for parca in ("--steps 6", "--cfg-scale 1.0", "-W 640 -H 384", "--sigmas hyperflow-h3-flash-6"):
            self.assertIn(parca, c)
        self.assertNotIn("tiling", c.lower().replace("no_tiling_fallback", ""))

    def test_f32_tablosu_eski_kuralla_ayni(self):
        for cc, f32 in (("6.1", False), ("7.0", True), ("7.5", True), ("8.0", True), ("8.6", True), ("8.9", True), ("9.0", True), ("12.0", True)):
            with self.subTest(cc=cc):
                _, c = self.uret(None, cc)
                self.assertEqual("GGML_CUDA_CUBLAS_COMPUTE_TYPE=f32" in c, f32, c[:400])

    def test_kullanici_f32_ayarina_dokunulmaz(self):
        _, c = self.uret(None, "8.6", ek={"GGML_CUDA_CUBLAS_COMPUTE_TYPE": "f16"})
        self.assertNotIn("GGML_CUDA_CUBLAS_COMPUTE_TYPE=f32", c)

    def test_amd_siniften_butce(self):
        # VT_GPU_CC=-1: nvidia-smi gorunmeyen kart gibi (cc okunamadi); sinif json'dan gelir
        _, c = self.uret({"motor": "stock_vulkan", "bin": "engine/stock_vulkan/bin", "kart_sinifi": "amd"}, "-1", vram="16384")
        self.assertIn("minimax_h3_attn_chunk_budget=0.03", c)
        self.assertIn("stock_vulkan", c)
        self.assertNotIn("GGML_CUDA_CUBLAS_COMPUTE_TYPE", c)
        _, c = self.uret({"motor": "stock_vulkan", "bin": "engine/stock_vulkan/bin", "kart_sinifi": "amd"}, "-1", vram="16384", ek={"VT_ATTN_BUDGET": "0.04"})
        self.assertIn("minimax_h3_attn_chunk_budget=0.04", c)

    def test_json_yok_amd_degil_butce_varsayilan(self):
        _, c = self.uret(None, "8.6")
        self.assertIn("minimax_h3_attn_chunk_budget=0.05", c)


class TabloGecerli(unittest.TestCase):
    def test_sinif_motor_baglari_ve_araliklar(self):
        motorlar = TABLO["motorlar"]
        nv = [k for k in TABLO["kartlar"] if k["uretici"] == "nvidia"]
        onceki = None
        for k in nv:
            self.assertIn(k["motor"], motorlar, k["id"])
            self.assertLess(k["cc_min"], k["cc_max"], k["id"])
            if onceki is not None:
                self.assertEqual(onceki["cc_max"], k["cc_min"], "cc araliklari bitisik ve ortusmesiz: %s -> %s" % (onceki["id"], k["id"]))
            onceki = k
        self.assertEqual(nv[0]["cc_min"], 6.1, "6.1 alti kart kur.ps1'de reddedilir")
        self.assertGreaterEqual(nv[-1]["cc_max"], 99)
        amd = [k for k in TABLO["kartlar"] if k["uretici"] == "amd"]
        self.assertEqual(len(amd), 1)
        self.assertIn(amd[0]["motor"], motorlar)
        self.assertIsNone(TABLO["diger_uretici"]["motor"])
        self.assertIn(TABLO["nvidia_cc_okunamadi"]["motor"], motorlar)

    def test_durum_ve_kanit_etiketli(self):
        for k in TABLO["kartlar"] + [TABLO["nvidia_cc_okunamadi"], TABLO["diger_uretici"]]:
            self.assertIn(k["durum"], ("dogrulanmis", "topluluk", "denenmemis"), k.get("id"))
            self.assertTrue(re.search(r"\[(okudum|olctum|kullanici bildirdi|tahmin)", k["kanit"]) or k["durum"] == "denenmemis", k.get("id"))
        # dogrulanmis yalniz yazarlarin olctugu sinif; baska sinifa dogrulanmis yazilmaz
        self.assertEqual([k["id"] for k in TABLO["kartlar"] if k["durum"] == "dogrulanmis"], ["pascal"])

    def test_stock_zipler_sabit_adres_ve_sha(self):
        for ad, m in TABLO["motorlar"].items():
            if ad == "release_sm61":
                self.assertIsInstance(m["zipler"], str)   # eski yol kur.ps1'de, burada kopyasi yok
                continue
            for z in m["zipler"]:
                self.assertRegex(z["sha256"], r"^[0-9a-f]{64}$")
                parcalar = z["url"].split("/")   # adres parcalari: sabit sunucu, sahip/depo ve surum etiketi
                self.assertEqual(parcalar[:2] + parcalar[2:5], ["https:", ""] + ["github.com", "leejet", "stable-diffusion.cpp"], z["url"])
                self.assertIn("master-1106-532d2c1", parcalar, z["url"])
                self.assertTrue(z["url"].endswith("/" + z["ad"]))
                self.assertGreater(z["boyut"], 1000)
            self.assertIn("sd-cli.exe", m["gerekli_dosyalar"])
            self.assertFalse(m["iki_asama"])

    def test_kalite_ayari_tabloda_yok(self):
        metin = (SC / "kart_tablosu.json").read_text(encoding="utf-8")
        anahtarlar = set(re.findall(r'"([a-zA-Z_0-9]+)"\s*:', metin))
        for yasak in ("steps", "adim", "cfg", "cfg_scale", "sigmas", "vae_tiling", "width", "height", "seed"):
            self.assertNotIn(yasak, anahtarlar)
        env_adlari = set(re.findall(r'"(GGML_[A-Z0-9_]+|SD_[A-Z0-9_]+)"', metin))
        self.assertEqual(env_adlari, {"GGML_CUDA_CUBLAS_COMPUTE_TYPE"})
        self.assertTrue(all(b < 128 for b in (SC / "kart_tablosu.json").read_bytes()), "ASCII olmali")
        self.assertTrue(all(b < 128 for b in (SC / "kart.ps1").read_bytes()), "ASCII olmali")

    def test_release_zipleri_kur_ps1de_degismedi(self):
        k = (SC / "kur.ps1").read_text(encoding="utf-8-sig")
        self.assertIn("videoturko-motor-0.1.0-win64-cuda12.8-sm61.zip", k)
        self.assertIn("7d28ff900ef4799f75cbe91c39e0a7b260f0207a7e2a4ebd3d8450590b79a64d", k)
        self.assertIn("344a0b04f043fb9cccdfe38ec77716afb59bafb894f11f0fac2365f151777355", k)


@unittest.skipUnless(sys.platform == "win32" and shutil.which("curl.exe"), "Windows PowerShell + curl.exe")
class StockMotorKurulumu(unittest.TestCase):
    """Gercek motor adimi (indirme + sha256 + acma + yerlestirme), sahte zip'lerle file:// uzerinden; gercek motor/ag yok."""

    def hazirla(self, t):
        zd = Path(t) / "sahte"
        zd.mkdir()
        sd = Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32" / "hostname.exe"   # `--help` calisan kucuk gercek exe
        z1 = zd / "sahte-motor.zip"
        with zipfile.ZipFile(z1, "w") as z:
            z.write(sd, "sd-cli.exe")
            z.writestr("ggml-cuda.dll", "x")
            z.writestr("stable-diffusion.cpp.txt", "lisans")
        z2 = zd / "sahte-cudart.zip"
        with zipfile.ZipFile(z2, "w") as z:
            for ad in ("cudart64_12.dll", "cublas64_12.dll", "cublasLt64_12.dll"):
                z.writestr(ad, "x")
        tablo = json.loads(json.dumps(TABLO))
        tablo["motorlar"]["stock_cuda12"]["zipler"] = [
            {"ad": z.name, "url": z.as_uri(), "sha256": hashlib.sha256(z.read_bytes()).hexdigest(), "boyut": z.stat().st_size} for z in (z1, z2)]
        yol = Path(t) / "tablo.json"
        yol.write_text(json.dumps(tablo), encoding="ascii")
        return str(yol), tablo

    def test_indir_dogrula_yerlestir_ve_tekrar_atla(self):
        with tempfile.TemporaryDirectory() as t:
            kok = os.path.join(t, "kok")
            os.makedirs(kok)
            tablo_yol, _ = self.hazirla(t)
            env = {"VT_ROOT": kok, "VT_MODEL_DIR": os.path.join(kok, "model"), "VT_KART_TABLOSU": tablo_yol}
            args = ["-File", str(SC / "kur.ps1"), "-Adim", "motor", "-MotorTuru", "stock_cuda12"]
            r = ps(args, env)
            c = r.stdout + r.stderr
            self.assertEqual(r.returncode, 0, c)
            bin_ = Path(kok, "engine", "stock_cuda12", "bin")
            for ad in ("sd-cli.exe", "ggml-cuda.dll", "cudart64_12.dll", "cublas64_12.dll", "cublasLt64_12.dll"):
                self.assertTrue((bin_ / ad).is_file(), ad + "\n" + c)
            sec = json.loads(Path(kok, "engine", "secili_motor.json").read_text(encoding="ascii"))
            self.assertEqual((sec["motor"], sec["bin"]), ("stock_cuda12", "engine/stock_cuda12/bin"))
            self.assertTrue(Path(kok, "engine", "stock_cuda12", "lisanslar").is_dir(), "lisanslar motor klasorunun yaninda")
            # eski yol bos: engine\bin olusmadi
            self.assertFalse(Path(kok, "engine", "bin").exists())
            # kok disina iz yok: yalniz kok icinde yeni dosya
            self.assertEqual(sorted(os.listdir(kok)), ["engine", "indirme", "runs"])
            # ikinci kosu: zaten var, yeniden inmez
            r2 = ps(args, env)
            self.assertEqual(r2.returncode, 0, r2.stdout + r2.stderr)
            self.assertIn("motor zaten var (atlandi)", r2.stdout)

    def test_sha_tutmazsa_reddedilir(self):
        with tempfile.TemporaryDirectory() as t:
            kok = os.path.join(t, "kok")
            os.makedirs(kok)
            tablo_yol, tablo = self.hazirla(t)
            tablo["motorlar"]["stock_cuda12"]["zipler"][0]["sha256"] = "0" * 64
            Path(tablo_yol).write_text(json.dumps(tablo), encoding="ascii")
            r = ps(["-File", str(SC / "kur.ps1"), "-Adim", "motor", "-MotorTuru", "stock_cuda12"],
                   {"VT_ROOT": kok, "VT_MODEL_DIR": os.path.join(kok, "model"), "VT_KART_TABLOSU": tablo_yol})
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("sha256 tutmadi", r.stdout + r.stderr)
            self.assertFalse(Path(kok, "engine", "stock_cuda12", "bin", "sd-cli.exe").exists())
            self.assertFalse(Path(kok, "engine", "secili_motor.json").exists())


if __name__ == "__main__":
    unittest.main()
