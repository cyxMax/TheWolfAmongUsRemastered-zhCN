# 《我们之中的狼：重制版》简体中文汉化

版本：2.0.1  
目标游戏：Steam AppID 3884860（The Wolf Among Us Remastered）  
已验证资源版本：`PCS.18.3.7585`

> GitHub 仓库仅用于展示说明、校验脚本与发布信息。完整汉化归档和可直接使用的 ZIP
> 请从本仓库的 Releases 页面下载；克隆源码仓库不能替代完整发布包。

## 特点

- 汉化 90 个语言库，共 26,298 条可见文本。
- 补齐 166 个动作/选择提示，共 265 处，例如挥拳、威胁、调查、抱起物品等。
- 补齐“玩家选择”结算页，共 103 条问题、比例统计与结局说明。
- 统一角色名、地名和关键术语；保留原版标点、占位符、语音标记与排版指令。
- 为 38 个字体槽位提供统一的 Unicode 中文字体回退，完整覆盖译文字形。
- 不含任何 EXE、安装器、联网下载或后台进程。
- 安装前验证原版归档哈希；安装时完整备份；卸载时恢复并再次校验哈希。

## 包内文件

- `install.ps1`：安装与自动回滚脚本。
- `uninstall.ps1`：卸载并恢复原版归档。
- `verify.ps1`：检查当前是原版、已汉化，还是混合/未知状态。
- `archives/`：8 个已重建的游戏资源归档。
- `manifest.json`：文件哈希、目标版本和安装清单。
- `checksums.sha256`：整个发布包的 SHA-256 清单。

## 安装

1. 完全退出游戏，并退出 Steam 客户端（避免 Steam 锁定归档文件）。
2. 在本目录打开 PowerShell。
3. 先做只读预检：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
```

4. 预检通过后安装：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

脚本会自动查找游戏安装目录。如果自动查找失败，可显式指定：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -GamePath "D:\game\steamapps\common\The Wolf Among Us Remastered"
```

安装后正常从 Steam 启动。游戏语言选项仍选英文即可，汉化直接替换英文文本资源。

## 卸载

先退出游戏，再运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

原版备份位于游戏根目录 `.wolf_zhcn_backup`。确认恢复成功后可手动删除；也可运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveBackup
```

## 安全设计

- 安装器只接受与 `manifest.json` 完全匹配的原版归档。Steam 更新后会自动拒绝安装。
- 先验证发布包哈希，再验证游戏原文件哈希，之后才创建备份。
- 备份和替换文件都会再次计算 SHA-256。
- 任一替换步骤失败时，安装器会尝试把所有已修改归档恢复为原版。
- 不关闭、绕过或修改安全软件。
- 不上传文件，不连接网络，不需要游戏账号密码。

可用 `verify.ps1` 随时检查：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\verify.ps1
```

## 已知限制

- 原版没有中文语音，本补丁只汉化文本。
- 中文使用位图字形，不同字号下字形会比原版拉丁字体略粗或略小。
- 为保证所有菜单、设置和剧情都走 Unicode 解码，部分界面会统一使用较中性的中文字体，原版特殊装饰字形可能有所不同。
- 少数仅用于演出的方括号表演说明不会显示，也保留原文；所有玩家可见的动作提示均已处理。
- 制作人员姓名、网址、商标和少量专有缩写按行业惯例保留拉丁形式。
- 中文换行由游戏 UI 自动完成；当前已实机检查启动页、主菜单、详细音频/画面设置、第一章剧情和“玩家选择”结算页。
- 未使用旧版第三方汉化安装器，也未采用任何来源不明二进制。

## 反馈时请附

- 出现问题的章节、场景、菜单位置和截图。
- `verify.ps1` 的输出。
- `manifest.json` 中的版本号。

请仅在本人合法拥有的游戏副本上使用，不要公开再分发其中包含的游戏资源。
