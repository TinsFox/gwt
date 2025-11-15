#!/bin/bash

# GitHub 自动化脚本
# 用于自动化 GitHub 仓库管理、发布和 CI/CD 操作

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 配置
PROJECT_NAME="gwt"
GITHUB_OWNER="tinsfox"
DEFAULT_REPO="gwt"

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
    echo -e "${CYAN}GitHub 自动化脚本${RESET}"
    echo -e "${BLUE}==================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET} $0 <命令> [选项]"
    echo ""
    echo -e "${GREEN}仓库管理命令:${RESET}"
    echo "  create-repo     # 创建新仓库"
    echo "  setup-repo      # 设置仓库配置"
    echo "  delete-repo     # 删除仓库（危险操作）"
    echo "  list-repos      # 列出用户仓库"
    echo "  repo-info       # 显示仓库信息"
    echo ""
    echo -e "${GREEN}发布管理命令:${RESET}"
    echo "  create-release  # 创建发布版本"
    echo "  list-releases   # 列出发布版本"
    echo "  delete-release  # 删除发布版本"
    echo "  upload-asset    # 上传发布资产"
    echo ""
    echo -e "${GREEN}Issue 管理命令:${RESET}"
    echo "  create-issue    # 创建 Issue"
    echo "  list-issues     # 列出 Issues"
    echo "  close-issue     # 关闭 Issue"
    echo "  add-label       # 添加标签"
    echo ""
    echo -e "${GREEN}CI/CD 命令:${RESET}"
    echo "  trigger-ci      # 触发 CI 工作流"
    echo "  check-status    # 检查 CI 状态"
    echo "  cancel-run      # 取消工作流运行"
    echo ""
    echo -e "${GREEN}标签管理命令:${RESET}"
    echo "  sync-labels     # 同步标签配置"
    echo "  create-label    # 创建标签"
    echo "  delete-label    # 删除标签"
    echo ""
    echo -e "${GREEN}其他命令:${RESET}"
    echo "  sync-fork       # 同步 Fork 仓库"
    echo "  clone-template  # 克隆模板仓库"
    echo "  cleanup         # 清理旧资源"
    echo "  status          # 显示状态信息"
    echo "  help            # 显示帮助信息"
    echo ""
    echo -e "${GREEN}全局选项:${RESET}"
    echo "  -o, --owner     # 指定仓库所有者"
    echo "  -r, --repo      # 指定仓库名称"
    echo "  -t, --token     # GitHub Token"
    echo "  --dry-run       # 试运行模式"
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
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing+=("curl or wget")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少依赖工具: ${missing[*]}"
        echo ""
        echo "安装 GitHub CLI:"
        echo "  macOS: brew install gh"
        echo "  Ubuntu/Debian: sudo apt install gh"
        echo "  其他系统: 参见 https://cli.github.com/"
        exit 1
    fi
}

# 验证 GitHub CLI 认证
verify_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI 未认证，请先运行: gh auth login"
        echo ""
        echo "认证方法:"
        echo "  1. gh auth login              # 交互式认证"
        echo "  2. gh auth login --with-token  # 使用 Token 认证"
        echo "  3. 设置 GITHUB_TOKEN 环境变量"
        exit 1
    fi
}

# 获取当前仓库信息
get_current_repo() {
    if [ -d ".git" ]; then
        git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git$//' || echo ""
    else
        echo ""
    fi
}

# 创建新仓库
create_repo() {
    local repo_name="$1"
    local description="$2"
    local is_private="$3"
    local template="$4"
    
    if [ -z "$repo_name" ]; then
        read -p "请输入仓库名称: " repo_name
    fi
    
    if [ -z "$description" ]; then
        description="Git Worktree CLI - A powerful command-line tool for managing Git worktrees"
    fi
    
    log_info "创建仓库: $repo_name"
    
    local visibility_flag="--public"
    if [ "$is_private" = "true" ]; then
        visibility_flag="--private"
    fi
    
    local template_flag=""
    if [ -n "$template" ]; then
        template_flag="--template $template"
    fi
    
    # 创建仓库
    if gh repo create "$repo_name" \
        $visibility_flag \
        --description "$description" \
        --homepage "https://github.com/$repo_name" \
        --confirm $template_flag; then
        
        log_success "仓库创建成功: https://github.com/$repo_name"
        
        # 如果当前目录是 Git 仓库，更新远程
        if [ -d ".git" ]; then
            log_info "更新当前仓库的远程地址..."
            git remote set-url origin "https://github.com/$repo_name.git"
            log_success "远程地址已更新"
        fi
        
        return 0
    else
        log_error "仓库创建失败"
        return 1
    fi
}

# 设置仓库配置
setup_repo() {
    local repo="$1"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    log_info "设置仓库配置: $repo"
    
    # 启用功能
    gh repo edit "$repo" \
        --enable-auto-merge \
        --delete-branch-on-merge \
        --enable-discussions \
        --enable-projects \
        --enable-wiki
    
    # 创建分支保护规则
    log_info "创建分支保护规则..."
    
    # 获取当前默认分支
    default_branch=$(gh api repos/$repo --jq '.default_branch')
    
    # 创建保护规则
    gh api repos/$repo/branches/$default_branch/protection \
        --method PUT \
        --input - <<< '{
            "required_status_checks": {
                "strict": true,
                "contexts": ["lint", "test", "build", "security"]
            },
            "enforce_admins": false,
            "required_pull_request_reviews": {
                "required_approving_review_count": 1,
                "dismiss_stale_reviews": true,
                "require_code_owner_reviews": true
            },
            "restrictions": null,
            "allow_force_pushes": false,
            "allow_deletions": false
        }' || log_warning "分支保护规则可能已存在"
    
    log_success "仓库配置完成"
}

# 创建发布版本
create_release() {
    local version="$1"
    local title="$2"
    local notes="$3"
    local prerelease="$4"
    local repo="$5"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    if [ -z "$version" ]; then
        # 自动生成版本号
        version=$(date +%Y.%m.%d-%H%M%S)
    fi
    
    if [ -z "$title" ]; then
        title="Release v$version"
    fi
    
    if [ -z "$notes" ]; then
        notes="Release created on $(date)"
    fi
    
    log_info "创建发布版本: v$version"
    
    # 创建标签
    if [ -d ".git" ]; then
        log_info "创建标签 v$version..."
        git tag "v$version"
        git push origin "v$version"
    fi
    
    # 创建发布
    local prerelease_flag=""
    if [ "$prerelease" = "true" ]; then
        prerelease_flag="--prerelease"
    fi
    
    if gh release create "v$version" \
        --title "$title" \
        --notes "$notes" \
        --generate-notes \
        $prerelease_flag \
        --repo "$repo"; then
        
        log_success "发布版本创建成功: v$version"
        
        # 如果有构建产物，上传它们
        if [ -d "dist" ]; then
            log_info "上传构建产物..."
            find dist -name "*.tar.gz" -o -name "*.zip" | while read file; do
                gh release upload "v$version" "$file" --repo "$repo" --clobber
            done
        fi
        
        return 0
    else
        log_error "发布版本创建失败"
        return 1
    fi
}

# 创建 Issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local repo="$4"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    if [ -z "$title" ]; then
        title="Automated issue created on $(date)"
    fi
    
    if [ -z "$body" ]; then
        body="This issue was automatically created by the automation script."
    fi
    
    if [ -z "$labels" ]; then
        labels="automated"
    fi
    
    log_info "创建 Issue: $title"
    
    if gh issue create \
        --title "$title" \
        --body "$body" \
        --label "$labels" \
        --repo "$repo"; then
        
        log_success "Issue 创建成功"
        return 0
    else
        log_error "Issue 创建失败"
        return 1
    fi
}

# 同步标签
sync_labels() {
    local repo="$1"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    log_info "同步标签到仓库: $repo"
    
    # 定义标准标签
    local labels=(
        "bug,#d73a4a,Something isn't working"
        "enhancement,#a2eeef,New feature or request"
        "documentation,#0075ca,Improvements or additions to documentation"
        "good first issue,#7057ff,Good for newcomers"
        "help wanted,#008672,Extra attention is needed"
        "priority-high,#b60205,High priority"
        "priority-medium,#fbca04,Medium priority"
        "priority-low,#0e8a16,Low priority"
        "question,#d876e3,Further information is requested"
        "wontfix,#ffffff,This will not be worked on"
        "invalid,#e4e669,This doesn't seem right"
        "duplicate,#cfd3d7,This issue or pull request already exists"
        "dependencies,#0366d6,Pull requests that update a dependency file"
        "security,#ee0701,Security related issues"
        "performance,#f9d0c4,Performance related issues"
        "refactor,#c5def5,Code refactoring"
        "test,#0e8a16,Adding or updating tests"
        "ci,#ffccd7,Continuous integration"
        "automated,#bfd4f2,Automatically created"
    )
    
    # 创建或更新标签
    for label_info in "${labels[@]}"; do
        IFS=',' read -r name color description <<< "$label_info"
        
        # 检查标签是否已存在
        if gh api repos/$repo/labels/$name >/dev/null 2>&1; then
            log_info "更新标签: $name"
            gh api repos/$repo/labels/$name \
                --method PATCH \
                --field color="$color" \
                --field description="$description" || true
        else
            log_info "创建标签: $name"
            gh api repos/$repo/labels \
                --method POST \
                --field name="$name" \
                --field color="$color" \
                --field description="$description" || true
        fi
    done
    
    log_success "标签同步完成"
}

# 触发 CI
trigger_ci() {
    local workflow="$1"
    local ref="$2"
    local repo="$3"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    if [ -z "$workflow" ]; then
        workflow="ci.yml"
    fi
    
    if [ -z "$ref" ]; then
        ref="main"
    fi
    
    log_info "触发 CI 工作流: $workflow ($ref)"
    
    if gh workflow run "$workflow" --ref "$ref" --repo "$repo"; then
        log_success "CI 工作流已触发"
        
        # 等待并显示状态
        sleep 5
        check_status "$workflow" "$repo"
        
        return 0
    else
        log_error "CI 工作流触发失败"
        return 1
    fi
}

# 检查 CI 状态
check_status() {
    local workflow="$1"
    local repo="$2"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    if [ -z "$workflow" ]; then
        workflow="ci.yml"
    fi
    
    log_info "检查 CI 状态: $workflow"
    
    # 获取最新的工作流运行
    local run_info=$(gh api repos/$repo/actions/workflows/$workflow/runs \
        --jq '.workflow_runs[0] | {id: .id, status: .status, conclusion: .conclusion, html_url: .html_url}')
    
    local run_id=$(echo "$run_info" | jq -r '.id')
    local status=$(echo "$run_info" | jq -r '.status')
    local conclusion=$(echo "$run_info" | jq -r '.conclusion')
    local url=$(echo "$run_info" | jq -r '.html_url')
    
    echo "Run ID: $run_id"
    echo "Status: $status"
    echo "Conclusion: $conclusion"
    echo "URL: $url"
    
    if [ "$status" = "completed" ]; then
        if [ "$conclusion" = "success" ]; then
            log_success "CI 运行成功 ✅"
        elif [ "$conclusion" = "failure" ]; then
            log_error "CI 运行失败 ❌"
        else
            log_warning "CI 运行状态: $conclusion"
        fi
    else
        log_info "CI 运行中... (状态: $status)"
    fi
}

# 显示状态信息
status() {
    local repo="$1"
    
    if [ -z "$repo" ]; then
        repo=$(get_current_repo)
        if [ -z "$repo" ]; then
            repo="$GITHUB_OWNER/$DEFAULT_REPO"
        fi
    fi
    
    log_info "仓库状态: $repo"
    echo ""
    
    # 基本信息
    echo "基本信息:"
    gh api repos/$repo --jq '
        {
            name: .name,
            description: .description,
            stars: .stargazers_count,
            forks: .forks_count,
            issues: .open_issues_count,
            language: .language,
            created: .created_at,
            updated: .updated_at
        }
    ' | jq -r '
        "  名称: \(.name)"
        "  描述: \(.description // "无")"
        "  ⭐ Stars: \(.stars)"
        "  🍴 Forks: \(.forks)"
        "  📋 Open Issues: \(.issues)"
        "  💻 Language: \(.language // "未知")"
        "  📅 Created: \(.created)"
        "  🔄 Updated: \(.updated)"
    '
    
    echo ""
    
    # 最新发布
    echo "最新发布:"
    gh api repos/$repo/releases/latest --jq '
        {
            tag: .tag_name,
            name: .name,
            published: .published_at,
            prerelease: .prerelease
        }
    ' 2>/dev/null | jq -r '
        "  标签: \(.tag)"
        "  名称: \(.name)"
        "  发布时间: \(.published)"
        "  预发布: \(.prerelease)"
    ' || echo "  无发布版本"
    
    echo ""
    
    # CI 状态
    echo "CI 状态:"
    check_status "ci.yml" "$repo"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    # 全局选项
    local owner="$GITHUB_OWNER"
    local repo=""
    local token=""
    local dry_run=false
    local verbose=false
    
    # 解析全局选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--owner)
                owner="$2"
                shift 2
                ;;
            -r|--repo)
                repo="$2"
                shift 2
                ;;
            -t|--token)
                token="$2"
                export GITHUB_TOKEN="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
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
        create-repo)
            create_repo "$@"
            ;;
        setup-repo)
            setup_repo "$@"
            ;;
        delete-repo)
            # 危险操作，需要确认
            read -p "⚠️  确定要删除仓库吗？此操作不可恢复 (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                gh repo delete "$1" --confirm
            else
                log_info "操作已取消"
            fi
            ;;
        list-repos)
            gh repo list "$owner" --limit 30
            ;;
        repo-info)
            status "$@"
            ;;
        create-release)
            create_release "$@"
            ;;
        list-releases)
            local target_repo="${1:-$owner/$DEFAULT_REPO}"
            gh release list --repo "$target_repo"
            ;;
        delete-release)
            local tag="$1"
            local target_repo="${2:-$owner/$DEFAULT_REPO}"
            if [ -n "$tag" ]; then
                gh release delete "$tag" --repo "$target_repo" --confirm
            else
                log_error "请提供要删除的发布版本标签"
            fi
            ;;
        upload-asset)
            local tag="$1"
            local file="$2"
            local target_repo="${3:-$owner/$DEFAULT_REPO}"
            if [ -n "$tag" ] && [ -n "$file" ]; then
                gh release upload "$tag" "$file" --repo "$target_repo" --clobber
            else
                log_error "请提供发布版本标签和文件路径"
            fi
            ;;
        create-issue)
            create_issue "$@"
            ;;
        list-issues)
            local target_repo="${1:-$owner/$DEFAULT_REPO}"
            gh issue list --repo "$target_repo" --limit 20
            ;;
        close-issue)
            local issue="$1"
            local target_repo="${2:-$owner/$DEFAULT_REPO}"
            if [ -n "$issue" ]; then
                gh issue close "$issue" --repo "$target_repo"
            else
                log_error "请提供要关闭的 Issue 编号"
            fi
            ;;
        add-label)
            sync_labels "$@"
            ;;
        sync-labels)
            sync_labels "$@"
            ;;
        create-label)
            # 单个标签创建
            local name="$1"
            local color="$2"
            local description="$3"
            local target_repo="${4:-$owner/$DEFAULT_REPO}"
            
            if [ -n "$name" ] && [ -n "$color" ]; then
                gh api repos/$target_repo/labels \
                    --method POST \
                    --field name="$name" \
                    --field color="$color" \
                    --field description="$description" || true
            else
                log_error "请提供标签名称和颜色"
            fi
            ;;
        delete-label)
            local name="$1"
            local target_repo="${2:-$owner/$DEFAULT_REPO}"
            if [ -n "$name" ]; then
                gh api repos/$target_repo/labels/$name --method DELETE || true
            else
                log_error "请提供要删除的标签名称"
            fi
            ;;
        trigger-ci)
            trigger_ci "$@"
            ;;
        check-status)
            check_status "$@"
            ;;
        cancel-run)
            local run_id="$1"
            local target_repo="${2:-$owner/$DEFAULT_REPO}"
            if [ -n "$run_id" ]; then
                gh api repos/$target_repo/actions/runs/$run_id/cancel --method POST || true
            else
                log_error "请提供工作流运行 ID"
            fi
            ;;
        sync-fork)
            local target_repo="${1:-$owner/$DEFAULT_REPO}"
            gh repo sync "$target_repo" || log_warning "同步失败，可能需要手动处理冲突"
            ;;
        clone-template)
            local template="$1"
            local new_repo="$2"
            
            if [ -z "$template" ]; then
                template="tinsfox/gwt"
            fi
            
            if [ -z "$new_repo" ]; then
                read -p "请输入新仓库名称: " new_repo
            fi
            
            gh repo create "$new_repo" --template "$template" --public --confirm
            ;;
        cleanup)
            local target_repo="${1:-$owner/$DEFAULT_REPO}"
            
            log_info "清理仓库资源: $target_repo"
            
            # 清理旧的 workflow runs
            log_info "清理旧的 workflow runs..."
            gh api repos/$target_repo/actions/runs \
                --paginate \
                --jq '.workflow_runs[] | select(.status == "completed") | .id' | \
                tail -n +21 | \
                while read run_id; do
                    echo "  Deleting workflow run: $run_id"
                    gh api repos/$target_repo/actions/runs/$run_id --method DELETE || true
                done
            
            # 清理旧的 artifacts
            log_info "清理旧的 artifacts..."
            gh api repos/$target_repo/actions/artifacts \
                --paginate \
                --jq '.artifacts[] | select(.expired == false) | .id' | \
                tail -n +11 | \
                while read artifact_id; do
                    echo "  Deleting artifact: $artifact_id"
                    gh api repos/$target_repo/actions/artifacts/$artifact_id --method DELETE || true
                done
            
            log_success "清理完成"
            ;;
        status)
            status "$@"
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