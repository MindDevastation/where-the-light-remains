import json, hashlib
from pathlib import Path
import numpy as np
import soundfile as sf
import librosa

OUT=Path('audio_reaudit_output'); OUT.mkdir(exist_ok=True)
GROUPS={
'A':'celestial neoclassical romantic ambient for a magical observatory archive, soft piano, chamber strings, celesta, glass harmonics, gentle choir, mysterious tender, no heavy percussion',
'B':'intimate magical chamber ambient about warmth, light, life and voice, felt piano, harp, soft strings, glass tones, resonance, breathing space, warm gentle',
'C':'dreamlike fantasy raid score, low strings, restrained frame drums, distant horns, fantasy choir, modal harmony, playful tension and action, cinematic game memory',
'D':'playful chamber fantasy, pizzicato strings, celesta, soft mallets, bells, harp, light whimsical motion, elegant not childish',
'E':'intimate cinematic romantic ambient, piano, cello, restrained lush strings, soft choir pads, shimmering synths, sincere hopeful tender future-facing atmosphere'
}
STAGES={
'0':'night prologue, dormant observatory, one fragile spark awakening, very sparse celestial piano and air, mysterious hopeful',
'1':'central observatory awakening, magical archive hub motif, wonder, celestial neoclassical ambience',
'2':'warmth and light puzzle wing, comforting golden chamber ambient, harp, soft piano, warm glow',
'3':'life and voice wing, resonant call and response, breath, echo, subtle pulse, intimate ambient',
'4':'first meeting memory in fantasy raid, calm dreamlike raid atmosphere, distant choir soft strings, little percussion, ordinary moment becoming meaningful',
'5':'laughter and lightness wing, playful elegant chamber fantasy, pizzicato celesta bells, buoyant motion',
'6a':'egg memory stealth, mischievous playful fantasy raid tension, pizzicato muted percussion, sneaky funny',
'6b':'egg memory chase, energetic fantasy raid action, rhythmic percussion short strings, exciting funny not deadly',
'7':'seriousness and smile wing, reflective chamber piano legato strings, restrained warmth, brief playful motif',
'8':'sincerity and admiration wing, intimate celestial romantic ambience, shimmering textures piano restrained strings',
'9':'possible future meeting, hopeful intimate cinematic ambient, fantasy dissolves to simple piano cello, open tender without certainty',
'10':'return to restored observatory, richer reprise archive motif, anticipation before final revelation',
'11':'final order of light puzzle, structured celestial neoclassical, gentle pulse, symbols aligning, calm meaningful',
'12':'poem assembly, sparse intimate music leaving room for text, soft piano glass minimal strings',
'13':'acrostic reveal, restrained luminous magical reveal, silence-friendly, not bombastic',
'14':'confession, extremely sparse sincere near-silence, isolated soft piano, no climax hit',
'15':'dawn epilogue, resolved hopeful warm archive-theme reprise, piano strings, quiet closure, pre-dawn to morning'
}

def read_window(path,start_s,dur_s=10,target_sr=48000):
    info=sf.info(path); start=max(0,int(start_s*info.samplerate)); frames=min(int(dur_s*info.samplerate),max(0,info.frames-start))
    if frames<=0: return np.zeros(int(dur_s*target_sr),dtype=np.float32),target_sr
    with sf.SoundFile(path) as f:
        f.seek(start); y=f.read(frames=frames,dtype='float32',always_2d=True).mean(axis=1)
    if info.samplerate!=target_sr: y=librosa.resample(y,orig_sr=info.samplerate,target_sr=target_sr)
    return y.astype(np.float32),target_sr

def loop_score(path,dur):
    a,sr=read_window(path,0,8,22050); b,_=read_window(path,max(0,dur-8),8,22050); n=min(len(a),len(b)); a=a[:n]; b=b[:n]
    if n<sr:return 0.0
    ca=librosa.feature.chroma_cqt(y=a,sr=sr).mean(axis=1); cb=librosa.feature.chroma_cqt(y=b,sr=sr).mean(axis=1)
    chrom=float(np.dot(ca,cb)/(np.linalg.norm(ca)*np.linalg.norm(cb)+1e-9)); ra=float(np.sqrt(np.mean(a*a))+1e-9); rb=float(np.sqrt(np.mean(b*b))+1e-9)
    loud=max(0,1-min(abs(20*np.log10(ra)-20*np.log10(rb))/18,1)); return float(np.clip(.65*chrom+.35*loud,0,1))

def technical(path):
    info=sf.info(path); dur=float(info.duration); ys=[]
    for frac in (.08,.47,.82):
        y,sr=read_window(path,max(0,dur*frac),12,22050); ys.append(y)
    y=np.concatenate(ys); rms=librosa.feature.rms(y=y)[0]; rms_db=librosa.amplitude_to_db(np.maximum(rms,1e-8),ref=1.0); onset=librosa.onset.onset_strength(y=y,sr=22050)
    tempo=float(np.atleast_1d(librosa.feature.tempo(onset_envelope=onset,sr=22050))[0]); cent=float(np.mean(librosa.feature.spectral_centroid(y=y,sr=22050)))
    yh,yp=librosa.effects.hpss(y); harm=float(np.sqrt(np.mean(yh*yh))+1e-9); perc=float(np.sqrt(np.mean(yp*yp))+1e-9); pr=perc/(harm+perc)
    sparse=float(np.clip((-np.mean(rms_db)-18)/32,0,1))*.55+float(np.clip(1-pr*2.2,0,1))*.45
    return {'duration_s':round(dur,2),'sample_rate':info.samplerate,'channels':info.channels,'tempo_bpm':round(tempo,1),'rms_dbfs':round(float(np.mean(rms_db)),2),'dynamic_range_db':round(float(np.percentile(rms_db,90)-np.percentile(rms_db,10)),2),'spectral_centroid_hz':round(cent,1),'percussive_ratio':round(pr,3),'sparse_score':round(sparse,3),'loop_score':round(loop_score(path,dur),3)}

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()

def main():
    tracks=sorted(Path('music').rglob('*.wav')); print('TRACK_COUNT',len(tracks),flush=True); rows=[]; seen={}
    for i,p in enumerate(tracks):
        h=sha256(p); r={'path':p.as_posix(),'filename':p.name,'sha256':h,'features':technical(p)}
        if h in seen:r['duplicate_of']=seen[h]
        else:seen[h]=p.as_posix()
        rows.append(r); print('TECH',i+1,len(tracks),p,r['features'],flush=True)
    unique=[r for r in rows if 'duplicate_of' not in r]
    import torch
    from transformers import ClapModel,ClapProcessor
    model_id='laion/clap-htsat-unfused'; proc=ClapProcessor.from_pretrained(model_id); model=ClapModel.from_pretrained(model_id).eval()
    labels=list(GROUPS.items())+[(f'STAGE_{k}',v) for k,v in STAGES.items()]; texts=[v for _,v in labels]
    ti=proc(text=texts,return_tensors='pt',padding=True)
    with torch.no_grad():te=model.get_text_features(**ti); te=te/te.norm(dim=-1,keepdim=True)
    for i,r in enumerate(unique):
        p=Path(r['path']); dur=r['features']['duration_s']; samples=[]
        for frac in (.18,.50,.78):
            y,_=read_window(p,max(0,dur*frac-5),10,48000); samples.append(y)
        ai=proc(audios=samples,sampling_rate=48000,return_tensors='pt',padding=True)
        with torch.no_grad():ae=model.get_audio_features(**ai); ae=ae/ae.norm(dim=-1,keepdim=True); ae=ae.mean(dim=0,keepdim=True); ae=ae/ae.norm(dim=-1,keepdim=True)
        sims=(ae@te.T).squeeze(0).cpu().numpy(); gs={k:float(sims[j]) for j,(k,_) in enumerate(labels) if not k.startswith('STAGE_')}; ss={k.replace('STAGE_',''):float(sims[j]) for j,(k,_) in enumerate(labels) if k.startswith('STAGE_')}
        r['group_scores']={k:round(v,4) for k,v in sorted(gs.items(),key=lambda x:-x[1])}; r['stage_scores']={k:round(v,4) for k,v in sorted(ss.items(),key=lambda x:-x[1])}; r['best_group']=max(gs,key=gs.get); r['best_stages']=[k for k,_ in sorted(ss.items(),key=lambda x:-x[1])[:5]]
        print('CLAP',i+1,len(unique),r['path'],r['best_group'],r['best_stages'],flush=True)
    by={r['path']:r for r in rows}
    for r in rows:
        if 'duplicate_of' in r:
            src=by[r['duplicate_of']]
            for k in ('group_scores','stage_scores','best_group','best_stages'):r[k]=src.get(k)
    with open(OUT/'audio_reaudit.json','w',encoding='utf-8') as f:json.dump(rows,f,ensure_ascii=False,indent=2)
    print('===ROWS_BEGIN===')
    for r in rows:print('AUDIT_ROW '+json.dumps(r,ensure_ascii=False,separators=(',',':')))
    print('===ROWS_END===')

if __name__=='__main__':main()
