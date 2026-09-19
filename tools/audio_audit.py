import os, json, math, hashlib
from pathlib import Path
import numpy as np
import soundfile as sf
import librosa

ROOT = Path('.')
OUT = Path('audio_audit_output')
OUT.mkdir(exist_ok=True)

GROUPS = {
 'A': 'celestial neoclassical romantic ambient music for a magical observatory archive, soft piano, chamber strings, celesta, glass harmonics, gentle choir, mysterious and tender, no heavy percussion',
 'B': 'intimate magical chamber ambient about warmth, light, life and voice, felt piano, harp, soft strings, glass tones, resonance, breathing space, warm and gentle',
 'C': 'dreamlike fantasy raid score, low strings, restrained frame drums, distant horns, fantasy choir, modal harmony, playful tension and action, cinematic game memory',
 'D': 'playful chamber fantasy with pizzicato strings, celesta, soft mallets, bells, harp and light whimsical motion, elegant not childish, reflective variation possible',
 'E': 'intimate cinematic romantic ambient, piano, cello, restrained lush strings, soft choir pads, shimmering synths, sincere hopeful tender future-facing atmosphere'
}

STAGES = {
 '0': 'quiet mysterious prologue at night, fragile spark, sparse celestial piano and air, melancholy but hopeful',
 '1': 'central observatory awakening, magical archive hub motif, wonder, gentle celestial neoclassical ambience',
 '2': 'warmth and light puzzle wing, comforting golden chamber ambient, harp, soft piano, warm glow',
 '3': 'life and voice puzzle wing, resonant call and response, breath, echo, subtle pulse, intimate ambient',
 '4': 'first meeting memory in a fantasy raid, calm dreamlike raid atmosphere, distant choir and soft strings, little percussion',
 '5': 'laughter and lightness wing, playful elegant chamber fantasy, pizzicato, celesta, bells, buoyant motion',
 '6a': 'egg memory stealth, mischievous playful fantasy raid tension, soft pizzicato and muted percussion',
 '6b': 'egg memory chase, energetic fantasy raid action, rhythmic percussion, short strings, exciting but funny not deadly',
 '7': 'seriousness and smile wing, reflective chamber music, piano and legato strings, restrained warmth, subtle return of playful motif',
 '8': 'sincerity and admiration wing, intimate celestial romantic ambience, shimmering textures, piano, restrained strings, beautiful and honest',
 '9': 'future memory, hopeful intimate cinematic ambient, fantasy gradually dissolving to simple piano and cello, open and tender',
 '10': 'return to restored observatory, richer reprise of archive motif, anticipation before final revelation',
 '11': 'final order of light puzzle, structured celestial neoclassical music, gentle pulse, symbols aligning, meaningful but calm',
 '12': 'poem assembly, sparse intimate music leaving room for text, soft piano, glass, minimal strings',
 '13': 'acrostic reveal, restrained magical reveal, luminous but not bombastic, silence-friendly',
 '14': 'confession scene, extremely sparse sincere music or near silence, soft piano, emotionally honest, no climax hit',
 '15': 'dawn epilogue, resolved hopeful warm version of archive theme, dawn light, piano and strings, quiet closure'
}

# Krumhansl-Schmuckler profiles
MAJ = np.array([6.35,2.23,3.48,2.33,4.38,4.09,2.52,5.19,2.39,3.66,2.29,2.88])
MIN = np.array([6.33,2.68,3.52,5.38,2.60,3.53,2.54,4.75,3.98,2.69,3.34,3.17])
NOTE_NAMES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']

def read_window(path, start_s, dur_s=12.0, target_sr=22050):
    info = sf.info(path)
    start = max(0, int(start_s * info.samplerate))
    frames = min(int(dur_s * info.samplerate), max(0, info.frames - start))
    if frames <= 0:
        return np.zeros(int(dur_s*target_sr), dtype=np.float32), target_sr
    with sf.SoundFile(path) as f:
        f.seek(start)
        y = f.read(frames=frames, dtype='float32', always_2d=True).mean(axis=1)
    if info.samplerate != target_sr:
        y = librosa.resample(y, orig_sr=info.samplerate, target_sr=target_sr)
    return y.astype(np.float32), target_sr

def safe_db(x):
    return 20*np.log10(max(float(x),1e-9))

def key_estimate(y, sr):
    chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
    prof = np.nan_to_num(chroma.mean(axis=1))
    if np.linalg.norm(prof)==0:
        return 'Unknown', 0.0
    prof = (prof-prof.mean())/(prof.std()+1e-9)
    best = (-99,None)
    for root in range(12):
        for mode, tpl in [('major',MAJ),('minor',MIN)]:
            t=np.roll(tpl,root); t=(t-t.mean())/(t.std()+1e-9)
            s=float(np.dot(prof,t)/(np.linalg.norm(prof)*np.linalg.norm(t)+1e-9))
            if s>best[0]: best=(s,(root,mode))
    return f"{NOTE_NAMES[best[1][0]]} {best[1][1]}", best[0]

def loop_score(path, duration):
    a,sr = read_window(path, 0, 8)
    b,_ = read_window(path, max(0,duration-8), 8)
    n=min(len(a),len(b)); a=a[:n]; b=b[:n]
    if n<sr: return 0.0
    ca=librosa.feature.chroma_cqt(y=a,sr=sr).mean(axis=1)
    cb=librosa.feature.chroma_cqt(y=b,sr=sr).mean(axis=1)
    chrom=float(np.dot(ca,cb)/(np.linalg.norm(ca)*np.linalg.norm(cb)+1e-9))
    ra=float(np.sqrt(np.mean(a*a))+1e-9); rb=float(np.sqrt(np.mean(b*b))+1e-9)
    loud=max(0.0,1.0-min(abs(safe_db(ra)-safe_db(rb))/18.0,1.0))
    return float(np.clip(0.65*chrom+0.35*loud,0,1))

def technical(path):
    info=sf.info(path); dur=float(info.duration)
    starts=[max(0,dur*0.08), max(0,dur*0.47), max(0,dur*0.82)]
    ys=[]
    for st in starts:
        y,sr=read_window(path,st,12); ys.append(y)
    y=np.concatenate(ys); sr=22050
    rms=librosa.feature.rms(y=y,frame_length=2048,hop_length=512)[0]
    rms_db=librosa.amplitude_to_db(np.maximum(rms,1e-8),ref=1.0)
    onset=librosa.onset.onset_strength(y=y,sr=sr)
    tempo=float(np.atleast_1d(librosa.feature.tempo(onset_envelope=onset,sr=sr))[0]) if len(onset) else 0.0
    cent=float(np.mean(librosa.feature.spectral_centroid(y=y,sr=sr)))
    bw=float(np.mean(librosa.feature.spectral_bandwidth(y=y,sr=sr)))
    roll=float(np.mean(librosa.feature.spectral_rolloff(y=y,sr=sr,roll_percent=0.85)))
    zcr=float(np.mean(librosa.feature.zero_crossing_rate(y)))
    yh,yp=librosa.effects.hpss(y)
    harm=float(np.sqrt(np.mean(yh*yh))+1e-9); perc=float(np.sqrt(np.mean(yp*yp))+1e-9)
    percussive_ratio=perc/(harm+perc)
    key,key_conf=key_estimate(y,sr)
    dyn=float(np.percentile(rms_db,90)-np.percentile(rms_db,10))
    activity=float(np.mean(onset)/(np.std(onset)+1e-6)) if len(onset) else 0.0
    sparse=float(np.clip((-np.mean(rms_db)-18)/32,0,1))*0.55 + float(np.clip(1-percussive_ratio*2.2,0,1))*0.45
    brightness=float(np.clip((cent-700)/3000,0,1))
    ls=loop_score(path,dur)
    return {
      'duration_s':round(dur,2),'sample_rate':info.samplerate,'channels':info.channels,
      'tempo_bpm':round(tempo,1),'rms_dbfs':round(float(np.mean(rms_db)),2),'dynamic_range_db':round(dyn,2),
      'spectral_centroid_hz':round(cent,1),'bandwidth_hz':round(bw,1),'rolloff85_hz':round(roll,1),'zcr':round(zcr,5),
      'percussive_ratio':round(percussive_ratio,3),'brightness':round(brightness,3),'sparse_score':round(float(sparse),3),
      'loop_score':round(ls,3),'key':key,'key_confidence':round(key_conf,3)
    }

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def find_tracks():
    return sorted([p for p in Path('music').rglob('*.wav') if p.is_file()])

def clap_scores(records):
    try:
        import torch
        from transformers import ClapModel, ClapProcessor
        model_id='laion/clap-htsat-unfused'
        processor=ClapProcessor.from_pretrained(model_id)
        model=ClapModel.from_pretrained(model_id)
        model.eval()
        device='cuda' if torch.cuda.is_available() else 'cpu'
        model.to(device)
        labels=list(GROUPS.items())+[(f'STAGE_{k}',v) for k,v in STAGES.items()]
        texts=[x[1] for x in labels]
        ti=processor(text=texts,return_tensors='pt',padding=True)
        ti={k:v.to(device) for k,v in ti.items()}
        with torch.no_grad(): te=model.get_text_features(**ti)
        te=te/te.norm(dim=-1,keepdim=True)
        for idx,r in enumerate(records):
            path=Path(r['path']); dur=r['duration_s']
            samples=[]
            for frac in (0.18,0.50,0.78):
                y,sr=read_window(path,max(0,dur*frac-5),10,target_sr=48000); samples.append(y)
            ai=processor(audios=samples,sampling_rate=48000,return_tensors='pt',padding=True)
            ai={k:v.to(device) for k,v in ai.items()}
            with torch.no_grad(): ae=model.get_audio_features(**ai)
            ae=ae/ae.norm(dim=-1,keepdim=True); ae=ae.mean(dim=0,keepdim=True); ae=ae/ae.norm(dim=-1,keepdim=True)
            sims=(ae@te.T).squeeze(0).cpu().numpy()
            group_vals={k:float(sims[i]) for i,(k,_) in enumerate(labels) if not k.startswith('STAGE_')}
            stage_vals={k.replace('STAGE_',''):float(sims[i]) for i,(k,_) in enumerate(labels) if k.startswith('STAGE_')}
            r['group_scores']={k:round(v,4) for k,v in sorted(group_vals.items(),key=lambda x:-x[1])}
            r['stage_scores']={k:round(v,4) for k,v in sorted(stage_vals.items(),key=lambda x:-x[1])}
            r['best_group']=max(group_vals,key=group_vals.get)
            r['best_stages']=[k for k,v in sorted(stage_vals.items(),key=lambda x:-x[1])[:4]]
            print(f'CLAP {idx+1}/{len(records)} {r["path"]} -> {r["best_group"]} {r["best_stages"]}',flush=True)
        return True
    except Exception as e:
        print('CLAP_FAILED',repr(e),flush=True)
        return False

def heuristic_group(r):
    f=r['features']; p=f['percussive_ratio']; b=f['brightness']; s=f['sparse_score']; t=f['tempo_bpm']
    scores={
      'A':0.40+0.22*s+0.12*(1-p)+0.08*(1-abs(b-0.45)),
      'B':0.38+0.20*s+0.18*(1-p)+0.10*(1-abs(b-0.50)),
      'C':0.25+0.35*p+0.12*min(t/120,1)+0.08*(1-s),
      'D':0.28+0.24*p+0.22*b+0.10*min(t/110,1),
      'E':0.40+0.28*s+0.15*(1-p)+0.08*(1-abs(b-0.38))
    }
    return max(scores,key=scores.get),{k:round(v,4) for k,v in sorted(scores.items(),key=lambda x:-x[1])}

def main():
    tracks=find_tracks(); print('TRACK_COUNT',len(tracks),flush=True)
    records=[]; seen={}
    for i,p in enumerate(tracks):
        try:
            h=sha256(p); f=technical(p)
            rec={'path':p.as_posix(),'filename':p.name,'sha256':h,'features':f,'duration_s':f['duration_s']}
            if h in seen: rec['duplicate_of']=seen[h]
            else: seen[h]=p.as_posix()
            records.append(rec)
            print(f'TECH {i+1}/{len(tracks)} {p} dur={f["duration_s"]} bpm={f["tempo_bpm"]} sparse={f["sparse_score"]} loop={f["loop_score"]}',flush=True)
        except Exception as e:
            records.append({'path':p.as_posix(),'filename':p.name,'error':repr(e)})
            print('TECH_ERROR',p,repr(e),flush=True)
    ok=clap_scores([r for r in records if 'error' not in r and 'duplicate_of' not in r])
    # propagate duplicates and fallback heuristic
    by_path={r['path']:r for r in records}
    for r in records:
        if 'duplicate_of' in r:
            src=by_path[r['duplicate_of']]
            for k in ('group_scores','stage_scores','best_group','best_stages'): 
                if k in src: r[k]=src[k]
        if 'error' not in r and 'best_group' not in r:
            bg,gs=heuristic_group(r); r['best_group']=bg; r['group_scores']=gs; r['best_stages']=[]
    with open(OUT/'audio_audit.json','w',encoding='utf-8') as f: json.dump(records,f,ensure_ascii=False,indent=2)
    # CSV-like compact log rows for retrieval
    print('===AUDIT_ROWS_BEGIN===')
    for r in records:
        slim={k:r.get(k) for k in ['path','duplicate_of','best_group','best_stages']}
        slim['features']=r.get('features',{})
        slim['group_scores']=r.get('group_scores',{})
        slim['stage_scores']=r.get('stage_scores',{})
        if 'error' in r: slim['error']=r['error']
        print('AUDIT_ROW '+json.dumps(slim,ensure_ascii=False,separators=(',',':')))
    print('===AUDIT_ROWS_END===')
    # group counts
    counts={g:0 for g in GROUPS}
    for r in records:
        if r.get('best_group') in counts and 'duplicate_of' not in r: counts[r['best_group']]+=1
    print('GROUP_COUNTS',json.dumps(counts))
    print('UNIQUE_TRACKS',sum(1 for r in records if 'duplicate_of' not in r))
    print('CLAP_OK',ok)

if __name__=='__main__': main()
