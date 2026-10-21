/*:
 * @target MZ
 * @plugindesc MARKS FE v3.2 - modo externo (sem painel F8)
 * @author Marks + ChatGPT
 * @help
 * Controle todos os recursos pelo executavel do trainer no Windows.
 * Compatibilidade: RPG Maker MZ, VisuStella ATB, Skill Learn System.
 * Teste em copia do save; recursos de arma e recarga dependem dos dados do jogo.
 */
(() => {
  'use strict';
  const TAG = 'MarksFEV3.2';
  const KEY = 'MarksFEV3.settings.2026-10';
  const OLD_KEY = 'MarksFEV2.settings.2026-10';
  const def = {
    yen:false, drops:false, speed:false,
    dropChance:5, dropAmount:3, attackSpeed:2,
    expEnabled:false, expMultiplier:5,
    perkEnabled:false, perksPerLevel:2,
    damageAllEnabled:false, damageAllMultiplier:2,
    pistolEnabled:false, pistolMultiplier:2, pistolType:0,
    machineEnabled:false, machineMultiplier:2, machineType:0,
    reloadEnabled:false, reloadMultiplier:2
  };
  const state = {...def};
  const allowed = {
    dropChance:[1,2,3,5,10], dropAmount:[1,2,3,5,10], attackSpeed:[1,1.5,2,3,5],
    expMultiplier:[1,2,5,10,15,20,25,50], perksPerLevel:[1,2,3,4,5,6,7,8,9,10,15,20],
    damageAllMultiplier:[1,1.5,2,3,5,10],
    pistolMultiplier:[1,1.5,2,2.5,3,3.5,5,10],
    machineMultiplier:[1,1.5,2,2.5,3,3.5,5,10],
    reloadMultiplier:[1,1.5,2,2.5,3,5,10]
  };
  const switches = ['yen','drops','speed','expEnabled','perkEnabled','damageAllEnabled','pistolEnabled','machineEnabled','reloadEnabled'];
  const stats = { gold:0,drops:0,atb:0,exp:0,damage:0,pistol:0,machine:0,reloadAtb:0,reloadCd:0,reloadProgress:0,reloadWait:0,perks:0 };
  const debug = {lastWeapon:'Nenhuma',lastAction:'Nenhuma',lastDamage:0,lastExp:0,perkHook:false};
  const clamp = (v,min,max) => Math.max(min,Math.min(max,v));

  function load() {
    try {
      const old = JSON.parse(window.localStorage.getItem(OLD_KEY)||'{}');
      const own = JSON.parse(window.localStorage.getItem(KEY)||'{}');
      const src = {...old,...own};
      for (const k of switches) if (typeof src[k]==='boolean') state[k]=src[k];
      for (const k of Object.keys(allowed)) if (allowed[k].includes(src[k])) state[k]=src[k];
      for (const k of ['pistolType','machineType']) {
        if (Number.isInteger(src[k]) && src[k]>=0 && src[k]<=999) state[k]=src[k];
      }
    } catch(e) { console.warn(`[${TAG}] Preferencias nao carregadas`,e); }
  }
  function save() {
    try { window.localStorage.setItem(KEY,JSON.stringify(state)); }
    catch(e) { console.warn(`[${TAG}] Falha ao salvar`,e); }
  }
  load();

  function party() { return typeof $gameParty!=='undefined' ? $gameParty:null; }
  function gold() { const p=party();return p && typeof p.gold==='function' ? p.gold():null; }
  function topUpYen() {
    if (!state.yen) return;
    const p=party(); if (!p || !p.gainGold || !p.gold) return;
    try {
      const lim=typeof p.maxGold==='function'?p.maxGold():99999999;
      const curr=p.gold();
      if (Number.isFinite(curr)&&Number.isFinite(lim)&&lim>curr) {p.gainGold(lim-curr);stats.gold++;}
    } catch(e) {console.warn(`[${TAG}] yen`,e);}
  }

  // Reutiliza os mesmos pontos de integracao testados na v2.
  if (typeof Game_Enemy!=='undefined' && typeof Game_Enemy.prototype.dropItemRate==='function') {
    const base=Game_Enemy.prototype.dropItemRate;
    Game_Enemy.prototype.dropItemRate=function() {
      const v=base.apply(this,arguments);
      return state.drops&&Number.isFinite(v)?v*state.dropChance:v;
    };
  }
  if (typeof Game_Troop!=='undefined' && typeof Game_Troop.prototype.makeDropItems==='function') {
    const base=Game_Troop.prototype.makeDropItems;
    Game_Troop.prototype.makeDropItems=function(){
      const items=base.apply(this,arguments);stats.drops++;
      if (!state.drops || !Array.isArray(items) || state.dropAmount===1) return items;
      const out=items.slice();
      for (let i=1;i<state.dropAmount;i++) out.push(...items);
      return out;
    };
  }

  // XP de VITORIA, respeitando o valor que os demais plugins ja calcularam.
  if (typeof BattleManager!=='undefined' && typeof BattleManager.makeRewards==='function') {
    const base=BattleManager.makeRewards;
    BattleManager.makeRewards=function(){
      const r=base.apply(this,arguments);
      const rewards=this._rewards;
      if (rewards && Number.isFinite(rewards.exp)) {
        const original=rewards.exp;
        if (state.expEnabled) {
          rewards.exp=clamp(Math.round(original*state.expMultiplier),0,999999999);
          stats.exp++;
        }
        debug.lastExp=rewards.exp;
      }
      return r;
    };
  }

  // PERKs: o jogo chama "SkillPoints" internamente.
  // O proprio VisuStella avalia o campo PerLevelUp ao subir um nivel.
  let perkSettings=null, originalPerLevel=null;
  function perkObject() {
    try {
      const system=(typeof VisuMZ!=='undefined')?VisuMZ.SkillLearnSystem:null;
      return system && system.Settings && system.Settings.SkillPoints || null;
    } catch (_) {return null;}
  }
  function applyPerks() {
    const obj=perkObject();
    if (!obj) {debug.perkHook=false;return;}
    if (obj!==perkSettings) {
      perkSettings=obj;
      originalPerLevel=String(obj.PerLevelUp == null?'1':obj.PerLevelUp);
    }
    obj.PerLevelUp=state.perkEnabled?String(state.perksPerLevel):originalPerLevel;
    debug.perkHook=true;
  }
  applyPerks();
  if (typeof Game_Actor!=='undefined' && typeof Game_Actor.prototype.levelUpGainSkillPoints==='function') {
    const base=Game_Actor.prototype.levelUpGainSkillPoints;
    Game_Actor.prototype.levelUpGainSkillPoints=function(){
      applyPerks();stats.perks++;return base.apply(this,arguments);
    };
  }

  function subjectActor(action) {
    try { const s=action&&typeof action.subject==='function'?action.subject():null;
      return s && typeof s.isActor==='function' && s.isActor()?s:null; }
    catch(_){return null;}
  }
  function equipped(actor) {
    try {return (actor && typeof actor.weapons==='function'?actor.weapons():[]).filter(Boolean);}
    catch(_){return [];}
  }
  function normalize(v) {return String(v==null?'':v).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();}
  const rxMachine=/machine[\s_-]*gun|sub[\s_-]*machine|\bsmg\b|\blmg\b|metralhadora|metralleta|機関銃/i;
  const rxPistol=/pistol|hand[\s_-]*gun|revolver|sidearm|拳銃|ハンドガン/i;
  const rxReload=/reload|recarreg|recarga|rearm|装填|リロード/i;
  // Identificadores conferidos nos dados desta versao de Tunnel Escape FE.
  // Tactical Pistol = ID 1 / tipo 1; Fidelity/Magnum = ID 5 / tipo 5.
  // Machine Gun = ID 2 / tipo 2. Skills Shoot = 233/234 e Burst Fire = 235.
  const pistolSkillIds = new Set([233,234,247,248,249]);
  const machineSkillIds = new Set([235,421,422,423,424]);
  const pistolWeaponIds = new Set([1,5]);
  const machineWeaponIds = new Set([2]);
  function weaponDescriptor(weapon) {
    if (!weapon) return '';
    let typeName='';
    try {typeName=($dataSystem && $dataSystem.weaponTypes && $dataSystem.weaponTypes[weapon.wtypeId])||'';}
    catch(_){}
    return normalize([weapon.name,typeName,weapon.note].join(' '));
  }
  function weaponClass(actor,action) {
    const weapons=equipped(actor);
    const item=action && typeof action.item==='function'?action.item():null;
    debug.lastWeapon=weapons.map(w=>w.name||`ID ${w.id}`).join(', ') || '(sem arma equipada)';
    debug.lastAction=item&&item.name||'(sem habilidade)';
    // Skill ID e tipo de dano sao mais confiaveis do que o nome traduzido.
    if (item && Number.isInteger(item.id)) {
      if(pistolSkillIds.has(item.id)) return 'pistol';
      if(machineSkillIds.has(item.id)) return 'machine';
      const e=Number(item.damage && item.damage.elementId);
      if(e===4) return 'pistol'; // elemento de dano da pistola
      if(e===6) return 'machine'; // elemento de dano da metralhadora
    }
    // Selecao manual ainda tem prioridade sobre heuristicas de texto.
    if (state.machineType>0 && weapons.some(w=>Number(w.wtypeId)===state.machineType)) return 'machine';
    if (state.pistolType>0 && weapons.some(w=>Number(w.wtypeId)===state.pistolType)) return 'pistol';
    if (weapons.some(w=>machineWeaponIds.has(Number(w.id)))) return 'machine';
    if (weapons.some(w=>pistolWeaponIds.has(Number(w.id)))) return 'pistol';
    for (const w of weapons) {
      const desc=weaponDescriptor(w);
      if (rxMachine.test(desc)) return 'machine';
      if (rxPistol.test(desc)) return 'pistol';
    }
    const skillText=normalize(item && [item.name,item.note].join(' '));
    if (rxMachine.test(skillText)) return 'machine';
    if (rxPistol.test(skillText)) return 'pistol';
    return '';
  }
  function isWeaponAttack(action,actor) {
    if (!actor) return false;
    if (typeof action.isItem==='function' && action.isItem()) return false;
    const skill=typeof action.item==='function'?action.item():null;
    if (!skill || !skill.damage || ![1,5].includes(Number(skill.damage.type))) return false;
    const id=Number(skill.id);
    const element=Number(skill.damage.elementId);
    if (pistolSkillIds.has(id) || machineSkillIds.has(id)) return true;
    if ([4,6].includes(element)) return true;
    if (/(PistolAmmo|MagnumAmmo|ARAmmo|ShotgunAmmo|GLAmmo|RLAmmo)\s+Cost/i.test(String(skill.note||''))) return true;
    // Ataques fisicos classicos usam arma equipada; habilidades especiais nao.
    return equipped(actor).length>0 && typeof action.isPhysical==='function' && action.isPhysical();
  }
  if (typeof Game_Action!=='undefined' && typeof Game_Action.prototype.makeDamageValue==='function') {
    const base=Game_Action.prototype.makeDamageValue;
    Game_Action.prototype.makeDamageValue=function(target,critical){
      const value=base.apply(this,arguments);
      if (!Number.isFinite(value) || value<=0) return value;
      if (!target || typeof target.isEnemy!=='function' || !target.isEnemy()) return value;
      const actor=subjectActor(this);
      if (!actor || !isWeaponAttack(this,actor)) return value;
      let m=state.damageAllEnabled?state.damageAllMultiplier:1;
      const kind=weaponClass(actor,this);
      if (kind==='pistol' && state.pistolEnabled) {m*=state.pistolMultiplier;stats.pistol++;}
      if (kind==='machine' && state.machineEnabled) {m*=state.machineMultiplier;stats.machine++;}
      if (m===1) return value;
      const result=clamp(Math.round(value*m),1,999999999);
      debug.lastDamage=result;stats.damage++;
      return result;
    };
  }
  function isReloadSkill(item) {return !!(item && (Number(item.id)===244 || rxReload.test(normalize([item.name,item.note].join(' ')))));}
  function reloading(actor) {
    try {return actor && typeof actor.currentAction==='function' && isReloadSkill(actor.currentAction()?.item?.());}
    catch(_){return false;}
  }
  // Esta versao usa o evento comum 38 para a recarga e o evento paralelo 766
  // para avancar o progresso (variavel 34) ate o total (variavel 35).
  // Diminuir o total e as esperas da animacao preserva o fluxo original.
  if (typeof Game_Variables!=='undefined' && typeof Game_Variables.prototype.setValue==='function') {
    const base=Game_Variables.prototype.setValue;
    Game_Variables.prototype.setValue=function(variableId,value) {
      if(variableId===35 && state.reloadEnabled &&
        Number.isFinite(value) && value>0 && state.reloadMultiplier>1) {
        value=Math.max(1,Math.ceil(value/state.reloadMultiplier));
        stats.reloadProgress++;
      }
      return base.call(this,variableId,value);
    };
  }
  // Somente os comandos de espera do EVENTO 38, nunca de outras cenas.
  if (typeof Game_Interpreter!=='undefined' && typeof Game_Interpreter.prototype.command230==='function') {
    const base=Game_Interpreter.prototype.command230;
    Game_Interpreter.prototype.command230=function(params) {
      const list=(typeof $dataCommonEvents!=='undefined' && $dataCommonEvents && $dataCommonEvents[38]) ? $dataCommonEvents[38].list:null;
      if(state.reloadEnabled && state.reloadMultiplier>1 && list && this._list===list) {
        const cmd=params || this._params;
        if(Array.isArray(cmd) && Number.isFinite(Number(cmd[0])) && Number(cmd[0])>0) {
          const accelerated=Math.max(1,Math.ceil(Number(cmd[0])/state.reloadMultiplier));
          stats.reloadWait++;
          // O original usa params, nao modificar o array compartilhado de eventos.
          return base.call(this,[accelerated,...cmd.slice(1)]);
        }
      }
      return base.apply(this,arguments);
    };
  }

  // ATB geral v2 + cast da habilidade identificada como recarga.
  if (typeof Game_Battler!=='undefined' && typeof Game_Battler.prototype.tpbAcceleration==='function') {
    const base=Game_Battler.prototype.tpbAcceleration;
    Game_Battler.prototype.tpbAcceleration=function(){
      const val=base.apply(this,arguments);
      if (!Number.isFinite(val) || !(this.isActor&&this.isActor())) return val;
      let m=1;
      if (state.speed) {m*=state.attackSpeed;stats.atb++;}
      if (state.reloadEnabled && reloading(this)) {m*=state.reloadMultiplier;stats.reloadAtb++;}
      return val*m;
    };
  }
  // Caso a recarga seja uma habilidade com cooldown do VisuStella,
  // diminui apenas a duracao daquele cooldown, nunca a dos inimigos.
  if (typeof Game_BattlerBase!=='undefined' && typeof Game_BattlerBase.prototype.setCooldown==='function') {
    const base=Game_BattlerBase.prototype.setCooldown;
    Game_BattlerBase.prototype.setCooldown=function(skillId,turns){
      if (state.reloadEnabled && this.isActor&&this.isActor() && Number.isFinite(turns) && turns>0) {
        const skill=(typeof $dataSkills!=='undefined' && $dataSkills) ? $dataSkills[skillId]:null;
        if (isReloadSkill(skill)) {
          turns=Math.max(0,Math.ceil(turns/state.reloadMultiplier));stats.reloadCd++;
        }
      }
      return base.call(this,skillId,turns);
    };
  }

  // MARKS_FE_HEADLESS_V66: Controle exclusivamente pelo trainer externo.
  // Mantem hooks, preferencias, multiplicadores e a API publica da ponte.
  // O painel HTML interno e o atalho F8 nao sao registrados.
  function sync() {} // Interface interna removida; ponte usa MarksFEV3.set.
  window.setInterval(()=>{topUpYen();applyPerks();},1000);
  window.MarksFEV3={status:()=>({...state,stats:{...stats},debug:{...debug},gold:gold()}),set:(name,value)=>{
    if(switches.includes(name)&&typeof value==='boolean')state[name]=value;
    else if(allowed[name]&&allowed[name].includes(value))state[name]=value;
    else return false;
    applyPerks();save();sync();return true;
  }};
  console.info(`[${TAG}] Modo externo iniciado, sem painel F8.`,window.MarksFEV3.status());
})();
