#请在外部调用，模板：pwsh .\Start-FabricServer.ps1 -Version 1.21.1 -LoaderVersion 0.18.3 -JavaVersion 21
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LoaderVersion,

    [ValidateNotNullOrEmpty()]
    [string]$InstallerVersion = "1.1.0",

    [ValidateNotNullOrEmpty()]
    [string]$JavaVersion = "21"
)

$Minecraft = @{
    Version       = $Version
    LoaderVersion = $LoaderVersion
    InstallerVersion = $InstallerVersion
    JavaVersion   = $JavaVersion
}

#代理
$env:HTTP_PROXY = "http://127.0.0.1:7897"
$env:HTTPS_PROXY = "http://127.0.0.1:7897"

#Java绝对路径
$JavaPath = "C:\Program Files\BellSoft\LibericaJDK-$($Minecraft.JavaVersion)-Full\bin\java.exe"

#常量
$Loaders = @{
    Fabric = @{
        InstallerUrl  = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$InstallerVersion/fabric-installer-$InstallerVersion.jar"
        InstallerPath = "fabric-installer-$InstallerVersion.jar"
        LoaderPath = "libraries\net\fabricmc\fabric-loader\$($Minecraft.LoaderVersion)\fabric-loader-$($Minecraft.LoaderVersion).jar"
    }
}

#常量转换
$InstallerUrl = $Loaders.Fabric.InstallerUrl
$InstallerPath = Join-Path $PSScriptRoot $Loaders.Fabric.InstallerPath
$FabricServerJarPath = Join-Path $PSScriptRoot "fabric-server-launch.jar"
$ServerJarPath = Join-Path $PSScriptRoot "server.jar"
$LoaderPath = Join-Path $PSScriptRoot $Loaders.Fabric.LoaderPath

$EulaPath = Join-Path $PSScriptRoot "eula.txt"
#安装服务端
function Install-Server {
    if (-not (Test-Path $InstallerPath)) {
        Write-Host "DOWNLOADING FABRIC INSTALLER"
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath
    }
    Write-Host "INSTALLING FABRIC SERVER"
    & $JavaPath -jar $InstallerPath server -mcversion $Version -loader $LoaderVersion -downloadMinecraft
}
#启动服务端
function Start-Server {
    Write-Host "STARTING SERVER"
    & $JavaPath -Xmx2G -jar $FabricServerJarPath nogui
}
#按任意键停止服务端
function Stop-Server {
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

Add-Type -AssemblyName System.IO.Compression

function Get-MinecraftVersionFromServerJar {
    if (-not (Test-Path $ServerJarPath)) {
        return $false
    }

    $stream = [System.IO.File]::OpenRead($ServerJarPath)
    try {
        $zip = [System.IO.Compression.ZipArchive]::new(
            $stream,
            [System.IO.Compression.ZipArchiveMode]::Read
        )
        try {
            $entry = $zip.GetEntry("version.json")
            if (-not $entry) {
                return $false
            }

            $reader = New-Object System.IO.StreamReader($entry.Open())
            try {
                $json = $reader.ReadToEnd()
            }
            finally {
                $reader.Close()
            }

            $versionInfo = $json | ConvertFrom-Json
            return $versionInfo.id
        }
        finally {
            $zip.Dispose()
        }
    }
    finally {
        $stream.Close()
    }
}

#开始运行
if (-not (Test-Path $JavaPath)) {
    Write-Error "JAVA NOT FOUND, STOPPING"
    Stop-Server
    exit 1
}

$DetectedVersion = Get-MinecraftVersionFromServerJar

if (-not (Test-Path $LoaderPath) -or -not ($Version -eq $DetectedVersion)) {
    Install-Server
    $DetectedVersion = Get-MinecraftVersionFromServerJar
    if (-not (Test-Path $LoaderPath) -or -not ($Version -eq $DetectedVersion)) {
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
if (-not (Test-Path $FabricServerJarPath) -or -not (Test-Path $ServerJarPath)) {
    Write-Error "SERVER JAR NOT FOUND, STOPPING"
    Stop-Server
    exit 1
}
Write-Host "RUNNING MINECRAFT $($Minecraft.Version) SERVER WITH FABRIC $($Minecraft.LoaderVersion), USING JAVA $($Minecraft.JavaVersion)"
Start-Server
Stop-Server
