#!/bin/bash

# GitHub Release 管理脚本
# 简化发布流程，提供交互式发布管理

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
RESET='\033[0m'

# 配置
PROJECT_NAME="gwt"
DEFAULT_OWNER="tinsfox"
VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"

# 发布类型
RELEASE_TYPES=(
    "major: Major release with breaking changes"
    "minor: Minor release with new features"
    "patch: Patch release with bug fixes"
    "prerelease: Pre-release version"
    "custom: Custom version number"
)

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

log_step() {
    echo -e "${MAGENTA}[STEP]${RESET} $1"
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}GitHub Release 管理脚本${RESET}"
    echo -e "${BLUE}=======================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET} $0 <命令> [选项]"
    echo ""
    echo -e "${GREEN}命令:${RESET}"
    echo "  interactive     # 交互式发布（推荐）"
    echo "  quick           # 快速发布（自动模式）"
    echo "  prepare         # 准备发布（检查+构建）"
    echo "  create          # 创建发布版本"
    echo "  publish         # 发布到 GitHub"
    echo "  rollback        # 回滚发布"
    echo "  list            # 列出发布版本"
    echo "  status          # 显示发布状态"
    echo "  changelog       # 生成变更日志"
    echo "  validate        # 验证发布准备"
    echo "  help            # 显示帮助信息"
    echo ""
    echo -e "${GREEN}选项:${RESET}"
    echo "  -v, --version   # 指定版本号"
    echo "  -o, --owner     # 指定仓库所有者"
    echo "  -r, --repo      # 指定仓库名称"
    echo "  -t, --type      # 发布类型 (major/minor/patch/prerelease)"
    echo "  -m, --message   # 发布说明"
    echo "  --prerelease    # 标记为预发布"
    echo "  --draft         # 创建草稿发布"
    echo "  --dry-run       # 试运行模式"
    echo "  --skip-tests    # 跳过测试"
    echo "  --skip-build    # 跳过构建"
    echo "  --force         # 强制执行"
    echo "  --verbose       # 详细输出"
}

# 检查依赖
check_dependencies() {
    local missing=()
    
    if ! command -v gh &> /dev/null; then
        missing+=("gh (GitHub CLI)")
    fi
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if ! command -v make &> /dev/null; then
        missing+=("make")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少依赖工具: ${missing[*]}"
        exit 1
    fi
}

# 验证 GitHub CLI 认证
verify_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI 未认证，请先运行: gh auth login"
        exit 1
    fi
}

# 获取当前版本
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        # 从最新的 git tag 获取版本
        git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"
    fi
}

# 计算下一个版本
calculate_next_version() {
    local current_version="$1"
    local release_type="$2"
    
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case "$release_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        prerelease)
            # 简单的预发布版本处理
            if [[ "$patch" =~ - ]]; then
                local pre_num=$(echo "$patch" | sed 's/.*-//')
                patch="${patch%-*}-$((pre_num + 1))"
            else
                patch="${patch}-pre.1"
            fi
            ;;
        *)
            echo "$current_version"
            return
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# 生成变更日志
generate_changelog() {
    local version="$1"
    local previous_version="$2"
    
    if [ -z "$previous_version" ]; then
        previous_version=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null || echo "")
    fi
    
    log_info "生成变更日志..."
    
    local changelog="## Release v$version\n\n"
    
    if [ -n "$previous_version" ]; then
        changelog+="### Changes since $previous_version\n\n"
        
        # 获取提交记录
        local commits=$(git log --pretty=format:"- %s" "$previous_version"..HEAD 2>/dev/null || echo "")
        
        if [ -n "$commits" ]; then
            changelog+="$commits\n\n"
        else
            changelog+="- Initial release\n\n"
        fi
    else
        changelog+="- Initial release\n\n"
    fi
    
    # 添加贡献者
    local contributors=$(git log --pretty=format:"%an" "$previous_version"..HEAD 2>/dev/null | sort -u | head -10)
    if [ -n "$contributors" ]; then
        changelog+="### Contributors\n\n"
        changelog+="$contributors\n\n"
    fi
    
    # 添加安装说明
    changelog+="### Installation\n\n"
    changelog+="\`\`\`bash\n"
    changelog+="# Using install script\n"
    changelog+="curl -fsSL https://raw.githubusercontent.com/tinsfox/gwt/main/scripts/install.sh | bash\n"
    changelog+="\n"
    changelog+="# Using go install\n"
    changelog+="go install github.com/tinsfox/gwt@latest\n"
    changelog+="\`\`\`\n\n"
    
    # 添加校验和说明
    changelog+="### Verification\n\n"
    changelog+="Download the appropriate binary for your platform and verify the checksum.\n"
    
    echo "$changelog"
}

# 验证发布准备
validate_release() {
    local version="$1"
    local skip_tests="$2"
    local skip_build="$3"
    
    log_step "验证发布准备..."
    
    # 检查 Git 状态
    if [ -n "$(git status --porcelain)" ]; then
        log_error "工作目录不干净，请先提交或暂存更改"
        git status --short
        return 1
    fi
    
    # 检查是否在主分支
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        log_warning "当前不在主分支 ($current_branch)，确定要继续吗？"
        read -p "继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 运行测试
    if [ "$skip_tests" != "true" ]; then
        log_info "运行测试..."
        if ! make test; then
            log_error "测试失败"
            return 1
        fi
    fi
    
    # 运行代码检查
    log_info "运行代码检查..."
    if ! make check; then
        log_error "代码检查失败"
        return 1
    fi
    
    # 构建测试
    if [ "$skip_build" != "true" ]; then
        log_info "测试构建..."
        if ! make build; then
            log_error "构建失败"
            return 1
        fi
    fi
    
    # 检查版本号格式
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        log_error "版本号格式无效: $version"
        return 1
    fi
    
    # 检查标签是否已存在
    if git rev-parse "v$version" >/dev/null 2>&1; then
        log_error "标签 v$version 已存在"
        return 1
    fi
    
    log_success "发布验证通过"
    return 0
}

# 准备发布
prepare_release() {
    local version="$1"
    local skip_tests="$2"
    local skip_build="$3"
    
    log_step "准备发布 v$version..."
    
    # 验证发布准备
    if ! validate_release "$version" "$skip_tests" "$skip_build"; then
        return 1
    fi
    
    # 清理旧的构建
    log_info "清理旧的构建..."
    make clean
    
    # 构建所有平台
    log_info "构建所有平台..."
    if ! make build-all; then
        log_error "跨平台构建失败"
        return 1
    fi
    
    # 生成校验和
    log_info "生成校验和..."
    cd dist
    sha256sum * > checksums.txt
    cd ..
    
    log_success "发布准备完成"
    return 0
}

# 创建发布
create_release() {
    local version="$1"
    local title="$2"
    local notes="$3"
    local prerelease="$4"
    local draft="$5"
    local repo="$6"
    
    if [ -z "$repo" ]; then
        repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git$//' || echo "$DEFAULT_OWNER/$DEFAULT_REPO")
    fi
    
    log_step "创建发布 v$version..."
    
    # 创建标签
    log_info "创建标签 v$version..."
    git tag -a "v$version" -m "Release v$version"
    git push origin "v$version"
    
    # 生成发布说明
    if [ -z "$notes" ]; then
        notes=$(generate_changelog "$version")
    fi
    
    # 构建发布参数
    local args=(
        "--title" "$title"
        "--notes" "$notes"
        "--generate-notes"
    )
    
    if [ "$prerelease" = "true" ]; then
        args+=("--prerelease")
    fi
    
    if [ "$draft" = "true" ]; then
        args+=("--draft")
    fi
    
    # 创建发布
    log_info "创建 GitHub 发布..."
    if gh release create "v$version" "${args[@]}" --repo "$repo"; then
        log_success "发布创建成功: v$version"
        
        # 上传构建产物
        if [ -d "dist" ]; then
            log_info "上传构建产物..."
            cd dist
            for file in *.tar.gz *.zip checksums.txt; do
                if [ -f "$file" ]; then
                    log_info "上传 $file..."
                    gh release upload "v$version" "$file" --repo "$repo" --clobber || log_warning "上传 $file 失败"
                fi
            done
            cd ..
        fi
        
        return 0
    else
        log_error "发布创建失败"
        return 1
    fi
}

# 交互式发布
interactive_release() {
    log_info "启动交互式发布流程..."
    echo ""
    
    # 获取当前版本
    local current_version=$(get_current_version)
    echo -e "${CYAN}当前版本: $current_version${RESET}"
    echo ""
    
    # 选择发布类型
    echo -e "${GREEN}选择发布类型:${RESET}"
    for i in "${!RELEASE_TYPES[@]}"; do
        echo "  $((i+1)). ${RELEASE_TYPES[$i]}"
    done
    echo ""
    
    read -p "请选择 (1-${#RELEASE_TYPES[@]}): " release_choice
    
    if [[ ! "$release_choice" =~ ^[1-${#RELEASE_TYPES[@]}]$ ]]; then
        log_error "无效的选择"
        return 1
    fi
    
    local release_type=$(echo "${RELEASE_TYPES[$((release_choice-1))]}" | cut -d':' -f1)
    local next_version=""
    
    if [ "$release_type" = "custom" ]; then
        read -p "请输入自定义版本号: " next_version
    else
        next_version=$(calculate_next_version "$current_version" "$release_type")
        echo -e "${CYAN}建议版本号: $next_version${RESET}"
        read -p "确认版本号 ($next_version) 或输入新的: " custom_version
        if [ -n "$custom_version" ]; then
            next_version="$custom_version"
        fi
    fi
    
    # 确认版本号
    echo ""
    echo -e "${YELLOW}即将发布版本: v$next_version${RESET}"
    read -p "确认继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "发布已取消"
        return 0
    fi
    
    # 高级选项
    echo ""
    echo -e "${GREEN}高级选项:${RESET}"
    read -p "是否为预发布版本？(y/N): " -n 1 -r
    local prerelease="false"
    [[ $REPLY =~ ^[Yy]$ ]] && prerelease="true"
    
    read -p "是否创建草稿发布？(y/N): " -n 1 -r
    local draft="false"
    [[ $REPLY =~ ^[Yy]$ ]] && draft="true"
    
    read -p "是否跳过测试？(y/N): " -n 1 -r
    local skip_tests="false"
    [[ $REPLY =~ ^[Yy]$ ]] && skip_tests="true"
    
    # 执行发布
    perform_release "$next_version" "$release_type" "$prerelease" "$draft" "$skip_tests"
}

# 执行完整发布流程
perform_release() {
    local version="$1"
    local release_type="$2"
    local prerelease="$3"
    local draft="$4"
    local skip_tests="$5"
    
    log_step "开始发布流程 v$version..."
    
    # 准备发布
    if ! prepare_release "$version" "$skip_tests" "false"; then
        return 1
    fi
    
    # 创建发布
    local title="Release v$version"
    local notes=""
    
    case "$release_type" in
        major)
            notes="Major release with breaking changes and new features"
            ;;
        minor)
            notes="Minor release with new features and improvements"
            ;;
        patch)
            notes="Patch release with bug fixes"
            ;;
        prerelease)
            notes="Pre-release version for testing"
            ;;
        *)
            notes="Release v$version"
            ;;
    esac
    
    if ! create_release "$version" "$title" "$notes" "$prerelease" "$draft"; then
        return 1
    fi
    
    # 更新版本文件
    if [ -f "$VERSION_FILE" ]; then
        echo "$version" > "$VERSION_FILE"
        git add "$VERSION_FILE"
        git commit -m "chore: bump version to $version"
        git push origin main
    fi
    
    # 成功消息
    echo ""
    log_success "🎉 发布成功！"
    echo ""
    echo -e "${CYAN}发布信息:${RESET}"
    echo "  版本: v$version"
    echo "  类型: $release_type"
    echo "  预发布: $prerelease"
    echo "  草稿: $draft"
    echo ""
    echo -e "${CYAN}下一步操作:${RESET}"
    echo "  1. 检查 GitHub 发布页面"
    echo "  2. 验证下载文件"
    echo "  3. 通知用户"
    echo "  4. 更新文档"
    
    if [ "$draft" = "true" ]; then
        echo ""
        log_info "⚠️  这是一个草稿发布，需要手动发布"
    fi
    
    return 0
}

# 快速发布
quick_release() {
    local version="$1"
    local release_type="$2"
    
    log_info "执行快速发布..."
    
    if [ -z "$version" ]; then
        local current_version=$(get_current_version)
        version=$(calculate_next_version "$current_version" "${release_type:-patch}")
    fi
    
    log_info "发布版本: v$version"
    perform_release "$version" "${release_type:-patch}" "false" "false" "false"
}

# 列出发布版本
list_releases() {
    local repo="$1"
    
    if [ -z "$repo" ]; then
        repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git$//' || echo "$DEFAULT_OWNER/$DEFAULT_REPO")
    fi
    
    log_info "发布版本列表:"
    echo ""
    
    gh release list --repo "$repo" --limit 10 | while IFS=$'\t' read -r tag name status published url; do
        echo -e "${CYAN}$tag${RESET} - $name ($status)"
        echo "  发布时间: $published"
        echo "  URL: $url"
        echo ""
    done
}

# 显示发布状态
release_status() {
    local version="$1"
    local repo="$2"
    
    if [ -z "$repo" ]; then
        repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git$//' || echo "$DEFAULT_OWNER/$DEFAULT_REPO")
    fi
    
    if [ -n "$version" ]; then
        # 显示特定版本的状态
        log_info "发布状态 v$version:"
        gh release view "v$version" --repo "$repo" --json tagName,name,createdAt,publishedAt,prerelease,draft,url | jq -r '
            "标签: \(.tagName)"
            "名称: \(.name)"
            "创建时间: \(.createdAt)"
            "发布时间: \(.publishedAt)"
            "预发布: \(.prerelease)"
            "草稿: \(.draft)"
            "URL: \(.url)"
        ' 2>/dev/null || log_error "发布版本 v$version 不存在"
    else
        # 显示最新发布状态
        log_info "最新发布状态:"
        gh release view --repo "$repo" --json tagName,name,createdAt,publishedAt,prerelease,draft,url | jq -r '
            "标签: \(.tagName)"
            "名称: \(.name)"
            "创建时间: \(.createdAt)"
            "发布时间: \(.publishedAt)"
            "预发布: \(.prerelease)"
            "草稿: \(.draft)"
            "URL: \(.url)"
        ' 2>/dev/null || log_info "没有发布版本"
    fi
}

# 回滚发布
rollback_release() {
    local version="$1"
    local repo="$2"
    
    if [ -z "$version" ]; then
        log_error "请提供要回滚的版本号"
        return 1
    fi
    
    if [ -z "$repo" ]; then
        repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git$//' || echo "$DEFAULT_OWNER/$DEFAULT_REPO")
    fi
    
    log_warning "即将回滚发布 v$version"
    echo "这将删除发布版本和对应的标签"
    read -p "确定要继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "回滚已取消"
        return 0
    fi
    
    # 删除发布
    log_info "删除发布 v$version..."
    gh release delete "v$version" --repo "$repo" --confirm || log_warning "发布删除失败或不存在"
    
    # 删除标签
    log_info "删除标签 v$version..."
    git tag -d "v$version" 2>/dev/null || true
    git push origin :refs/tags/v$version 2>/dev/null || log_warning "远程标签删除失败"
    
    # 重置版本文件
    if [ -f "$VERSION_FILE" ]; then
        local previous_version=$(git describe --tags --abbrev=0 HEAD~1 2>/dev/null | sed 's/^v//' || echo "0.0.0")
        echo "$previous_version" > "$VERSION_FILE"
        git add "$VERSION_FILE"
        git commit -m "chore: rollback to version $previous_version"
        git push origin main
    fi
    
    log_success "回滚完成"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        # 默认进入交互式模式
        interactive_release
        exit 0
    fi
    
    local command=$1
    shift
    
    # 解析全局选项
    local version=""
    local owner="$DEFAULT_OWNER"
    local repo=""
    local release_type=""
    local message=""
    local prerelease="false"
    local draft="false"
    local dry_run="false"
    local skip_tests="false"
    local skip_build="false"
    local force="false"
    local verbose="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                version="$2"
                shift 2
                ;;
            -o|--owner)
                owner="$2"
                shift 2
                ;;
            -r|--repo)
                repo="$2"
                shift 2
                ;;
            -t|--type)
                release_type="$2"
                shift 2
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            --prerelease)
                prerelease="true"
                shift
                ;;
            --draft)
                draft="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --skip-tests)
                skip_tests="true"
                shift
                ;;
            --skip-build)
                skip_build="true"
                shift
                ;;
            --force)
                force="true"
                shift
                ;;
            --verbose)
                verbose="true"
                set -x
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # 检查依赖
    check_dependencies
    verify_auth
    
    case $command in
        interactive)
            interactive_release
            ;;
        quick)
            quick_release "$version" "$release_type"
            ;;
        prepare)
            prepare_release "$version" "$skip_tests" "$skip_build"
            ;;
        create)
            create_release "$version" "$message" "" "$prerelease" "$draft" "$repo"
            ;;
        publish)
            # 从草稿发布转换为正式发布
            if [ -n "$version" ]; then
                gh release edit "v$version" --draft=false --repo "${repo:-$owner/$DEFAULT_REPO}"
            else
                log_error "请提供版本号"
                exit 1
            fi
            ;;
        rollback)
            rollback_release "$version" "$repo"
            ;;
        list)
            list_releases "$repo"
            ;;
        status)
            release_status "$version" "$repo"
            ;;
        changelog)
            generate_changelog "$version"
            ;;
        validate)
            validate_release "$version" "$skip_tests" "$skip_build"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"