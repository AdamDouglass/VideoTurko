# Dikis denetimi (CPU): python -I dikis_denetim.py parcaA.mp4 parcaB.mp4 [...]  (ardisik parcalar)
# Olcu: son3/ilk3 akis (medyan dx,dy + ortalama buyukluk), oran, yon kosinusu, gurultu kapisi (medyan artigi), son5 spike.
import sys, cv2, numpy as np
def fr(p):
    c=cv2.VideoCapture(p); o=[]
    while True:
        r,f=c.read()
        if not r: break
        o.append(cv2.cvtColor(f,cv2.COLOR_BGR2GRAY))
    return o
def fl(a,b): return cv2.calcOpticalFlowFarneback(a,b,None,.5,3,15,3,5,1.2,0)
def vec(g,idx):
    F=[fl(g[k],g[k+1]) for k in idx]
    return np.mean([[np.median(f[...,0]),np.median(f[...,1])] for f in F],axis=0), np.mean([np.linalg.norm(f,axis=2).mean() for f in F])
def gur(g): return np.mean([np.abs(x.astype(float)-cv2.medianBlur(x,3)).mean() for x in g[::8]])
P=[fr(p) for p in sys.argv[1:]]
for i,g in enumerate(P):
    mg=[np.linalg.norm(fl(g[k],g[k+1]),axis=2).mean() for k in range(len(g)-1)]
    print('parca %d: kare=%d gurultu=%.2f (kapi<=1.5, gercek H3 56 kare 0.7-1.14) orta akis=%.2f son5 spike=%s'%(i+1,len(g),gur(g),np.mean(mg),' '.join('%.2f'%x for x in mg[-5:])))
for i in range(len(P)-1):
    a,ma=vec(P[i],range(len(P[i])-4,len(P[i])-1)); b,mb=vec(P[i+1],range(1,4))
    cos=float(a@b/(np.linalg.norm(a)*np.linalg.norm(b)+1e-9)); r=mb/max(ma,1e-9)
    print('dikis %d-%d: buyukluk oran=%.2f (0.7-1.4) medyan vektor kosinus=%.2f (>0.8; kamera ~0 ise anlamsiz) -> %s'%(i+1,i+2,r,cos,'TAMAM' if 0.7<=r<=1.4 else 'RED'))
