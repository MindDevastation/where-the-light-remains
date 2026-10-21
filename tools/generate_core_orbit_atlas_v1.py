"""Generate bounded numeric PBR calibration strips from existing original brass maps."""
from pathlib import Path
import hashlib,json,math
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/3d/textures_source/archive_core_v1'
W,H=4096,512

def main():
 OUT.mkdir(parents=True,exist_ok=False)
 source=ROOT/'game/art/textures/material_library';maps={k:np.array(Image.open(source/f't_polished_brass_{k}.png').convert('RGB')) for k in ['albedo','normal','orm']}
 yy,xx=np.mgrid[:H,:W];atlas={k:a[yy%a.shape[0],xx%a.shape[1]].copy() for k,a in maps.items()};regions=[]
 for radius,y0 in zip([.58,.46,.34],[24,184,344]):
  length=round(math.tau*radius*1024);circ=math.tau*radius
  # Each unique strip is periodic in U,including its last padding texels.
  x=np.arange(W)%length;theta=x/length*math.tau
  for k,a in maps.items():
   u=(x*a.shape[1]/length).astype(int)%a.shape[1]
   for y in range(y0-16,y0+112):atlas[k][y,:,:]=a[(y-y0)%a.shape[0],u,:]
  relief=np.zeros((128,W),np.float32)
  for step in range(72):
   cx=step*length/72;distance=np.minimum(np.abs(x-cx),length-np.abs(x-cx));line=np.exp(-(distance/1.2)**4)
   span=12 if step%6 else 22
   # Profilefront/back faces receive restrained workshop ticks;no glyph or code.
   for v0 in [0,38]:relief[v0+5:v0+5+span,:]-=.00035*line
  gy,gx=np.gradient(relief*1024);normal=np.stack([-gx,-gy,np.ones_like(gx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
  encoded=np.clip((normal*.5+.5)*255,0,255).astype(np.uint8)
  cut=np.abs(relief[y0*0+16:y0*0+96])>.00005
  atlas['albedo'][y0:y0+80][cut]=(atlas['albedo'][y0:y0+80][cut].astype(float)*.35).astype(np.uint8)
  # Existing micro normal is retained;engraving contributes its tangent gradient.
  old=atlas['normal'][y0:y0+80].astype(np.float32)/127.5-1
  engr=normal[16:96];combined=old+np.stack([engr[:,:,0],engr[:,:,1],np.zeros_like(gx[16:96])],axis=-1)
  combined/=np.linalg.norm(combined,axis=-1,keepdims=True);atlas['normal'][y0:y0+80]=np.clip((combined*.5+.5)*255,0,255).astype(np.uint8)
  atlas['orm'][y0:y0+80,:,2]=255;atlas['orm'][y0:y0+80,:,0]=np.where(cut,185,255)
  regions.append({'radius_m':radius,'u_pixels':length,'v_start':y0,'profile_height_pixels':80,'density_px_per_m':length/circ})
 outputs=[]
 for k,data in atlas.items():
  p=OUT/f't_core_orbit_brass_{k}.png';Image.fromarray(data).save(p);outputs.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size':list(Image.open(p).size)})
 (OUT/'atlas_manifest.json').write_text(json.dumps({'regions':regions,'resolution':[W,H],'source_maps':{f't_polished_brass_{k}.png':hashlib.sha256((source/f't_polished_brass_{k}.png').read_bytes()).hexdigest() for k in maps},'ornament':'Unnumbered instrument ticks only;no new narrative sigil or gameplay hint','outputs':outputs},indent=2)+'\n')
 print(json.dumps({'status':'GENERATED','regions':regions}))
if __name__=='__main__':main()
