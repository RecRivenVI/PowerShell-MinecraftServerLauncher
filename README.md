# 专用于Minecraft模组服务端启动脚本
## 使用Powershell编写
### 因为目前还是我个人使用，所以内置了代理和硬编码Java路径
### 使用前（大概率）需要修改以下部分：
```powershell
#代理
$env:HTTP_PROXY = "http://127.0.0.1:7897"
$env:HTTPS_PROXY = "http://127.0.0.1:7897"

#Java绝对路径
$JavaPath = "C:\Program Files\BellSoft\LibericaJDK-$($Minecraft.JavaVersion)-Full\bin\java.exe"
```

## 使用方法
使用方法见startserver.ps1

非常简易的命令行调用方法，更换参数即可实现加载器（包括版本）修改，MC版本修改以及Java版本修改

针对Forge/NeoForge的服务端安装设计的检测方式：

检测是否存在对应的win_args.txt

检测是否存在user_jvm_args.txt

Fabric端检测机制还不够完善，目前只能一次性使用

### 待办（大概会忘）
- [ ] Fabric 检测机制有问题，需要完善
- [ ] server.properties 预修改/覆盖修改