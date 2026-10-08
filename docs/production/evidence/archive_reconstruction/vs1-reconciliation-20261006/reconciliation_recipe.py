from pathlib import Path
import json,re,hashlib,collections,subprocess,datetime
r=Path('/workspace/scratch/0152d86aa631/where-the-light-remains');d=r/'docs/production'; canonical=r/'docs/design/REQUIRED_ASSET_TABLE.md'
rows=[];section=''
for l in canonical.read_text().splitlines():
 if l.startswith('## '):section=l[3:]
 if l.startswith('|'):
  c=[x.strip() for x in l.strip('|').split('|')]
  if len(c)==8 and c[1] in ['MUST','FALLBACK']:rows.append(dict(section=section,id=c[0],kind=c[1],category=c[2],requirement=c[3],stages=c[4],reuse=c[5],variants=c[6],canonical_notes=c[7]))
assert len(rows)==185
# Explicit statuses apply to required production scope, not functional graybox acceptance.
choices={}
def put(ids,status,note,paths=[]):
 for id in ids.split(','):choices[id]=(status,note,paths)
put('ARCH-001,ARCH-002,ARCH-003,ARCH-008,ARCH-011,ARCH-012,ARCH-013,ARCH-017,ARCH-018','MISSING','No corresponding production shell/portal/rotunda/window/stair/railing/recess/backdrop family; graybox and concept images are not assets.',['game/worlds/archive/archive_main.tscn','game/worlds/archive/archive_prologue.tscn'])
put('ARCH-004','ACCEPTED','2/3/4m authored wall family integrated in corridor and Wing I; broader Hub/exterior composition remains open.',['docs/production/ASSET_INDEX.md','game/worlds/archive/wing01_room_presentation.tscn'])
put('ARCH-005','PARTIAL','One original arch is accepted and instanced; second required global variant absent.',['game/worlds/archive/modules/archive_arch_4m.tscn'])
put('ARCH-006','PARTIAL','Authored floor module and corridor/room composition accepted; full global 2–3 variation coverage not claimed.',['game/worlds/archive/wing01_room_floor.tscn'])
put('ARCH-007','ACCEPTED','10m/12m ribs, transitions and dome integrated with bounded roof evidence; not Hub/exterior ceiling approval.',['docs/production/WING01_CEILING_ACCEPTANCE.md','docs/production/WING01_ROOF_INTEGRATION.md'])
put('ARCH-009','PARTIAL','One 4m pier accepted; second global height absent.',['game/worlds/archive/modules/archive_pier_4m.tscn'])
put('ARCH-010','PARTIAL','Optical stepped plinth and Hearth pedestal accepted; full 3-height standalone family absent.',['docs/production/WING01_OPTICS_SAMPLE.md','docs/production/WING01_HEARTH_EMITTER.md'])
put('ARCH-014','MISSING','Five functional barriers/states are validated, but their BoxMesh is graybox, not an authored shared gate.',['game/worlds/archive/common/archive_gate.tscn'])
put('ARCH-015','PARTIAL','Existing route ownership/pulses accepted; Hub strip is still a BoxMesh, no authored channel trim. Reusable S02 beam does not close this row.',['game/worlds/archive/common/archive_light_channel.tscn','docs/production/WING01_BEAM_STAR_ACCEPTANCE.md'])
put('ARCH-016','ACCEPTED','Accepted corridor/threshold assembly, exact shipping placement; no new level or collision redesign.',['game/worlds/archive/wing01_corridor_presentation.tscn'])
put('PROP-001,PROP-002','MISSING','Hub hero remains primitive body/two TorusMesh rings. Canon requires complete mechanism/3–5 pieces; reference ring counts cannot silently redesign existing drivers.',['game/worlds/archive/archive_main.tscn'])
put('PROP-003','ACCEPTED','Editable source, lens/socket/installed runtime instances, actual E/save/quiet and independent LFS evidence.',['docs/production/S01_STARTING_LENS_ACCEPTANCE.md'])
put('PROP-004','PARTIAL','S01 base/cover and lever child variants accepted inside original target contracts; full console/mounting and universal skins not accepted. Unused later-stage skins are not the next VS1 priority.',['docs/production/S01_HUB_CONTROLS_ACCEPTANCE.md'])
put('PROP-005','PARTIAL','S02 focus wheel is an accepted original rotary master; generic reuse is not instantiated elsewhere and ASSET_INDEX older not-produced wording must not force a duplicate wheel.',['docs/production/WING01_OPTICS_SAMPLE.md','game/gameplay/puzzles/wing01/wing01_optics_sample.tscn'])
put('PROP-006','PARTIAL','Two bounded shapes exist: S01 lever and S00 bolt. Earlier second-shape-not-produced wording is superseded; global adoption/stopper variants remain open.',['docs/production/S01_HUB_CONTROLS_ACCEPTANCE.md','docs/production/S00_DOOR_LOCK_ACCEPTANCE.md'])
put('PROP-007','MISSING','No original fragment shell/stand source or GLB. Existing optical pedestal and Hearth bowl are their puzzle assets, not the specified shared fragment carrier.',['game/gameplay/collectibles/fragment_presenter.tscn'])
put('SIG-001–010','PARTIAL','Only canonical Star/Hearth SVGs and their presentation are implemented; remaining eight glyphs belong to gated stages.',['game/art/sigils/star.svg','game/art/sigils/hearth.svg'])
for id,name in [('MAT-001','m_aged_brass'),('MAT-003','m_dark_walnut'),('MAT-004','m_observatory_stone'),('MAT-006','m_clear_glass'),('MAT-009','m_archive_parchment'),('MAT-010','m_crimson_textile'),('MAT-014','m_archive_emissive_gold')]:
 put(id,'ACCEPTED','Shared authored runtime material accepted in documented bounded integration; representative full-slice lighting remains open.',['game/art/materials/'+name+'.tres','docs/production/MATERIAL_LIBRARY.md'])
put('MAT-002,MAT-005,MAT-011,MAT-012,TRIM-001,TRIM-002,DECAL-001','MISSING','No distinct required production master/atlas/trim file. Tileables/micro-wear are not a trim or decal atlas; palette-only primitive material is not an authored surface.')
put('VFX-001','ACCEPTED','Shared beam immutable mesh/shaders accepted for S02; other route/global variants not implicitly approved.',['docs/production/WING01_BEAM_STAR_ACCEPTANCE.md'])
put('VFX-002','MISSING','S00 spark is still an emissive SphereMesh; no authored guided-mote particle/trail family.',['game/worlds/archive/archive_prologue.tscn'])
put('VFX-003','PARTIAL','Existing pausable route pulses/target feedback functional; final unified chime/pulse presentation and audio unbound.',['game/worlds/archive/common/archive_light_channel.gd'])
put('VFX-004,VFX-006,VFX-007','MISSING','No production materialize/dissolve, ambient dust particle or shared inspect-highlight family. Quiet Star breathing and local Flame are separate accepted effects, not these assets.')
put('UI-001,UI-002,UI-003','ACCEPTED','Russian/Cyrillic runtime reticle, interaction and hint widgets validated; retain accepted behavior.',['docs/production/IMPLEMENTATION_PLAN.md'])
put('UI-004,UI-005','PARTIAL','Fragment card and menu/pause/settings ship functional accepted widgets; final v2 presentation/style pass remains open.',['game/gameplay/collectibles/fragment_presenter.tscn','docs/production/IMPLEMENTATION_PLAN.md'])
put('FONT-001,FONT-002','PARTIAL','Cyrillic runtime uses engine/system fallback; no tracked licensed authored font files/redistribution proof for the full requested families.')
put('CAM-001','ACCEPTED','Persistent first-person rig accepted; no reimplementation.',['game/core/player/first_person_player.tscn'])
put('CAM-002','PARTIAL','S00 timed rail/camera handoff/pause accepted; generic later paths and final exterior composition remain open.',['game/worlds/archive/archive_prologue.gd'])
put('SAVE-ART-001','ACCEPTED','Existing subtle checkpoint notice accepted; no new persistent state or noisy popup.',['game/core/ui/checkpoint_notice.gd'])
put('ANIM-008','PARTIAL','Existing seven-second core awakening and two ring drivers accepted; full 3–5 authored ring/final sequence remains open.')
put('ANIM-009','PARTIAL','Star breathing/fragment modal and quiet restoration accepted; full shared reveal/float/settle rig not authored.')
put('ANIM-010','PARTIAL','S00 sliding leaves and Hub gate timing/state accepted; door/gate production meshes remain open.',['game/worlds/archive/archive_prologue.gd'])
put('S00-001','MISSING','No authored exterior shell/portal/backdrop/approach; current continuous scene is functional graybox only.')
put('S00-002','MISSING','First-spark event/audio ownership and visibility accepted, but guided-mote production visual absent.')
put('S00-003','PARTIAL','Existing night ambient/fill; required composed moon fill plus one warm practical and full exterior review absent.')
put('S00-004','PARTIAL','Actual rail/pause/handoff accepted; composition requires exterior completion.')
put('S00-005','ACCEPTED','848-triangle original housing/bolt/keeper, actual release/pause/physical restore and independent LFS acceptance.',['docs/production/S00_DOOR_LOCK_ACCEPTANCE.md'])
put('S01-001','MISSING','Full central hero core and console have no production source/GLB; two graybox ring primitives not production art.')
put('S01-002,S01-003','ACCEPTED','Original accepted pickup lens/socket and existing paths/targets/save projection.',['docs/production/S01_STARTING_LENS_ACCEPTANCE.md'])
put('S01-004','MISSING','All five gates/state bindings accepted functionally; no authored gate production family.')
put('S01-005','PARTIAL','Five route pulses/states exist, but authored channel mesh/material composition remains open.')
put('S01-006','PARTIAL','Sleeping/awakened light state implemented; complete rotunda/core composition not present.')
put('S02-001,S02-003','ACCEPTED','Three original optical rings/five-position focus carrier accepted and wired to actual existing puzzle; no remodel justified.',['docs/production/WING01_OPTICS_SAMPLE.md'])
put('S02-002','ACCEPTED','Original emitter, reusable beam and quiet canonical Star target accepted; room gate remains open.',['docs/production/WING01_HEARTH_EMITTER.md','docs/production/WING01_BEAM_STAR_ACCEPTANCE.md'])
put('S02-004','ACCEPTED','Original bowl/pedestal and local Flame plus actual warm projection accepted.',['docs/production/WING01_HEARTH_EMITTER.md','docs/production/WING01_HEARTH_FLAME.md'])
put('S02-005,S02-006','PARTIAL','Canonical SVG/couplet/feeling modal, acquisition and physical quiet load accepted; shared world carrier missing.',['game/gameplay/collectibles/fragment_presenter.tscn'])
put('S02-007','PARTIAL','Real cold/warm projections and scoped native room evidence accepted; final full-room material/lighting/art/GPU gate open.')
# Exact canonical stage relevance, including transition arrows; scope excludes endgame-only interfaces.
def stages(s):
 out=set()
 for token in s.replace(' ', '').split(','):
  m=re.fullmatch(r'(\d+)[–-](\d+)',token)
  if m:out.update(range(int(m[1]),int(m[2])+1))
  else:out.update(map(int,re.findall(r'\d+',token)))
 return out
future_only={'UI-006','UI-007','VFX-005','CHAR-006'}
for row in rows:
 relevant=bool(stages(row['stages'])&{0,1,2}) or row['stages']=='global'
 if row['id'] in future_only:relevant=False
 row['required_for_vs1']=relevant
 if not relevant: row.update(status='NOT REQUIRED FOR VS1',finding='Canonical use belongs to gated stages/endgame; no production execution in this session.',evidence_paths=[])
 else:
  assert row['id'] in choices,row['id']
  status,note,paths=choices[row['id']];row.update(status=status,finding=note,evidence_paths=paths)
# Static serialized instance dependency graph: preserves exact owners without re-running accepted engine preflights.
refs={};instances=[];missing=[]
def walk(path,owner,stack):
 rel='game/'+path.removeprefix('res://');p=r/rel
 if not p.exists():missing.append(rel);return
 if rel in stack:raise RuntimeError('Scene cycle')
 refs[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
 s=p.read_text();ext={m[1]:m[0] for m in re.findall(r'\[ext_resource[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"',s)}
 for header in re.findall(r'\[node[^\n]+\]',s):
  match=re.search(r'instance=ExtResource\("([^"]+)"\)',header)
  if not match:continue
  name=re.search(r'name="([^"]+)"',header)[1];parent=re.search(r'parent="([^"]+)"',header)
  node=owner+'/'+('' if not parent or parent[1]=='.' else parent[1]+'/')+name;resource=ext[match[1]];f=r/('game/'+resource.removeprefix('res://'))
  instances.append({'owner':node,'resource':resource,'exists':f.is_file()})
  if resource.endswith('.tscn'):walk(resource,node,stack+[rel])
  elif not f.is_file():missing.append(str(f.relative_to(r)))
walk('res://worlds/archive/archive_main.tscn','ArchiveMain',[]);assert not missing,missing
v2=json.loads((d/'visual_rebaseline_v2.json').read_text());reference_rows=[{'id':s['slot'],'status':'REFERENCE-ONLY','angles':s['angles'],'stage':s['stage'],'production_asset':False} for s in v2['slots']]
legacy=[{'id':v['retained_at'],'status':'SUPERSEDED','production_asset':False} for v in v2['old_to_new']]
prior=[]
for p in (d/'evidence').rglob('results.json'):
 if 'acceptance' not in p.parent.name:continue
 v=json.loads(p.read_text());h={n:x for n,x in v.get('source_hashes',{}).items() if n.startswith(('assets/3d/blender/','game/art/','game/worlds/archive/modules/','game/worlds/archive/wing01_'))}
 assert v.get('status')=='PASS';assert all((r/n).is_file() and hashlib.sha256((r/n).read_bytes()).hexdigest()==x for n,x in h.items()),str(p)
 prior.append({'receipt':p.relative_to(r).as_posix(),'status':'PASS','current_art_hashes_checked':len(h),'scope':'Only art/module subset checked; historical controller/source seal not re-promoted as current.'})
source_paths=[canonical.relative_to(r).as_posix(),'docs/production/visual_rebaseline_v2.json','docs/production/ASTRA_WORKFLOW.md','docs/production/THREE_D_PRODUCTION_PIPELINE.md','docs/design/NARRATIVE_CANON.md']+list(refs)
source_paths += [p.relative_to(r).as_posix() for p in (r/'assets/3d/blender').rglob('*.blend')]+[p.relative_to(r).as_posix() for p in (r/'game/art').rglob('*') if p.is_file() and '.godot' not in p.parts]
source_paths += [x['receipt'] for x in prior]
source_paths += [a for s in v2['slots'] for a in s['angles'].values() if s['stage'].startswith(('S00','S01','S02')) or 'production_sheets' in s['slot']]
source_hashes={n:hashlib.sha256((r/n).read_bytes()).hexdigest() for n in set(source_paths)}
output=d/'evidence/archive_reconstruction/vs1-reconciliation-20261006';output.mkdir()
counts=dict(collections.Counter(x['status'] for x in rows if x['required_for_vs1']))
result={'status':'PASS','started_from_remote_sha':'c186b4fa39721d88416091a714e633de28cba5a8','finished_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'scope':'Complete canonical 185-row classification, including all VS1 stage/shared dependencies; static serialized production owners and current art subset of prior receipts. No new engine/Blender/preflight execution, no full visual or physical GPU acceptance.','canonical_row_count':185,'vs1_counts':counts,'source_hashes':source_hashes,'mandatory_rows':rows,'references':reference_rows,'superseded':legacy,'serialized_instances':instances,'prior_acceptance_art_checks':prior,'ranked_bounded_work':[{'priority':1,'family':'S00 timber entrance leaf skin','reason':'ARCH-002/S00-001 missing production leaf; exact existing 1.3x3.8x.25 body and lock interface permit ordinary modeling without exterior/layout design.'},{'priority':2,'family':'S01 core lower housing/console mounting leaf','reason':'PROP-001/004 missing hero housing around existing 1m radius/1.4m collision and existing accepted controls. Ring/rotunda design remains separate.'},{'priority':3,'family':'S00 guided spark local presentation','reason':'VFX-002 production missing, preserve current clock/event/audio/rail contract.'},{'priority':4,'family':'PROP-007 shared fragment carrier','reason':'World carrier missing; requires integrating exact Star/Hearth visibility and geometry safely.'}], 'global_blockers':['Full S00/S15 reusable exterior and Hub rotunda architecture need approved breakdown/fit per pipeline; no mass construction from perspective.','Target GTX1060-class physical device unavailable; software scope explicitly excludes its gate.','Authored audio derivatives are technical review candidates, no binding/motif/mix acceptance.']}
(output/'results.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=['# Exact S00/S01/S02 mandatory-art reconciliation — 2026-10-06','','Recovered exact remote c186b4f; no older snapshot/preflight reapplied.185 canonical groups are exhaustively classified in the accompanying JSON. All serialized ArchiveMain dependencies exist;14 prior acceptance art subsets retain current identities. Whole historical gameplay receipts are not declared current after later integration.','','Statuses apply to documented production art, separate from accepted runtime functionality. ACCEPTED always means the listed bounded scope. Missing final composition is not a defect in accepted leaf models. Concept slots are REFERENCE-ONLY;62 legacy entries are SUPERSEDED. Future/endgame-only rows are NOT REQUIRED FOR VS1, not finished game content.','',f'VS1-related rows: {counts}. Counts are not weighted percent completion.','','| ID | Status | Canonical requirement / current finding | Evidence |','| --- | --- | --- | --- |']
for x in rows:
 if x['required_for_vs1']:lines.append('| '+x['id']+' | '+x['status']+' | '+x['requirement'].replace('|','/')+'; '+x['finding']+' | '+', '.join(x['evidence_paths'])+' |')
lines += ['','## Priority after complete reconciliation','','1. Missing S00 timber entrance leaf production skin, keeping original BoxShape/body/bolt/slide path. This is part of ARCH-002, not completion of its portal/exterior.','2. Missing lower Hub core housing/console mounting inside original collision; accepted controls/lens remain unchanged. Full central orbit/rotunda remains an independent design scope.','3. S00 local spark visual, retaining event/clock/pause/audio/save behavior.','4. Shared fragment carrier and representative final lighting/gallery once surrounding geometry exists.','','Universal panel/handle audit: S01 base/cover + lever child already provide current slice interfaces. The original focus wheel is actual S02 rotary hardware (older PROP-005 not-produced wording is historical). S00 bolt now provides the second bounded PROP-006 shape. Future skin/master adoption still PARTIAL; no duplicate uninstantiated future knobs/panels will be made ahead of missing VS1 hero geometry.','','The three-ring S02 apparatus is accepted and must not be altered to match crystal/ring drift in references. Canonical Hub3–5 orbit pieces cannot be inferred from two current primitive drivers or copied count from concepts; complete hero integration needs its own exact brief.','','Source hashes, every185 mandatory row,45 reference slots,62 superseded entries, serialized owners and14 accepted art-subset checks: evidence/archive_reconstruction/vs1-reconciliation-20261006/results.json. GATE-VS1 remains OPEN: full exterior/Hub hero/gates/channels, remaining material/trim/VFX/font/presentation, authored audio/mix, full gallery and physical GPU. S03 remains gated.']
(d/'VS1_ART_RECONCILIATION.md').write_text('\n'.join(lines)+'\n')
print('PASS',counts,'serialized instances',len(instances),'source hashes',len(source_hashes))
