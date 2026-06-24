#!/bin/sh
# Steam Deck 工具箱 — 一键安装脚本
#
# 使用方法：在桌面模式终端中运行
#   sh install.sh
#
# 功能：
#   1. 检测运行环境（是否为 Steam Deck）
#   2. 检查并安装 Decky Loader（如未安装）
#   3. 下载工具箱插件包
#   4. 安装到 Decky 插件目录
#   5. 提示重启

set -e

# ==================== 常量定义 ====================

# 插件 GitHub 仓库地址
REPO_URL="https://github.com/deveuper/DeveSteamAPP"
# 最新版本下载地址
DOWNLOAD_URL="${REPO_URL}/releases/latest/download/steam-deck-toolbox.zip"
# Decky 插件目录
PLUGIN_DIR="/home/deck/homebrew/plugins/steam-deck-toolbox"
# 临时下载目录
TEMP_DIR="/tmp/steam-deck-toolbox-install"

# ==================== 辅助函数 ====================

# 打印信息
info() {
    echo "[INFO] $1"
}

# 打印成功信息
success() {
    echo "[SUCCESS] $1"
}

# 打印错误信息
error() {
    echo "[ERROR] $1" >&2
}

# 打印警告信息
warn() {
    echo "[WARN] $1"
}

# ==================== 环境检测 ====================

# 检测是否为 Steam Deck
check_environment() {
    info "检测运行环境..."

    # 检查是否为 deck 用户
    if [ "$(whoami)" != "deck" ]; then
        warn "当前用户不是 deck，请确认是否在 Steam Deck 上运行"
        warn "继续安装可能需要手动调整路径"
    fi

    # 检查 /etc/os-release 是否包含 SteamOS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if echo "$NAME" | grep -qi "Steam"; then
            success "检测到 SteamOS: $VERSION_ID"
        else
            warn "未检测到 SteamOS，当前系统: $NAME"
            warn "本工具专为 Steam Deck 设计，在其他设备上可能无法正常工作"
        fi
    else
        warn "无法检测操作系统版本"
    fi

    # 检查网络连接
    info "检查网络连接..."
    if ping -c 1 -W 3 github.com > /dev/null 2>&1; then
        success "网络连接正常"
    else
        error "无法连接 GitHub，请检查网络后重试"
        exit 1
    fi
}

# 检查 Decky Loader 是否已安装
check_decky() {
    info "检查 Decky Loader 安装状态..."
    if systemctl is-active --quiet plugin_loader 2>/dev/null; then
        success "Decky Loader 已安装并运行中"
        return 0
    else
        warn "Decky Loader 未安装"
        return 1
    fi
}

# 安装 Decky Loader
install_decky() {
    info "开始安装 Decky Loader..."
    info "使用官方安装脚本: https://github.com/SteamDeckHomebrew/decky-loader"

    if curl -L https://github.com/SteamDeckHomebrew/decky-loader/releases/latest/download/prerelease.sh | sh; then
        success "Decky Loader 安装成功"
    else
        error "Decky Loader 安装失败，请检查网络连接后重试"
        exit 1
    fi
}

# ==================== 插件安装 ====================

# 下载插件包
download_plugin() {
    info "下载工具箱插件包..."
    mkdir -p "$TEMP_DIR"

    if curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/toolbox.zip"; then
        success "插件包下载完成"
    else
        error "插件包下载失败，请检查网络连接"
        exit 1
    fi
}

# 安装插件
install_plugin() {
    info "安装插件到 Decky 插件目录..."

    # 创建插件目录
    mkdir -p "$(dirname "$PLUGIN_DIR")"

    # 如果已存在旧版本，先删除
    if [ -d "$PLUGIN_DIR" ]; then
        info "检测到旧版本，正在更新..."
        rm -rf "$PLUGIN_DIR"
    fi

    # 解压插件包
    mkdir -p "$PLUGIN_DIR"
    if unzip -o "$TEMP_DIR/toolbox.zip" -d "$PLUGIN_DIR" > /dev/null 2>&1; then
        success "插件安装成功"
    else
        error "插件解压失败"
        exit 1
    fi

    # 清理临时文件
    rm -rf "$TEMP_DIR"
}

# ==================== 主流程 ====================

main() {
    echo "============================================"
    echo "  Steam Deck 工具箱 — 一键安装脚本"
    echo "  版本: v1.0"
    echo "============================================"
    echo ""

    # 1. 环境检测
    check_environment
    echo ""

    # 2. 检查/安装 Decky Loader
    if check_decky; then
        info "跳过 Decky Loader 安装"
    else
        echo ""
        info "Decky Loader 是运行工具箱的前置条件"
        printf "是否现在安装 Decky Loader？(y/n): "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            install_decky
        else
            warn "跳过 Decky 安装。请先手动安装 Decky Loader 后再运行此脚本"
            exit 0
        fi
    fi
    echo ""

    # 3. 下载并安装插件
    download_plugin
    install_plugin
    echo ""

    # 4. 完成
    echo "============================================"
    echo "  ✅ 安装完成！"
    echo "============================================"
    echo ""
    echo "下一步："
    echo "  1. 切回游戏模式"
    echo "  2. 按 ≡ 键打开 Decky 菜单"
    echo "  3. 在插件列表中找到「Steam Deck 工具箱」"
    echo ""
    echo "如果安装后未显示，请重启 Steam Deck。"
    echo ""
}

# 执行主流程
main
