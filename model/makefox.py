import numpy as np, sys
from glbio import *
from render import *

def sm(t): 
    t=np.clip(t,0,1); return t*t*(3-2*t)

def fox_positions(g, P):
    """P: list of per-primitive positions (copies). returns new list"""
    names=[g.j['materials'][pr['material']]['name'].split('.')[0] for pr in g.j['meshes'][0]['primitives']]
    out=[]
    # tail axis from hips root to tip
    a0=np.array([0,0.66,-0.5]); a1=np.array([0,1.4,-1.27]); ax=(a1-a0); L=np.linalg.norm(ax); ax/=L
    for name,pos in zip(names,P):
        p=pos.copy()
        x,y,z=p[:,0].copy(),p[:,1].copy(),p[:,2].copy()
        # ---- body: slimmer, a touch shorter in the leg
        slim=np.ones_like(x)
        slim=0.84-0.0*z
        isbody = name not in ('pet_tail','pet_tailbase','pet_ear_inner','pet_ear_back')
        if isbody: p[:,0]=x*slim
        # legs thinner (below y 0.65, away from the head)
        leg = (y<0.62)&(name in ('pet_legs','pet_hindlegs','pet_paws'))
        if np.any(leg): p[leg,0]=x[leg]*0.78
        # ---- snout: longer and narrower; everything beyond z=0.95 moves forward
        t=sm((z-0.95)/0.35)
        head_names=('pet_head','pet_face','pet_muzzle','pet_black','pet_eye','pet_white','pet_mouth','pet_tongue','pet_throat','pet_neck','pet_fur','pet_light')
        if name in head_names:
            front=(z>0.85)&(y>0.7)
            tt=np.where(front,t,0)
            p[:,2]=p[:,2]+0.12*tt
            # narrower snout (not the eyes: they stay at the sides of the face)
            if name in ('pet_muzzle','pet_black','pet_mouth','pet_tongue'):
                p[:,0]=p[:,0]*(1-0.30*tt)
                p[:,1]=y-0.04*tt
            elif name in ('pet_head','pet_face'):
                p[:,0]=p[:,0]*(1-0.18*tt)
        # ---- ears: taller and bigger
        if name in ('pet_ear_inner','pet_ear_back'):
            base=np.array([0.0,1.02,0.78])
            q=p-base
            q[:,1]*=1.4; q[:,2]*=1.2
            p=base+q
            c=np.sign(pos[:,0])*0.13
            p[:,0]=c+(p[:,0]-c)*1.0
        # ---- tail: much bushier
        if name in ('pet_tail','pet_tailbase') or (name=='pet_fur' and False):
            v=p-a0
            along=v@ax
            radial=v-np.outer(along,ax)
            grow=1.0+0.32*sm(along/ (L*0.45))
            if name=='pet_tail': grow=grow*1.05
            p=a0+np.outer(along,ax)+radial*grow[:,None]
        # eye shine: pulled back so it sits just proud of the eye instead of sticking out
        if name == 'pet_white':
            p[:, 2] -= SHINE_BACK
        out.append(p)
    return ear_refit(names, out)

SHINE_BACK = 0.012

EAR_NAMES = ('pet_ear_inner', 'pet_ear_back')
HEAD_SURFACE = ('pet_head', 'pet_fur', 'pet_face')

def ear_refit(names, P):
    """Smaller ears whose bottoms sit flush on the head. Works on the already warped positions
    (the same step is applied to the fox mesh in the .blend, so both stay in step)."""
    H = np.vstack([p for n, p in zip(names, P) if n in HEAD_SURFACE])
    out = []
    for n, p in zip(names, P):
        if n in EAR_NAMES:
            out.append(refit_ear_points(p, H))
        else:
            out.append(p)
    return out

def refit_ear_points(p, H, size=(0.78, 0.78, 0.8)):
    """Shrinks each ear about the middle of its base, so the base stays down on the head."""
    p = p.copy()
    side = np.where(p[:, 0] >= 0, 1.0, -1.0)
    for s in (1.0, -1.0):
        m = side == s
        q = p[m]
        piv = np.array([s * 0.13, q[:, 1].min() + 0.01, 0.5 * (q[:, 2].min() + q[:, 2].max())])
        p[m] = piv + (q - piv) * np.array(size)
    # tips leaning slightly apart, a little closer together and sunk a touch, so each ear's whole base sits on the
    # narrower head (the outer edge otherwise hung off its side)
    for s in (1.0, -1.0):
        m = side == s
        q = p[m]
        piv = np.array([s * 0.5 * (np.abs(q[:, 0]).min() + np.abs(q[:, 0]).max()), q[:, 1].min(),
                        0.5 * (q[:, 2].min() + q[:, 2].max())])
        a = np.radians(EAR_TILT) * s
        R = np.array([[np.cos(a), np.sin(a), 0], [-np.sin(a), np.cos(a), 0], [0, 0, 1]])
        q = (q - piv) @ R.T + piv
        q[:, 0] -= s * EAR_IN
        q[:, 1] -= EAR_SINK
        # a rounder tip: the little cap of points at the top is widened and lowered a touch
        tip = q[:, 1] > q[:, 1].max() - EAR_TIP_BAND
        c = q[tip].mean(0)
        d = q[tip] - c
        d[:, 0] *= EAR_TIP_WIDEN; d[:, 2] *= EAR_TIP_WIDEN
        q[tip] = c + d - np.array([0, EAR_TIP_DROP, 0])
        p[m] = q
    return p

EAR_TILT, EAR_IN, EAR_SINK = 20.0, 0.03, 0.02
EAR_TIP_BAND, EAR_TIP_WIDEN, EAR_TIP_DROP = 0.03, 2.6, 0.025
