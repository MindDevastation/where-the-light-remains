/* Offline audition proposals; no manifest mutation or musical approval. */
'use strict';
function listeningProposal(candidate, start, end, note, motif, notes) {
  const [lo, hi] = candidate.source_interval_seconds;
  if (![start, end].every(v => typeof v === 'number' && Number.isFinite(v)) ||
      start < lo || end > hi || end - start <= 0.3) {
    throw new Error('Укажите участок внутри 0–8 секунд длительностью больше 0,3 с.');
  }
  const identity = note.trim() || null;
  const four = motif.trim() ? motif.split(',').map(v => v.trim()) : null;
  if (four && (four.length !== 4 || four.some(v => !v))) {
    throw new Error('Укажите ровно четыре ноты через запятую или оставьте мотив пустым.');
  }
  return {
    schema_version: 1, status: 'LISTENING_PROPOSAL_PENDING_REVIEW',
    source_cue_id: candidate.source_cue_id, source_path: candidate.source_path,
    source_sha256: candidate.source_sha256, source_interval_seconds: [start, end],
    audition_path: candidate.audition_path, audition_sha256: candidate.audition_sha256,
    audition_interval_seconds: [...candidate.source_interval_seconds],
    audition_existing_fades_seconds: [candidate.fade_in_seconds, candidate.fade_out_seconds],
    note_identity: identity, four_note_motif: four, listening_notes: notes.trim(),
    fade_in_seconds: null, fade_out_seconds: null, gain_db: null,
    shipping_binding: false, manifest_modified: false,
    acceptance: 'EDIT_AND_MOTIF_VERIFICATION_REQUIRED'
  };
}
if (typeof module !== 'undefined') module.exports = {listeningProposal};
if (typeof document !== 'undefined') {
  const data = JSON.parse(document.getElementById('review-data').textContent);
  const get = id => document.getElementById(id);
  let selected = 0, context, source, revision = 0;
  const buffers = new Map(), players = [];
  const fields = ['start', 'end', 'note', 'motif', 'notes'];
  const drafts = data.candidates.map(() => ['0', '8', '', '', '']);
  const message = (text, error = false) => {
    get('message').textContent = text;
    get('message').dataset.error = String(error);
  };
  const stop = () => {
    revision++;
    if (source) {source.onended = null; source.stop(); source.disconnect(); source = null;}
    for (const player of players) player.pause();
  };
  const current = () => listeningProposal(data.candidates[selected],
    get('start').valueAsNumber, get('end').valueAsNumber,
    get('note').value, get('motif').value, get('notes').value);
  const choose = index => {
    if (selected === index) return;
    drafts[selected] = fields.map(id => get(id).value);
    selected = index;
    fields.forEach((id, field) => {get(id).value = drafts[index][field];});
  };
  data.candidates.forEach((candidate, index) => {
    const card = document.createElement('div'); card.className = 'card';
    const label = document.createElement('label'); label.className = 'choose';
    const radio = document.createElement('input'); radio.type = 'radio'; radio.name = 'source';
    radio.checked = index === 0; radio.value = String(index);
    radio.addEventListener('change', () => {stop(); choose(index); message('Выбран источник: ' + candidate.label);});
    label.append(radio, document.createTextNode(candidate.label));
    const player = document.createElement('audio'); player.controls = true; player.preload = 'metadata';
    player.src = candidate.media_data_url; player.setAttribute('aria-label', candidate.label + ', первые 8 секунд');
    player.addEventListener('play', () => {
      revision++;
      if (source) {source.onended = null; source.stop(); source.disconnect(); source = null;}
      for (const other of players) if (other !== player) other.pause();
      choose(index); radio.checked = true;
    });
    players.push(player);
    const info = document.createElement('small');
    info.textContent = '0–8 с · ' + candidate.decoded_loudness.integrated_lufs + ' LUFS · ' + candidate.decoded_loudness.true_peak_dbtp + ' dBTP';
    card.append(label, player, info); get('candidates').append(card);
  });
  get('stop').addEventListener('click', () => {stop(); message('Прослушивание остановлено.');});
  get('preview').addEventListener('click', async () => {
    stop(); const ownRevision = revision;
    try {
      const proposal = current(), candidate = data.candidates[selected], key = candidate.audition_sha256;
      const Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio) throw new Error('Этот браузер не поддерживает точное прослушивание участка. Полные вырезки доступны выше.');
      context ||= new Audio(); await context.resume();
      if (!buffers.has(key)) {
        const bytes = Uint8Array.from(atob(candidate.media_data_url.split(',')[1]), c => c.charCodeAt(0));
        const decoded = await context.decodeAudioData(bytes.buffer); buffers.set(key, decoded);
      }
      if (revision !== ownRevision) return;
      source = context.createBufferSource(); source.buffer = buffers.get(key); source.connect(context.destination);
      source.onended = () => {
        if (revision !== ownRevision) return;
        source.disconnect(); source = null; message('Участок завершен.');
      };
      const [start, end] = proposal.source_interval_seconds;
      source.start(0, start - candidate.source_interval_seconds[0], end - start);
      message('Прослушивание ' + start.toFixed(2) + '–' + end.toFixed(2) + ' с · ' + candidate.label);
    } catch (error) {if (revision === ownRevision) message(error.message, true);}
  });
  for (const id of ['start', 'end']) get(id).addEventListener('input', () => {stop(); message('Границы изменены. Прослушайте выбранный участок.');});
  get('save').addEventListener('click', () => {
    try {
      const proposal = current();
      const url = URL.createObjectURL(new Blob([JSON.stringify(proposal, null, 2) + '\n'], {type: 'application/json'}));
      const link = document.createElement('a'); link.href = url; link.download = 's00-listening-proposal.json'; link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
      message('Предложение сохранено. Нота, мотив и монтаж требуют проверки по исходному WAV.');
    } catch (error) {message(error.message, true);}
  });
  document.addEventListener('visibilitychange', () => {if (document.hidden) stop();});
  window.addEventListener('pagehide', () => {stop(); if (context) context.close();});
}
