#!/bin/bash

# Homebrew Formula 自动更新脚本
# 用于自动更新 Git Worktree CLI 的 Homebrew Formula

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 配置
GITHUB_OWNER="TinsFox"
GITHUB_REPO="gwt"
FORMULA_FILE="Formula/gwt.rb"
DEFAULT_BRANCH="main"

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
    echo -e "${CYAN}Homebrew Formula 自动更新脚本${RESET}"
    echo -e "${BLUE}============================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET} $0 <新版本号> [选项]"
    echo ""
    echo -e "${GREEN}参数:${RESET}"
    echo "  <新版本号>     - 新版本号 (例如: 1.1.0)"
    echo ""
    echo -e "${GREEN}选项:${RESET}"
    echo "  --dry-run      - 试运行模式 (不实际执行更新)"
    echo "  --auto-commit  - 自动提交更改"
    echo "  --auto-push    - 自动推送更改"
    echo "  --help         - 显示帮助信息"
    echo ""
    echo -e "${GREEN}示例:${RESET}"
    echo "  $0 1.1.0                    # 更新到 v1.1.0"
    echo "  $0 1.1.0 --dry-run          # 试运行模式"
    echo "  $0 1.1.0 --auto-commit      # 自动提交"
    echo "  $0 1.1.0 --auto-push        # 自动推送"
}

# 检查依赖
check_dependencies() {
    local missing=()
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if ! command -v sha256sum &> /dev/null; then
        missing+=("sha256sum")
    fi
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少依赖工具: ${missing[*]}"
        exit 1
    fi
}

# 获取最新版本信息
get_latest_version() {
    local repo="$1"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    
    log_info "获取最新版本信息..."
    
    local latest_version=$(curl -s "$api_url" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4 | sed 's/^v//')
    
    if [ -z "$latest_version" ]; then
        log_error "无法获取最新版本信息"
        return 1
    fi
    
    echo "$latest_version"
}

# 下载并计算 SHA256
download_and_hash() {
    local version="$1"
    local repo="$2"
    local download_url="https://github.com/${repo}/archive/v${version}.tar.gz"
    local temp_file="/tmp/gwt-${version}.tar.gz"
    
    log_info "下载 v${version} 源码..."
    
    # 下载文件
    if ! curl -L -o "$temp_file" "$download_url"; then
        log_error "下载失败: $download_url"
        return 1
    fi
    
    # 计算 SHA256
    local sha256=$(sha256sum "$temp_file" | cut -d' ' -f1)
    
    # 清理临时文件
    rm -f "$temp_file"
    
    echo "$sha256"
}

# 更新 Formula 文件
update_formula() {
    local version="$1"
    local sha256="$2"
    local formula_file="$3"
    local dry_run="$4"
    
    log_info "更新 Formula 文件..."
    
    if [ "$dry_run" = "true" ]; then
        log_info "【试运行模式】将要执行以下更新："
        echo "  - 版本: v${version}"
        echo "  - SHA256: ${sha256}"
        echo "  - 文件: ${formula_file}"
        return 0
    fi
    
    # 创建备份
    cp "$formula_file" "$formula_file.bak"
    
    # 更新版本号
    sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v${version}/g" "$formula_file"
    
    # 更新 SHA256
    sed -i.bak "s/sha256 \".*\"/sha256 \"${sha256}\"/g" "$formula_file"
    
    # 清理备份文件
    rm -f "$formula_file.bak"
    
    log_success "Formula 文件更新完成"
}

# 测试更新后的 Formula
test_formula() {
    local formula_file="$1"
    
    log_info "测试更新后的 Formula..."
    
    # 语法检查
    if ! ruby -c "$formula_file" >/dev/null 2>&1; then
        log_error "Formula 语法检查失败"
        return 1
    fi
    
    # Homebrew 风格检查
    if ! brew style "$formula_file" >/dev/null 2>&1; then
        log_warning "Formula 风格检查失败，但继续执行"
    fi
    
    log_success "Formula 测试通过"
}

# 自动更新流程
auto_update() {
    local version="$1"
    local auto_commit="$2"
    local auto_push="$3"
    local dry_run="$4"
    
    log_info "开始自动更新流程..."
    
    # 1. 获取 SHA256
    local sha256=$(download_and_hash "$version" "$GITHUB_OWNER/$GITHUB_REPO")
    if [ -z "$sha256" ]; then
        return 1
    fi
    
    # 2. 更新 Formula
    update_formula "$version" "$sha256" "$FORMULA_FILE" "$dry_run"
    if [ "$dry_run" = "true" ]; then
        return 0
    fi
    
    # 3. 测试 Formula
    test_formula "$FORMULA_FILE"
    
    # 4. 本地测试（可选）
    if [ "$dry_run" != "true" ]; then
        log_info "进行本地测试..."
        if ! brew install --build-from-source "$FORMULA_FILE" >/dev/null 2>&1; then
            log_error "本地安装测试失败"
            return 1
        fi
        
        # 测试基本功能
        if ! gwt --version >/dev/null 2>&1; then
            log_error "功能测试失败"
            return 1
        fi
        
        log_success "本地测试通过"
    fi
    
    # 5. 提交更改（如果启用）
    if [ "$auto_commit" = "true" ]; then
        log_info "提交更改..."
        git add "$FORMULA_FILE"
        git commit -m "Update gwt to v${version}"
    fi
    
    # 6. 推送更改（如果启用）
    if [ "$auto_push" = "true" ]; then
        log_info "推送更改..."
        git push origin "$DEFAULT_BRANCH"
    fi
    
    log_success "自动更新完成！"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local version="$1"
    shift
    
    # 默认选项
    local auto_commit="false"
    local auto_push="false"
    local dry_run="false"
    
    # 解析选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-commit)
                auto_commit="true"
                shift
                ;;
            --auto-push)
                auto_push="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --help|-h)
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
    
    # 检查依赖
    check_dependencies
    
    # 验证版本号格式
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "版本号格式无效: $version (应该是 x.y.z 格式)"
        exit 1
    fi
    
    # 执行自动更新
    auto_update "$version" "$auto_commit" "$auto_push" "$dry_run"
}

# 运行主函数
main "$@"