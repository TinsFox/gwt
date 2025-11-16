#!/bin/bash

# Git Worktree CLI 安装脚本
# 支持多平台安装

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 项目信息
PROJECT_NAME="gwt"
GITHUB_REPO="tinsfox/gwt"
VERSION="0.1.1"
INSTALL_DIR="/usr/local/bin"

# 帮助信息
show_help() {
    echo -e "${CYAN}Git Worktree CLI 安装脚本${RESET}"
    echo -e "${BLUE}========================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${GREEN}选项:${RESET}"
    echo "  -v, --version <版本>    指定安装版本 (默认: latest)"
    echo "  -d, --dir <目录>       安装目录 (默认: /usr/local/bin)"
    echo "  -u, --uninstall        卸载程序"
    echo "  -h, --help             显示帮助信息"
    echo ""
    echo -e "${GREEN}示例:${RESET}"
    echo "  $0                     # 安装最新版本"
    echo "  $0 -v 0.1.0           # 安装指定版本"
    echo "  $0 -d ~/bin           # 安装到指定目录"
    echo "  $0 --uninstall        # 卸载程序"
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否有管理员权限
check_permission() {
    if [ "$INSTALL_DIR" = "/usr/local/bin" ] || [ "$INSTALL_DIR" = "/usr/bin" ]; then
        if [ "$EUID" -ne 0 ]; then
            log_error "需要管理员权限才能安装到 $INSTALL_DIR"
            log_info "请使用 sudo 运行脚本"
            exit 1
        fi
    fi
}

# 检测操作系统和架构
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
        linux*)
            PLATFORM="linux"
            ;;
        darwin*)
            PLATFORM="darwin"
            ;;
        mingw*|cygwin*|msys*)
            PLATFORM="windows"
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armhf)
            ARCH="arm"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    PLATFORM_NAME="${PLATFORM}-${ARCH}"
    if [ "$PLATFORM" = "windows" ]; then
        BINARY_NAME="${PROJECT_NAME}.exe"
    else
        BINARY_NAME="${PROJECT_NAME}"
    fi
    
    log_info "检测到平台: $PLATFORM_NAME"
}

# 下载二进制文件
download_binary() {
    local version=$1
    local download_url
    
    if [ "$version" = "latest" ]; then
        download_url="https://github.com/${GITHUB_REPO}/releases/latest/download/${BINARY_NAME}-${PLATFORM_NAME}"
    else
        download_url="https://github.com/${GITHUB_REPO}/releases/download/${version}/${BINARY_NAME}-${PLATFORM_NAME}"
    fi
    
    log_info "下载地址: $download_url"
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    # 下载文件
    log_info "正在下载..."
    if command_exists curl; then
        curl -fsSL "$download_url" -o "$TEMP_DIR/$BINARY_NAME"
    elif command_exists wget; then
        wget -q "$download_url" -O "$TEMP_DIR/$BINARY_NAME"
    else
        log_error "需要 curl 或 wget 来下载文件"
        exit 1
    fi
    
    # 检查下载是否成功
    if [ ! -f "$TEMP_DIR/$BINARY_NAME" ]; then
        log_error "下载失败"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x "$TEMP_DIR/$BINARY_NAME"
    
    DOWNLOADED_FILE="$TEMP_DIR/$BINARY_NAME"
    log_success "下载完成"
}

# 验证二进制文件
verify_binary() {
    log_info "验证二进制文件..."
    
    # 检查文件格式
    if ! file "$DOWNLOADED_FILE" | grep -q "executable"; then
        log_error "下载的文件不是可执行文件"
        exit 1
    fi
    
    # 测试运行
    if ! "$DOWNLOADED_FILE" --version >/dev/null 2>&1; then
        log_error "二进制文件验证失败"
        exit 1
    fi
    
    log_success "二进制文件验证通过"
}

# 安装二进制文件
install_binary() {
    log_info "安装到 $INSTALL_DIR..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 复制文件
    cp "$DOWNLOADED_FILE" "$INSTALL_DIR/$PROJECT_NAME"
    
    # 确保有执行权限
    chmod +x "$INSTALL_DIR/$PROJECT_NAME"
    
    log_success "安装完成"
}

# 卸载程序
uninstall_program() {
    log_info "卸载 $PROJECT_NAME..."
    
    if [ -f "$INSTALL_DIR/$PROJECT_NAME" ]; then
        rm -f "$INSTALL_DIR/$PROJECT_NAME"
        log_success "卸载完成"
    else
        log_warning "$PROJECT_NAME 未安装"
    fi
}

# 尝试写入补全文件到第一个可写目录
write_completion() {
    local shell_name="$1"
    local file_name="$2"
    shift 2
    local dirs=("$@")

    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            if "$INSTALL_DIR/$PROJECT_NAME" completion "$shell_name" > "$dir/$file_name" 2>/dev/null; then
                log_info "${shell_name} 补全已安装到 $dir/$file_name"
                return 0
            fi
        fi
    done

    log_warning "未能安装 ${shell_name} 补全（无可写目录）"
    return 1
}

# 配置 shell 补全
setup_completion() {
    log_info "设置 shell 自动补全..."

    if [ ! -x "$INSTALL_DIR/$PROJECT_NAME" ]; then
        log_warning "未找到可执行的 $PROJECT_NAME，跳过补全安装"
        return
    }

    # Bash
    write_completion "bash" "$PROJECT_NAME" \
        "/etc/bash_completion.d" \
        "/usr/local/etc/bash_completion.d" \
        "$HOME/.local/share/bash-completion/completions" \
        "$HOME/.config/bash-completion/completions"

    # Zsh
    write_completion "zsh" "_$PROJECT_NAME" \
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" \
        "/usr/local/share/zsh/site-functions" \
        "${ZDOTDIR:-$HOME}/.zsh/completions"

    # Fish
    write_completion "fish" "$PROJECT_NAME.fish" \
        "/usr/share/fish/vendor_completions.d" \
        "/usr/local/share/fish/vendor_completions.d" \
        "$HOME/.config/fish/completions"
}

# 显示安装结果
show_install_result() {
    log_success "安装成功！"
    echo ""
    echo -e "${CYAN}使用说明:${RESET}"
    echo "  运行: $PROJECT_NAME --help"
    echo "  查看版本: $PROJECT_NAME --version"
    echo ""
    echo -e "${CYAN}快速开始:${RESET}"
    echo "  $PROJECT_NAME list          # 查看 worktree 列表"
    echo "  $PROJECT_NAME create <分支>  # 创建新 worktree"
    echo "  $PROJECT_NAME edit <分支>    # 用编辑器打开 worktree"
    echo ""
    
    # 检查是否在 PATH 中
    if command_exists "$PROJECT_NAME"; then
        log_success "$PROJECT_NAME 已在 PATH 中"
    else
        log_warning "$PROJECT_NAME 可能不在您的 PATH 中"
        log_info "请将 $INSTALL_DIR 添加到 PATH"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
}

# 主安装函数
install_program() {
    log_info "开始安装 $PROJECT_NAME $VERSION..."
    
    check_permission
    detect_platform
    download_binary "$VERSION"
    verify_binary
    install_binary
    setup_completion
    show_install_result
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -u|--uninstall)
            uninstall_program
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 主程序
main() {
    # 检查依赖
    if ! command_exists file; then
        log_warning "file 命令未找到，跳过文件类型检查"
    fi
    
    # 执行安装
    install_program
}

# 运行主程序
main "$@"
