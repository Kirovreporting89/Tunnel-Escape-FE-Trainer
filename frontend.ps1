# TUNNEL ESCAPE FE TRAINER V6.6 - Modo externo, sem painel F8
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MarksUi {
  [DllImport("gdi32.dll", EntryPoint="CreateRoundRectRgn")]
  public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
}
"@
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:appDir = Join-Path $env:LOCALAPPDATA 'MarksFETrainer'
$script:resourcesDir=$env:MARKS_FE_RESOURCES
if([string]::IsNullOrWhiteSpace($script:resourcesDir)){$script:resourcesDir=$script:appDir}
$script:configFile = Join-Path $script:appDir 'settings.json'
$script:bridgeCode = Join-Path $script:resourcesDir 'MarksFE_Bridge_Windows.js'
$script:coreCode = Join-Path $script:resourcesDir 'MarksFEV3_2_ORIGINAL.js'
$script:game = $null
$script:gameExe = $null
$script:updatingUI = $false
$script:commandTime = [datetime]::MinValue
$script:state = @{
 yen=$false; drops=$false; speed=$false; expEnabled=$false; perkEnabled=$false
 damageAllEnabled=$false; pistolEnabled=$false; machineEnabled=$false; reloadEnabled=$false
 dropChance=5; dropAmount=3; attackSpeed=2; expMultiplier=5; perksPerLevel=2
 damageAllMultiplier=2; pistolMultiplier=2; machineMultiplier=2; reloadMultiplier=2
}
$script:choice = @{
 dropChance=@(1,2,3,5,10); dropAmount=@(1,2,3,5,10)
 attackSpeed=@(1,1.5,2,3,5); expMultiplier=@(1,2,5,10,15,20,25,50)
 perksPerLevel=@(1,2,3,4,5,6,7,8,9,10,15,20)
 damageAllMultiplier=@(1,1.5,2,3,5,10)
 pistolMultiplier=@(1,1.5,2,2.5,3,3.5,5,10)
 machineMultiplier=@(1,1.5,2,2.5,3,3.5,5,10)
 reloadMultiplier=@(1,1.5,2,2.5,3,5,10)
}
$script:items = @(
 @{name='YEN INFINITO';desc='Reabastece yen automaticamente';key='yen';cat='GERAL';icon='💰';tag='YEN';opts=@()},
 @{name='DROPS AUMENTADOS';desc='Ajusta chance e quantidade';key='drops';cat='GERAL';icon='📦';tag='DROP';opts=@(@{label='CHANCE';key='dropChance'},@{label='ITENS';key='dropAmount'})},
 @{name='ATB ACELERADO';desc='Aumenta a velocidade do ATB';key='speed';cat='GERAL';icon='⚡';tag='ATB';opts=@(@{label='VELOCIDADE';key='attackSpeed'})},
 @{name='XP MULTIPLICADO';desc='Multiplica a experiência ganha';key='expEnabled';cat='PROGRESSÃO';icon='⭐';tag='XP';opts=@(@{label='XP';key='expMultiplier'})},
 @{name='PERKS POR NÍVEL';desc='Define perks extras por nível';key='perkEnabled';cat='PROGRESSÃO';icon='🧩';tag='PERK';opts=@(@{label='PERKS';key='perksPerLevel'})},
 @{name='DANO GERAL';desc='Aumenta o dano de todas as armas';key='damageAllEnabled';cat='ARMAS';icon='💥';tag='DANO';opts=@(@{label='DANO';key='damageAllMultiplier'})},
 @{name='DANO DA PISTOLA';desc='Ajuste exclusivo da pistola';key='pistolEnabled';cat='ARMAS';icon='🔫';tag='PISTOLA';opts=@(@{label='DANO';key='pistolMultiplier'})},
 @{name='DANO MACHINE GUN';desc='Ajuste exclusivo da metralhadora';key='machineEnabled';cat='ARMAS';icon='🔥';tag='M-GUN';opts=@(@{label='DANO';key='machineMultiplier'})},
 @{name='RECARGA RÁPIDA';desc='Reduz o tempo de recarga';key='reloadEnabled';cat='RECARGA';icon='🔄';tag='RELOAD';opts=@(@{label='VELOCIDADE';key='reloadMultiplier'})}
)
$script:toggles = @{}
$script:sliders = @{}
$script:values = @{}
$script:iconImages = @{}
$script:headerImage = $null
$script:exeIcon = $null


function Brush([string] $hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Font([float]$size,[bool]$bold=$false,[string]$family='Segoe UI'){
  $style = if($bold){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}
  New-Object System.Drawing.Font($family,$size,$style)
}
function Round([System.Windows.Forms.Control]$ctrl,[int]$radius=18){
  $ctrl.Region = [System.Drawing.Region]::FromHrgn([MarksUi]::CreateRoundRectRgn(0,0,$ctrl.Width,$ctrl.Height,$radius,$radius))
}
$script:c = @{
 bg=(Brush '#121315'); bg2=(Brush '#18191C'); header=(Brush '#1A1D22'); panel=(Brush '#1E2126')
 card=(Brush '#23262D'); card2=(Brush '#2A2E37'); track=(Brush '#393E49');
 accent=(Brush '#F5C05D'); accent2=(Brush '#F08A4B'); txt=(Brush '#FAF7F0'); sub=(Brush '#D2D7E1'); muted=(Brush '#95A0B2');
 dark=(Brush '#181513'); warn=(Brush '#F8CF80'); border=(Brush '#49505F');
 g1=(Brush '#F0B55A'); g2=(Brush '#69C8FF'); g3=(Brush '#FF7B7B'); g4=(Brush '#A6E071');
 key=(Brush '#313744'); keyText=(Brush '#FAF7F0'); badge=(Brush '#232A36');
 on=(Brush '#F5C05D'); off=(Brush '#454B57')
}
function CatColor([string]$cat){
  switch($cat){
    'PROGRESSÃO' {return $script:c.g2}
    'ARMAS' {return $script:c.g3}
    'RECARGA' {return $script:c.g4}
    default {return $script:c.g1}
  }
}
function Text([System.Windows.Forms.Control]$parent,[string]$value,[int]$x,[int]$y,[int]$w,[int]$h,[float]$size=10,[string]$col='txt',[bool]$bold=$false,[string]$align='Left', [string]$family='Segoe UI'){
  $l=New-Object System.Windows.Forms.Label
  $l.SetBounds($x,$y,$w,$h); $l.Text=$value; $l.ForeColor=$script:c[$col]; $l.Font=(Font $size $bold $family)
  $l.BackColor=$parent.BackColor
  switch($align){'Center' {$l.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter} 'Right' {$l.TextAlign=[System.Drawing.ContentAlignment]::MiddleRight} default {$l.TextAlign=[System.Drawing.ContentAlignment]::MiddleLeft}}
  $parent.Controls.Add($l)
  return $l
}
function Pill([System.Windows.Forms.Control]$parent,[string]$text,[int]$x,[int]$y,[int]$w,[int]$h,[System.Drawing.Color]$back,[System.Drawing.Color]$fore,[float]$size=8.5,[string]$family='Segoe UI'){
  $p=New-Object System.Windows.Forms.Label
  $p.SetBounds($x,$y,$w,$h); $p.Text=$text; $p.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter; $p.BackColor=$back; $p.ForeColor=$fore; $p.Font=(Font $size $true $family)
  $parent.Controls.Add($p); Round $p ([Math]::Floor($h/2))
  return $p
}
function FlatButton([System.Windows.Forms.Control]$parent,[string]$caption,[int]$x,[int]$y,[int]$w,[int]$h,[string]$kind='secondary'){
  $b=New-Object System.Windows.Forms.Button
  $b.SetBounds($x,$y,$w,$h); $b.Text=$caption; $b.FlatStyle=[System.Windows.Forms.FlatStyle]::Flat; $b.FlatAppearance.BorderSize=1
  $b.Font=(Font 9.3 $true); $b.Cursor=[System.Windows.Forms.Cursors]::Hand; $b.UseVisualStyleBackColor=$false
  switch($kind){
    'primary' {$b.BackColor=$script:c.accent; $b.ForeColor=$script:c.dark; $b.FlatAppearance.BorderColor=$script:c.accent}
    'danger' {$b.BackColor=$script:c.accent2; $b.ForeColor=$script:c.dark; $b.FlatAppearance.BorderColor=$script:c.accent2}
    'ghost' {$b.BackColor=$script:c.card2; $b.ForeColor=$script:c.txt; $b.FlatAppearance.BorderColor=$script:c.border}
    default {$b.BackColor=$script:c.track; $b.ForeColor=$script:c.txt; $b.FlatAppearance.BorderColor=$script:c.border}
  }
  $parent.Controls.Add($b); Round $b 15
  return $b
}
function Alert([string]$message,[string]$title='MARKS FE'){
  [void][System.Windows.Forms.MessageBox]::Show($script:form,$message,$title,[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}
function GetGame([string]$candidate){
  if([string]::IsNullOrWhiteSpace($candidate)){return $null}
  try{
    if([IO.File]::Exists($candidate)){$candidate=[IO.Path]::GetDirectoryName($candidate)}
    foreach($dir in @($candidate,(Join-Path $candidate 'www'))){
      if((Test-Path -LiteralPath (Join-Path $dir 'index.html') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $dir 'js\plugins.js') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $dir 'js\rmmz_objects.js') -PathType Leaf)){ return [IO.Path]::GetFullPath($dir) }
    }
  }catch{}
  return $null
}
function LoadConfig(){
  try{
    if(Test-Path -LiteralPath $script:configFile){
      $data=Get-Content -LiteralPath $script:configFile -Raw -Encoding UTF8 | ConvertFrom-Json
      $script:game=GetGame ([string]$data.game)
      if($script:game -and $data.gameExe -and [IO.File]::Exists([string]$data.gameExe)){
        $script:gameExe=[string]$data.gameExe
      }
    }
  }catch{}
}
function SaveConfig(){
  if(-not $script:game){return}
  [IO.Directory]::CreateDirectory($script:appDir)|Out-Null
  $cfg=@{game=$script:game;gameExe=$script:gameExe}
  [IO.File]::WriteAllText($script:configFile,($cfg|ConvertTo-Json -Compress),(New-Object System.Text.UTF8Encoding($false)))
}
function GetGameRoot(){
  if(-not $script:game){return $null}
  $dir = New-Object System.IO.DirectoryInfo -ArgumentList @($script:game)
  if($dir.Name -ieq 'www' -and $dir.Parent){return $dir.Parent.FullName}
  return $dir.FullName
}
function FindGameExecutable(){
  $root=GetGameRoot
  if(-not $root){return $null}
  $folders=@($root,$script:game) | Select-Object -Unique
  $candidates=New-Object System.Collections.ArrayList
  foreach($folder in $folders){
    if(-not [IO.Directory]::Exists($folder)){continue}
    try{$files=[IO.Directory]::GetFiles($folder,'*.exe')}catch{continue}
    foreach($file in $files){
      $name=[IO.Path]::GetFileNameWithoutExtension($file).ToLowerInvariant()
      # Nao executar instaladores, atualizadores ou launchers nao relacionados.
      if($name -match '^(unins|uninstall|setup|install|updater|update|crash|dxsetup|vcredist|redist|marks|trainer|unitycrash)'){continue}
      [void]$candidates.Add($file)
    }
  }
  if($candidates.Count -eq 0){return $null}
  if($candidates.Count -eq 1){return [string]$candidates[0]}
  $ranked=@()
  foreach($file in $candidates){
    $name=[IO.Path]::GetFileNameWithoutExtension([string]$file).ToLowerInvariant()
    $points=0
    if($name -match 'tunnel.*escape|escape.*tunnel'){$points=100}
    elseif($name -eq 'game'){$points=90}
    elseif($name -match 'fates.*entwined|entwined.*fates'){$points=85}
    elseif($name -eq 'nw'){$points=75}
    $ranked+=([pscustomobject]@{path=[string]$file;points=$points})
  }
  $ranked=@($ranked | Sort-Object -Property points -Descending)
  if($ranked.Count -ge 2 -and $ranked[0].points -gt $ranked[1].points -and $ranked[0].points -gt 0){return [string]$ranked[0].path}
  return $null
}
function ChooseGameExecutable(){
  $root=GetGameRoot
  $dlg=New-Object System.Windows.Forms.OpenFileDialog
  $dlg.Title='Selecione o executavel do Tunnel Escape: Fates Entwined'
  $dlg.Filter='Aplicativos do Windows (*.exe)|*.exe'
  $dlg.CheckFileExists=$true
  $dlg.Multiselect=$false
  if($root){$dlg.InitialDirectory=$root}
  try{
    if($dlg.ShowDialog($script:form) -eq [System.Windows.Forms.DialogResult]::OK){
      return [string]$dlg.FileName
    }
  }finally{$dlg.Dispose()}
  return $null
}
function PlayGame(){
  if(-not $script:game){SelectGame; if(-not $script:game){return}}
  if(-not $script:gameExe -or -not [IO.File]::Exists($script:gameExe)){
    $script:gameExe=FindGameExecutable
    if(-not $script:gameExe){
      Alert 'Nao foi possivel identificar automaticamente o EXE do jogo. Selecione o arquivo correto (normalmente Game.exe ou Tunnel Escape.exe). Esta escolha sera salva para os proximos cliques.' 'Localizar executavel'
      $script:gameExe=ChooseGameExecutable
    }
    if(-not $script:gameExe){return}
    SaveConfig
  }
  try{
    if([IO.Path]::GetExtension($script:gameExe) -ine '.exe'){throw 'Arquivo selecionado nao e um executavel .exe.'}
    Start-Process -FilePath $script:gameExe -WorkingDirectory ([IO.Path]::GetDirectoryName($script:gameExe)) -ErrorAction Stop
  }catch{
    Alert ('Nao foi possivel abrir o jogo: '+$_.Exception.Message) 'Erro ao jogar'
  }
}
function FileText([string]$file){ [IO.File]::ReadAllText($file,[System.Text.Encoding]::UTF8) }
function WriteText([string]$file,[string]$data){
  $id=[guid]::NewGuid().ToString('N')
  $tmp=$file+'.marksfe-'+$id+'.tmp'
  $backup=$file+'.marksfe-'+$id+'.backup'
  [IO.File]::WriteAllText($tmp,$data,(New-Object System.Text.UTF8Encoding($false)))
  try{
    if([IO.File]::Exists($file)){
      try{ [IO.File]::Replace($tmp,$file,$backup) }
      catch [System.IO.IOException]{ [IO.File]::Copy($tmp,$file,$true) }
      catch [System.ArgumentException]{ [IO.File]::Copy($tmp,$file,$true) }
    }else{ [IO.File]::Move($tmp,$file) }
  }finally{
    if([IO.File]::Exists($tmp)){[IO.File]::Delete($tmp)}
    if([IO.File]::Exists($backup)){[IO.File]::Delete($backup)}
  }
}
function SendSetting([string]$key,$val){
  if(-not $script:game){ Alert 'Clique em LOCALIZAR JOGO antes de alterar os cheats.'; return $false }
  if(-not $script:state.ContainsKey($key)){ return $false }
  try{
    $dir=Join-Path $script:game 'js\plugins'
    $dest=Join-Path $dir 'MarksFE_DesktopBridge.ini'
    $sv = if($val -is [bool]){$val.ToString().ToLowerInvariant()} else {[Convert]::ToString($val,[globalization.cultureinfo]::InvariantCulture)}
    WriteText $dest ("# TUNNEL ESCAPE FE TRAINER V6.6 - comando local`n$key=$sv`n")
    $script:state[$key]=$val; $script:commandTime=[datetime]::UtcNow; return $true
  }catch{ Alert ("Não foi possível enviar o comando ao jogo:`n"+$_.Exception.Message) 'Falha de comunicação'; return $false }
}
function FormatVal([string]$key,$val){ $n=[Convert]::ToString($val,[globalization.cultureinfo]::InvariantCulture); if($key -eq 'perksPerLevel'){return $n}; return "$($n)x" }
function UpdateButton([string]$key){ if(-not $script:toggles.ContainsKey($key)){return}; $b=$script:toggles[$key]; $en=[bool]$script:state[$key]; $b.Text=$(if($en){'LIGADO'}else{'DESLIGADO'}); $b.BackColor=$(if($en){$script:c.on}else{$script:c.off}); $b.ForeColor=$(if($en){$script:c.dark}else{$script:c.txt}) }
function Toggle([string]$key){ $new= -not [bool]$script:state[$key]; if(SendSetting $key $new){ UpdateButton $key } }
function ChangeSlider([string]$key,[int]$delta){ if(-not $script:sliders.ContainsKey($key)){return}; $tb=$script:sliders[$key]; $new=[Math]::Max($tb.Minimum,[Math]::Min($tb.Maximum,$tb.Value+$delta)); if($new -ne $tb.Value){ $tb.Value=$new } }
function AddSlider([System.Windows.Forms.Control]$parent,[string]$label,[string]$key,[int]$x,[int]$y,[int]$width,[System.Drawing.Color]$accent){
  [void](Pill $parent $label $x ($y+2) 73 17 $script:c.track $script:c.sub 7.1)
  $minus=FlatButton $parent '-' ($x+79) ($y+1) 24 21 'ghost'
  $plus=FlatButton $parent '+' ($x+$width-91) ($y+1) 24 21 'ghost'
  $tb=New-Object System.Windows.Forms.TrackBar
  $tb.AutoSize=$false
  $tb.SetBounds(($x+109),($y+1),($width-201),21)
  $tb.Minimum=0
  $tb.Maximum=$script:choice[$key].Count-1
  $tb.TickStyle=[System.Windows.Forms.TickStyle]::None
  $tb.SmallChange=1
  $tb.LargeChange=1
  $tb.BackColor=$parent.BackColor
  $list=$script:choice[$key]
  $idx=0
  for($i=0;$i -lt $list.Count;$i++){
    if([double]$list[$i] -eq [double]$script:state[$key]){$idx=$i; break}
  }
  $tb.Value=$idx
  $parent.Controls.Add($tb)
  $value=Text $parent (FormatVal $key $list[$idx]) ($x+$width-61) ($y+1) 55 21 9.4 'txt' $true 'Right'
  $value.ForeColor=$accent
  $tb.Tag=@{Key=$key;ValueLabel=$value}
  $tb.Add_ValueChanged({
    param($sender,$e)
    $ctx=$sender.Tag; $k=[string]$ctx.Key
    $val=$script:choice[$k][$sender.Value]
    $ctx.ValueLabel.Text=FormatVal $k $val
    if(-not $script:updatingUI){ [void](SendSetting $k $val) }
  })
  $minus.Tag=$key; $plus.Tag=$key
  $minus.Add_Click({ param($sender,$e) ChangeSlider ([string]$sender.Tag) -1 })
  $plus.Add_Click({ param($sender,$e) ChangeSlider ([string]$sender.Tag) 1 })
  $script:sliders[$key]=$tb
  $script:values[$key]=$value
}
function SelectGame(){
  $dlg=New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.Description='Selecione a pasta do Tunnel Escape FE que contém index.html (ou sua pasta principal).'; $dlg.ShowNewFolderButton=$false
  if($script:game){$dlg.SelectedPath=$script:game}
  try{ if($dlg.ShowDialog($script:form) -ne [System.Windows.Forms.DialogResult]::OK){return}; $candidate=GetGame $dlg.SelectedPath; if(-not $candidate){Alert 'Pasta inválida. Selecione a pasta com index.html e js\plugins.js, ou a pasta principal quando esses arquivos estiverem em www.' 'Pasta incorreta'; return}; if($script:game -ne $candidate){$script:gameExe=$null}; $script:game=$candidate; SaveConfig; RefreshStatus } finally{ $dlg.Dispose() }
}
function RemoveInternalPanel([string]$source){
  # Preserva os hooks do jogo e remove apenas interface/atalho F8 do plugin.
  if($source.Contains('MARKS_FE_HEADLESS_V66')){return $source}
  $start='  // MARKS FE v3.2: somente a interface foi substituida.'
  $finish='  window.MarksFEV3={status:'
  $a=$source.IndexOf($start,[System.StringComparison]::Ordinal)
  $b=$source.IndexOf($finish,[System.StringComparison]::Ordinal)
  if($a -lt 0 -or $b -lt $a){
    throw 'Nao foi possivel identificar com seguranca o painel interno F8. O arquivo original foi preservado.'
  }
  $head=$source.Substring(0,$a)
  $tail=$source.Substring($b)
  $body=@'
  // MARKS_FE_HEADLESS_V66: painel HTML e atalho F8 removidos.
  function sync() {} // Mantido para compatibilidade com a API set.
  window.setInterval(()=>{topUpYen();applyPerks();},1000);
'@
  return $head+$body+"`r`n"+$tail
}

function InstallBridge(){
  if(-not $script:game){SelectGame;if(-not $script:game){return}}
  $ans=[System.Windows.Forms.MessageBox]::Show($script:form,'Com o jogo fechado, atualizar a ponte e remover o painel interno F8? Os cheats permanecem no aplicativo externo, e os saves serao preservados. Prosseguir?','Instalar ponte',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
  if($ans -ne [System.Windows.Forms.DialogResult]::Yes){return}
  try{
    $dir=Join-Path $script:game 'js\plugins'; $plugin=Join-Path $dir 'MarksFEV3.js'; $plugins=Join-Path $script:game 'js\plugins.js'
    $original= if([IO.File]::Exists($plugin)){FileText $plugin}else{FileText $script:coreCode}
    if((-not $original.Contains('window.MarksFEV3')) -or (-not $original.Contains('set:(name,value)'))){throw 'O MARKS FE existente é incompatível. Nenhum arquivo foi modificado.'}
    $previousMark='/* MARKS FE - Desktop Companion v1.0'; $markIdx=$original.IndexOf($previousMark); if($markIdx -ge 0){$original=$original.Substring(0,$markIdx).TrimEnd()}
    $pattern='(?s)/\* MARKS_FE_DESKTOP_BRIDGE_V2_BEGIN.*?/\* MARKS_FE_DESKTOP_BRIDGE_V2_END \*/'; $original=[regex]::Replace($original,$pattern,'').TrimEnd()
    $original=RemoveInternalPanel $original
    $newPlugin=$original+"`r`n`r`n"+(FileText $script:bridgeCode)+"`r`n"; $originalList=FileText $plugins; $hasEntry=[regex]::IsMatch($originalList,'name\s*:\s*[\x27\x22]MarksFEV3[\x27\x22]')
    $newList=$originalList; if(-not $hasEntry){$newList=$originalList.TrimEnd()+"`r`n// MARKS FE Windows Companion`r`n"+'$plugins.push({name:"MarksFEV3",status:true,description:"MARKS FE v3.2",parameters:{}});'+"`r`n"}
    $pluginBack=$plugin+'.before_windows.bak'; $pluginMissing=$plugin+'.before_windows.missing'; $listBack=$plugins+'.before_windows.bak'
    if((-not [IO.File]::Exists($pluginBack)) -and (-not [IO.File]::Exists($pluginMissing))){ if([IO.File]::Exists($plugin)){[IO.File]::Copy($plugin,$pluginBack)} else {WriteText $pluginMissing 'Original plugin absent before Windows companion.'} }
    if(-not [IO.File]::Exists($listBack)){[IO.File]::Copy($plugins,$listBack)}
    $oldPlugin=if([IO.File]::Exists($plugin)){[IO.File]::ReadAllBytes($plugin)}else{$null}; $oldList=[IO.File]::ReadAllBytes($plugins)
    try{ WriteText $plugin $newPlugin; if(-not $hasEntry){WriteText $plugins $newList} }catch{ if($null -ne $oldPlugin){[IO.File]::WriteAllBytes($plugin,$oldPlugin)} elseif([IO.File]::Exists($plugin)){[IO.File]::Delete($plugin)}; [IO.File]::WriteAllBytes($plugins,$oldList); throw }
    Alert 'Ponte atualizada! O jogo nao exibira mais o painel interno F8. Abra o jogo pelo botao JOGAR e controle os cheats pelo aplicativo externo.' 'Instalacao concluida'; RefreshStatus
  }catch{ Alert ("Falha na instalação:`n"+$_.Exception.Message) 'Erro' }
}
function RestoreBridge(){
  if(-not $script:game){Alert 'Selecione primeiro a pasta do jogo.';return}
  $ans=[System.Windows.Forms.MessageBox]::Show($script:form,'Restaurar o plugin anterior e remover a ponte do Windows? Feche o jogo antes. Os saves serão preservados.','Restaurar instalação',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
  if($ans -ne [System.Windows.Forms.DialogResult]::Yes){return}
  try{ $plugin=Join-Path $script:game 'js\plugins\MarksFEV3.js'; $plugins=Join-Path $script:game 'js\plugins.js'; $bak=$plugin+'.before_windows.bak'; $missing=$plugin+'.before_windows.missing'; $bakList=$plugins+'.before_windows.bak'; if((-not [IO.File]::Exists($bak)) -and (-not [IO.File]::Exists($missing))){throw 'Backup anterior não encontrado. Nenhum arquivo foi alterado.'}; if([IO.File]::Exists($bak)){[IO.File]::Copy($bak,$plugin,$true)} elseif([IO.File]::Exists($plugin)){[IO.File]::Delete($plugin)}; if([IO.File]::Exists($bakList)){[IO.File]::Copy($bakList,$plugins,$true)}; Alert 'Restaurado. Os backups foram mantidos. Reinicie o jogo.' }catch{ Alert ("Falha ao restaurar:`n"+$_.Exception.Message) }
}
function ReadStatus(){
  if(-not $script:game){return $null}
  try{ $file=Join-Path $script:game 'js\plugins\MarksFE_DesktopStatus.ini'; if(-not [IO.File]::Exists($file)){return $null}; $age=[datetime]::UtcNow.Subtract([IO.File]::GetLastWriteTimeUtc($file)).TotalSeconds; if($age -gt 6 -or $age -lt -10){return $null}; $kv=@{}; foreach($line in [IO.File]::ReadAllLines($file)){ $idx=$line.IndexOf('='); if($idx -gt 0){$kv[$line.Substring(0,$idx).Trim()]=$line.Substring($idx+1).Trim()} }; if($kv.bridge -ne 'online'){return $null}; return $kv }catch{return $null}
}
function SyncControls($status){
  if(-not $status){return}; if([datetime]::UtcNow.Subtract($script:commandTime).TotalMilliseconds -lt 1500){return}
  $script:updatingUI=$true
  try{ foreach($key in @($script:state.Keys)){ if(-not $status.ContainsKey($key)){continue}; $raw=[string]$status[$key]; if($script:choice.ContainsKey($key)){ $v=0.0; if(-not [double]::TryParse($raw,[globalization.numberstyles]::Float,[globalization.cultureinfo]::InvariantCulture,[ref]$v)){continue}; if(-not ($script:choice[$key] -contains $v)){continue}; $script:state[$key]=$v; if($script:sliders.ContainsKey($key)){ $idx=0; for($i=0;$i -lt $script:choice[$key].Count;$i++){ if([double]$script:choice[$key][$i] -eq $v){$idx=$i; break} }; $script:sliders[$key].Value=$idx; $script:values[$key].Text=FormatVal $key $v } } else { if($raw -ne 'true' -and $raw -ne 'false'){continue}; $script:state[$key]=($raw -eq 'true'); UpdateButton $key } } }finally{$script:updatingUI=$false}
}
function RefreshStatus(){
  if(-not $script:game){ $script:pathLabel.Text='---'; $script:statusLabel.Text='SEM PASTA'; $script:statusLabel.ForeColor=$script:c.warn; $script:statusDetail.Text='Clique em LOCALIZAR JOGO para começar.'; $script:yenLabel.Text='--'; return }
  $script:pathLabel.Text=$script:game; $status=ReadStatus
  if($status){ $script:statusLabel.Text='CONECTADO'; $script:statusLabel.ForeColor=$script:c.accent; $script:statusDetail.Text='Cheats prontos. Interface HD mais legível e chamativa.'; $script:yenLabel.Text=[string]$status.gold; SyncControls $status }
  else { $script:statusLabel.Text='AGUARDANDO JOGO'; $script:statusLabel.ForeColor=$script:c.warn; $script:statusDetail.Text='Com o jogo fechado, clique INSTALAR PONTE para retirar o painel F8.'; $script:yenLabel.Text='--' }
}
function LoadArtwork(){
  $imgDir = Join-Path $script:resourcesDir 'assets'
  foreach($item in $script:items){
    $filename='ic_'+([string]$item.key)+'.png'
    $full=Join-Path $imgDir $filename
    if([IO.File]::Exists($full)){
      $script:iconImages[[string]$item.key]=[System.Drawing.Image]::FromFile($full)
    }
  }
  $head=Join-Path $imgDir 'header_animado.gif'
  if([IO.File]::Exists($head)){$script:headerImage=[System.Drawing.Image]::FromFile($head)}
  $ico=Join-Path $imgDir 'Tunnel_Escape_FE_Trainer.ico'
  if([IO.File]::Exists($ico)){$script:exeIcon=[System.Drawing.Icon]::new($ico)}
}

function BuildIcon([System.Windows.Forms.Control]$parent,[hashtable]$item,[System.Drawing.Color]$accent){
  # Mesmo quadrado, mesmas margens e alinhamento para as nove imagens HD.
  # Imagens pre-processadas em 512 x 512 e moldura integrada na propria arte.
  $tile=New-Object System.Windows.Forms.Panel
  $tile.SetBounds(15,1,48,47)
  $tile.BackColor=$script:c.bg2
  $parent.Controls.Add($tile)
  Round $tile 10
  $key=[string]$item.key
  if($script:iconImages.ContainsKey($key)){
    $pic=New-Object System.Windows.Forms.PictureBox
    $pic.SetBounds(0,0,48,47)
    $pic.Margin=[System.Windows.Forms.Padding]::Empty
    $pic.BackColor=$tile.BackColor
    $pic.SizeMode=[System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pic.Image=$script:iconImages[$key]
    $tile.Controls.Add($pic)
    Round $pic 10
  }else{
    [void](Pill $tile ([string]$item.tag) 3 12 42 25 $script:c.key $accent 7.6)
  }
  return $tile
}
function BuildCard([hashtable]$item,[int]$x,[int]$y,[int]$w,[int]$h,[int]$idx){
  $accent=CatColor $item.cat
  $card=New-Object System.Windows.Forms.Panel
  $card.SetBounds($x,$y,$w,$h)
  $card.BackColor=$(if($idx % 2 -eq 0){$script:c.card}else{$script:c.card2})
  $script:cards.Controls.Add($card); Round $card 14
  $stripe=New-Object System.Windows.Forms.Panel
  $stripe.SetBounds(7,5,3,($h-10)); $stripe.BackColor=$accent
  $card.Controls.Add($stripe); Round $stripe 4
  [void](BuildIcon $card $item $accent)
  [void](Pill $card ('F'+($idx+1)) 72 11 38 26 $script:c.track $accent 8.8)
  [void](Text $card 'Ctrl+Alt' 116 13 55 20 7.3 'muted')
  [void](Text $card $item.name 179 5 241 22 9.5 'txt' $true)
  [void](Text $card $item.desc 179 26 253 18 7.5 'sub')
  $toggle=FlatButton $card 'DESLIGADO' 887 9 109 31 'secondary'
  $toggle.Tag=$item.key
  $toggle.Add_Click({param($sender,$e) Toggle ([string]$sender.Tag)})
  $script:toggles[$item.key]=$toggle
  UpdateButton $item.key
  if($item.opts.Count -eq 1){
    AddSlider $card ([string]$item.opts[0].label) ([string]$item.opts[0].key) 431 13 436 $accent
  }elseif($item.opts.Count -eq 2){
    AddSlider $card ([string]$item.opts[0].label) ([string]$item.opts[0].key) 431 1 436 $accent
    AddSlider $card ([string]$item.opts[1].label) ([string]$item.opts[1].key) 431 25 436 $accent
  }
}

$script:form=New-Object System.Windows.Forms.Form
$script:form.Text='TUNNEL ESCAPE FE TRAINER V6.6  |  SOMENTE PAINEL EXTERNO'
$script:form.ClientSize=New-Object System.Drawing.Size(1040,796)
$script:form.StartPosition=[System.Windows.Forms.FormStartPosition]::CenterScreen
$script:form.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedSingle
$script:form.MaximizeBox=$false
$script:form.MinimizeBox=$true
$script:form.BackColor=$script:c.bg
$script:form.Font=(Font 9.5)
$script:form.AutoScaleMode=[System.Windows.Forms.AutoScaleMode]::None
$script:form.AutoScroll=$true
$area=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
if($area.Height -lt 843 -or $area.Width -lt 1080){
  $w=[Math]::Min(1040,($area.Width-32))
  $h=[Math]::Min(796,($area.Height-54))
  $script:form.ClientSize=New-Object System.Drawing.Size($w,$h)
  $script:form.AutoScrollMinSize=New-Object System.Drawing.Size(1040,796)
}
LoadArtwork
if($script:exeIcon){$script:form.Icon=$script:exeIcon}

# Faixa de cabecalho animada, composta a partir da arte do proprio jogo.
$top=New-Object System.Windows.Forms.Panel
$top.SetBounds(0,0,1040,157)
$top.BackColor=$script:c.header
$script:form.Controls.Add($top)
if($script:headerImage){
  $picHeader=New-Object System.Windows.Forms.PictureBox
  $picHeader.SetBounds(0,0,1040,157)
  $picHeader.Image=$script:headerImage
  $picHeader.SizeMode=[System.Windows.Forms.PictureBoxSizeMode]::StretchImage
  $top.Controls.Add($picHeader)
  # PictureBox anima automaticamente GIFs com frames temporizados no WinForms
}else{
  [void](Text $top 'TUNNEL ESCAPE FE TRAINER' 28 38 975 85 27 'txt' $true 'Center')
}

# Status preserva selecao de jogo, instalacao da ponte e leitura de yen.
$statusBox=New-Object System.Windows.Forms.Panel
$statusBox.SetBounds(16,166,1008,87)
$statusBox.BackColor=$script:c.panel
$script:form.Controls.Add($statusBox); Round $statusBox 18
$script:statusLabel=Text $statusBox 'SEM PASTA' 20 7 275 25 12 'warn' $true
$script:statusDetail=Text $statusBox 'Selecione a pasta do jogo para começar.' 20 32 521 18 8 'sub'
[void](Text $statusBox 'PASTA DO JOGO' 20 60 95 16 7 'muted' $true)
$script:pathLabel=Text $statusBox '---' 116 60 548 16 7.3 'sub'
[void](Text $statusBox 'YEN NO JOGO' 667 8 121 16 7.3 'muted' $true)
$script:yenLabel=Text $statusBox '--' 668 27 120 37 17 'accent' $true
$localizar=FlatButton $statusBox 'LOCALIZAR JOGO' 826 7 162 32 'primary'; $localizar.Add_Click({SelectGame})
$instalar=FlatButton $statusBox 'INSTALAR PONTE' 826 47 162 32 'ghost'; $instalar.Add_Click({InstallBridge})

# 9 cheats, todos visiveis em tela unica.
$script:cards=New-Object System.Windows.Forms.Panel
$script:cards.SetBounds(16,261,1008,476)
$script:cards.BackColor=$script:c.bg
$script:form.Controls.Add($script:cards)
for($i=0; $i -lt $script:items.Count; $i++){
  BuildCard $script:items[$i] 0 ($i*53) 1008 49 $i
}

$footer=New-Object System.Windows.Forms.Panel
$footer.SetBounds(16,747,1008,40)
$footer.BackColor=$script:c.bg2
$script:form.Controls.Add($footer); Round $footer 15
[void](Text $footer 'Ctrl + Alt + F1 a F9  |  Painel F8 interno desativado  |  Saves preservados' 13 9 640 22 8 'muted')
$play=FlatButton $footer 'JOGAR' 682 5 146 30 'primary'
$play.Add_Click({PlayGame})
$restore=FlatButton $footer 'RESTAURAR PONTE' 846 5 148 30 'danger'
$restore.Add_Click({RestoreBridge})

$script:timer=New-Object System.Windows.Forms.Timer
$script:timer.Interval=950
$script:timer.Add_Tick({RefreshStatus})
$script:form.KeyPreview=$true
$script:form.Add_KeyDown({
  param($sender,$e)
  if($e.Control -and $e.Alt -and $e.KeyCode -ge [System.Windows.Forms.Keys]::F1 -and $e.KeyCode -le [System.Windows.Forms.Keys]::F9){
    $idx=[int]$e.KeyCode-[int][System.Windows.Forms.Keys]::F1
    if($idx -ge 0 -and $idx -lt $script:items.Count){ Toggle $script:items[$idx].key; $e.Handled=$true }
  }
})
LoadConfig
if($script:game){$script:pathLabel.Text=$script:game}
RefreshStatus
$script:timer.Start()
try{ [void]$script:form.ShowDialog() }
finally{ $script:timer.Stop(); $script:timer.Dispose(); $script:form.Dispose()
  foreach($im in @($script:iconImages.Values)){if($im){$im.Dispose()}}
  if($script:headerImage){$script:headerImage.Dispose()}
  if($script:exeIcon){$script:exeIcon.Dispose()}
}
