#!/bin/bash

# Git Worktree CLI 构建工具脚本
# 提供常用的构建功能和辅助工具

set -e

# 颜色输出
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# 项目配置
PROJECT_NAME="gwt"
VERSION_FILE="VERSION"
DEFAULT_VERSION="0.1.0"

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
    echo -e "${CYAN}Git Worktree CLI 构建工具${RESET}"
    echo -e "${BLUE}=======================${RESET}"
    echo ""
    echo -e "${GREEN}用法:${RESET} $0 <命令> [选项]"
    echo ""
    echo -e "${GREEN}命令:${RESET}"
    echo "  quick-build     # 快速构建当前平台"
    echo "  dev-build       # 开发模式构建（带调试信息）"
    echo "  cross-compile   # 交叉编译所有平台"
    echo "  release-build   # 构建发布版本"
    echo "  docker-build    # Docker 构建"
    echo "  test-all        # 运行所有测试"
    echo "  bench           # 运行基准测试"
    echo "  coverage        # 生成覆盖率报告"
    echo "  profile         # 性能分析构建"
    echo "  size-analysis   # 二进制大小分析"
    echo "  security-check  # 安全扫描"
    echo "  help            # 显示帮助信息"
    echo ""
    echo -e "${GREEN}选项:${RESET}"
    echo "  -v, --version   # 指定版本号"
    echo "  -o, --output    # 指定输出目录"
    echo "  -p, --platform  # 指定目标平台"
    echo "  --debug         # 启用调试模式"
    echo "  --verbose       # 详细输出"
}

# 检查依赖
check_dependencies() {
    local missing=()
    
    if ! command -v go &> /dev/null; then
        missing+=("go")
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

# 获取当前版本
get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "$DEFAULT_VERSION"
    fi
}

# 快速构建当前平台
quick_build() {
    log_info "快速构建当前平台..."
    
    check_dependencies
    
    # 清理旧的构建
    rm -rf build/
    
    # 构建
    go build -o build/$PROJECT_NAME .
    
    if [ $? -eq 0 ]; then
        log_success "构建成功: build/$PROJECT_NAME"
        log_info "文件大小: $(ls -lh build/$PROJECT_NAME | awk '{print $5}')"
    else
        log_error "构建失败"
        exit 1
    fi
}

# 开发模式构建
dev_build() {
    log_info "开发模式构建..."
    
    check_dependencies
    
    # 构建带调试信息的二进制
    go build -gcflags="-N -l" -race -o build/${PROJECT_NAME}-dev .
    
    if [ $? -eq 0 ]; then
        log_success "开发构建成功: build/${PROJECT_NAME}-dev"
        log_info "特性: 调试符号、竞态检测、性能分析支持"
    else
        log_error "开发构建失败"
        exit 1
    fi
}

# 交叉编译
cross_compile() {
    log_info "交叉编译所有平台..."
    
    check_dependencies
    
    # 创建输出目录
    mkdir -p dist/cross
    
    # 定义平台
    local platforms=(
        "linux/amd64"
        "linux/arm64"
        "darwin/amd64"
        "darwin/arm64"
        "windows/amd64"
    )
    
    for platform in "${platforms[@]}"; do
        GOOS=${platform%/*}
        GOARCH=${platform#*/}
        
        local output="dist/cross/${PROJECT_NAME}-${GOOS}-${GOARCH}"
        if [ "$GOOS" = "windows" ]; then
            output="${output}.exe"
        fi
        
        log_info "构建 ${GOOS}/${GOARCH}..."
        
        GOOS=$GOOS GOARCH=$GOARCH go build -o "$output" .
        
        if [ $? -eq 0 ]; then
            log_success "  ✓ ${GOOS}/${GOARCH} 构建成功"
        else
            log_error "  ✗ ${GOOS}/${GOARCH} 构建失败"
        fi
    done
    
    log_info "交叉编译完成，输出目录: dist/cross/"
}

# 发布构建
release_build() {
    local version=$(get_version)
    log_info "构建发布版本 v${version}..."
    
    check_dependencies
    
    # 运行测试
    log_info "运行测试..."
    go test ./...
    
    if [ $? -ne 0 ]; then
        log_error "测试失败，终止发布构建"
        exit 1
    fi
    
    # 构建生产版本
    local build_time=$(date -u '+%Y-%m-%d_%H:%M:%S')
    local git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    local ldflags="-s -w -X main.Version=${version} -X main.BuildTime=${build_time} -X main.GitCommit=${git_commit}"
    
    mkdir -p dist/release
    
    # 构建当前平台
    go build -ldflags "$ldflags" -trimpath -o "dist/release/${PROJECT_NAME}" .
    
    if [ $? -eq 0 ]; then
        log_success "发布构建成功: dist/release/${PROJECT_NAME}"
        log_info "版本: ${version}"
        log_info "构建时间: ${build_time}"
        log_info "Git Commit: ${git_commit}"
    else
        log_error "发布构建失败"
        exit 1
    fi
}

# Docker 构建
docker_build() {
    log_info "Docker 构建..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装"
        exit 1
    fi
    
    # 构建镜像
    docker build -t ${PROJECT_NAME}:latest .
    docker tag ${PROJECT_NAME}:latest ${PROJECT_NAME}:$(get_version)
    
    if [ $? -eq 0 ]; then
        log_success "Docker 构建成功"
        log_info "镜像标签: ${PROJECT_NAME}:latest"
        log_info "镜像标签: ${PROJECT_NAME}:$(get_version)"
    else
        log_error "Docker 构建失败"
        exit 1
    fi
}

# 运行所有测试
test_all() {
    log_info "运行所有测试..."
    
    # 单元测试
    log_info "运行单元测试..."
    go test -v ./...
    
    # 集成测试（如果有）
    if [ -d "test/integration" ]; then
        log_info "运行集成测试..."
        go test -v ./test/integration/...
    fi
    
    # 端到端测试（如果有）
    if [ -d "test/e2e" ]; then
        log_info "运行端到端测试..."
        go test -v ./test/e2e/...
    fi
    
    log_success "所有测试完成"
}

# 基准测试
bench() {
    log_info "运行基准测试..."
    
    go test -bench=. -benchmem ./...
    
    log_success "基准测试完成"
}

# 覆盖率报告
coverage() {
    log_info "生成覆盖率报告..."
    
    mkdir -p coverage
    
    # 运行测试并生成覆盖率数据
    go test -coverprofile=coverage/coverage.out ./...
    
    # 生成 HTML 报告
    go tool cover -html=coverage/coverage.out -o coverage/coverage.html
    
    # 显示覆盖率摘要
    local coverage_percent=$(go tool cover -func=coverage/coverage.out | grep total | awk '{print $3}')
    
    log_success "覆盖率报告生成完成"
    log_info "总覆盖率: ${coverage_percent}"
    log_info "HTML 报告: coverage/coverage.html"
    
    # 尝试打开报告（macOS）
    if command -v open &> /dev/null; then
        open coverage/coverage.html
    fi
}

# 性能分析构建
profile() {
    log_info "构建性能分析版本..."
    
    mkdir -p build/profile
    
    # CPU 分析构建
    go build -o build/profile/${PROJECT_NAME}-cpu -gcflags="-cpuprofile=build/profile/cpu.prof" .
    
    # 内存分析构建
    go build -o build/profile/${PROJECT_NAME}-mem -gcflags="-memprofile=build/profile/mem.prof" .
    
    log_success "性能分析构建完成"
    log_info "CPU 分析: build/profile/${PROJECT_NAME}-cpu"
    log_info "内存分析: build/profile/${PROJECT_NAME}-mem"
}

# 二进制大小分析
size_analysis() {
    log_info "二进制大小分析..."
    
    # 构建不同版本
    log_info "构建标准版本..."
    go build -o build/${PROJECT_NAME}-standard .
    
    log_info "构建优化版本..."
    go build -ldflags="-s -w" -o build/${PROJECT_NAME}-optimized .
    
    log_info "构建压缩版本..."
    go build -ldflags="-s -w" -gcflags="-trimpath" -o build/${PROJECT_NAME}-compressed .
    
    # 显示大小对比
    echo ""
    echo -e "${CYAN}二进制大小对比:${RESET}"
    echo "标准版本:     $(ls -lh build/${PROJECT_NAME}-standard | awk '{print $5}')"
    echo "优化版本:     $(ls -lh build/${PROJECT_NAME}-optimized | awk '{print $5}')"
    echo "压缩版本:     $(ls -lh build/${PROJECT_NAME}-compressed | awk '{print $5}')"
    
    # 分析符号表（如果可用）
    if command -v nm &> /dev/null; then
        echo ""
        echo -e "${CYAN}符号表分析:${RESET}"
        echo "标准版本符号数:   $(nm build/${PROJECT_NAME}-standard | wc -l)"
        echo "优化版本符号数:   $(nm build/${PROJECT_NAME}-optimized | wc -l)"
    fi
    
    # 使用 upx 压缩（如果可用）
    if command -v upx &> /dev/null; then
        log_info "使用 UPX 压缩..."
        cp build/${PROJECT_NAME}-optimized build/${PROJECT_NAME}-upx
        upx --best --lzma build/${PROJECT_NAME}-upx
        
        echo "UPX 压缩版本: $(ls -lh build/${PROJECT_NAME}-upx | awk '{print $5}')"
    fi
}

# 安全扫描
security_check() {
    log_info "运行安全扫描..."
    
    # Go 安全扫描（如果安装了 gosec）
    if command -v gosec &> /dev/null; then
        log_info "运行 gosec 安全扫描..."
        gosec ./...
    else
        log_warning "gosec 未安装，跳过安全扫描"
    fi
    
    # 依赖漏洞扫描（如果安装了 nancy）
    if command -v nancy &> /dev/null; then
        log_info "运行 nancy 依赖漏洞扫描..."
        go list -json -m all | nancy sleuth
    else
        log_warning "nancy 未安装，跳过依赖漏洞扫描"
    fi
    
    log_success "安全扫描完成"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        quick-build)
            quick_build "$@"
            ;;
        dev-build)
            dev_build "$@"
            ;;
        cross-compile)
            cross_compile "$@"
            ;;
        release-build)
            release_build "$@"
            ;;
        docker-build)
            docker_build "$@"
            ;;
        test-all)
            test_all "$@"
            ;;
        bench)
            bench "$@"
            ;;
        coverage)
            coverage "$@"
            ;;
        profile)
            profile "$@"
            ;;
        size-analysis)
            size_analysis "$@"
            ;;
        security-check)
            security_check "$@"
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