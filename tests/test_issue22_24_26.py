"""Regression tests for issues #22 (gate ignores <ROOT>/.venv), #24 (VT_ENGINE_BIN keeps the stock engine type), #26 (8 GB cards report < 8192 MiB).
No GPU, no network: fake card readings (VT_GPU_CC / VT_GPU_VRAM) and uret.ps1 -Kuru.

python -B -m unittest tests/test_issue22_24_26.py -v"""
import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

KOK = Path(__file__).resolve().parents[1]
SC = KOK / "scripts"
PS = shutil.which("powershell") or "powershell.exe"


def kos(args, env_ek, kok_kopya=None):
    env = dict(os.environ)
    for a in ("VT_ROOT", "VT_ENGINE_BIN", "VT_ENGINE_TYPE", "VT_MODEL_DIR", "VT_PYTHON", "VT_MAX_JETON", "VT_MAX_KARE", "VT_GPU_CC", "VT_GPU_VRAM"):
        env.pop(a, None)
    env.update(env_ek)
    return subprocess.run([PS, "-NoProfile", "-ExecutionPolicy", "Bypass"] + args, capture_output=True, text=True, encoding="utf-8",
                          errors="replace", env=env, timeout=150, stdin=subprocess.DEVNULL)


class Issue26EsikTest(unittest.TestCase):
    """8 GB cards (8151-8192 MiB) reach the 8 GB class (token cap 16320, EndImg unchanged: 192 frames from 8000 MiB); 6 GB and below stay small."""

    def uret(self, vram, ek_args=()):
        with tempfile.TemporaryDirectory() as t:
            istem = os.path.join(t, "i.txt")
            Path(istem).write_text("a lake", encoding="ascii")
            r = kos(["-File", str(SC / "uret.ps1"), "-Istem", istem, "-Kuru"] + list(ek_args), {"VT_ROOT": t, "VT_GPU_CC": "8.9", "VT_GPU_VRAM": str(vram)})
        return r.returncode, r.stdout + r.stderr

    def test_sekiz_gb_kartlar_16320_tavanli_dala_girer(self):
        for vram in (8151, 8188, 8191, 8192, 10240):
            with self.subTest(vram=vram):
                kod, c = self.uret(vram, ["-Kare", "56", "-W", "1280", "-H", "768"])   # 16320 tokens = the reported pass, exactly the cap
                self.assertEqual(kod, 0, c)
                self.assertNotIn("VT-E-BOYUT", c)
                kod, c = self.uret(vram, ["-Kare", "73", "-W", "1280", "-H", "768"])   # 21120 tokens: above the 8 GB cap
                self.assertNotEqual(kod, 0, c)
                self.assertIn("VT-E-BOYUT", c)
                self.assertIn("tavan 16320", c)

    def test_on_bir_gb_ve_ustu_tavansiz(self):
        for vram in (11264, 12288):
            with self.subTest(vram=vram):
                kod, c = self.uret(vram, ["-Kare", "73", "-W", "1280", "-H", "768"])
                self.assertEqual(kod, 0, c)
                self.assertNotIn("VT-E-BOYUT", c)

    def test_sekiz_gb_end_img_eski_davranis(self):
        with tempfile.TemporaryDirectory() as t:
            istem = os.path.join(t, "i.txt"); Path(istem).write_text("a lake", encoding="ascii")
            png = os.path.join(t, "e.png"); Path(png).write_bytes(b"x")
            for vram, bekle in ((7999, False), (8188, True), (12288, True)):
                r = kos(["-File", str(SC / "uret.ps1"), "-Istem", istem, "-EndImg", png, "-Kare", "192", "-Kuru"], {"VT_ROOT": t, "VT_GPU_CC": "8.9", "VT_GPU_VRAM": str(vram)})
                c = r.stdout + r.stderr
                with self.subTest(vram=vram):
                    self.assertEqual(r.returncode == 0, bekle, c)
                    if not bekle:
                        self.assertIn("VT-E-KARE", c)

    def test_alti_gb_ve_alti_kucuk_kalir(self):
        for vram in (4096, 6144, 7999):
            with self.subTest(vram=vram):
                kod, c = self.uret(vram, ["-Kare", "56", "-W", "1280", "-H", "768"])
                self.assertNotEqual(kod, 0, c)
                self.assertIn("VT-E-BOYUT", c)
                self.assertIn("tavan 14880", c)

    def test_betikler_ayni_esik(self):
        ps1 = (SC / "uret.ps1").read_text(encoding="utf-8")
        sh = (SC / "uret.sh").read_text(encoding="utf-8")
        a = re.search(r"\$KucukKartMiB = (\d+)", ps1).group(1)
        b = re.search(r"KUCUK_KART_MIB=(\d+)", sh).group(1)
        self.assertEqual(a, b)
        self.assertLess(int(a), 8151)
        self.assertEqual(re.search(r"\$Jeton8GB = (\d+)", ps1).group(1), re.search(r"JETON_8GB=(\d+)", sh).group(1))
        self.assertEqual(re.search(r"\$OrtaKartUstMiB = (\d+)", ps1).group(1), re.search(r"ORTA_KART_UST_MIB=(\d+)", sh).group(1))


class Issue24MotorTuruTest(unittest.TestCase):
    """VT_ENGINE_BIN pointing elsewhere must not keep the type from secili_motor.json."""

    def uret(self, ek):
        with tempfile.TemporaryDirectory() as t:
            os.makedirs(os.path.join(t, "engine"))
            Path(t, "engine", "secili_motor.json").write_text('{"motor": "stock_cuda12", "bin": "engine/stock_cuda12/bin", "kart_sinifi": "ampere"}', encoding="ascii")
            istem = os.path.join(t, "i.txt")
            Path(istem).write_text("a lake", encoding="ascii")
            env = {"VT_ROOT": t, "VT_GPU_CC": "8.6", "VT_GPU_VRAM": "12288"}
            env.update({k: v.replace("<ROOT>", t) for k, v in ek.items()})
            r = kos(["-File", str(SC / "uret.ps1"), "-Istem", istem, "-Kuru"], env)
        return r.returncode, (r.stdout + r.stderr).replace(t, "<ROOT>")

    def test_secili_motor_degismedi(self):
        kod, c = self.uret({})
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=False", c)
        self.assertIn("stock motoru (stock_cuda12)", c)

    def test_baska_klasor_release_sayilir(self):
        kod, c = self.uret({"VT_ENGINE_BIN": os.path.join("<ROOT>", "engine", "bin")})
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=True", c)
        self.assertNotIn("stock motoru", c)
        self.assertIn("motor turu release", c)

    def test_ayni_klasor_stock_kalir(self):
        kod, c = self.uret({"VT_ENGINE_BIN": os.path.join("<ROOT>", "engine", "stock_cuda12", "bin") + os.sep})
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=False", c)

    def test_engine_type_ezer(self):
        kod, c = self.uret({"VT_ENGINE_BIN": os.path.join("<ROOT>", "engine", "bin"), "VT_ENGINE_TYPE": "stock"})
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=False", c)
        kod, c = self.uret({"VT_ENGINE_TYPE": "release"})
        self.assertEqual(kod, 0, c)
        self.assertIn("iki_asama=True", c)
        kod, c = self.uret({"VT_ENGINE_TYPE": "xyz"})
        self.assertIn("VT_ENGINE_TYPE='xyz' tanimsiz", c)
        self.assertIn("iki_asama=False", c)


class Issue22VenvTest(unittest.TestCase):
    """uretim_kapi.ps1 must pick <ROOT>/.venv/Scripts/python.exe like uret.ps1 does (VT_PYTHON > .venv > python)."""

    def test_kapi_venv_python_secer(self):
        s = (SC / "uretim_kapi.ps1").read_text(encoding="utf-8")
        self.assertIn(".venv/Scripts/python.exe", s)

    def test_kapi_venv_python_calistirir(self):
        """Fake root: .venv python = a copy of the real interpreter would need its DLLs, so use a stub exe that prints a marker; the gate must reach it."""
        with tempfile.TemporaryDirectory() as t:
            run = Path(t, "runs", "x")
            run.mkdir(parents=True)
            (run / "v.avi").write_bytes(b"x")
            venv = Path(t, ".venv", "Scripts")
            venv.mkdir(parents=True)
            # stub: compile-free marker via a copy of cmd.exe renamed python.exe (it ignores the extra args after /c is absent -> prints banner)
            cmd = Path(os.environ.get("SystemRoot", r"C:\Windows"), "System32", "cmd.exe")
            if not cmd.exists():
                self.skipTest("cmd.exe yok")
            shutil.copy(cmd, venv / "python.exe")
            r = kos(["-File", str(SC / "uretim_kapi.ps1"), "-Dizin", str(run), "-Ad", "v", "-Kare", "5"], {"VT_ROOT": t})
            c = r.stdout + r.stderr
            # the gate ran the venv stub (not system python): the line names the venv python path in its error text or the stub banner shows up
            self.assertIn("Microsoft Corporation", c)   # banner of the cmd.exe stub: proves the .venv python ran
            self.assertNotIn("python bulunamadi", c)


if __name__ == "__main__":
    unittest.main()
