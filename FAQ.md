# 常见问题排查 | FAQ
适配：Linux Mint 22.3 休眠配置工具 v2.0
适用：Cinnamon / MATE / Xfce 全桌面环境

---

## 一、基础检测
### 1. 如何快速检查我的配置是否正常？
运行工具选择 **1) 查看系统状态**
正常状态：
- Swap 已启用（容量 ≥ 物理内存）
- GRUB 已配置
- initramfs 已配置

### 2. 查看 Swap 状态命令
```bash
swapon --show
free -h

## 二、配置失败问题
### 1. 脚本提示「未检测到 Swap UUID」
原因：无可用 Swap 分区 / 文件解决：运行工具选择 2) 仅创建 / 扩容 Swap，完成后重试

### 2. GRUB 更新失败 / 引导配置报错
解决：执行以下命令修复后，重新运行脚本
bash
运行
sudo apt update
sudo apt install --reinstall grub2-common
sudo update-grub

### 3. 权限报错：必须使用 sudo 运行
解决：严格使用 root 权限启动
bash
运行
sudo bash hibernate-tool.sh

## 三、休眠功能异常
### 1. 执行休眠无反应 / 立即唤醒
运行工具 1 确认配置全部正常
BIOS 开启 S3 Sleep / 休眠支持
建议关闭 Secure Boot（安全启动）

### 2. 休眠后唤醒黑屏、卡死
核心原因：显卡驱动兼容问题（NVIDIA 常见）解决：
安装系统推荐的官方闭源驱动
驱动安装完成后，重新运行工具 4) 一键完整配置

### 3. 休眠失败，提示内存不足
原因：Swap 容量小于物理内存解决：运行工具 2 自动扩容 Swap

## 四、回滚与卸载
### 1. 如何彻底关闭休眠，恢复系统默认？
运行工具选择 6) 卸载休眠配置
自动清除所有休眠引导参数
保留 Swap 文件（不影响系统性能）

### 2. 配置文件备份位置
脚本自动备份关键系统文件，可手动恢复：
plaintext
/var/tmp/hibernate-tool-backup/

## 五、日志排查（高级用户）
查看休眠失败详细日志，定位问题根源：
bash
运行
journalctl -u systemd-hibernate.service -b

## 六、通用建议
本工具仅修改系统底层配置，与桌面环境无关，全桌面通用
推荐操作流程：检测状态 → 一键配置 → 测试休眠
所有操作均为 Linux 官方标准配置，无安全风险
