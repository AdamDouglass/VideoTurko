# Doku-normalize gurultu N (a1): python -I doku_norm.py klip.avi|mp4 [...]
# N = medyan artik (|kare - medianBlur3|) / Sobel doku gucu (Gauss s=1), her 6. kare; cikti: kare, ham, doku, N, ilk/son ceyrek N.
# Kalibrasyon (WW2 sahne ailesi): 10 olculu klip 0,034-0,052; sentetik gurultu s=2 -> 0,091. Dokulu sahnede (S1 cim sirasi) temiz N 0,075: esik sahne basina temiz taban + %25.
import cv2, numpy as np, sys, os
for p in sys.argv[1:]:
    c = cv2.VideoCapture(p); g = []
    while True:
        r, x = c.read()
        if not r: break
        g.append(cv2.cvtColor(x, cv2.COLOR_BGR2GRAY))
    res = []; tex = []
    for x in g[::6]:
        res.append(np.abs(x.astype(float) - cv2.medianBlur(x, 3)).mean())
        b = cv2.GaussianBlur(x, (0, 0), 1.0)
        tex.append(np.sqrt(cv2.Sobel(b, cv2.CV_32F, 1, 0) ** 2 + cv2.Sobel(b, cv2.CV_32F, 0, 1) ** 2).mean())
    res = np.array(res); tex = np.array(tex); N = res / tex; q = len(N) // 4
    print('%s kare=%d ham=%.2f doku=%.1f N=%.3f ilkCeyrek=%.3f sonCeyrek=%.3f' % (os.path.basename(p), len(g), res.mean(), tex.mean(), N.mean(), N[:q].mean(), N[-q:].mean()))
