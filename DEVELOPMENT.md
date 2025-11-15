# 开发文档

本文档为开发者提供详细的开发环境搭建、架构设计、代码规范和开发流程指导。

## 📚 目录

1. [环境搭建](#环境搭建)
2. [架构设计](#架构设计)
3. [开发流程](#开发流程)
4. [代码规范](#代码规范)
5. [测试指南](#测试指南)
6. [构建发布](#构建发布)
7. [调试技巧](#调试技巧)
8. [性能优化](#性能优化)
9. [故障排除](#故障排除)

## 🔧 环境搭建

### 基础要求

| 工具 | 最低版本 | 推荐版本 | 安装链接 |
|------|----------|----------|----------|
| Go | 1.21 | 最新稳定版 | [下载地址](https://golang.org/dl/) |
| Git | 2.6+ | 最新版 | [下载地址](https://git-scm.com/downloads) |
| Make | 任意版本 | 最新版 | 系统包管理器安装 |

### 开发工具推荐

#### 编辑器/IDE
- **VS Code** + Go 扩展
- **GoLand** (JetBrains)
- **Vim/Neovim** + vim-go 插件

#### 必备工具
```bash
# 安装开发工具
make tools

# 或者手动安装
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/lint/golint@latest
go install github.com/golang/mock/mockgen@latest
go install github.com/air-verse/air@latest
```

### 环境配置

#### Go 环境变量
```bash
# ~/.bashrc 或 ~/.zshrc
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GO111MODULE=on
export GOPROXY=https://goproxy.io,direct
```

#### Git 配置
```bash
# 配置用户信息
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 配置别名
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
```

### 项目初始化

```bash
# 克隆项目
git clone https://github.com/tinsfox/gwt.git
cd gwt

# 下载依赖
make init

# 验证环境
make build
./build/gwt --version
```

## 🏗️ 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                        CLI Layer                           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │  Root   │ │  List   │ │ Create  │ │  Edit   │          │
│  │ Command │ │ Command │ │ Command │ │ Command │          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
└─────────────────────────┬───────────────────────────────────┘
                         │
┌─────────────────────────▼───────────────────────────────────┐
│                    Internal Layer                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       │
│  │ Git Package  │ │Editor Package│ │  UI Package  │       │
│  │              │ │              │ │              │       │
│  │- Repository  │ │- Detection   │ │- Colors      │       │
│  │- Worktree    │ │- Launch      │ │- Formatting  │       │
│  │- Branch      │ │- Config      │ │- Tables      │       │
│  └──────────────┘ └──────────────┘ └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### 包结构

```
gwt/
├── main.go                 # 程序入口点
├── cmd/                    # 命令行接口层
│   ├── root.go            # 根命令定义
│   ├── list.go            # list 命令实现
│   ├── create.go          # create 命令实现
│   ├── remove.go          # remove 命令实现
│   ├── edit.go            # edit 命令实现
│   ├── browse.go          # browse 命令实现
│   ├── switch.go          # switch 命令实现
│   ├── prune.go           # prune 命令实现
│   ├── config.go          # config 命令实现
│   ├── tutorial.go        # tutorial 命令实现
│   └── completion.go      # completion 命令实现
├── internal/              # 内部业务逻辑层
│   ├── git/               # Git 操作封装
│   │   ├── repository.go  # 仓库操作
│   │   ├── worktree.go    # worktree 操作
│   │   └── branch.go      # 分支操作
│   ├── editor/            # 编辑器集成
│   │   ├── detector.go    # 编辑器检测
│   │   ├── launcher.go    # 编辑器启动
│   │   └── config.go      # 编辑器配置
│   └── ui/                # 用户界面
│       ├── colors.go      # 颜色主题
│       ├── table.go       # 表格输出
│       └── format.go      # 格式化工具
└── pkg/                   # 可复用工具包
    └── utils/             # 通用工具函数
```

### 核心组件

#### 1. Git 操作封装 (`internal/git/`)

```go
// Repository 封装 Git 仓库操作
type Repository struct {
    Path   string
    gitDir string
}

// 主要方法
- OpenRepository(path string) (*Repository, error)
- GetWorktrees() ([]WorktreeInfo, error)
- CreateWorktree(options CreateWorktreeOptions) (*Worktree, error)
- RemoveWorktree(path string) error
- BranchExists(branch string) (bool, error)
```

#### 2. 编辑器集成 (`internal/editor/`)

```go
// EditorInfo 编辑器信息
type EditorInfo struct {
    Name              string
    Command           string
    SupportsNewWindow bool
    NewWindowFlag     string
    SupportsWait      bool
    WaitFlag          string
}

// 主要方法
- DetectEditor(editorName string) (*EditorInfo, error)
- GetAvailableEditors() []*EditorInfo
- LaunchEditor(editor *EditorInfo, path string, options LaunchOptions) error
```

#### 3. UI 组件 (`internal/ui/`)

```go
// 颜色函数
var ColorSuccess = color.New(color.FgGreen, color.Bold).SprintFunc()
var ColorError = color.New(color.FgRed, color.Bold).SprintFunc()
var ColorWarning = color.New(color.FgYellow, color.Bold).SprintFunc()

// 表格输出
func RenderWorktreeTable(worktrees []git.WorktreeInfo) string
func RenderSimpleList(worktrees []git.WorktreeInfo) string
```

## 🔄 开发流程

### 1. 需求分析
- 阅读相关 issue 和需求文档
- 分析技术可行性
- 设计实现方案
- 评估影响范围

### 2. 设计阶段
- 设计 API 接口（如果需要）
- 设计数据结构
- 设计用户交互流程
- 编写设计文档（复杂功能）

### 3. 编码实现
- 创建功能分支
- 实现核心逻辑
- 添加错误处理
- 编写单元测试
- 添加集成测试

### 4. 测试验证
- 运行自动化测试
- 手动测试验证
- 性能测试（如需要）
- 边界条件测试

### 5. 代码审查
- 自我审查
- 提交 PR 请求审查
- 根据反馈修改
- 最终合并

## 📏 代码规范

### 命名规范

#### 包命名
- 使用小写字母
- 不使用下划线或混合大小写
- 简短而有意义

```go
// Good
package git
package editor
package ui

// Bad
package GitPackage
package editor_utils
package userInterface
```

#### 文件命名
- 使用小写字母和下划线
- 反映文件内容

```go
// Good
repository.go
worktree_manager.go
color_theme.go

// Bad
Repository.go
worktreemanager.go
colorTheme.go
```

#### 函数命名
- 使用驼峰命名法
- 导出函数以大写字母开头
- 私有函数以小写字母开头
- 名字要描述函数的作用

```go
// Good
func GetWorktrees() ([]WorktreeInfo, error)
func renderTable(data [][]string) string
func detectAvailableEditor() *EditorInfo

// Bad
func getw() ([]WorktreeInfo, error)
func Render(data [][]string) string
func detect() *EditorInfo
```

#### 变量命名
- 使用驼峰命名法
- 简短而有意义
- 避免单字母变量（循环除外）

```go
// Good
var worktreeInfo WorktreeInfo
var editorPath string
var isDirty bool

// Bad
var w WorktreeInfo
var ep string
var dirty bool
```

### 代码格式

#### 基本格式
```go
// 使用 gofmt 格式化
// 每行最大长度 100 字符
// 使用制表符缩进
// 左大括号不换行
```

#### 错误处理
```go
// 返回错误而不是 panic
func DoSomething() error {
    result, err := operation()
    if err != nil {
        return fmt.Errorf("操作失败: %w", err)
    }
    
    // 使用错误包装提供上下文
    if err := process(result); err != nil {
        return fmt.Errorf("处理结果失败: %w", err)
    }
    
    return nil
}
```

#### 日志记录
```go
// 使用适当的日志级别
log.Debug("调试信息")
log.Info("一般信息")
log.Warn("警告信息")
log.Error("错误信息")

// 结构化日志
log.WithFields(log.Fields{
    "worktree": worktreePath,
    "branch": branchName,
}).Info("创建 worktree")
```

## 🧪 测试指南

### 测试策略

#### 单元测试
- 测试单个函数和方法
- 使用 mock 隔离外部依赖
- 覆盖正常和异常情况
- 测试边界条件

```go
func TestCreateWorktree(t *testing.T) {
    tests := []struct {
        name        string
        branch      string
        path        string
        expectError bool
    }{
        {"正常创建", "feature/test", "./test-worktree", false},
        {"空分支名", "", "./test", true},
        {"无效路径", "test", "/invalid/path", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := setupTestRepo(t)
            defer cleanupTestRepo(t)
            
            worktree, err := repo.CreateWorktree(git.CreateWorktreeOptions{
                Branch: tt.branch,
                Path:   tt.path,
            })
            
            if tt.expectError {
                assert.Error(t, err)
                assert.Nil(t, worktree)
            } else {
                assert.NoError(t, err)
                assert.NotNil(t, worktree)
                assert.Equal(t, tt.branch, worktree.Branch)
            }
        })
    }
}
```

#### 集成测试
- 测试组件之间的交互
- 使用真实的 Git 仓库
- 测试完整的用户流程

```go
func TestWorktreeLifecycle(t *testing.T) {
    // 创建测试仓库
    repo := setupRealRepo(t)
    defer cleanupRepo(t)
    
    // 测试创建 worktree
    worktree, err := repo.CreateWorktree("feature/test", "./test-worktree")
    require.NoError(t, err)
    
    // 测试列出 worktree
    worktrees, err := repo.GetWorktrees()
    require.NoError(t, err)
    assert.Contains(t, worktrees, worktree)
    
    // 测试删除 worktree
    err = repo.RemoveWorktree(worktree.Path)
    require.NoError(t, err)
}
```

#### 端到端测试
- 测试完整的命令行接口
- 验证用户交互
- 测试错误处理

```go
func TestCreateCommand(t *testing.T) {
    // 设置测试环境
    setupE2ETest(t)
    
    // 执行命令
    cmd := exec.Command("./build/gwt", "create", "test-branch")
    output, err := cmd.CombinedOutput()
    
    // 验证结果
    assert.NoError(t, err)
    assert.Contains(t, string(output), "worktree 创建成功")
    
    // 验证 worktree 存在
    assert.DirExists(t, "./test-branch")
}
```

### Mock 使用

```go
// 定义接口
type GitRepository interface {
    GetWorktrees() ([]WorktreeInfo, error)
    CreateWorktree(options CreateWorktreeOptions) (*Worktree, error)
}

// 生成 mock
go generate ./...

// 在测试中使用
func TestWithMock(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    
    mockRepo := NewMockGitRepository(ctrl)
    mockRepo.EXPECT().
        CreateWorktree(gomock.Any()).
        Return(&Worktree{Path: "./test", Branch: "test"}, nil)
    
    // 使用 mock 进行测试
    result, err := mockRepo.CreateWorktree(options)
    assert.NoError(t, err)
    assert.Equal(t, "test", result.Branch)
}
```

## 📦 构建发布

### 本地构建

```bash
# 构建当前平台
make build

# 构建所有平台
make build-all

# 生成发布版本
make release

# 打包和校验
make package checksum
```

### 构建输出

```
dist/
├── gwt-linux-amd64          # Linux AMD64
├── gwt-linux-arm64          # Linux ARM64
├── gwt-darwin-amd64         # macOS AMD64
├── gwt-darwin-arm64         # macOS ARM64
├── gwt-windows-amd64.exe    # Windows AMD64
├── gwt-linux-amd64.tar.gz   # 压缩包
├── gwt-darwin-amd64.zip     # 压缩包
└── checksums.txt             # 校验和
```

### Docker 构建

```bash
# 构建 Docker 镜像
make docker-build

# 运行容器
make docker-run
```

## 🐛 调试技巧

### 日志调试

```go
// 添加调试日志
log.Debugf("正在创建 worktree: branch=%s, path=%s", branch, path)

// 条件日志
if verbose {
    log.Infof("详细模式: 执行命令: git %v", args)
}

// 错误日志
if err != nil {
    log.Errorf("创建 worktree 失败: %v", err)
    return fmt.Errorf("创建 worktree 失败: %w", err)
}
```

### 调试工具

```bash
# 使用 delve 调试器
dlv debug main.go -- list

# 添加调试标志构建
go build -gcflags="-N -l" -o build/gwt-debug

# 使用 gdb
gdb ./build/gwt-debug
```

### 性能分析

```go
// CPU 分析
import _ "net/http/pprof"

go func() {
    log.Println(http.ListenAndServe("localhost:6060", nil))
}()

// 内存分析
import "runtime/pprof"

f, _ := os.Create("mem.prof")
defer f.Close()
pprof.WriteHeapProfile(f)
```

## ⚡ 性能优化

### 优化策略

1. **减少系统调用**
   - 批量执行 Git 命令
   - 缓存频繁查询的结果
   - 使用 Git 的批量操作

2. **并发处理**
   - 并行处理多个 worktree
   - 使用 goroutine 处理 I/O 操作
   - 合理控制并发数量

3. **内存优化**
   - 及时释放大对象
   - 使用对象池
   - 避免内存泄漏

### 性能测试

```go
func BenchmarkGetWorktrees(b *testing.B) {
    repo := setupBenchmarkRepo(b)
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        worktrees, err := repo.GetWorktrees()
        if err != nil {
            b.Fatal(err)
        }
        _ = worktrees
    }
}
```

## 🔍 故障排除

### 常见问题

#### 1. Git 命令失败
```bash
# 检查 Git 版本
git --version

# 检查 Git 配置
git config --list

# 启用 Git 调试
GIT_TRACE=1 ./build/gwt list
```

#### 2. 构建失败
```bash
# 清理构建缓存
make clean

# 更新依赖
make deps

# 详细构建输出
go build -v ./...
```

#### 3. 测试失败
```bash
# 运行特定测试
go test -v ./internal/git -run TestCreateWorktree

# 测试覆盖率
go test -cover ./...

# 竞态检测
go test -race ./...
```

#### 4. 编辑器检测失败
```bash
# 检查 PATH
echo $PATH

# 检查编辑器安装
which code vim nvim

# 手动指定编辑器
./build/gwt edit main -e /usr/bin/vim
```

### 调试环境变量

```bash
# Git 调试
export GIT_TRACE=1
export GIT_CURL_VERBOSE=1

# Go 调试
export GODEBUG=gctrace=1
export GOPROXY=https://goproxy.io,direct

# 程序调试
export GWT_DEBUG=1
export GWT_VERBOSE=1
```

---

## 📞 获取帮助

- [GitHub Issues](https://github.com/tinsfox/gwt/issues) - 问题报告
- [GitHub Discussions](https://github.com/tinsfox/gwt/discussions) - 一般讨论
- [贡献指南](CONTRIBUTING.md) - 贡献代码

** Happy Coding! ** 🚀