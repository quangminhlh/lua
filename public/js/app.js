const codeEl = document.getElementById('code');
const fileEl = document.getElementById('file');
const resultEl = document.getElementById('result');
const downloadBtn = document.getElementById('download');

async function obfuscate(){
  let res;
  const btn = document.getElementById('obfuscate');
  btn.disabled = true;
  if(fileEl.files[0]){
    const data = new FormData();
    data.append('luaFile', fileEl.files[0]);
    res = await fetch('/api/obf-file', {method:'POST', body:data});
  }else{
    const payload = {code: codeEl.value};
    res = await fetch('/api/obf-text', {
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body: JSON.stringify(payload)
    });
  }
  if(!res.ok){
    resultEl.textContent = 'Error: '+res.statusText;
    return;
  }
  const text = await res.text();
  resultEl.textContent = text;
  const blob = new Blob([text], {type:'text/plain'});
  downloadBtn.href = URL.createObjectURL(blob);
  downloadBtn.download = 'obf.lua';
  downloadBtn.style.display = 'inline-block';
  btn.disabled = false;
}

document.getElementById('obfuscate').addEventListener('click', obfuscate);
