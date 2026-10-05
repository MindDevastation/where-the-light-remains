'use strict';
const {test} = require('node:test');
const vm = require('node:vm');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const {listeningProposal} = require('./audio_review_panel.js');
const candidate = {
  source_cue_id: 'mus_s00_archive_seed_v01', source_path: 'source.wav', source_sha256: 'source-hash',
  source_interval_seconds: [0, 8], audition_path: 'audition.ogg', audition_sha256: 'sealed-media-hash',
  fade_in_seconds: 0.02, fade_out_seconds: 0.25
};
test('blank identities remain pending; source bytes and original clip are preserved', () => {
  const before = structuredClone(candidate);
  const result = listeningProposal(candidate, 0.4, 1.2, '', '', '  listen again  ');
  assert.equal(result.status, 'LISTENING_PROPOSAL_PENDING_REVIEW');
  assert.equal(result.note_identity, null); assert.equal(result.four_note_motif, null);
  assert.equal(result.manifest_modified, false); assert.equal(result.shipping_binding, false);
  assert.equal(result.fade_in_seconds, null); assert.equal(result.fade_out_seconds, null);
  assert.equal(result.gain_db, null);
  assert.deepEqual(result.source_interval_seconds, [0.4, 1.2]);
  assert.deepEqual(result.audition_interval_seconds, [0, 8]);
  assert.equal(result.listening_notes, 'listen again'); assert.deepEqual(candidate, before);
});
test('a entered note and four-note identity remain a proposal, never acceptance', () => {
  const result = listeningProposal(candidate, 0, 8, ' D4 ', 'D4, F4, A4, E4', '');
  assert.equal(result.note_identity, 'D4'); assert.deepEqual(result.four_note_motif, ['D4','F4','A4','E4']);
  assert.equal(result.acceptance, 'EDIT_AND_MOTIF_VERIFICATION_REQUIRED');
  assert.equal(result.source_sha256, candidate.source_sha256);
});
test('invalid/outside/empty/non-finite intervals cannot be saved', () => {
  for (const [start,end] of [[-1,2],[0,9],[1,1],[2,1],[0,0.3],[NaN,2],[0,Infinity],['0',8]]) {
    assert.throws(() => listeningProposal(candidate, start, end, '', '', ''));
  }
});
test('partial/malformed motifs cannot silently become four notes', () => {
  for (const motif of ['D4','D4,F4,A4','D4,F4,A4,','D4,F4,,E4','D4,F4,A4,E4,G4']) {
    assert.throws(() => listeningProposal(candidate, 0, 8, '', motif, ''));
  }
});

function panel() {
  class Element {
    constructor() {this.value = ''; this.children = []; this.handlers = {}; this.dataset = {}; this.paused = true;}
    get valueAsNumber() {return this.value === '' ? NaN : Number(this.value);}
    addEventListener(name, callback) {(this.handlers[name] ||= []).push(callback);}
    append(...children) {this.children.push(...children);}
    setAttribute() {}
    pause() {this.paused = true;}
    click() {return this.emit('click');}
    emit(name) {return Promise.all((this.handlers[name] || []).map(callback => callback()));}
  }
  const ids = Object.fromEntries(['review-data','candidates','message','start','end','note','motif','notes','preview','stop','save'].map(id => [id,new Element()]));
  ids.start.value = '0'; ids.end.value = '8';
  ids['review-data'].textContent = JSON.stringify({candidates: [0,1].map(index => ({...candidate,
    source_cue_id: 'cue-' + index, label: 'Source ' + index, audition_sha256: 'hash-' + index,
    media_data_url: 'data:audio/ogg;base64,T2dnUw==', decoded_loudness: {integrated_lufs:-17, true_peak_dbtp:-5}}))});
  let resolveDecode, blob, decodeReady;
  const ready = new Promise(resolve => {decodeReady = resolve;});
  const started = [], stopped = [], contextEvents = [];
  class AudioContext {
    resume() {return Promise.resolve();}
    decodeAudioData() {return new Promise(resolve => {resolveDecode = resolve; decodeReady();});}
    createBufferSource() {return {connect(){},disconnect(){},start(...args){started.push(args);},stop(){stopped.push(true);}};}
    close() {contextEvents.push('closed');}
  }
  const docHandlers = {}, windowHandlers = {};
  const document = {getElementById:id=>ids[id], createElement:()=>new Element(), createTextNode:text=>text,
    addEventListener:(name,callback)=>{docHandlers[name]=callback;}};
  const sandbox = {document,window:{AudioContext,addEventListener:(name,callback)=>{windowHandlers[name]=callback;}},
    atob,Uint8Array,Blob,URL:{createObjectURL:value=>{blob=value;return 'blob:proposal';},revokeObjectURL(){}},setTimeout:callback=>callback()};
  vm.runInNewContext(fs.readFileSync(require.resolve('./audio_review_panel.js'),'utf8'), sandbox);
  const cards = ids.candidates.children;
  return {ids, started, stopped, docHandlers, windowHandlers, ready,
    resolve:()=>resolveDecode({duration:8}), download:async()=>JSON.parse(await blob.text()),
    choose:index=>cards[index].children[0].children[0].emit('change'),
    play:index=>cards[index].children[1].emit('play')};
}
test('switching sources preserves separate note/motif/cut drafts', async () => {
  const p = panel(); p.ids.note.value = 'D4'; p.ids.start.value = '0.6';
  await p.choose(1); assert.equal(p.ids.note.value, ''); assert.equal(p.ids.start.value, '0');
  p.ids.note.value = 'F4'; await p.ids.save.click();
  let saved = await p.download(); assert.equal(saved.source_cue_id, 'cue-1'); assert.equal(saved.note_identity, 'F4');
  await p.choose(0); assert.equal(p.ids.note.value, 'D4'); assert.equal(p.ids.start.value, '0.6');
  await p.ids.save.click(); saved = await p.download(); assert.equal(saved.source_cue_id, 'cue-0');
});
test('stop during decoding prevents delayed preview playback', async () => {
  const p = panel(), pending = p.ids.preview.click(); await p.ready;
  await p.ids.stop.click(); p.resolve(); await pending;
  assert.equal(p.started.length, 0);
});
test('source switch during decoding prevents the old source from starting', async () => {
  const p = panel(), pending = p.ids.preview.click(); await p.ready;
  await p.choose(1); p.resolve(); await pending; assert.equal(p.started.length, 0);
});
test('preview uses exact finite offset/duration; native play revokes it', async () => {
  const p = panel(); p.ids.start.value = '0.5'; p.ids.end.value = '1.5';
  const pending = p.ids.preview.click(); await p.ready; p.resolve(); await pending;
  assert.deepEqual(p.started, [[0,0.5,1]]); await p.play(1); assert.equal(p.stopped.length, 1);
  assert.equal(p.ids.start.value, '0');
});
