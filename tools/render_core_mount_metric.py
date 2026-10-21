#!/usr/bin/env python3
"""Render measured centre lines and mount routes; no production geometry."""
import argparse,json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
matplotlib.rcParams['svg.hashsalt']='wlr-core-mount-v2'
import matplotlib.pyplot as plt

def main(folder):
 root=Path(__file__).resolve().parents[1]
 c=json.loads((root/'docs/production/core_orbits_mount_revision2.json').read_text())
 native=json.loads((folder/'native.json').read_text())
 pivot=np.array(c['pivot_world_m']);theta=np.linspace(0,2*np.pi,1025)
 colours=['#ac8133','#626f81','#bfa45b']
 fig=plt.figure(figsize=(12,6));ax=fig.add_subplot(121,projection='3d');front=fig.add_subplot(122)
 fig.subplots_adjust(bottom=.22,top=.85,left=.04,right=.98,wspace=.20)
 front.set_aspect('equal');front.grid(alpha=.2)
 for orbit,basis,colour in zip(c['orbits'],native['native_bases'],colours):
  basis=np.array(basis).T
  curve=np.stack((orbit['radius_m']*np.cos(theta),np.zeros_like(theta),orbit['radius_m']*np.sin(theta)),axis=1)@basis.T+pivot
  ax.plot(curve[:,0],curve[:,2],curve[:,1],color=colour,linewidth=1.7,label=orbit['id'].replace('orbit_',''))
  front.plot(curve[:,0],curve[:,1],color=colour,linewidth=1.7)
 route=np.array(native['bridge_routes'][0]['path_world_m']);legacy=route[[0,-1]]
 ax.plot(legacy[:,0],legacy[:,2],legacy[:,1],'--',color='#bf3d48',linewidth=2,label='v1: прямая опора')
 front.plot(legacy[:,0],legacy[:,1],'--',color='#bf3d48',linewidth=2)
 for index,item in enumerate(native['bridge_routes']):
  points=np.array(item['path_world_m'])
  ax.plot(points[:,0],points[:,2],points[:,1],color='#267c96',linewidth=2.5,label='v2: верхние опоры' if index==0 else None)
  front.plot(points[:,0],points[:,1],color='#267c96',linewidth=2.5)
 ax.scatter(route[1,0],route[1,2],route[1,1],color='#267c96',s=32)
 front.scatter(route[1,0],route[1,1],color='#267c96',s=32)
 front.annotate('Y = 2,15 м',(route[1,0],route[1,1]),xytext=(-.55,2.40),arrowprops={'arrowstyle':'->','color':'#267c96'},fontsize=10)
 ax.set_xlabel('X, м');ax.set_ylabel('Z, м');ax.set_zlabel('Y, м');ax.set_box_aspect((1,1,1));ax.view_init(20,-55)
 ax.set_title('Метрика и маршруты креплений');front.set_title('Проекция X/Y')
 front.set_xlabel('X, м');front.set_ylabel('Y, м');front.set_xlim(-.65,.65);front.set_ylim(1.2,2.5)
 fig.legend(*ax.get_legend_handles_labels(),loc='lower center',bbox_to_anchor=(.5,.09),ncol=5,fontsize=9)
 fig.suptitle('Brief v2: измеренная схема, без production-геометрии',fontsize=13,y=.96)
 fig.text(.5,.045,'v1: пересечение 20-мм оболочек ≈33 мм; v2: зазор до третьей орбиты ≥56,6 мм',ha='center',fontsize=10)
 fig.savefig(folder/'mount_revision2_metric.png',dpi=140)
 fig.savefig(folder/'mount_revision2_metric.svg',metadata={'Date':None});plt.close(fig)

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--folder',type=Path,required=True);main(parser.parse_args().folder.resolve())
