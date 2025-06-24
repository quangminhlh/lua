const express = require('express');
const multer = require('multer');
const { execFile } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const app = express();
const upload = multer({ dest: os.tmpdir() });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function runObf(input, output, res){
  execFile('lua', ['obfuscator.lua', input, output],
    { windowsHide: true }, (err) => {
    if(err){
      console.error(err);
      fs.unlink(input, () => {});
      fs.unlink(output, () => {});
      return res.status(500).type('text/plain').send('Obfuscation failed');
    }
    fs.readFile(output, 'utf8', (err, data) => {
      fs.unlink(input, () => {});
      fs.unlink(output, () => {});
      if(err){
        console.error(err);
        return res.status(500).type('text/plain').send('Read failed');
      }
      res.type('text/plain').send(data);
    });
  });
}

app.post('/api/obf-text', (req, res) => {
  const code = req.body.code;
  if(!code) return res.status(400).send('No code');
  const inPath = path.join(os.tmpdir(), `in_${Date.now()}.lua`);
  const outPath = path.join(os.tmpdir(), `out_${Date.now()}.lua`);
  fs.writeFile(inPath, code, (err) => {
    if(err){
      console.error(err);
      return res.status(500).send('Write failed');
    }
    runObf(inPath, outPath, res);
  });
});

app.post('/api/obf-file', upload.single('luaFile'), (req, res) => {
  if(!req.file) return res.status(400).send('No file');
  const inPath = req.file.path;
  const outPath = path.join(os.tmpdir(), req.file.filename + '.out.lua');
  runObf(inPath, outPath, res);
});

const arg = process.argv.find(a => a.startsWith('--port='));
const PORT = arg ? parseInt(arg.split('=')[1], 10) : process.env.PORT || 8767;
app.listen(PORT, () => console.log(`Server running on ${PORT}`));
