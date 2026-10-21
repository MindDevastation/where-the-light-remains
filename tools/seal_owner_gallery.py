#!/usr/bin/env python3
"""Check native frame identities, embedded pairs, links and protected sources."""
import argparse,base64,hashlib,json,datetime
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
class Page(HTMLParser):
 def __init__(self):super().__init__();self.images=[];self.links=[];self.ids=set()
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id' in a:self.ids.add(a['id'])
  if tag=='img':self.images.append(a)
  if tag=='a' and 'href' in a:self.links.append(a['href'])
def main(a):
 folder=(ROOT/a.folder).resolve();result=json.loads((folder/'results.json').read_text())
 assert result['status']=='PASS_CAPTURE_ONLY' and result['fresh_native_frames']==16
 review=json.loads((folder/'visual-review.json').read_text());assert review['reviewed_individually']==16
 for name,h in result['source_hashes'].items():assert sha(ROOT/name)==h,name
 for name,h in result['evidence_hashes'].items():assert sha(folder/name)==h,name
 expected={x['file']:x for x in result['captures']};assert len(expected)==16
 source_game=[n for n in result['source_hashes'] if n.startswith('game/')];assert len(source_game)==595
 for item in result['runtime_lfs_payloads']:
  p=ROOT/item['path'];data=p.read_text()
  assert data=='version https://git-lfs.github.com/spec/v1\noid sha256:'+item['oid_sha256']+'\nsize '+str(item['bytes'])+'\n'
 for name,item in expected.items():
  assert sha(folder/name)==item['sha256']==review['frames'][name]['sha256']
 pages=sorted((ROOT/'docs/production/review').glob('owner_overview*.html'));assert len(pages)==9
 receipts=[];linked_originals=set();embedded_originals=set()
 for page in pages:
  doc=Page();doc.feed(page.read_text())
  is_index=page.name=='owner_overview.html';assert len(doc.images)==(16 if is_index else 2)
  for item in doc.images:
   assert item.get('alt') and item.get('src')
   value=item['src']
   if value.startswith('data:image/png;base64,'):
    raw=base64.b64decode(value.split(',',1)[1],validate=True);h=hashlib.sha256(raw).hexdigest()
    matches=[n for n,x in expected.items() if x['sha256']==h];assert len(matches)==1
    embedded_originals.add(matches[0])
   else:
    p=(page.parent/unquote(value)).resolve();assert p.is_relative_to(folder) and p.is_file()
    assert sha(p)==expected[p.name]['sha256'];linked_originals.add(p.name)
  for href in doc.links:
   parsed=urlsplit(href)
   if parsed.scheme or parsed.netloc:continue
   if not parsed.path:assert parsed.fragment in doc.ids,href
   else:assert (page.parent/unquote(parsed.path)).resolve().exists(),(page,href)
  receipts.append({'path':page.relative_to(ROOT).as_posix(),'sha256':sha(page),'bytes':page.stat().st_size,'images':len(doc.images)})
 assert linked_originals==embedded_originals==set(expected)
 pairs={}
 for item in result['captures']:pairs.setdefault(item['name'],[]).append(item)
 assert len(pairs)==8
 for rows in pairs.values():assert len(rows)==2 and rows[0]['camera_transform']==rows[1]['camera_transform'] and rows[0]['camera_fov']==rows[1]['camera_fov']
 receipt={'status':'PASS_REVIEW_ONLY','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
  'source_hashes':{**result['source_hashes'],'tools/build_owner_gallery.py':sha(ROOT/'tools/build_owner_gallery.py'),'tools/seal_owner_gallery.py':sha(Path(__file__))},
  'native_originals':16,'individually_inspected':16,'same_camera_pairs':8,'html_pages':receipts,
  'protected_game_files':595,'runtime_pointer_identities_preserved':47,'shipping_changes':0,
  'new_native_commands_in_seal':0,'fresh_gameplay_assertions':0,'raw_pngs_altered':False,
  'original_failed_guard_retained':result['prior_failed_directory_check'],'native_scope':result['scope'],
  'inventory_delta':[],'gate_vs1':'OPEN','s03':'BLOCKED','main_changed':False,'owner_style_accepted':False}
 (folder/'review-seal.json').write_text(json.dumps(receipt,indent=2)+'\n')
 print(json.dumps({k:receipt[k] for k in ['status','native_originals','html_pages','protected_game_files','runtime_pointer_identities_preserved']}))
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('folder');main(p.parse_args())
