#请在外部调用，模板：pwsh .\Start-ForgeServer.ps1 -Version 1.21.1 -Loader NeoForge -LoaderVersion 21.1.216 -JavaVersion 21
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter(Mandatory)]
    [ValidateSet("Forge", "NeoForge")]
    [string]$Loader,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LoaderVersion,

    [ValidateNotNullOrEmpty()]
    [string]$JavaVersion = "21",

    [switch]$ImmediatelyExit
)

$Minecraft = @{
    Version       = $Version
    Loader        = $Loader
    LoaderVersion = $LoaderVersion
    JavaVersion   = $JavaVersion
}

#代理
$env:HTTP_PROXY = "http://127.0.0.1:7897"
$env:HTTPS_PROXY = "http://127.0.0.1:7897"

#Java绝对路径
$JavaPath = "C:\Program Files\BellSoft\LibericaJDK-$($Minecraft.JavaVersion)-Full\bin\java.exe"

#常量
$Loaders = @{
    Forge    = @{
        InstallerUrl  = "https://maven.minecraftforge.net/net/minecraftforge/forge/$($Minecraft.Version)-$($Minecraft.LoaderVersion)/forge-$($Minecraft.Version)-$($Minecraft.LoaderVersion)-installer.jar"
        InstallerPath = "forge-$($Minecraft.Version)-$($Minecraft.LoaderVersion)-installer.jar"
        WinArgsPath   = "libraries/net/minecraftforge/forge/$($Minecraft.Version)-$($Minecraft.LoaderVersion)/win_args.txt"
    }
    NeoForge = @{
        InstallerUrl  = "https://maven.neoforged.net/releases/net/neoforged/neoforge/$($Minecraft.LoaderVersion)/neoforge-$($Minecraft.LoaderVersion)-installer.jar"
        InstallerPath = "neoforge-$($Minecraft.LoaderVersion)-installer.jar"
        WinArgsPath   = "libraries/net/neoforged/neoforge/$($Minecraft.LoaderVersion)/win_args.txt"
    }
}

#常量转换
$InstallerUrl = $Loaders[$Minecraft.Loader].InstallerUrl
$InstallerPath = Join-Path $PSScriptRoot $Loaders[$Minecraft.Loader].InstallerPath
$WinArgsPath = Join-Path $PSScriptRoot $Loaders[$Minecraft.Loader].WinArgsPath
$WinArgs = "@$WinArgsPath"
$UserJvmArgsPath = Join-Path $PSScriptRoot "user_jvm_args.txt"
$UserJvmArgs = "@$UserJvmArgsPath"

$EulaPath = Join-Path $PSScriptRoot "eula.txt"
#安装服务端
function Install-Server {
    if (-not (Test-Path $InstallerPath)) {
        Write-Host "DOWNLOADING SERVER INSTALLER"
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath
    }
    Write-Host "INSTALLING SERVER"
    & $JavaPath -jar $InstallerPath --installServer
}
#启动服务端
function Start-Server {
    Write-Host "STARTING SERVER"
    & $JavaPath $UserJvmArgs $WinArgs nogui
}
#按任意键停止服务端
function Stop-Server {
    if ($ImmediatelyExit) {
        Write-Host "SERVER STOPPED"
        return
    }
    Write-Host "SERVER STOPPED, PRESS ANY KEY TO CONTINUE"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
#测试eula.txt状态
function Test-EulaStatus {
    if (-not (Test-Path $EulaPath)) {
        return $false
    }
    return (Get-Content $EulaPath) -match '^eula=true'
}
#修改eula.txt
function Edit-Eula {
    if (Test-EulaStatus) {
        return $true
    }
    Write-Host "YOU NEED ACCEPT MINECRAFT EULA TO CONTINUE"

    $answer = Read-Host "TYPE TRUE AND PRESS ENTER TO ACCEPT OR ANYTHING TO EXIT"
    if ($answer -eq "true") {
        if (Test-Path $EulaPath) {
            $content = Get-Content $EulaPath
            if ($content -match '^eula=.*') {
                $content = $content -replace '^eula=.*', 'eula=true'
            }
            else {
                $content += 'eula=true'
            }
            Set-Content $EulaPath -Value $content -Encoding UTF8
        }
        else {
            Set-Content $EulaPath -Value 'eula=true' -Encoding UTF8
        }
        Write-Host "EULA ACCEPTED"
        return $true
    }
    return $false
}
#开始运行
if (-not (Test-Path $JavaPath)) {
    Write-Error "JAVA NOT FOUND, STOPPING"
    Stop-Server
    exit 1
}
if (-not (Test-Path $WinArgsPath)) {
    Install-Server
    if (-not (Test-Path $WinArgsPath)) {
        Write-Error "SERVER INSTALL FAILED, STOPPING"
        Stop-Server
        exit 1
    }
}

if (-not (Edit-Eula)) {
    Write-Error "EULA NOT ACCEPTED, STOPPING"
    Stop-Server
    exit 1
}
if (-not (Test-Path $UserJvmArgsPath)) {
    Write-Error "user_jvm_args.txt NOT FOUND, STOPPING"
    Stop-Server
    exit 1
}
Write-Host "RUNNING MINECRAFT $($Minecraft.Version) SERVER WITH $($Minecraft.Loader) $($Minecraft.LoaderVersion), USING JAVA $($Minecraft.JavaVersion)"
Start-Server
Stop-Server
