# 构建指南

本文档详细介绍 Git Worktree CLI 项目的构建系统、脚本使用方法和发布流程。

## 📋 目录

1. [构建系统概览](#构建系统概览)
2. [Makefile 目标详解](#makefile-目标详解)
3. [跨平台构建](#跨平台构建)
4. [Docker 构建](#docker-构建)
5. [发布流程](#发布流程)
6. [CI/CD 集成](#cicd-集成)
7. [构建优化](#构建优化)
8. [故障排除](#故障排除)

## 🔨 构建系统概览

### 构建工具链

| 工具 | 用途 | 版本要求 |
|------|------|----------|
| Make | 构建协调 | 3.8+ |
| Go | 编译器 | 1.21+ |
| Docker | 容器化构建 | 20.10+（可选） |

### 构建配置

**主配置文件：Makefile**
```makefile
# 项目信息
PROJECT_NAME := gwt
VERSION := 0.1.0
PACKAGE_NAME := github.com/tinsfox/gwt

# 构建参数
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT)"
BUILD_FLAGS := -trimpath

# 目标平台
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64
```

**版本信息注入**
```go
// main.go
var (
    Version   = "dev"
    BuildTime = "unknown" 
    GitCommit = "unknown"
)
```

## 🎯 Makefile 目标详解

### 基础构建目标

#### `make build` - 构建当前平台
```bash
# 执行流程
1. 运行代码检查 (make check)
2. 创建 build 目录
3. 执行 go build 编译
4. 输出构建信息

# 输出示例
$ make build
构建 gwt 0.1.0...
构建完成: build/gwt
文件大小:
-rwxr-xr-x  1 user  staff    11M  1月  15 10:30 build/gwt
```

#### `make build-all` - 构建所有平台
```bash
# 支持的平台
- linux/amd64    # Linux x86_64
- linux/arm64    # Linux ARM64
- darwin/amd64   # macOS x86_64
- darwin/arm64   # macOS ARM64 (M1/M2)
- windows/amd64  # Windows x86_64

# 输出结构
dist/
├── gwt-linux-amd64
├── gwt-linux-arm64  
├── gwt-darwin-amd64
├── gwt-darwin-arm64
└── gwt-windows-amd64.exe
```

#### `make release` - 构建发布版本
```bash
# 完整流程
1. 清理旧的构建文件
2. 运行完整测试
3. 构建所有平台版本
4. 显示发布信息

# 输出信息
发布版本构建完成
版本: 1.0.0
Git Commit: abc1234
构建时间: 2024-01-15 10:30:00
发布文件:
-rwxr-xr-x  1 user  staff    11M  gwt-linux-amd64
-rwxr-xr-x  1 user  staff    10M  gwt-darwin-amd64
...
```

### 代码质量目标

#### `make check` - 运行所有检查
```bash
# 包含的检查
1. make fmt    # 代码格式化
2. make vet    # 静态检查  
3. make lint   # 代码 lint

# 使用示例
$ make check
格式化代码...
代码格式化完成
运行静态检查...
静态检查完成
运行代码 lint...
代码 lint 完成
所有检查完成
```

#### `make test` - 运行测试
```bash
# 测试配置
go test -v ./...

# 覆盖率测试
make test-coverage

# 基准测试
make bench
```

#### `make test-coverage` - 生成覆盖率报告
```bash
# 输出文件
coverage/
├── coverage.out     # 覆盖率数据
└── coverage.html    # HTML 报告

# 查看报告
open coverage/coverage.html
```

### 开发辅助目标

#### `make run` - 构建并运行
```bash
# 等效于
make build && ./build/gwt
```

#### `make dev` - 开发模式
```bash
# 使用 air 热重载
# 需要安装: go install github.com/air-verse/air@latest

# 配置文件: .air.toml
# 监控文件变化，自动重新构建和运行
```

#### `make clean` - 清理构建文件
```bash
# 清理内容
- build/ 目录
- dist/ 目录  
- coverage/ 目录
- Go 构建缓存
```

## 🌍 跨平台构建

### 环境变量控制

```bash
# 手动指定目标平台
GOOS=linux GOARCH=amd64 make build
GOOS=darwin GOARCH=arm64 make build
GOOS=windows GOARCH=amd64 make build

# 支持的 GOOS 和 GOARCH 组合
GOOS: linux, darwin, windows
GOARCH: amd64, arm64, arm, 386
```

### 平台特定处理

```makefile
# Windows 构建特殊处理
ifeq ($(GOOS),windows)
    BINARY_NAME := $(PROJECT_NAME).exe
    PACKAGE_NAME := $(PROJECT_NAME)-$(VERSION)-windows-$(GOARCH).zip
else
    BINARY_NAME := $(PROJECT_NAME)
    PACKAGE_NAME := $(PROJECT_NAME)-$(VERSION)-$(GOOS)-$(GOARCH).tar.gz
endif
```

### 交叉编译示例

```bash
#!/bin/bash
# cross-compile.sh

PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

for platform in "${PLATFORMS[@]}"; do
    GOOS=${platform%/*}
    GOARCH=${platform#*/}
    
    output="dist/${GOOS}-${GOARCH}/gwt"
    if [ "$GOOS" = "windows" ]; then
        output="${output}.exe"
    fi
    
    echo "Building for $GOOS/$GOARCH..."
    GOOS=$GOOS GOARCH=$GOARCH go build -o "$output" .
done
```

## 🐳 Docker 构建

### Dockerfile

```dockerfile
# 多阶段构建
FROM golang:1.21-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache git make

# 设置工作目录
WORKDIR /build

# 复制依赖文件
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN make build

# 运行时镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache git bash

# 复制二进制文件
COPY --from=builder /build/build/gwt /usr/local/bin/gwt

# 设置入口点
ENTRYPOINT ["gwt"]
CMD ["--help"]
```

### Docker 构建命令

```bash
# 构建镜像
make docker-build
# 或
docker build -t gwt:latest .

# 运行容器
make docker-run
# 或
docker run --rm -it gwt:latest

# 挂载当前目录
docker run --rm -it -v $(pwd):/workspace gwt:latest
```

## 🚀 发布流程

### 版本管理

#### 语义化版本
```
MAJOR.MINOR.PATCH

MAJOR: 不兼容的API修改
MINOR: 向下兼容的功能性新增  
PATCH: 向下兼容的问题修正

示例: 1.2.3
```

#### 版本更新
```bash
# 更新版本号
make update-version VERSION=1.0.0

# 验证版本
./build/gwt --version
```

### 发布步骤

#### 1. 准备发布
```bash
# 确保在 main 分支
git checkout main
git pull origin main

# 创建发布分支
git checkout -b release/v1.0.0
```

#### 2. 更新版本和文档
```bash
# 更新版本号
make update-version VERSION=1.0.0

# 更新 CHANGELOG.md
# 更新相关文档
```

#### 3. 构建和测试
```bash
# 完整测试
make ci

# 构建发布版本
make release

# 验证构建结果
./dist/gwt-linux-amd64 --version
```

#### 4. 打包和校验
```bash
# 打包
make package

# 生成校验和
make checksum
```

#### 5. 创建 Git 标签
```bash
# 提交更改
git add .
git commit -m "chore: release v1.0.0"

# 创建标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 推送
git push origin main
git push origin v1.0.0
```

### 发布产物

```
dist/
├── gwt-linux-amd64
├── gwt-linux-arm64
├── gwt-darwin-amd64
├── gwt-darwin-arm64
├── gwt-windows-amd64.exe
├── gwt-linux-amd64.tar.gz
├── gwt-linux-arm64.tar.gz
├── gwt-darwin-amd64.zip
├── gwt-darwin-arm64.zip
├── gwt-windows-amd64.zip
└── checksums.txt
```

## 🔄 CI/CD 集成

### GitHub Actions 工作流

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: 1.21
      - run: make ci

  build:
    needs: test
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        arch: [amd64, arm64]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: 1.21
      - run: make build-all
      
  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/*
          generate_release_notes: true
```

### 自动化脚本

```bash
#!/bin/bash
# scripts/release.sh

set -e

# 参数检查
if [ $# -ne 1 ]; then
    echo "用法: $0 <版本号>"
    exit 1
fi

VERSION=$1

echo "开始发布 v${VERSION}..."

# 1. 更新版本号
make update-version VERSION=${VERSION}

# 2. 运行完整测试
make ci

# 3. 构建所有平台
make release

# 4. 打包和校验
make package checksum

# 5. 创建标签
git add .
git commit -m "chore: release v${VERSION}"
git tag -a v${VERSION} -m "Release version ${VERSION}"

echo "发布准备完成！"
echo "请执行: git push origin main v${VERSION}"
```

## ⚡ 构建优化

### 构建速度优化

```makefile
# 并行构建
MAKEFLAGS += -j$(shell nproc)

# 缓存利用
GOCACHE := $(HOME)/.cache/go-build
GOMODCACHE := $(HOME)/.cache/go-mod

# 增量构建
.PHONY: force
force:
	@touch main.go
```

### 二进制大小优化

```makefile
# 去除调试信息
LDFLAGS += -s -w

# 压缩二进制
UPX_FLAGS := --best --lzma

compress:
	upx $(UPX_FLAGS) $(BUILD_DIR)/$(PROJECT_NAME)
```

### 构建缓存

```bash
# 查看缓存状态
go env GOCACHE
go clean -cache -testcache -modcache

# 使用构建缓存
go build -buildmode=cache
```

## 🔍 故障排除

### 常见问题

#### 1. 构建失败：找不到包
```bash
# 解决方案
make init
go mod tidy
make clean
make build
```

#### 2. 交叉编译失败
```bash
# 检查 Go 版本
go version

# 验证平台支持
go tool dist list

# 手动指定平台
GOOS=linux GOARCH=amd64 go build
```

#### 3. 测试失败
```bash
# 详细测试输出
go test -v ./...

# 特定测试
go test -v ./internal/git -run TestCreateWorktree

# 竞态检测
go test -race ./...
```

#### 4. 权限问题
```bash
# 安装权限
sudo make install

# 文件权限
chmod +x scripts/*.sh
```

### 调试构建过程

```bash
# 详细输出
make VERBOSE=1 build

# 调试 Make
make -d build

# 显示命令
make SHELL='sh -x' build
```

### 性能分析

```bash
# 构建时间分析
time make build

# Go 构建分析
go build -x -v ./...

# 内存使用
/usr/bin/time -v make build-all
```

## 📊 构建指标

### 构建时间
| 目标 | 时间 | 说明 |
|------|------|------|
| make build | ~3s | 当前平台构建 |
| make build-all | ~15s | 所有平台构建 |
| make test | ~5s | 完整测试 |
| make release | ~25s | 完整发布流程 |

### 二进制大小
| 平台 | 大小 | 压缩后 |
|------|------|--------|
| Linux AMD64 | 11MB | 4.2MB |
| macOS AMD64 | 10MB | 4.0MB |
| Windows AMD64 | 11MB | 4.1MB |

---

## 📚 相关文档

- [开发指南](DEVELOPMENT.md) - 详细开发文档
- [贡献指南](CONTRIBUTING.md) - 贡献代码指南
- [安装脚本](scripts/install.sh) - 自动安装脚本

## 💡 最佳实践

1. **频繁构建**：开发过程中经常运行 `make build` 验证代码
2. **自动化测试**：提交代码前运行 `make test`
3. **代码检查**：使用 `make check` 保持代码质量
4. **版本管理**：遵循语义化版本规范
5. **文档同步**：代码变更时同步更新文档

**Happy Building!** 🚀