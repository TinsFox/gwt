# Git Worktree CLI Makefile
# 支持跨平台构建、测试、安装和发布

# 项目信息
PROJECT_NAME := gwt
PACKAGE_NAME := github.com/yourusername/git-worktree-cli
VERSION := 0.1.1
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# 构建变量
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT)"
BUILD_FLAGS := -trimpath

# 目标平台
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

# 输出目录
DIST_DIR := dist
BUILD_DIR := build
COVERAGE_DIR := coverage

# Go 相关命令
GOCMD := go
GOBUILD := $(GOCMD) build
GOCLEAN := $(GOCMD) clean
GOTEST := $(GOCMD) test
GOGET := $(GOCMD) get
GOMOD := $(GOCMD) mod
GOFMT := gofmt
GOVET := $(GOCMD) vet
GOLINT := golint

# 默认目标
.DEFAULT_GOAL := help

# 颜色输出
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
RESET := \033[0m

## help: 显示帮助信息
.PHONY: help
help: ## 显示可用的 make 目标
	@echo "$(CYAN)Git Worktree CLI - Makefile$(RESET)"
	@echo "$(BLUE)===========================$(RESET)"
	@echo ""
	@echo "$(GREEN)可用目标:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)使用示例:$(RESET)"
	@echo "  make build          # 构建当前平台"
	@echo "  make build-all      # 构建所有平台"
	@echo "  make test           # 运行测试"
	@echo "  make install        # 安装到系统"
	@echo "  make release        # 构建发布版本"

## info: 显示项目信息
.PHONY: info
info: ## 显示项目构建信息
	@echo "$(CYAN)项目信息:$(RESET)"
	@echo "  项目名称: $(PROJECT_NAME)"
	@echo "  版本: $(VERSION)"
	@echo "  构建时间: $(BUILD_TIME)"
	@echo "  Git Commit: $(GIT_COMMIT)"
	@echo "  包名: $(PACKAGE_NAME)"
	@echo ""
	@echo "$(CYAN)Go 环境:$(RESET)"
	@go version
	@echo "  GOOS: $(shell go env GOOS)"
	@echo "  GOARCH: $(shell go env GOARCH)"
	@echo "  GOROOT: $(shell go env GOROOT)"
	@echo "  GOPATH: $(shell go env GOPATH)"

## init: 初始化项目依赖
.PHONY: init
init: ## 下载并初始化项目依赖
	@echo "$(BLUE)初始化项目依赖...$(RESET)"
	@$(GOMOD) download
	@$(GOMOD) tidy
	@echo "$(GREEN)依赖初始化完成$(RESET)"

## deps: 更新依赖
.PHONY: deps
deps: ## 更新项目依赖
	@echo "$(BLUE)更新依赖...$(RESET)"
	@$(GOMOD) tidy
	@$(GOMOD) verify
	@echo "$(GREEN)依赖更新完成$(RESET)"

## fmt: 格式化代码
.PHONY: fmt
fmt: ## 格式化 Go 代码
	@echo "$(BLUE)格式化代码...$(RESET)"
	@$(GOFMT) -w .
	@echo "$(GREEN)代码格式化完成$(RESET)"

## vet: 静态检查
.PHONY: vet
vet: ## 运行 go vet 静态检查
	@echo "$(BLUE)运行静态检查...$(RESET)"
	@$(GOVET) ./...
	@echo "$(GREEN)静态检查完成$(RESET)"

## lint: 代码 lint
.PHONY: lint
lint: ## 运行 golint
	@echo "$(BLUE)运行代码 lint...$(RESET)"
	@if command -v golint >/dev/null 2>&1; then \
		golint ./...; \
	else \
		echo "$(YELLOW)golint 未安装，跳过...$(RESET)"; \
	fi

## check: 运行所有检查
.PHONY: check
check: fmt vet lint ## 运行所有代码检查
	@echo "$(GREEN)所有检查完成$(RESET)"

## test: 运行测试
.PHONY: test
test: ## 运行单元测试
	@echo "$(BLUE)运行测试...$(RESET)"
	@$(GOTEST) -v ./...

## test-coverage: 运行测试并生成覆盖率报告
.PHONY: test-coverage
test-coverage: ## 运行测试并生成覆盖率报告
	@echo "$(BLUE)运行测试并生成覆盖率报告...$(RESET)"
	@mkdir -p $(COVERAGE_DIR)
	@$(GOTEST) -v -coverprofile=$(COVERAGE_DIR)/coverage.out ./...
	@$(GOCMD) tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@echo "$(GREEN)覆盖率报告生成完成: $(COVERAGE_DIR)/coverage.html$(RESET)"

## bench: 运行基准测试
.PHONY: bench
bench: ## 运行基准测试
	@echo "$(BLUE)运行基准测试...$(RESET)"
	@$(GOTEST) -bench=. -benchmem ./...

## build: 构建当前平台
.PHONY: build
build: check ## 构建当前平台的二进制文件
	@echo "$(BLUE)构建 $(PROJECT_NAME) $(VERSION)...$(RESET)"
	@mkdir -p $(BUILD_DIR)
	@$(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o $(BUILD_DIR)/$(PROJECT_NAME) .
	@echo "$(GREEN)构建完成: $(BUILD_DIR)/$(PROJECT_NAME)$(RESET)"
	@echo "$(CYAN)文件大小:$(RESET)"
	@ls -lh $(BUILD_DIR)/$(PROJECT_NAME)

## build-all: 构建所有平台
.PHONY: build-all
build-all: check ## 构建所有支持的平台
	@echo "$(BLUE)构建所有平台...$(RESET)"
	@mkdir -p $(DIST_DIR)
	@for platform in $(PLATFORMS); do \
		GOOS=$${platform%/*} GOARCH=$${platform#*/} ; \
		output_name=$(PROJECT_NAME)-$${GOOS}-$${GOARCH} ; \
		if [ "$${GOOS}" = "windows" ]; then \
			output_name="$${output_name}.exe" ; \
		fi ; \
		echo "$(YELLOW)构建 $${GOOS}/$${GOARCH}...$(RESET)" ; \
		GOOS=$${GOOS} GOARCH=$${GOARCH} $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o $(DIST_DIR)/$${output_name} . ; \
		if [ $$? -ne 0 ]; then \
			echo "$(RED)构建 $${GOOS}/$${GOARCH} 失败$(RESET)" ; \
			exit 1 ; \
		fi ; \
	done
	@echo "$(GREEN)所有平台构建完成$(RESET)"
	@echo "$(CYAN)构建产物:$(RESET)"
	@ls -la $(DIST_DIR)/

## install: 安装到系统
.PHONY: install
install: build ## 安装到系统 PATH
	@echo "$(BLUE)安装 $(PROJECT_NAME)...$(RESET)"
	@install -d $(DESTDIR)/usr/local/bin
	@install -m 755 $(BUILD_DIR)/$(PROJECT_NAME) $(DESTDIR)/usr/local/bin/
	@echo "$(GREEN)安装完成: /usr/local/bin/$(PROJECT_NAME)$(RESET)"
	@echo "$(YELLOW)请确保 /usr/local/bin 在您的 PATH 中$(RESET)"

## uninstall: 从系统卸载
.PHONY: uninstall
uninstall: ## 从系统卸载
	@echo "$(BLUE)卸载 $(PROJECT_NAME)...$(RESET)"
	@rm -f $(DESTDIR)/usr/local/bin/$(PROJECT_NAME)
	@echo "$(GREEN)卸载完成$(RESET)"

## clean: 清理构建文件
.PHONY: clean
clean: ## 清理构建文件和缓存
	@echo "$(BLUE)清理构建文件...$(RESET)"
	@rm -rf $(BUILD_DIR) $(DIST_DIR) $(COVERAGE_DIR)
	@$(GOCLEAN) -cache
	@echo "$(GREEN)清理完成$(RESET)"

## run: 运行程序
.PHONY: run
run: build ## 构建并运行程序
	@echo "$(BLUE)运行 $(PROJECT_NAME)...$(RESET)"
	@$(BUILD_DIR)/$(PROJECT_NAME)

## dev: 开发模式运行
.PHONY: dev
dev: ## 开发模式运行（带热重载）
	@echo "$(BLUE)开发模式运行...$(RESET)"
	@if command -v air >/dev/null 2>&1; then \
		air; \
	else \
		echo "$(YELLOW)air 未安装，使用普通运行模式...$(RESET)"; \
		make run; \
	fi

## docker-build: Docker 构建
.PHONY: docker-build
docker-build: ## 使用 Docker 构建
	@echo "$(BLUE)Docker 构建...$(RESET)"
	@docker build -t $(PROJECT_NAME):$(VERSION) .
	@docker tag $(PROJECT_NAME):$(VERSION) $(PROJECT_NAME):latest
	@echo "$(GREEN)Docker 构建完成$(RESET)"

## docker-run: Docker 运行
.PHONY: docker-run
docker-run: docker-build ## 使用 Docker 运行
	@echo "$(BLUE)Docker 运行...$(RESET)"
	@docker run --rm -it $(PROJECT_NAME):latest

## release: 构建发布版本
.PHONY: release
release: clean test build-all ## 构建发布版本
	@echo "$(BLUE)构建发布版本...$(RESET)"
	@echo "$(GREEN)发布版本构建完成$(RESET)"
	@echo "$(CYAN)版本: $(VERSION)$(RESET)"
	@echo "$(CYAN)Git Commit: $(GIT_COMMIT)$(RESET)"
	@echo "$(CYAN)构建时间: $(BUILD_TIME)$(RESET)"
	@echo "$(CYAN)发布文件:$(RESET)"
	@ls -la $(DIST_DIR)/

## package: 打包发布文件
.PHONY: package
package: release ## 打包发布文件
	@echo "$(BLUE)打包发布文件...$(RESET)"
	@cd $(DIST_DIR) && \
	for file in *; do \
		if [[ "$${file}" == *.exe ]]; then \
			zip "$${file%.exe}.zip" "$${file}"; \
		else \
			tar -czf "$${file}.tar.gz" "$${file}"; \
		fi; \
	done
	@echo "$(GREEN)打包完成$(RESET)"
	@echo "$(CYAN)打包文件:$(RESET)"
	@ls -la $(DIST_DIR)/*.{zip,tar.gz}

## checksum: 生成校验和
.PHONY: checksum
checksum: package ## 生成文件校验和
	@echo "$(BLUE)生成校验和...$(RESET)"
	@cd $(DIST_DIR) && \
	shasum -a 256 *.zip *.tar.gz > checksums.txt
	@echo "$(GREEN)校验和生成完成: $(DIST_DIR)/checksums.txt$(RESET)"

## snapshot: 创建快照版本
.PHONY: snapshot
snapshot: ## 创建开发快照版本
	@echo "$(BLUE)创建快照版本...$(RESET)"
	@mkdir -p $(BUILD_DIR)
	@$(GOBUILD) $(BUILD_FLAGS) -ldflags "-X main.Version=$(VERSION)-snapshot-$(GIT_COMMIT)" -o $(BUILD_DIR)/$(PROJECT_NAME)-snapshot .
	@echo "$(GREEN)快照版本创建完成: $(BUILD_DIR)/$(PROJECT_NAME)-snapshot$(RESET)"

## tools: 安装开发工具
.PHONY: tools
tools: ## 安装开发依赖工具
	@echo "$(BLUE)安装开发工具...$(RESET)"
	@go install golang.org/x/tools/cmd/goimports@latest
	@go install golang.org/x/lint/golint@latest
	@go install github.com/golang/mock/mockgen@latest
	@go install github.com/air-verse/air@latest
	@echo "$(GREEN)开发工具安装完成$(RESET)"

## proto: 生成 protobuf 代码（如果有）
.PHONY: proto
proto: ## 生成 protobuf 代码
	@echo "$(BLUE)生成 protobuf 代码...$(RESET)"
	@protoc --go_out=. --go_opt=paths=source_relative proto/*.proto
	@echo "$(GREEN)protobuf 代码生成完成$(RESET)"

## mock: 生成 mock 代码
.PHONY: mock
mock: ## 生成测试 mock 代码
	@echo "$(BLUE)生成 mock 代码...$(RESET)"
	@go generate ./...
	@echo "$(GREEN)mock 代码生成完成$(RESET)"

## docs: 生成文档
.PHONY: docs
docs: ## 生成项目文档
	@echo "$(BLUE)生成文档...$(RESET)"
	@if command -v godoc >/dev/null 2>&1; then \
		echo "文档服务器启动于 http://localhost:6060"; \
		godoc -http=:6060; \
	else \
		echo "$(YELLOW)godoc 未安装，跳过文档生成$(RESET)"; \
	fi

## serve-docs: 服务文档
.PHONY: serve-docs
serve-docs: ## 在本地服务文档
	@echo "$(BLUE)启动文档服务器...$(RESET)"
	@python3 -m http.server 8080 -d docs/ 2>/dev/null || python -m SimpleHTTPServer 8080

## completion: 生成自动补全脚本
.PHONY: completion
completion: build ## 生成 shell 自动补全脚本
	@echo "$(BLUE)生成自动补全脚本...$(RESET)"
	@mkdir -p $(BUILD_DIR)/completion
	@$(BUILD_DIR)/$(PROJECT_NAME) completion bash > $(BUILD_DIR)/completion/$(PROJECT_NAME).bash
	@$(BUILD_DIR)/$(PROJECT_NAME) completion zsh > $(BUILD_DIR)/completion/$(PROJECT_NAME).zsh
	@$(BUILD_DIR)/$(PROJECT_NAME) completion fish > $(BUILD_DIR)/completion/$(PROJECT_NAME).fish
	@echo "$(GREEN)自动补全脚本生成完成$(RESET)"
	@echo "$(CYAN)使用方式:$(RESET)"
	@echo "  Bash:  source $(BUILD_DIR)/completion/$(PROJECT_NAME).bash"
	@echo "  Zsh:   source $(BUILD_DIR)/completion/$(PROJECT_NAME).zsh"
	@echo "  Fish:  source $(BUILD_DIR)/completion/$(PROJECT_NAME).fish"

## ci: CI/CD 构建流程
.PHONY: ci
ci: init check test build ## CI/CD 构建流程
	@echo "$(GREEN)CI/CD 构建完成$(RESET)"

## watch: 文件变化监控
.PHONY: watch
watch: ## 监控文件变化并自动构建
	@echo "$(BLUE)监控文件变化...$(RESET)"
	@if command -v entr >/dev/null 2>&1; then \
		find . -name '*.go' | entr -r make build; \
	else \
		echo "$(YELLOW)entr 未安装，使用简单的文件监控...$(RESET)"; \
		while true; do \
			inotifywait -e modify,create,delete -r . --include='.*\.go$$' 2>/dev/null && make build; \
		done; \
	fi

## update-version: 更新版本号
.PHONY: update-version
update-version: ## 更新版本号 (用法: make update-version VERSION=1.0.0)
ifndef VERSION
	@echo "$(RED)错误: 请指定版本号$(RESET)"
	@echo "用法: make update-version VERSION=1.0.0"
	@exit 1
endif
	@echo "$(BLUE)更新版本号到 $(VERSION)...$(RESET)"
	@sed -i.bak 's/VERSION := .*/VERSION := $(VERSION)/' Makefile
	@rm -f Makefile.bak
	@echo "$(GREEN)版本号更新完成$(RESET)"

# 防止 Makefile 规则被当作文件
.PHONY: Makefile
