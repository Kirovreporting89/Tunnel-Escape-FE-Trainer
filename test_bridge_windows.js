// Validação isolada: simula somente a API pública do MARKS FE.
'use strict';
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const url = require('url');
const vm = require('vm');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'marks-fe-bridge-test-'));
let state={yen:false,drops:false,speed:false,expEnabled:false,perkEnabled:false,
  damageAllEnabled:false,pistolEnabled:false,machineEnabled:false,reloadEnabled:false,
  dropChance:1,dropAmount:1,attackSpeed:1,expMultiplier:1,perksPerLevel:1,
  damageAllMultiplier:1,pistolMultiplier:1,machineMultiplier:1,reloadMultiplier:1,gold:4321};
let calls=[];
const plugin={status:()=>({...state}),set:(name,value)=>{calls.push([name,value]);state[name]=value;return true;}};
const intervals=[];
const filename=path.join(dir,'MarksFEV3.js');
const code=fs.readFileSync(path.join(__dirname,'MarksFE_Bridge_Windows.js'),'utf8');
const context={window:{MarksFEV3:plugin,location:{href:url.pathToFileURL(path.join(dir,'index.html')).href}},
  document:{currentScript:{src:url.pathToFileURL(filename).href}},
  require,setInterval:(fn,ms)=>intervals.push({fn,ms}),console};
try {
  vm.runInNewContext(code,context);
  const status=fs.readFileSync(path.join(dir,'MarksFE_DesktopStatus.ini'),'utf8');
  assert(status.includes('bridge=online\n'));
  assert(status.includes('protocol=2\n'));
  assert(status.includes('gold=4321\n'));
  assert(status.includes('damageAllMultiplier=1\n'));
  assert.strictEqual(intervals.length,2);
  fs.writeFileSync(path.join(dir,'MarksFE_DesktopBridge.ini'), 'yen=true\npistolMultiplier=3.5\nexpMultiplier=999\n');
  intervals[0].fn();
  assert.strictEqual(state.yen,true);
  assert.strictEqual(state.pistolMultiplier,3.5);
  assert.strictEqual(state.expMultiplier,1); // rejected
  assert.strictEqual(calls.length,2);
  intervals[1].fn();
  assert(fs.readFileSync(path.join(dir,'MarksFE_DesktopStatus.ini'),'utf8').includes('yen=true\n'));
  console.log('Ponte JavaScript: 7 verificações concluídas com sucesso.');
} finally {
  fs.rmSync(dir,{recursive:true,force:true});
}
