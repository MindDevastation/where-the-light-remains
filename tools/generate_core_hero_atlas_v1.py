"""Original numeric brass engravings for the broad hero orbit straps."""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
out=ROOT/'assets/3d/textures_source/archive_core_hero_v1'
out.mkdir(parents=True,exist_ok=False)
source=ROOT/'game/art/textures/material_library'
w,h=4096,1024
yy,xx=np.mgrid[:h,:w]
maps={k:np.array(Image.open(source/f't_polished_brass_{k}.png').convert('RGB')) for k in ['albedo','normal','orm']}
atlas={k:v[yy%v.shape[0],xx%v.shape[1]].copy() for k,v in maps.items()}
regions=[]
for radius,y0 in zip([.58,.46,.34],[24,296,568]):
 length=round(math.tau*radius*1024)
 x=np.arange(w)%length
 for k,v in maps.items():
  u=(x*v.shape[1]/length).astype(int)%v.shape[1]
  for y in range(y0-16,y0+202):atlas[k][y,:,:]=v[(y-y0)%v.shape[0],u,:]
 relief=np.zeros((184,w),np.float32)
 rows=np.arange(184)[:,None]
 for edge in [4,47,86,129]:relief-=.00022*np.exp(-((rows-edge)/.8)**4)
 for i in range(72):
  cx=i*length/72
  distance=np.abs(x-cx);distance=np.minimum(distance,length-distance)
  line=np.exp(-(distance/1.1)**4)[None,:]
  for v0 in [0,82]:
   span=17 if i%6==0 else 8
   relief[v0+5:v0+5+span,:]-=.0003*line
  if i%6==0:
   for cy in [29,111]:
    diamond=np.abs(distance[None,:]/5+np.abs(rows-cy)/8-1)
    relief-=.0003*np.exp(-(diamond/.11)**4)
 cut=np.abs(relief)>.00005
 patch=atlas['albedo'][y0:y0+184].astype(np.float32)
 # Restrained polished gold, with darker original workshop incisions.
 patch*=np.array([1.1,1.04,.92])[None,None,:]
 patch[cut]*=.28
 atlas['albedo'][y0:y0+184]=np.clip(patch,0,255).astype(np.uint8)
 gy,gx=np.gradient(relief*1024)
 old=atlas['normal'][y0:y0+184].astype(np.float32)/127.5-1
 old[:,:,0]-=gx;old[:,:,1]-=gy
 old/=np.linalg.norm(old,axis=-1,keepdims=True)
 atlas['normal'][y0:y0+184]=np.clip((old*.5+.5)*255,0,255).astype(np.uint8)
 atlas['orm'][y0:y0+184,:,0]=np.where(cut,175,255)
 atlas['orm'][y0:y0+184,:,1]=np.where(cut,130,85)
 atlas['orm'][y0:y0+184,:,2]=255
 regions.append({'radius_m':radius,'u_pixels':length,'v_start':y0,'density_px_per_m':length/(math.tau*radius)})
outputs=[]
for kind,data in atlas.items():
 p=out/f't_core_hero_brass_{kind}.png';Image.fromarray(data).save(p)
 outputs.append({'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'atlas_manifest.json').write_text(json.dumps({'resolution':[w,h],'regions':regions,'outputs':outputs,'ornament':'Unlettered ticks and geometric diamonds; no code, narrative seal or hint'},indent=2)+'\n')
print('CORE_HERO_ATLAS_GENERATED')
