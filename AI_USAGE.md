# 给 AI 的 Ceedling 使用入口

## 环境事实

工具源码目录：`D:\vmware_share\AI工具\Ceedling`。
先阅读 `LOCAL_DEPLOYMENT_ZH.md`，其中记录来源、commit、安装步骤和完整示例。
这是 Ceedling CLI 源码，不是 MCP server；不要为它编造 MCP 配置或声称已部署 MCP。
2026-10-22 已完成递归克隆，但当前终端未找到 Ruby、gem、GCC、Ceedling，尚未完成运行验收。后续必须重新检测，不能把此快照当作机器永久状态。

## 操作流程

1. 运行 `& 'D:\vmware_share\AI工具\Ceedling\tools-local\check-environment.ps1'`；记录退出码及输出。非零表示前置条件不齐。
2. 需要安装时依照部署文档，使用官方 RubyInstaller + Devkit 和固定版本的 Ceedling gem。
3. 找到用户实际 STM32 工程，在其原始目录内增量建立/维护独立的宿主机测试项目；不要擅自只改隔离副本。
4. 检查该测试项目的 `project.yml`、源码/include 路径、宏、测试前缀和编译器。不要把 Ceedling 工具仓库与被测业务项目混淆。
5. 在含 `project.yml` 的测试工程目录执行 `ceedling test:all`。单模块示例：`ceedling test:crc16`，实际名称随测试文件而变。
6. 捕获命令退出码、测试数量、失败断言及文件行号。非零是失败；没有测试也不能算验收通过。修改后运行相关测试及必要回归。
7. 报告分别说明：源码修改、宿主机测试、Keil 构建、板级结果。不能用某一层成功代替另一层。

硬件权限：本流程无需访问目标 MCU。不要因为要做单元测试而 halt/reset/write/erase/program，也不要占用 Hub 已连接串口。板级操作遵守用户工程 AGENTS.md 及明确授权。

## 可直接发给 AI 的任务

> 阅读 D:\vmware_share\AI工具\Ceedling\LOCAL_DEPLOYMENT_ZH.md 和 AI_USAGE.md，先检测环境。对我指定的 STM32 原始工程内的 CRC/协议解析模块建立独立 Ceedling 宿主机测试项目，引用真实源码，隔离 HAL，补充正常、边界和错误输入测试。保留已有修改。实际运行测试，报告命令、退出码和通过/失败数量。若依赖缺失，明确列出，不得声称测试通过。未经授权不要操作 MCU。
