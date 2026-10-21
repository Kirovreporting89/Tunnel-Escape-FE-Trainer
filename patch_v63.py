from pathlib import Path
p = Path(__file__).parent / 'frontend.ps1'
s = p.read_text(encoding='utf-8-sig')
s = s.replace('$script:game = $null\n', '$script:game = $null\n$script:gameExe = $null\n', 1)
old = """function LoadConfig(){ try{ if(Test-Path -LiteralPath $script:configFile){ $data=Get-Content -LiteralPath $script:configFile -Raw -Encoding UTF8 | ConvertFrom-Json; $script:game=GetGame ([string]$data.game) } }catch{} }
function SaveConfig(){ if(-not $script:game){return}; [IO.Directory]::CreateDirectory($script:appDir)|Out-Null; [IO.File]::WriteAllText($script:configFile,(@{game=$script:game}|ConvertTo-Json -Compress),(New-Object System.Text.UTF8Encoding($false))) }
"""
new = """function LoadConfig(){
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
  $dir = New-Object System.IO.DirectoryInfo($script:game)
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
    foreach($file in [IO.Directory]::GetFiles($folder,'*.exe')){
      $name=[IO.Path]::GetFileNameWithoutExtension($file).ToLowerInvariant()
      # Nao executar instaladores, atualizadores ou launchers nao relacionados.
      if($name -match '^(unins|uninstall|setup|install|updater|update|crash|dxsetup|vcredist|redist|marks|trainer|unitycrash)'){continue}
      [void]$candidates.Add($file)
    }
  }
  if($candidates.Count -eq 0){return $null}
  if($candidates.Count -eq 1){return [string]$candidates[0]}
  $ranked=@(foreach($file in $candidates){
    $name=[IO.Path]::GetFileNameWithoutExtension([string]$file).ToLowerInvariant()
    $points=0
    if($name -match 'tunnel.*escape|escape.*tunnel'){$points=100}
    elseif($name -eq 'game'){$points=90}
    elseif($name -match 'fates.*entwined|entwined.*fates'){$points=85}
    elseif($name -eq 'nw'){$points=75}
    [pscustomobject]@{path=[string]$file;points=$points}
  } | Sort-Object -Property points -Descending)
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
"""
if old not in s: raise SystemExit('config block not found')
s=s.replace(old,new)
old2='$script:game=$candidate; SaveConfig; RefreshStatus'
new2="if($script:game -ne $candidate){$script:gameExe=$null}; $script:game=$candidate; SaveConfig; RefreshStatus"
assert old2 in s
s=s.replace(old2,new2)
old3="""[void](Text $footer 'Ctrl + Alt + F1 a F9  |  Painel F8  |  Cheats do jogo  |  Saves preservados' 13 9 732 22 8 'muted')
$restore=FlatButton $footer 'RESTAURAR PONTE' 846 5 148 30 'danger'
$restore.Add_Click({RestoreBridge})"""
new3="""[void](Text $footer 'Ctrl + Alt + F1 a F9  |  F8 no jogo  |  Saves preservados' 13 9 640 22 8 'muted')
$play=FlatButton $footer 'JOGAR' 682 5 146 30 'primary'
$play.Add_Click({PlayGame})
$restore=FlatButton $footer 'RESTAURAR PONTE' 846 5 148 30 'danger'
$restore.Add_Click({RestoreBridge})"""
if old3 not in s: raise SystemExit('footer block not found')
s=s.replace(old3,new3)
s=s.replace("$script:form.Text='TUNNEL ESCAPE FE TRAINER V6.2'","$script:form.Text='TUNNEL ESCAPE FE TRAINER V6.3'")
# Make the original face icon visible also in Windows taskbar form; asset update handles the EXE icon.
p.write_text('\ufeff'+s,encoding='utf-8')
print('patched game launcher and UI in',p)
