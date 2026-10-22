# Ceedling 本机部署与使用说明

记录日期：2026-10-22。

## 本次交付及验证状态

- 原始目录：`D:\vmware_share\AI工具\Ceedling`，直接克隆官方仓库，没有使用隔离 worktree。
- 来源：<https://github.com/ThrowTheSwitch/Ceedling>
- 分支：`master`；本次提交：`6feaf94e40e2c802af43035a081ea3cb1bd6dfc4`。
- `git describe`：`v1.2.0-4-g6feaf94e`。这是源码快照；`lib/version.rb` 将本地构建标记为 `1.2.0.dev`，不应把它当作发布版 1.2.0。
- Unity、CMock、CException 及嵌套子模块已随 `--recurse-submodules` 克隆。
- 当前 PowerShell 的 PATH 中未发现 `ruby`、`gem`、`gcc`、`ceedling`；这不排除机器其他目录存在未配置的安装。
- **已完成源码获取；未安装运行依赖，未运行 C 单元测试，不能视为可运行环境验收通过。**
- Ceedling 是 Ruby 实现的命令行构建/测试工具，本仓库不是 MCP 服务。本次无需注册 MCP，也没有改动 Codex 全局配置。

## Notion 中的要求

依据以下两篇笔记：

- [STM32 + Codex 实机开发自动化配置清单](https://app.notion.com/p/4000dad50a8f81ffb139c2aa1810e303)
- [STM32 嵌入式开发 AI 工具方案｜Codex、Keil 与 MCP](https://app.notion.com/p/4000dad50a8f81adb120e9ac5c4736e0)

目标是建立独立的宿主机测试工程，先测试 CRC、Modbus、协议解析、环形队列、状态机。硬件依赖通过接口隔离或 CMock 替换。Ceedling 组织编译和测试，Unity 提供 C 断言，CMock 根据头文件生成替身。

宿主机测试通过只证明所测逻辑通过；Keil 固件编译、MCU 上运行、时序与外设验证仍需分别执行。

## Windows 安装流程（尚未在本机执行）

### 1. 安装 Ruby 和宿主机 GCC

从 [RubyInstaller 官方下载页](https://rubyinstaller.org/downloads/) 选择适合本机架构的 **Ruby+Devkit 3.x**。Ceedling 源码要求 Ruby >= 3.0；官方 README 对 Ruby 4 仅声明非正式支持，因此这里选择 3.x。

安装时启用 Ruby 命令的 PATH 配置，完成 Devkit/MSYS2 安装；若 Devkit 未完成，在 Ruby 命令提示符执行 `ridk install`，按提示安装开发工具链。重新打开终端后执行：

```powershell
ruby --version
gem --version
ridk enable
gcc --version
```

`ridk enable` 为当前终端启用 MSYS2 工具环境。每个新终端都应先验证 GCC 可见。此处需要生成 Windows 宿主机可执行程序的 GCC，不能用 Keil ARM 编译器或 `arm-none-eabi-gcc` 代替。

### 2. 安装发布版 Ceedling（通常使用这条路径）

源码 clone 与命令行安装是两件事。使用者通常安装发布版 gem，无需先构建本仓库。

```powershell
gem install ceedling --version 1.2.0 --no-document
ceedling version
```

1.2.0 是本次核对的官方发布版本；在其他日期部署时先核对官方 release，团队项目应记录并固定实际使用版本。gem 会安装运行依赖及测试框架。

### 3. 可选：使用本次克隆的源码

只在需要开发/验证 Ceedling 本身时使用；普通业务模块测试优先用发布版。

```powershell
Set-Location 'D:\vmware_share\AI工具\Ceedling'
git submodule update --init --recursive
gem build ceedling.gemspec
gem install .\ceedling-1.2.0.dev.gem --no-document
ceedling _1.2.0.dev_ version
```

这里不要加 `--local`：若依赖尚未安装，需要允许 RubyGems 获取依赖。开发版和发布版并存时，用 RubyGems 的 `_版本_` 语法明确选择，不要假设默认命令一定用了这个源码版本。若后续源码版本变化，以构建输出的 gem 文件名为准。

## 第一个测试工程

安装依赖后，可在当前仓库的 `local-tests` 子目录创建练习工程。不要直接把 Ceedling 工具源码根目录当成 STM32 的测试项目。

```powershell
Set-Location 'D:\vmware_share\AI工具\Ceedling'
ceedling new local-tests --gitsupport
Set-Location .\local-tests
```

在生成的工程中创建 `src/crc16.h`：

```c
#ifndef CRC16_H
#define CRC16_H
#include <stddef.h>
#include <stdint.h>
uint16_t crc16_modbus(const uint8_t *data, size_t length);
#endif
```

创建 `src/crc16.c`：

```c
#include "crc16.h"

uint16_t crc16_modbus(const uint8_t *data, size_t length)
{
    uint16_t crc = 0xFFFFu;
    for (size_t i = 0; i < length; ++i)
    {
        crc ^= data[i];
        for (unsigned bit = 0; bit < 8; ++bit)
        {
            crc = (crc & 1u) ? (uint16_t)((crc >> 1) ^ 0xA001u)
                             : (uint16_t)(crc >> 1);
        }
    }
    return crc;
}
```

创建 `test/test_crc16.c`：

```c
#include "unity.h"
#include "crc16.h"

void setUp(void) {}
void tearDown(void) {}

void test_crc16_known_vector(void)
{
    const uint8_t input[] = "123456789";
    TEST_ASSERT_EQUAL_HEX16(0x4B37u, crc16_modbus(input, sizeof(input) - 1u));
}

void test_crc16_empty_input_preserves_initial_value(void)
{
    TEST_ASSERT_EQUAL_HEX16(0xFFFFu, crc16_modbus(NULL, 0u));
}
```

执行：

```powershell
ceedling test:all
ceedling test:crc16
```

预期两个测试通过。上述代码是部署示例，本次没有在 Ceedling 中执行。验收时把 `0x4B37u` 临时改为 `0x0000u`，确认测试失败且进程返回非零，再恢复并确认通过。这能验证 AI/CI 不会漏掉失败状态。

## 接入真实 STM32 工程

1. 在用户指定的原始工程中增加独立的 `unit_tests` 项目，保留已有修改。
2. 调整该项目的 `project.yml`：`:paths` 下的 `:source` 指向实际待测源码，`:include` 指向实际头文件，`:test` 指向测试目录。路径相对于测试工程；优先测试真实源码，避免复制后不同步。
3. 不要直接加入 MCU 启动代码、寄存器操作、`main.c`、完整 HAL/RTOS。先把纯逻辑与硬件接口分开，按需配置宏和头文件。
4. CMock 常见模式：业务模块依赖 `transport.h`，测试包含 `mock_transport.h`，通过生成的 `transport_send_Expect...` 设置期望。函数签名、期望函数名必须以实际头文件及生成结果为准。
5. 新增正常路径、边界、长度不足、CRC 错误、超时/状态切换测试，然后运行单个测试和全部回归。
6. 宿主机通过后再执行 Keil 编译；只有得到用户相应授权后，才使用已有调试/串口 MCP 做烧录和板级验证。

覆盖率是后续配置项：需要额外配置 GCC/gcov、gcovr 和 Ceedling gcov 插件，本次未部署。

## 排错及交接

- 找不到命令：先定位安装目录、重新打开终端、检查 PATH；用 `ridk enable` 启用 GCC。
- `require`/gem 缺失：确认 Ruby 与 gem 来自同一安装，并检查 `gem list`；不要把源码 clone 成功当成安装成功。
- 链接失败：检查依赖源文件、Mock、宏、库配置，不能用空实现掩盖业务错误。
- 找不到测试：确认执行目录有 `project.yml`，并检查测试前缀与 `:paths`。
- 中文路径问题：保存完整错误，先用独立的英文路径临时测试项目定位；不能直接移动或删除用户原工程。
- 网络失败：本次沙箱内 Git 访问失败，使用获准的沙箱外联网克隆成功；未修改用户全局代理配置。其他机器应检查自身网络，不要照搬代理设置。

交接给其他 AI 时，同时提供本文件和 [AI_USAGE.md](AI_USAGE.md)。先执行 `tools-local/check-environment.ps1`，再依据检测结果行动；它只检查，不安装软件。

官方参考：[Ceedling README](https://github.com/ThrowTheSwitch/Ceedling)、[Ceedling 文档](https://docs.throwtheswitch.org/Ceedling/)、本地 `docs/mkdocs/getting-started/command-line.md`、`ceedling.gemspec`。
