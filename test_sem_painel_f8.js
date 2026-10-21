// Testa o nucleo sem UI: nenhuma janela do jogo e nenhuma escuta de F8.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const js = fs.readFileSync(path.join(__dirname, 'MarksFEV3_2_ORIGINAL.js'), 'utf8');
let eventCalls = 0, domCalls = 0;
const prefs = new Map();
const intervals = [];
const gold = 1234;
const window = {
  localStorage: {getItem:(k)=>prefs.get(k)||null,setItem:(k,v)=>prefs.set(k,v)},
  setInterval:(fn, ms)=>intervals.push({fn,ms}),
  addEventListener:()=>{eventCalls++},
};
const document = {createElement:()=>{domCalls++;throw Error('No in-game UI allowed')}};
vm.runInNewContext(js,{window,document,console});
assert.equal(eventCalls,0,'The trainer must not bind F8 or other UI key handlers');
assert.equal(domCalls,0,'No panel should be created');
assert.equal(intervals.length,1,'Gameplay loop preserved');
assert.equal(typeof window.MarksFEV3.status,'function');
assert.equal(typeof window.MarksFEV3.set,'function');
assert.equal(window.MarksFEV3.set('expEnabled',true),true);
assert.equal(window.MarksFEV3.set('expMultiplier',25),true);
assert.equal(window.MarksFEV3.set('expMultiplier',9999),false);
assert.equal(window.MarksFEV3.status().expMultiplier,25);
assert.equal(window.MarksFEV3.status().expEnabled,true);
assert.equal(window.MarksFEV3.set('yen',true),true);
intervals[0].fn();
assert.equal(eventCalls,0);
assert.equal(domCalls,0);
console.log('Nucleo headless: 10 validacoes passaram; menu F8 removido e API preservada.');
