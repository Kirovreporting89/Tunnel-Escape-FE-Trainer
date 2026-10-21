// Integracao isolada do nucleo + bridge, sem o jogo nem Windows.
'use strict';
const assert = require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const url=require('node:url');
const vm=require('node:vm');
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'tunnel-headless-'));
try {
  const prefs=new Map();
  const intervals=[];
  let uiCount=0, keyListenerCount=0;
  const win={localStorage:{getItem:k=>prefs.get(k)||null,setItem:(k,v)=>prefs.set(k,v)},
    location:{href:url.pathToFileURL(path.join(dir,'index.html')).href},
    setInterval:(fn,ms)=>intervals.push({fn,ms}),
    addEventListener:()=>{keyListenerCount++}};
  const doc={currentScript:{src:url.pathToFileURL(path.join(dir,'js/plugins/MarksFEV3.js')).href},
    createElement:()=>{uiCount++;throw new Error('Never create trainer UI')}};
  fs.mkdirSync(path.join(dir,'js/plugins'),{recursive:true});
  const core=fs.readFileSync(path.join(__dirname,'MarksFEV3_2_ORIGINAL.js'),'utf8');
  const bridge=fs.readFileSync(path.join(__dirname,'MarksFE_Bridge_Windows.js'),'utf8');
  vm.runInNewContext(core+'\n'+bridge,{window:win,document:doc,require,console,setInterval:(fn,ms)=>intervals.push({fn,ms})});
  assert.equal(uiCount,0);
  assert.equal(keyListenerCount,0);
  assert.equal(intervals.length,3);
  const statusFile=path.join(dir,'js/plugins/MarksFE_DesktopStatus.ini');
  assert.match(fs.readFileSync(statusFile,'utf8'),/bridge=online/);
  fs.writeFileSync(path.join(dir,'js/plugins/MarksFE_DesktopBridge.ini'),'expEnabled=true\nexpMultiplier=25\n');
  intervals[1].fn();
  assert.equal(win.MarksFEV3.status().expEnabled,true);
  assert.equal(win.MarksFEV3.status().expMultiplier,25);
  intervals[2].fn();
  assert.match(fs.readFileSync(statusFile,'utf8'),/expMultiplier=25/);
  assert.equal(uiCount,0);
  console.log('Integracao completa: painel interno ausente; comandos e status da ponte ativos.');
} finally {fs.rmSync(dir,{recursive:true,force:true});}
