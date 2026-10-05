#!/usr/bin/env node
/* Bounded, offline Chromium verification; never an acoustic/musical approval. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const root = path.resolve(__dirname, '..');
const review = path.join(root, 'docs/production/evidence/audio_director');
const options = Object.fromEntries(Array.from({length:(process.argv.length-2)/2}, (_,i)=>[process.argv[i*2+2],process.argv[i*2+3]]));
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const stamp = () => new Date().toISOString();
function receipt(file, value) {
  const pending = file + '.pending', bytes = Buffer.from(JSON.stringify(value,null,2)+'\n');
  let descriptor, owned = false;
  try {
    descriptor = fs.openSync(pending,'wx'); owned = true;
    for(let offset=0;offset<bytes.length;) {
      const written = fs.writeSync(descriptor,bytes,offset,bytes.length-offset);
      if(written<=0) throw new Error('No receipt write progress'); offset+=written;
    }
    fs.fsyncSync(descriptor); fs.closeSync(descriptor); descriptor=undefined;
    fs.renameSync(pending,file); assert.deepEqual(fs.readFileSync(file),bytes);
  } finally {if(descriptor!==undefined)fs.closeSync(descriptor);if(owned&&fs.existsSync(pending))fs.unlinkSync(pending);}
}
async function run() {
  assert(options['--browser']&&options['--page']&&options['--output'],'Required: --browser --page --output');
  const target = path.resolve(options['--page']), output = path.resolve(options['--output']);
  assert(target.startsWith(review+path.sep)&&target.endsWith(path.sep+'listen.html'),'Only a sealed review page');
  assert(output.startsWith(review+path.sep)&&!fs.existsSync(output),'Only a new evidence family');
  const sealed=JSON.parse(fs.readFileSync(path.join(path.dirname(target),'panel_checks.json'),'utf8'));
  assert.equal(sealed.status,'PASS');
  const hashes={...sealed.source_hashes};
  hashes['tools/validate_audio_review_panel.js']=hash(__filename);
  for(const [file,sha] of Object.entries(hashes))assert.equal(hash(path.join(root,file)),sha,file);
  fs.mkdirSync(output,{recursive:false});
  const record={status:'RUNNING',started_at:stamp(),scope:'Actual offline Chromium DOM, compressed decoding, finite preview and JSON proposal only; no listening/first-note/motif/scene mix acceptance.',source_hashes:hashes,checks:[],errors:[],external_requests:[]};
  const result=path.join(output,'results.json');receipt(result,record);
  const check=(name,condition)=>{assert(condition,name);record.checks.push(name);};
  const privateFolder=fs.mkdtempSync(path.join(os.tmpdir(),'wlr-review-browser-'));
  let browser;
  const terminate=()=>{if(browser)browser.close().finally(()=>process.exit(124));else process.exit(124);};
  process.once('SIGTERM',terminate);
  try {
    browser=await chromium.launch({executablePath:path.resolve(options['--browser']),headless:true,timeout:15000,args:['--no-sandbox','--disable-dev-shm-usage']});
    record.browser_version=browser.version();
    const page=await browser.newPage({viewport:{width:1200,height:1000},acceptDownloads:true});
    page.setDefaultTimeout(5000);
    page.on('pageerror',error=>record.errors.push(String(error)));
    page.on('request',request=>{if(!/^(file:|data:|blob:)/.test(request.url()))record.external_requests.push(request.url());});
    await page.addInitScript(()=>{
      window.reviewCapture={decoded:[],starts:[],stops:0};
      const Native=window.AudioContext;
      window.AudioContext=class extends Native {
        async decodeAudioData(bytes) {
          const decoded=await super.decodeAudioData(bytes);
          const samples=decoded.getChannelData(0);let sum=0;for(const sample of samples)sum+=sample*sample;
          window.reviewCapture.decoded.push({duration:decoded.duration,channels:decoded.numberOfChannels,sample_rate:decoded.sampleRate,rms:Math.sqrt(sum/samples.length)});
          return decoded;
        }
        createBufferSource() {
          const source=super.createBufferSource(),start=source.start.bind(source),stop=source.stop.bind(source);
          source.start=(...args)=>{window.reviewCapture.starts.push(args);return start(...args);};
          source.stop=(...args)=>{window.reviewCapture.stops++;return stop(...args);};return source;
        }
      };
    });
    await page.goto(pathToFileURL(target).href,{waitUntil:'load',timeout:15000});
    check('Russian document language',await page.locator('html').getAttribute('lang')==='ru');
    check('Two playable original excerpts',await page.locator('audio').count()===2);
    await page.waitForFunction(()=>[...document.querySelectorAll('audio')].every(audio=>Math.abs(audio.duration-8)<.02));
    check('Both native media durations are 8 seconds',true);
    await page.locator('#start').fill('0.5');await page.locator('#end').fill('1.5');
    await page.locator('#preview').click();
    await page.waitForFunction(()=>window.reviewCapture.starts.length===1);
    const captured=await page.evaluate(()=>window.reviewCapture);
    check('Actual finite WebAudio start at 0.5 for one second',JSON.stringify(captured.starts[0])==='[0,0.5,1]');
    check('Actual primary Vorbis decode has stereo finite positive PCM',captured.decoded[0].channels===2&&Math.abs(captured.decoded[0].duration-8)<.02&&captured.decoded[0].rms>0);
    await page.waitForFunction(()=>document.getElementById('message').textContent==='Участок завершен.');
    check('Preview ends without automatic repeat',await page.evaluate(()=>window.reviewCapture.starts.length)===1);
    await page.locator('#note').fill('D4');
    await page.locator('input[type=radio]').nth(1).check();
    check('Changing source clears prior source note and cut',await page.locator('#note').inputValue()===''&&await page.locator('#start').inputValue()==='0');
    await page.locator('#start').fill('1');await page.locator('#end').fill('2');
    await page.locator('#preview').click();await page.waitForFunction(()=>window.reviewCapture.starts.length===2);
    const second=await page.evaluate(()=>window.reviewCapture.decoded[1]);
    check('Actual alternate Vorbis decode has stereo finite positive PCM',second.channels===2&&Math.abs(second.duration-8)<.02&&second.rms>0);
    await page.locator('#stop').click();
    check('Stop revokes the active buffer source',await page.evaluate(()=>window.reviewCapture.stops)===1);
    await page.locator('#note').fill('F4');await page.locator('#motif').fill('F4, A4, C5, G4');
    const downloadPromise=page.waitForEvent('download');await page.locator('#save').click();
    const download=await downloadPromise;const downloaded=path.join(privateFolder,'proposal.json');await download.saveAs(downloaded);
    const proposal=JSON.parse(fs.readFileSync(downloaded,'utf8'));
    check('Download preserves alternate identity and exact cut',proposal.source_cue_id==='mus_s00_archive_seed_alternate_v01'&&JSON.stringify(proposal.source_interval_seconds)==='[1,2]'&&proposal.note_identity==='F4');
    check('Typed example notes remain pending without shipping approval',proposal.status==='LISTENING_PROPOSAL_PENDING_REVIEW'&&proposal.shipping_binding===false&&proposal.manifest_modified===false&&proposal.four_note_motif.length===4);
    // These are deliberately invented TEST inputs, never production selections.
    record.download_test_scope='Synthetic UI input only; downloaded proposal removed with private fixture.';
    await page.locator('input[type=radio]').nth(0).check();
    check('Returning to source restores its own draft',await page.locator('#note').inputValue()==='D4'&&await page.locator('#start').inputValue()==='0.5');
    await page.locator('#start').fill('7.9');await page.locator('#end').fill('8');await page.locator('#preview').click();
    check('Invalid tiny cut is visibly rejected',await page.locator('#message').getAttribute('data-error')==='true');
    await page.locator('#start').fill('0');await page.locator('#end').fill('8');
    await page.locator('#note').fill('');await page.locator('#motif').fill('');
    await page.screenshot({path:path.join(output,'desktop.png'),fullPage:true});
    await page.setViewportSize({width:390,height:844});
    // The first headless full-page capture omitted offscreen paint after resize.
    // Put all mobile-width content inside the capture viewport and let it paint.
    const height=await page.evaluate(()=>document.documentElement.scrollHeight);
    assert(height<5000,'Bounded mobile capture height');
    await page.setViewportSize({width:390,height});
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
    await page.screenshot({path:path.join(output,'mobile.png')});
    check('Mobile page has no horizontal overflow',await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    check('Browser runtime has no errors',record.errors.length===0);
    check('Page makes no external network requests',record.external_requests.length===0);
    record.decoded=await page.evaluate(()=>window.reviewCapture.decoded);
    await page.close();record.status='CHECKS_PASSED';
  } catch(error) {record.status='FAIL';record.failure=String(error);throw error;}
  finally {
    try {if(browser)await browser.close();}
    catch(error) {record.status='FAIL';record.failure=String(error);}
    fs.rmSync(privateFolder,{recursive:true,force:true});process.removeListener('SIGTERM',terminate);
    for(const file of ['desktop.png','mobile.png'])if(fs.existsSync(path.join(output,file)))record.source_hashes[path.relative(root,path.join(output,file))]=hash(path.join(output,file));
    try {
      for(const [file,sha] of Object.entries(record.source_hashes))assert.equal(hash(path.join(root,file)),sha,file);
      if(record.status==='CHECKS_PASSED')record.status='PASS';
    } catch(error) {record.status='FAIL';record.failure=String(error);}
    record.finished_at=stamp();record.browser_closed=!browser||!browser.isConnected();record.private_fixture_removed=!fs.existsSync(privateFolder);
    receipt(result,record);
  }
  assert.equal(record.status,'PASS',record.failure);
  process.stdout.write(JSON.stringify({status:record.status,checks:record.checks.length,result:path.relative(root,result)})+'\n');
}
run().catch(error=>{process.stderr.write(String(error)+'\n');process.exitCode=1;});
