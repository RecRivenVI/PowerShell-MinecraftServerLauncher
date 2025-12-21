# 专用于 Minecraft Forge（1.17+），NeoForge 与 Fabric 服务端的启动脚本

## 使用 Powershell 编写

### 因为目前还是我个人使用，所以内置了代理和硬编码 Java 路径

### 使用前（大概率）需要修改以下部分：

```powershell
#代理
$env:HTTP_PROXY = "http://127.0.0.1:7897"
$env:HTTPS_PROXY = "http://127.0.0.1:7897"

#Java绝对路径
$JavaPath = "C:\Program Files\BellSoft\LibericaJDK-$($Minecraft.JavaVersion)-Full\bin\java.exe"
```

## 使用方法

非常简易的命令行调用方法，更换参数即可实现加载器（包括版本）修改，Minecraft 版本修改以及 Java 版本修改

示例：

```powershell
pwsh .\Start-ForgeServer.ps1 -Version 1.20.1 -Loader Forge -LoaderVersion 47.4.13 -JavaVersion 21 -ImmediatelyExit
```

```powershell
pwsh .\Start-FabricServer.ps1 -Version 1.21.1 -LoaderVersion 0.18.3 -JavaVersion 21 -ImmediatelyExit
```

Forge 与 Fabric 都必须指定 Minecraft 版本与加载器版本，Forge 端还必须指定使用 Forge 或者 NeoForge 加载器

Java 版本如果不指定，默认为 21

已实现根据参数自动检测/下载/安装加载器，并支持终端内无缝同意 EULA，支持通过添加 -ImmediatelyExit 参数实现服务端关闭后立即退出脚本

Forge/NeoForge 端检测 Minecraft 与加载器版本依靠 win_args.txt 所在路径内容，启动前会检查是否存在 user_jvm_args.txt

Fabric 端检测 Minecraft 版本依靠解析 server.jar 中的 version.json 内容，检测加载器版本依靠 fabric-loader-xxx.jar 文件名，启动前会检查是否存在 fabric-server-launcher.jar 与 server.jar

从 26.1-snapshot-1 开始，Fabric 端默认直接使用未混淆版本，没有了 intermediary-xxx.jar，无法通过文件名判断 Minecraft 版本，因此需要通过解析 server.jar 来获取 Minecraft 版本

### 待办（大概会忘）

- [x] Fabric 检测机制有问题，需要完善
- [x] 通过参数指定服务器关闭后的行为（等待任意键或直接退出）
- [ ] 支持 1.16.5 以及更早版本的 Forge 服务端启动（目前只能下载并安装，检测逻辑与启动命令待完善）
- [ ] 控制台输出内容调整（以及中文支持）
- [ ] server.properties 预修改/覆盖修改
- [ ] 以某种方式指定 java 参数

## 致谢

### 部分功能灵感来自 ATM9 与 ATM10 的服务端启动脚本 startserver.bat

- [![All the Mods 9](http://cf.way2muchnoise.eu/715572.svg "ATM9") All The Mods 9 - ATM9](https://www.curseforge.com/minecraft/modpacks/all-the-mods-9)
- [![All the Mods 10](http://cf.way2muchnoise.eu/925200.svg "ATM10") All The Mods 10 - ATM10](https://www.curseforge.com/minecraft/modpacks/all-the-mods-10)

### Fabric 端解析 server.jar 逻辑由 Microsfot Copilot 生成
