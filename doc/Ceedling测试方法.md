# Ceedling 测试方法（Windows PowerShell）

记录日期：2026-10-22。

## 已验证的结果

用户在本机运行官方 `temp_sensor` 示例，截图显示：

```text
OVERALL TEST SUMMARY
TESTED:  86
PASSED:  86
FAILED:  0
IGNORED: 0

Ceedling operations completed in 19.76 seconds
```

该结果表明本机已能完成示例的编译和测试运行；不代表实际 STM32 固件已通过测试。本记录依据用户提供的运行截图，没有重新执行测试。

## 1. 打开 PowerShell，启用工具环境

本机 Ruby 安装目录是 `C:\Ruby40-x64`，GCC 位于其 MSYS2 的 `ucrt64\bin`。新开终端后，如果找不到命令，执行：

```powershell
$env:Path = "C:\Ruby40-x64\bin;C:\Ruby40-x64\msys64\ucrt64\bin;$env:Path"

ruby --version
gem --version
gcc --version
ceedling version
```

PATH 设置仅对当前 PowerShell 窗口有效。其他机器应替换为自己的实际安装目录。

如果尚未安装 Ceedling：

```powershell
gem install ceedling --version 1.2.0 --no-document
```

## 2. 检查环境

```powershell
Set-Location 'D:\vmware_share\AI工具\Ceedling'
.\tools-local\check-environment.ps1
```

如果提示禁止运行脚本，在当前窗口执行下面的命令，再重新运行检查脚本：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

所有命令应显示 `FOUND`。该脚本只检查命令可用性，实际编译和运行还需执行下面的测试。

## 3. 创建官方示例（只需一次）

```powershell
Set-Location 'D:\vmware_share\AI工具\Ceedling'
ceedling example temp_sensor local-temp-sensor
```

此命令创建的测试项目位于：

```text
D:\vmware_share\AI工具\Ceedling\local-temp-sensor\temp_sensor
```

注意有两层目录：`local-temp-sensor\temp_sensor`。`project.yml` 在最里面一层。当前机器已经创建过示例，直接进入下一步，不要重复创建或覆盖。

## 4. 运行全部测试

```powershell
Set-Location 'D:\vmware_share\AI工具\Ceedling\local-temp-sensor\temp_sensor'
Test-Path .\project.yml
ceedling test:all
$LASTEXITCODE
```

`Test-Path` 应返回 `True`。测试完成后立即检查 `$LASTEXITCODE`，返回 `0` 表示本次命令成功。

同时检查测试汇总：确实运行了测试，`FAILED` 为 `0`，并关注是否有 `IGNORED`。本次官方示例的已知结果为 86 个测试全部通过，0 个忽略；以后修改测试后，数量和耗时可能改变。

## 5. 日常重复测试

示例创建完成后，每次只需启用当前终端的工具路径，进入正确目录，再运行测试：

```powershell
$env:Path = "C:\Ruby40-x64\bin;C:\Ruby40-x64\msys64\ucrt64\bin;$env:Path"
Set-Location 'D:\vmware_share\AI工具\Ceedling\local-temp-sensor\temp_sensor'
ceedling test:all
$LASTEXITCODE
```

修改业务代码或测试后，重新执行上述测试。测试失败时，查看输出中的测试文件、行号、期望值和实际值，修复后再次运行。

## 常见问题

### 找不到 gcc

先执行第 1 步的 PATH 设置。若下面的路径也不存在，才需要检查 Devkit 安装：

```powershell
Test-Path 'C:\Ruby40-x64\msys64\ucrt64\bin\gcc.exe'
```

如果确认开发工具链未安装，执行 `ridk install` 并选择 `3`；完成后重新启用工具环境。

### 找不到 project.yml

错误示例：

```text
No project filepath provided and neither default ./project.yml nor ./ceedling.yml found
```

原因是当前目录不对。使用第 4 步的完整路径进入 `local-temp-sensor\temp_sensor`，再运行测试。

### 环境检查通过，但测试失败

`FOUND` 只说明命令可见，不能代替实际测试。保留完整错误输出，区分编译错误、链接错误和测试断言失败。

## 用于真实 STM32 工程

官方示例用于验证工具链。实际项目应建立独立的宿主机测试项目，引用实际 CRC、协议解析、环形队列、状态机等源码，并隔离或 Mock HAL/外设依赖。

宿主机单元测试、Keil 固件编译和板级测试是不同验证层。运行这里的测试无需烧录、复位或暂停 MCU。

其他 AI 可先阅读本文件，再参考仓库根目录的 `LOCAL_DEPLOYMENT_ZH.md` 和 `AI_USAGE.md`。若旧文档中的“尚未验收”快照与本记录不同，以日期、实际检测及本次截图证据区分状态；后续部署仍需重新检测。
