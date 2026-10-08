#!/usr/bin/env python3
"""Build a self-contained read-only current-scene review from exact native PNGs."""
import base64,hashlib,html,json
from pathlib import Path
from collections import Counter

ROOT=Path(__file__).resolve().parents[1]
VIEWS=[('s00_closed','S00 · закрытый вход'),('s00_entry','S00 · открытый вход'),('s01_asleep','S01 · спящее ядро'),('s01_awakened','S01 · пробуждённый Hub'),('s02_entry_cold','S02 · холодный вход'),('s02_star','S02 · Звезда'),('s02_hearth','S02 · Очаг'),('s01_return','S01 · возвращение')]

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def build(folder):
 result=json.loads((folder/'results.json').read_text())
 assert result['status']=='PASS_CAPTURE_ONLY' and result['fresh_native_frames']==16
 for p,h in result['source_hashes'].items():assert digest(ROOT/p)==h,p
 for p,h in result['evidence_hashes'].items():assert digest(folder/p)==h,p
 inspected=json.loads((folder/'visual-review.json').read_text())
 assert inspected['reviewed_individually']==16 and len(inspected['frames'])==16
 rows={(x['name'],x['quality']):x for x in result['captures']}
 assert len(rows)==16
 sections=[];embedded=[]
 for name,title in VIEWS:
  figures=[]
  for quality in ['low','medium']:
   item=rows[name,quality];path=folder/item['file'];raw=path.read_bytes();assert digest(path)==item['sha256']
   assert inspected['frames'][item['file']]['sha256']==item['sha256']
   uri='data:image/png;base64,'+base64.b64encode(raw).decode()
   note=html.escape(inspected['frames'][item['file']]['observation'])
   figures.append(f'<figure><figcaption>{quality.title()} · 1280×720</figcaption><a href="{uri}" target="_blank"><img alt="{html.escape(title)} / {quality}" src="{uri}" loading="lazy"></a><p>{note}</p><details><summary>Камера и состояние</summary><pre>{html.escape(json.dumps(item,ensure_ascii=False,indent=2))}</pre></details></figure>')
   embedded.append({'file':item['file'],'sha256':item['sha256'],'bytes':len(raw)})
  sections.append(f'<section id="{name}"><h2>{html.escape(title)}</h2><div class="pair">'+''.join(figures)+'</div></section>')
 nav=' · '.join(f'<a href="#{name}">{html.escape(title)}</a>' for name,title in VIEWS)
 page='''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Where the Light Remains · текущая сцена S00–S02</title><style>body{margin:0;background:#111923;color:#e5e8eb;font:16px/1.55 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:28px}h1{font-size:clamp(24px,3vw,38px)}h2{margin-top:40px}a{color:#acd5ff}nav{line-height:2.2}p{max-width:1100px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}figure{margin:0;background:#192430;border:1px solid #344557;border-radius:8px;padding:12px}figcaption{font-weight:650;margin-bottom:8px}img{width:100%;height:auto;display:block}figure p{font-size:14px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px}details{margin-top:8px}.status{padding:14px;border-left:4px solid #e2b968;background:#25303b}@media(max-width:850px){.pair{grid-template-columns:1fr}main{padding:16px}}</style><main><h1>Where the Light Remains · S00–S02</h1><p class="status">Частичный обзор текущей сцены для владельца. 16 новых нативных кадров: 8 состояний × Low/Medium. GATE-VS1 открыт; S03 заблокирован. Это ещё не полная художественная приёмка.</p><p>Кадры получены в Godot 4.7.2, Forward+, X11, software llvmpipe. Выходной viewport 1280×720; действующие Low/Medium сохраняют свой внутренний масштаб и эффекты. Показаны текущие геометрия, материалы и свет, включая два временных torus-кольца ядра. Новые stone/linen/leaf/trim источники пока не назначены игровым носителям.</p><p>S00 использует образцы исходной камерной траектории. S01/S02 показывают проекции состояний в загруженной ArchiveMain с игровой камерой. Кадры не подтверждают прохождение, нажатия E, сохранение/загрузку, полный маршрут или производительность на целевой видеокарте. DTO, dirty и приватные контрольные файлы primary/backup сохранены.</p><p>Проверены существующие 47 runtime GLB по committed OID и размеру. Новые .blend/.glb здесь не созданы и не загружены. Инвентарь: 26 ACCEPTED / 44 PARTIAL / 7 MISSING; 185 строк сохранены. ARCH-011 ждёт решения A/B.</p><nav>'''+nav+'</nav>'+''.join(sections)+'''<h2>Открытые зависимости</h2><p>Авторские орбиты и крепления, UV-носитель каменного trim, оставшаяся архитектура и декор, растения, эмблемы и световые каналы, художественная приёмка, авторское аудио и целевая GPU остаются открытыми. Для следующего нового 3D-пакета нужны рабочая авторизация private LFS upload и восстановленный pinned Blender.</p><p><a href="../OWNER_GALLERY_READINESS.md">Граница проверки и доказательства</a> · <a href="../CORE_ORBITS_MOUNT_REVISION2.md">Исправленный контракт трёх орбит</a> · <a href="../STONE_TRIM_FIRST_INTEGRATION.md">Первый trim-носитель</a></p></main></html>'''
 out=ROOT/'docs/production/review/owner_overview.html';out.parent.mkdir(exist_ok=True);out.write_text(page)
 assert out.stat().st_size<8*1024**2
 receipt={'status':'PASS_EXACT_EMBEDDED_GALLERY','native_folder':folder.relative_to(ROOT).as_posix(),'gallery':out.relative_to(ROOT).as_posix(),'gallery_sha256':digest(out),'gallery_bytes':out.stat().st_size,'frames':embedded,'raw_pngs_altered':False,'reviewed_individually':16,'inventory_delta':[],'shipping_changes':0}
 (folder/'gallery-build.json').write_text(json.dumps(receipt,indent=2)+'\n')
 print(json.dumps({k:receipt[k] for k in ['status','gallery_bytes','reviewed_individually']}))
if __name__=='__main__':
 import sys
 build((ROOT/sys.argv[1]).resolve())
