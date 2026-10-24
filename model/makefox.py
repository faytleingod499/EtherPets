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
        out.append(p)
    return out

def recompute_normals(g,P):
    norms=[]
    for pr,pos in zip(g.j['meshes'][0]['primitives'],P):
        idx=g.acc(pr['indices']).reshape(-1,3)
        n=np.zeros_like(pos)
        a,b,c=pos[idx[:,0]],pos[idx[:,1]],pos[idx[:,2]]
        fn=np.cross(b-a,c-a)
        for k in range(3): np.add.at(n,idx[:,k],fn)
        ln=np.linalg.norm(n,axis=1,keepdims=True); ln[ln==0]=1
        norms.append((n/ln).astype(np.float32))
    return norms

if __name__=='__main__':
    g=Glb('/home/claude/etherpets/model/pet_wolf.glb')
    P0=[g.acc(pr['attributes']['POSITION']) for pr in g.j['meshes'][0]['primitives']]
    P=fox_positions(g,P0)
    N=recompute_normals(g,P)
    for pr,p,n in zip(g.j['meshes'][0]['primitives'],P,N):
        g.set_acc(pr['attributes']['POSITION'],p.astype(np.float32))
        g.set_acc(pr['attributes']['NORMAL'],n)
    g.j['meshes'][0]['name']='Fox'
    g.save('/home/claude/fox/pet_fox.glb')
    render(load_prims(g,P),path='fox.png')
    # side by side with the wolf on the same extents
