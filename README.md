[README.md](https://github.com/user-attachments/files/26897311/README.md)
# Linux Mint 22.3 休眠功能一键配置工具
适用于 **Linux Mint 22.3 所有桌面环境**（Cinnamon 6.6.7 / MATE / Xfce），支持最新官方内核，**菜单式交互、自动检测、结果验证、安全备份**

## ✨ 工具特性
- 全桌面环境通用（与桌面无关，仅配置系统底层）
- 菜单式选择，无需记命令
- 自动检测内存/Swap/引导状态
- 每步操作带 **成功/失败** 校验
- 自动备份关键配置，安全无风险
- 支持一键配置 / 单独配置 / 卸载回滚

## 🔧 支持系统
- Linux Mint 22.3（Cinnamon / MATE / Xfce）
- 基于 Ubuntu 24.04 的衍生系统
- 所有官方内核版本

## 📦 快速使用
### 1. 克隆项目
```bash
git clone https://github.com/PGonly/linuxmint-22.3-hibernate.git
cd linuxmint-22.3-hibernate
```

### 2. 赋予执行权限
```bash
chmod +x hibernate-tool.sh
```

### 3. 运行工具（必须 root）
```bash
sudo bash hibernate-tool.sh
```

## 📖 菜单功能说明
运行后将出现交互式菜单，按需选择：
```plaintext
1) 查看系统状态（Swap/GRUB/引导配置）—— 只读，安全无修改
2) 仅创建/扩容 Swap 文件
3) 仅配置 GRUB + initramfs 引导
4) 一键完整配置（推荐新手，全自动）
5) 测试休眠功能
6) 卸载休眠配置（安全回滚）
0) 退出工具
```

## ✅ 推荐操作流程（最安全）
1. 选 1 查看当前系统状态
2. 选 4 执行一键完整配置
3. 选 5 测试休眠功能
4. 正常唤醒 = 配置成功

## 🧪 测试休眠命令
也可直接命令行测试：
```bash
sudo systemctl hibernate
```

## 🛑 卸载 / 回滚（恢复原样）
如需关闭休眠，运行工具选择：
```plaintext
6) 卸载休眠配置
```
自动清除所有休眠参数，恢复系统原始状态（Swap 文件保留）

## 📋 项目文件
- `hibernate-tool.sh` 主程序（菜单式休眠配置工具）
- `README.md` 使用说明
- `FAQ.md` 常见问题与故障排查

## 🔒 安全说明
- 所有修改均为 Linux 官方标准配置
- 自动备份配置文件，支持无损回滚
- 不修改驱动、不替换内核、不破坏系统
- 兼容 BIOS/UEFI、Secure Boot

## 📄 开源协议
MIT License
