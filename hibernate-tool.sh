#!/bin/bash
# Linux Mint 22.3 专业休眠配置工具 v2.0
# 功能：菜单化操作 | 模块化执行 | 结果验证 | 状态检查
set -euo pipefail

# ==========================================
# 全局变量与颜色定义
# ==========================================
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"
BACKUP_DIR="/var/tmp/hibernate-tool-backup"
GRUB_FILE="/etc/default/grub"
RESUME_CONF="/etc/initramfs-tools/conf.d/resume"

# ==========================================
# 工具函数：结果验证与输出
# ==========================================
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[成功]${NC} $1"
        return 0
    else
        echo -e "${RED}[失败]${NC} $1"
        return 1
    fi
}

print_banner() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "  Linux Mint 22.3 休眠配置工具 v2.0"
    echo "=============================================="
    echo -e "${NC}"
}

# ==========================================
# 功能模块 1：系统状态检查
# ==========================================
check_system_status() {
    echo -e "\n${YELLOW}[系统状态检查]${NC}"
    echo "----------------------------------------"
    
    # 内存信息
    MEM_TOTAL=$(free -g | awk '/Mem:/{print $2}')
    echo -e "物理内存：${BLUE}${MEM_TOTAL}GB${NC}"
    
    # Swap信息
    SWAP_TOTAL=$(free -g | awk '/Swap:/{print $2}')
    SWAP_PATH=$(swapon --show=NAME --noheadings | head -n1 || echo "未启用")
    if [ "$SWAP_TOTAL" -eq 0 ]; then
        echo -e "Swap状态：${RED}未启用${NC}"
    else
        echo -e "Swap状态：${GREEN}已启用${NC} (${SWAP_TOTAL}GB) - ${SWAP_PATH}"
    fi
    
    # GRUB配置检查
    if grep -q "resume=UUID=" $GRUB_FILE; then
        echo -e "GRUB配置：${GREEN}已配置${NC}"
    else
        echo -e "GRUB配置：${YELLOW}未配置${NC}"
    fi
    
    # initramfs配置检查
    if [ -f "$RESUME_CONF" ]; then
        echo -e "initramfs：${GREEN}已配置${NC}"
    else
        echo -e "initramfs：${YELLOW}未配置${NC}"
    fi
    echo "----------------------------------------"
}

# ==========================================
# 功能模块 2：创建/扩容 Swap
# ==========================================
setup_swap() {
    echo -e "\n${YELLOW}[Swap 配置]${NC}"
    mkdir -p $BACKUP_DIR
    
    # 获取内存大小并计算推荐Swap
    MEM_TOTAL=$(free -g | awk '/Mem:/{print $2}')
    SWAP_RECOMMEND=$((MEM_TOTAL + 2))
    CURRENT_SWAP=$(free -g | awk '/Swap:/{print $2}')
    
    echo "当前内存：${MEM_TOTAL}GB | 推荐Swap：${SWAP_RECOMMEND}GB"
    
    if [ "$CURRENT_SWAP" -ge "$MEM_TOTAL" ]; then
        echo -e "${GREEN}Swap空间充足，无需创建${NC}"
        return 0
    fi
    
    read -p "是否创建 ${SWAP_RECOMMEND}GB Swap文件？(y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "已取消操作"
        return 0
    fi
    
    # 执行Swap创建
    echo "正在关闭旧Swap（如有）..."
    swapoff /swapfile 2>/dev/null || true
    
    echo "正在创建 ${SWAP_RECOMMEND}GB Swap文件..."
    fallocate -l "${SWAP_RECOMMEND}G" /swapfile
    check_success "创建Swap文件" || return 1
    
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    check_success "格式化Swap" || return 1
    
    swapon /swapfile
    check_success "启用Swap" || return 1
    
    # 备份并更新fstab
    cp /etc/fstab $BACKUP_DIR/fstab.bak
    grep -qxF '/swapfile none swap sw 0 0' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
    check_success "写入fstab（永久生效）"
    
    echo -e "${GREEN}Swap配置完成！${NC}"
}

# ==========================================
# 功能模块 3：配置 GRUB 与 initramfs
# ==========================================
configure_boot() {
    echo -e "\n${YELLOW}[引导配置]${NC}"
    mkdir -p $BACKUP_DIR
    
    # 获取Swap UUID
    SWAP_PATH=$(swapon --show=NAME --noheadings | head -n1)
    if [ -z "$SWAP_PATH" ]; then
        echo -e "${RED}错误：未检测到启用的Swap，请先运行模块2${NC}"
        return 1
    fi
    
    SWAP_UUID=$(blkid -s UUID -o value "$SWAP_PATH")
    if [ -z "$SWAP_UUID" ]; then
        echo -e "${RED}错误：无法获取Swap UUID${NC}"
        return 1
    fi
    echo "检测到Swap UUID：$SWAP_UUID"
    
    # 备份并配置GRUB
    echo "正在配置GRUB..."
    cp $GRUB_FILE $BACKUP_DIR/grub.bak
    sed -i 's/ resume=UUID=[^ ]*//g' $GRUB_FILE
    sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"resume=UUID=$SWAP_UUID /" $GRUB_FILE
    check_success "修改GRUB配置" || return 1
    
    update-grub >/dev/null 2>&1
    check_success "更新GRUB引导" || return 1
    
    # 配置initramfs
    echo "正在配置initramfs..."
    echo "RESUME=UUID=$SWAP_UUID" > $RESUME_CONF
    check_success "创建resume配置" || return 1
    
    update-initramfs -u -k all >/dev/null 2>&1
    check_success "更新initramfs镜像"
    
    echo -e "${GREEN}引导配置完成！${NC}"
}

# ==========================================
# 功能模块 4：一键完整配置（推荐）
# ==========================================
full_setup() {
    echo -e "\n${BLUE}[一键完整配置]${NC}"
    setup_swap || return 1
    configure_boot || return 1
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}  全部配置完成！${NC}"
    echo -e "${YELLOW}  请使用菜单选项5测试休眠${NC}"
    echo -e "${GREEN}=====================================${NC}"
}

# ==========================================
# 功能模块 5：测试休眠
# ==========================================
test_hibernate() {
    echo -e "\n${YELLOW}[休眠测试]${NC}"
    echo "警告：即将进入休眠状态，请保存所有工作！"
    read -p "确认继续？(y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "已取消测试"
        return 0
    fi
    echo "正在进入休眠..."
    systemctl hibernate
}

# ==========================================
# 功能模块 6：卸载休眠配置
# ==========================================
uninstall() {
    echo -e "\n${RED}[卸载配置]${NC}"
    read -p "警告：将移除所有休眠相关配置，确认？(y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "已取消"
        return 0
    fi
    
    mkdir -p $BACKUP_DIR
    echo "正在移除配置..."
    
    # 恢复GRUB
    [ -f $GRUB_FILE ] && cp $GRUB_FILE $BACKUP_DIR/grub.uninstall.bak
    sed -i 's/ resume=UUID=[^ ]*//g' $GRUB_FILE
    update-grub >/dev/null 2>&1
    
    # 删除resume配置
    rm -f $RESUME_CONF
    update-initramfs -u -k all >/dev/null 2>&1
    
    echo -e "${GREEN}配置已移除，Swap文件保留（如需删除请手动操作）${NC}"
}

# ==========================================
# 主菜单
# ==========================================
show_menu() {
    echo -e "\n${BLUE}请选择操作：${NC}"
    echo "1) 查看系统状态（Swap/GRUB/内核）"
    echo "2) 仅创建/扩容 Swap"
    echo "3) 仅配置 GRUB 与 initramfs"
    echo "4) 一键完整配置（推荐新手）"
    echo "5) 测试休眠功能"
    echo "6) 卸载休眠配置"
    echo "0) 退出工具"
    echo ""
}

# ==========================================
# 主程序入口
# ==========================================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[错误] 必须使用 sudo 运行此工具！${NC}"
    echo "用法：sudo bash $0"
    exit 1
fi

print_banner
while true; do
    show_menu
    read -p "请输入选项 [0-6]: " choice
    case $choice in
        1) check_system_status ;;
        2) setup_swap ;;
        3) configure_boot ;;
        4) full_setup ;;
        5) test_hibernate ;;
        6) uninstall ;;
        0) echo -e "${GREEN}再见！${NC}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${NC}" ;;
    esac
done
