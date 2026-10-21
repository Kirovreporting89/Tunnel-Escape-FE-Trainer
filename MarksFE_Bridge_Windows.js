/* MARKS_FE_DESKTOP_BRIDGE_V2_BEGIN
 * Ponte local para MARKS FE 3.2, Windows 10/11 e Fedora.
 * Mantém os hooks existentes, sem modificar saves ou processos.
 */
;(function () {
  'use strict';
  var TAG = '[MARKS FE Windows bridge v2]';
  var plugin = window.MarksFEV3;
  if (!plugin || typeof plugin.status !== 'function' || typeof plugin.set !== 'function') {
    console.warn(TAG, 'MARKS FE 3.2 nao encontrado; painel interno nao foi alterado.');
    return;
  }
  var fs, path, url;
  try {
    var req = typeof require === 'function' ? require : window.require;
    if (!req) throw new Error('Node.js nao disponivel neste NW.js');
    fs = req('fs'); path = req('path'); url = req('url');
  } catch (error) {
    console.warn(TAG, 'Conexao externa indisponivel:', error.message);
    return;
  }
  var folder = '';
  try {
    if (document.currentScript && document.currentScript.src)
      folder = path.dirname(url.fileURLToPath(document.currentScript.src));
  } catch (ignored) {}
  if (!folder) {
    try { folder = path.join(path.dirname(url.fileURLToPath(window.location.href)), 'js', 'plugins'); }
    catch (ignored2) { folder = path.join(process.cwd(), 'js', 'plugins'); }
  }
  var inFile = path.join(folder, 'MarksFE_DesktopBridge.ini');
  var outFile = path.join(folder, 'MarksFE_DesktopStatus.ini');
  var switches = {
    yen:1,drops:1,speed:1,expEnabled:1,perkEnabled:1,
    damageAllEnabled:1,pistolEnabled:1,machineEnabled:1,reloadEnabled:1
  };
  var choice = {
    dropChance:[1,2,3,5,10],dropAmount:[1,2,3,5,10],attackSpeed:[1,1.5,2,3,5],
    expMultiplier:[1,2,5,10,15,20,25,50],
    perksPerLevel:[1,2,3,4,5,6,7,8,9,10,15,20],
    damageAllMultiplier:[1,1.5,2,3,5,10],
    pistolMultiplier:[1,1.5,2,2.5,3,3.5,5,10],
    machineMultiplier:[1,1.5,2,2.5,3,3.5,5,10],
    reloadMultiplier:[1,1.5,2,2.5,3,5,10]
  };
  var keys = Object.keys(switches).concat(Object.keys(choice));
  var lastStamp = '';
  function receive() {
    try {
      if (!fs.existsSync(inFile)) return;
      var st = fs.statSync(inFile);
      var stamp = st.mtimeMs + ':' + st.size;
      if (stamp === lastStamp) return;
      var lines = fs.readFileSync(inFile, 'utf8').split(/\r?\n/);
      var current = plugin.status();
      lines.forEach(function (line) {
        var cut = line.indexOf('=');
        if (cut < 1) return;
        var key = line.substring(0,cut).trim(), raw = line.substring(cut+1).trim();
        if (!Object.prototype.hasOwnProperty.call(switches,key) &&
            !Object.prototype.hasOwnProperty.call(choice,key)) return;
        var value;
        if (switches[key]) {
          if (raw !== 'true' && raw !== 'false') return;
          value = (raw === 'true');
        } else {
          value = Number(raw);
          if (choice[key].indexOf(value) < 0) return;
        }
        if (current[key] !== value) plugin.set(key, value);
      });
      lastStamp = stamp;
    } catch (error) { console.warn(TAG, 'Leitura do comando falhou:',error.message); }
  }
  function publish() {
    try {
      var s=plugin.status();
      var lines=['bridge=online','protocol=2','time='+Date.now(),
        'gold='+String(s.gold==null ? '?' : s.gold).replace(/[\r\n=]/g,'')];
      keys.forEach(function(key) {
        var val = s[key];
        if (typeof val === 'boolean' || typeof val === 'number')
          lines.push(key+'='+val);
      });
      fs.writeFileSync(outFile, lines.join('\n')+'\n','utf8');
    } catch (error) {
      if (!publish.warned) console.warn(TAG, 'Publicacao de status falhou:',error.message);
      publish.warned = true;
    }
  }
  receive(); publish();
  setInterval(receive, 300);
  setInterval(publish, 850);
  console.info(TAG, 'Conexao local disponivel em',folder);
})();
/* MARKS_FE_DESKTOP_BRIDGE_V2_END */
