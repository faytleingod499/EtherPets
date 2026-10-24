import json,struct,numpy as np
CT={5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
NC={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
class Glb:
    def __init__(s,path):
        d=open(path,'rb').read()
        l,_=struct.unpack('<II',d[12:20]); s.j=json.loads(d[20:20+l])
        off=20+l; bl,_=struct.unpack('<II',d[off:off+8]); s.bin=bytearray(d[off+8:off+8+bl])
    def acc(s,i):
        a=s.j['accessors'][i]; bv=s.j['bufferViews'][a['bufferView']]
        n=NC[a['type']]; dt=CT[a['componentType']]
        start=bv.get('byteOffset',0)+a.get('byteOffset',0)
        stride=bv.get('byteStride',n*np.dtype(dt).itemsize)
        cnt=a['count']; sz=n*np.dtype(dt).itemsize
        if stride==sz:
            return np.frombuffer(s.bin,dtype=dt,count=cnt*n,offset=start).reshape(cnt,n).copy()
        raw=np.frombuffer(s.bin,dtype=np.uint8)
        out=np.empty((cnt,n),dt)
        for k in range(cnt): out[k]=np.frombuffer(s.bin,dtype=dt,count=n,offset=start+k*stride)
        return out
    def set_acc(s,i,arr):
        a=s.j['accessors'][i]; bv=s.j['bufferViews'][a['bufferView']]
        n=NC[a['type']]; dt=CT[a['componentType']]
        start=bv.get('byteOffset',0)+a.get('byteOffset',0)
        stride=bv.get('byteStride',n*np.dtype(dt).itemsize)
        arr=np.asarray(arr,dt).reshape(a['count'],n)
        sz=n*np.dtype(dt).itemsize
        assert stride==sz
        s.bin[start:start+a['count']*sz]=arr.tobytes()
        if a['type']=='VEC3' and a['componentType']==5126:
            a['min']=arr.min(0).tolist(); a['max']=arr.max(0).tolist()
    def save(s,path):
        js=json.dumps(s.j,separators=(',',':')).encode()
        js+=b' '*((4-len(js)%4)%4)
        b=bytes(s.bin); b+=b'\0'*((4-len(b)%4)%4)
        s.j['buffers'][0]['byteLength']=len(b)
        js=json.dumps(s.j,separators=(',',':')).encode(); js+=b' '*((4-len(js)%4)%4)
        out=struct.pack('<III',0x46546C67,2,12+8+len(js)+8+len(b))
        out+=struct.pack('<II',len(js),0x4E4F534A)+js+struct.pack('<II',len(b),0x004E4942)+b
        open(path,'wb').write(out)
