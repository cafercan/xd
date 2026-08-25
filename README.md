# xd

`xd`, PowerShell içinde sık kullandığınız klasörlere kısa adlarla gitmenizi sağlar.
Kayıtlar terminal kapandıktan sonra da korunur.

## Gereksinimler

- Windows PowerShell 5.1 veya PowerShell 7+
- Windows 10/11

## Kurulum

### GitHub Release üzerinden

1. [Son sürümü](../../releases/latest) açın ve **Source code (zip)** dosyasını indirin.
2. ZIP dosyasını bir klasöre çıkarın.
3. Çıkardığınız klasörde PowerShell açıp şu komutu çalıştırın:

```powershell
.\install.ps1
```

### Git ile

```powershell
git clone https://github.com/cafercan/xd.git
cd xd
.\install.ps1
```

### Betik çalıştırma izni

PowerShell betik çalıştırmayı engelliyorsa kullanıcı hesabınız için yerel betiklere izin
verip kurulumu yeniden çalıştırın:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\install.ps1
```

`Set-ExecutionPolicy` kurum politikası tarafından engellenirse sistem yöneticinizle
görüşmeniz gerekir. `xd` bir PowerShell modülü olduğu için yalnızca kurulum anında
`Bypass` kullanmak sonraki terminallerde yeterli olmaz.

Kurulumdan sonra açık terminallerinizi yeniden başlatın. Kurulumun yapıldığı terminalde
komut hemen kullanılabilir.

Kurulumu doğrulamak için:

```powershell
xd -help
```

## Kullanım

Bir klasörü kaydedin:

```powershell
xd -add GDRS D:\Workspaces\EWARM_FS\GDRS_SERIE\GDRS
```

İçinde bulunduğunuz klasörü doğrudan kaydetmek için aşağıdaki iki eşdeğer komuttan
birini kullanabilirsiniz:

```powershell
xd -atf GDMP
xd -pwd GDMP
```

`-atf`, "add this folder" ifadesinin kısaltmasıdır. `-atf` ve `-pwd` aynı işlemi
yapar; o anki klasörü verilen kısa adla kaydeder.

Ardından istediğiniz zaman klasöre gidin:

```powershell
xd GDRS
```

Diğer komutlar:

```powershell
xd -list
xd -remove GDRS
xd -help
```

Boşluk içeren yolları tırnak içine alın:

```powershell
xd -add proje "D:\Workspaces\Benim Projem"
```

Kısa adlar büyük/küçük harfe duyarlı değildir; `xd GDRS` ile `xd gdrs` aynıdır.
Kayıtlar `%LOCALAPPDATA%\xd\aliases.json` dosyasında tutulur.

## Kaldırma

```powershell
.\uninstall.ps1
```

Bu işlem kayıtlı klasörleri silmez. Kayıtları da silmek isterseniz
`%LOCALAPPDATA%\xd` klasörünü ayrıca kaldırabilirsiniz.

## Test

Proje klasöründe:

```powershell
.\tests\xd.Tests.ps1
```
