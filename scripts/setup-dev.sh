#!/bin/bash

# Git Worktree CLI 开发环境设置脚本
# 自动安装和配置开发所需的工具和依赖

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 配置
GO_VERSION_MIN="1.21"
PROJECT_NAME="gwt"

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

# 显示帮助信息
show_help() {
    echo -e "${CYAN}Git Worktree CLI 开发环境设置${RESET}"
    echo -e "${BLUE}============================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET} $0 [选项]"
    echo ""
    echo -e "${GREEN}选项:${RESET}"
    echo "  --basic         # 仅安装基础工具"
    echo "  --full          # 安装所有开发工具（默认）"
    echo "  --check         # 检查环境但不安装"
    echo "  --update        # 更新已安装的工具"
    echo "  --uninstall     # 卸载开发工具"
    echo "  -y, --yes       # 自动确认所有提示"
    echo "  -h, --help      # 显示帮助信息"
    echo ""
    echo -e "${GREEN}示例:${RESET}"
    echo "  $0              # 完整安装"
    echo "  $0 --basic      # 基础安装"
    echo "  $0 --check      # 环境检查"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查 Go 版本
check_go_version() {
    if command_exists go; then
        local version=$(go version | awk '{print $3}' | sed 's/go//')
        log_info "检测到 Go 版本: $version"
        
        # 简单的版本比较
        if [[ "$version" < "$GO_VERSION_MIN" ]]; then
            log_warning "Go 版本过低，需要 $GO_VERSION_MIN 或更高版本"
            return 1
        fi
        
        return 0
    else
        log_warning "未检测到 Go"
        return 1
    fi
}

# 检查 Git 版本
check_git_version() {
    if command_exists git; then
        local version=$(git --version | awk '{print $3}')
        log_info "检测到 Git 版本: $version"
        return 0
    else
        log_warning "未检测到 Git"
        return 1
    fi
}

# 检查 Make
check_make() {
    if command_exists make; then
        log_info "检测到 Make"
        return 0
    else
        log_warning "未检测到 Make"
        return 1
    fi
}

# 检查 Docker
check_docker() {
    if command_exists docker; then
        log_info "检测到 Docker"
        return 0
    else
        log_warning "未检测到 Docker"
        return 1
    fi
}

# 环境检查
check_environment() {
    log_info "检查开发环境..."
    
    local missing=()
    
    if ! check_go_version; then
        missing+=("go")
    fi
    
    if ! check_git_version; then
        missing+=("git")
    fi
    
    if ! check_make; then
        missing+=("make")
    fi
    
    if [ ${#missing[@]} -eq 0 ]; then
        log_success "基础环境检查通过"
        return 0
    else
        log_error "缺少基础工具: ${missing[*]}"
        return 1
    fi
}

# 安装 Go
install_go() {
    log_info "安装 Go..."
    
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            log_error "不支持的架构: $arch"
            return 1
            ;;
    esac
    
    local go_version="1.21.5"  # 可以根据需要更新
    local download_url="https://go.dev/dl/go${go_version}.${os}-${arch}.tar.gz"
    
    log_info "下载 Go: $download_url"
    
    # 下载和安装
    if command_exists curl; then
        curl -fsSL "$download_url" -o /tmp/go.tar.gz
    elif command_exists wget; then
        wget -q "$download_url" -O /tmp/go.tar.gz
    else
        log_error "需要 curl 或 wget 来下载 Go"
        return 1
    fi
    
    # 解压到 /usr/local
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    
    # 清理
    rm -f /tmp/go.tar.gz
    
    # 设置环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
    
    log_success "Go 安装完成"
    log_info "请重新加载 shell 配置或重启终端"
}

# 安装开发工具
install_dev_tools() {
    log_info "安装 Go 开发工具..."
    
    # 确保 Go 可用
    if ! check_go_version; then
        log_error "Go 不可用，无法安装开发工具"
        return 1
    fi
    
    # 基础开发工具
    local tools=(
        "golang.org/x/tools/cmd/goimports@latest"
        "golang.org/x/lint/golint@latest"
        "github.com/golang/mock/mockgen@latest"
        "github.com/air-verse/air@latest"
    )
    
    # 高级工具
    local advanced_tools=(
        "github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"
        "github.com/sonatypecommunity/nancy@latest"
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    )
    
    # 安装基础工具
    log_info "安装基础开发工具..."
    for tool in "${tools[@]}"; do
        local tool_name=$(echo "$tool" | cut -d'@' -f1)
        log_info "安装 $tool_name..."
        go install "$tool"
    done
    
    # 询问是否安装高级工具
    if [ "$INSTALL_ADVANCED" = "true" ] || [ "$AUTO_YES" = "true" ]; then
        install_advanced_tools
    else
        echo ""
        read -p "是否安装高级开发工具？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_advanced_tools
        fi
    fi
    
    log_success "开发工具安装完成"
}

# 安装高级工具
install_advanced_tools() {
    log_info "安装高级开发工具..."
    
    local advanced_tools=(
        "github.com/securecodewarrior/gosec/v2/cmd/gosec@latest"
        "github.com/sonatypecommunity/nancy@latest"
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    )
    
    for tool in "${advanced_tools[@]}"; do
        local tool_name=$(echo "$tool" | cut -d'@' -f1)
        log_info "安装 $tool_name..."
        go install "$tool"
    done
}

# 配置开发环境
setup_dev_environment() {
    log_info "配置开发环境..."
    
    # Git 配置
    if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
        log_info "配置 Git 用户信息..."
        read -p "请输入 Git 用户名: " git_name
        read -p "请输入 Git 邮箱: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
    fi
    
    # Go 环境变量
    local go_path=$(go env GOPATH)
    local go_bin="$go_path/bin"
    
    # 检查 PATH
    if [[ ":$PATH:" != *":$go_bin:"* ]]; then
        log_info "添加 Go bin 目录到 PATH..."
        echo "export PATH=\$PATH:$go_bin" >> ~/.bashrc
        echo "export PATH=\$PATH:$go_bin" >> ~/.zshrc
    fi
    
    # 项目初始化
    if [ -f "go.mod" ]; then
        log_info "初始化项目依赖..."
        go mod download
        go mod tidy
    fi
    
    log_success "开发环境配置完成"
}

# 安装可选工具
install_optional_tools() {
    log_info "安装可选工具..."
    
    # Docker（如果可用）
    if command_exists docker; then
        log_info "Docker 已安装，跳过 Docker 安装"
    else
        log_warning "Docker 未安装，可以手动安装以获得更好的开发体验"
    fi
    
    # 编辑器推荐
    log_info "推荐安装以下编辑器之一："
    echo "  - Visual Studio Code (https://code.visualstudio.com/)"
    echo "  - GoLand (https://www.jetbrains.com/go/)"
    echo "  - Vim/Neovim + vim-go 插件"
    
    # 其他工具
    if command_exists brew; then
        log_info "检测到 Homebrew，可以安装以下工具："
        echo "  - hub: GitHub 命令行工具"
        echo "  - gh: GitHub CLI"
        echo "  - direnv: 环境变量管理"
    fi
}

# 完整安装
full_install() {
    log_info "开始完整开发环境安装..."
    
    # 检查基础环境
    if ! check_environment; then
        log_info "需要安装基础工具"
        
        # 安装 Go
        if ! check_go_version; then
            read -p "是否安装 Go？（需要管理员权限）(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_go
            else
                log_error "需要 Go 才能继续"
                exit 1
            fi
        fi
    fi
    
    # 安装开发工具
    install_dev_tools
    
    # 配置环境
    setup_dev_environment
    
    # 安装可选工具
    install_optional_tools
    
    # 验证安装
    verify_installation
    
    log_success "完整安装完成！"
}

# 基础安装
basic_install() {
    log_info "开始基础开发环境安装..."
    
    # 只检查基础环境
    check_environment || exit 1
    
    # 只安装基础工具
    log_info "安装基础开发工具..."
    local basic_tools=(
        "golang.org/x/tools/cmd/goimports@latest"
        "golang.org/x/lint/golint@latest"
    )
    
    for tool in "${basic_tools[@]}"; do
        go install "$tool"
    done
    
    # 基础配置
    setup_dev_environment
    
    log_success "基础安装完成！"
}

# 验证安装
verify_installation() {
    log_info "验证安装结果..."
    
    local failed=0
    
    # 检查工具
    local tools=("go" "git" "make" "goimports" "golint")
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_success "✓ $tool 可用"
        else
            log_error "✗ $tool 不可用"
            failed=1
        fi
    done
    
    # 检查项目构建
    log_info "测试项目构建..."
    if go build -o /tmp/${PROJECT_NAME}-test .; then
        log_success "✓ 项目构建成功"
        rm -f /tmp/${PROJECT_NAME}-test
    else
        log_error "✗ 项目构建失败"
        failed=1
    fi
    
    # 检查测试
    log_info "运行快速测试..."
    if go test ./... > /dev/null 2>&1; then
        log_success "✓ 测试通过"
    else
        log_warning "⚠ 部分测试失败（可能需要完整环境）"
    fi
    
    if [ $failed -eq 0 ]; then
        log_success "安装验证通过！"
    else
        log_error "安装验证失败，请检查上述问题"
        exit 1
    fi
}

# 更新工具
update_tools() {
    log_info "更新开发工具..."
    
    # 更新 Go 工具
    local tools=(
        "golang.org/x/tools/cmd/goimports@latest"
        "golang.org/x/lint/golint@latest"
        "github.com/golang/mock/mockgen@latest"
        "github.com/air-verse/air@latest"
    )
    
    for tool in "${tools[@]}"; do
        log_info "更新 $tool..."
        go install "$tool"
    done
    
    log_success "工具更新完成"
}

# 卸载开发工具
uninstall_tools() {
    log_warning "卸载开发工具..."
    
    local go_bin=$(go env GOPATH)/bin
    
    # 要卸载的工具
    local tools=(
        "goimports"
        "golint"
        "mockgen"
        "air"
        "gosec"
        "nancy"
        "golangci-lint"
    )
    
    for tool in "${tools[@]}"; do
        if [ -f "$go_bin/$tool" ]; then
            rm -f "$go_bin/$tool"
            log_info "已卸载: $tool"
        fi
    done
    
    log_success "开发工具卸载完成"
}

# 显示状态
show_status() {
    log_info "开发环境状态:"
    echo ""
    
    # 基础工具
    echo -e "${CYAN}基础工具:${RESET}"
    check_go_version && echo "  ✓ Go 环境正常" || echo "  ✗ Go 环境异常"
    check_git_version && echo "  ✓ Git 环境正常" || echo "  ✗ Git 环境异常"
    check_make && echo "  ✓ Make 可用" || echo "  ✗ Make 不可用"
    
    # 开发工具
    echo ""
    echo -e "${CYAN}开发工具:${RESET}"
    command_exists goimports && echo "  ✓ goimports 已安装" || echo "  ✗ goimports 未安装"
    command_exists golint && echo "  ✓ golint 已安装" || echo "  ✗ golint 未安装"
    command_exists mockgen && echo "  ✓ mockgen 已安装" || echo "  ✗ mockgen 未安装"
    command_exists air && echo "  ✓ air 已安装" || echo "  ✗ air 未安装"
    
    # 高级工具
    echo ""
    echo -e "${CYAN}高级工具:${RESET}"
    command_exists gosec && echo "  ✓ gosec 已安装" || echo "  ✗ gosec 未安装"
    command_exists nancy && echo "  ✓ nancy 已安装" || echo "  ✗ nancy 未安装"
    command_exists golangci-lint && echo "  ✓ golangci-lint 已安装" || echo "  ✗ golangci-lint 未安装"
    
    # 项目状态
    echo ""
    echo -e "${CYAN}项目状态:${RESET}"
    if [ -f "go.mod" ]; then
        echo "  ✓ 项目文件存在"
        if go build -o /dev/null . 2>/dev/null; then
            echo "  ✓ 项目可以构建"
        else
            echo "  ✗ 项目构建失败"
        fi
    else
        echo "  ✗ 项目文件缺失"
    fi
}

# 主函数
main() {
    local install_type="full"
    local check_only=false
    local update_mode=false
    local uninstall_mode=false
    local auto_yes=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --basic)
                install_type="basic"
                shift
                ;;
            --full)
                install_type="full"
                shift
                ;;
            --check)
                check_only=true
                shift
                ;;
            --update)
                update_mode=true
                shift
                ;;
            --uninstall)
                uninstall_mode=true
                shift
                ;;
            -y|--yes)
                auto_yes=true
                shift
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
    
    # 设置全局变量
    export AUTO_YES=$auto_yes
    export INSTALL_ADVANCED=$( [ "$install_type" = "full" ] && echo "true" || echo "false" )
    
    # 执行操作
    if [ "$check_only" = "true" ]; then
        check_environment
        show_status
    elif [ "$update_mode" = "true" ]; then
        update_tools
    elif [ "$uninstall_mode" = "true" ]; then
        uninstall_tools
    else
        # 安装模式
        echo -e "${CYAN}Git Worktree CLI 开发环境设置${RESET}"
        echo -e "${BLUE}============================${RESET}"
        echo ""
        
        if [ "$install_type" = "full" ]; then
            full_install
        else
            basic_install
        fi
        
        echo ""
        log_success "开发环境设置完成！"
        echo ""
        echo -e "${CYAN}下一步:${RESET}"
        echo "  1. 重新加载 shell 配置（如果需要）"
        echo "  2. 运行: make build"
        echo "  3. 运行: make test"
        echo "  4. 开始开发！"
        echo ""
        echo -e "${CYAN}有用命令:${RESET}"
        echo "  make dev     # 开发模式（热重载）"
        echo "  make check   # 代码检查"
        echo "  make help    # 查看所有可用命令"
    fi
}

# 运行主函数
main "$@"