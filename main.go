// TUNNEL ESCAPE FE TRAINER V6.6 - desktop Windows 10/11 x64.
// Funcionalidade de cheats offline herdada da V4.2, com tema Fates Entwined.
// Arquivo unico: extrai a interface, imagens e scripts locais e abre WinForms.
package main

import (
  "embed"
  "fmt"
  "os"
  "os/exec"
  "path/filepath"
  "strings"
  "syscall"
  "unsafe"
)

//go:embed frontend.ps1 MarksFE_Bridge_Windows.js MarksFEV3_2_ORIGINAL.js assets/*
var data embed.FS

func msgBox(message string) {
  dll := syscall.NewLazyDLL("user32.dll")
  proc := dll.NewProc("MessageBoxW")
  msg, _ := syscall.UTF16PtrFromString(message)
  title, _ := syscall.UTF16PtrFromString("TUNNEL ESCAPE FE TRAINER")
  proc.Call(0, uintptr(unsafe.Pointer(msg)), uintptr(unsafe.Pointer(title)), 0x10)
}

func installResources(instanceDir string) error {
  names := []string{"frontend.ps1", "MarksFE_Bridge_Windows.js", "MarksFEV3_2_ORIGINAL.js"}
  icons, err := data.ReadDir("assets")
  if err != nil { return err }
  for _, ent := range icons {
    if ent.IsDir() { continue }
    names = append(names, "assets/" + ent.Name())
  }
  for _, name := range names {
    bytes, err := data.ReadFile(name)
    if err != nil { return fmt.Errorf("recurso %s: %w",name,err) }
    dst := filepath.Join(instanceDir,filepath.FromSlash(name))
    if err = os.MkdirAll(filepath.Dir(dst),0755);err != nil {return err}
    // Arquivos sao isolados por execucao: nenhum GIF aberto e sobrescrito.
    if err = os.WriteFile(dst, bytes,0644);err != nil {return fmt.Errorf("gravar %s: %w",name,err)}
  }
  return nil
}

func main() {
  local := os.Getenv("LOCALAPPDATA")
  if local == "" {msgBox("Nao foi possivel localizar LOCALAPPDATA.");return}
  home := filepath.Join(local,"MarksFETrainer")
  if err := os.MkdirAll(home,0755);err != nil {msgBox(err.Error());return}
  // Uma pasta temporaria exclusiva por abertura evita conflitos com
  // instancias da V6.4, e tambem entre duas janelas abertas da V6.6.
  runs := filepath.Join(home,"runs")
  if err := os.MkdirAll(runs,0755);err!=nil{msgBox("Erro ao preparar a pasta temporaria: "+err.Error());return}
  instanceDir,err := os.MkdirTemp(runs,"v66-")
  if err!=nil{msgBox("Erro ao criar a pasta temporaria: "+err.Error());return}
  defer os.RemoveAll(instanceDir)
  if err := installResources(instanceDir); err != nil {msgBox("Falha ao preparar o trainer:\n"+err.Error());return}
  log := filepath.Join(home,"ultimo_erro.log")
  cmd := exec.Command("powershell.exe","-NoLogo","-NoProfile","-STA","-ExecutionPolicy","Bypass","-File",filepath.Join(instanceDir,"frontend.ps1"))
  cmd.SysProcAttr=&syscall.SysProcAttr{CreationFlags:0x08000000} // no console
  cmd.Env=append(os.Environ(),"MARKS_FE_RESOURCES="+instanceDir)
  out,err:=cmd.CombinedOutput()
  if err!=nil {
    _=os.WriteFile(log,out,0644)
    detail:=strings.TrimSpace(string(out))
    if len(detail)>900 { detail=detail[:900]+"\n[veja o log completo]" }
    msgBox(fmt.Sprintf("Nao foi possivel abrir o trainer.\n\n%s\n\nLog: %s",detail,log))
  }
}
