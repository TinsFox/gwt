# 快速开始指南

本指南帮助新开发者快速搭建开发环境并开始贡献代码。

## 🚀 5分钟快速上手

### 步骤1：环境检查
```bash
# 检查 Go 版本（需要 1.21+）
go version

# 检查 Git 版本（需要 2.6+）
git --version

# 检查 Make 工具
make --version
```

### 步骤2：克隆和初始化
```bash
# 克隆项目
git clone https://github.com/tinsfox/gwt.git
cd gwt

# 初始化项目
make init

# 验证环境
make build
./build/gwt --version
```

### 步骤3：运行第一个命令
```bash
# 查看帮助
./build/gwt --help

# 查看当前目录的 worktree
./build/gwt list

# 创建测试 worktree
./build/gwt create test-branch

# 查看结果
./build/gwt list
```

### 步骤4：运行测试
```bash
# 运行所有测试
make test

# 运行特定测试
go test -v ./internal/git -run TestGetWorktrees
```

## 📋 开发工作流

### 日常开发流程

```bash
# 1. 开始工作前
make dev          # 启动热重载开发模式

# 2. 编写代码
# ... 修改代码 ...

# 3. 验证更改
make check        # 运行代码检查
make test         # 运行测试
make build        # 构建项目

# 4. 提交代码
git add .
git commit -m "feat: 添加新功能"
```

### 添加新功能

```bash
# 1. 创建功能分支
git checkout -b feature/my-new-feature

# 2. 实现功能
# ... 编写代码 ...

# 3. 添加测试
# ... 编写测试 ...

# 4. 验证功能
make test-coverage  # 检查测试覆盖率
make build         # 确保能正常构建

# 5. 提交更改
git add .
git commit -m "feat: 实现新功能"
```

### 修复 Bug

```bash
# 1. 创建修复分支
git checkout -b fix/issue-description

# 2. 重现问题
# ... 确认问题存在 ...

# 3. 修复代码
# ... 修复问题 ...

# 4. 添加回归测试
# ... 确保问题不再发生 ...

# 5. 验证修复
make test  # 运行所有测试
make build # 确保构建成功

# 6. 提交修复
git add .
git commit -m "fix: 修复问题描述"
```

## 🛠️ 常用命令速查

### 构建命令
```bash
make build        # 构建当前平台
make build-all    # 构建所有平台
make clean        # 清理构建文件
make release      # 构建发布版本
```

### 测试命令
```bash
make test         # 运行所有测试
make test-coverage # 生成覆盖率报告
make bench        # 运行基准测试
```

### 代码质量
```bash
make check        # 运行所有检查
make fmt          # 格式化代码
make vet          # 静态检查
make lint         # 代码 lint
```

### 开发工具
```bash
make dev          # 开发模式（热重载）
make run          # 构建并运行
make install      # 安装到系统
```

## 📁 项目结构速览

```
gwt/
├── cmd/                    # 命令实现
│   ├── list.go            # list 命令
│   ├── create.go          # create 命令
│   └── ...
├── internal/              # 内部包
│   ├── git/               # Git 操作
│   ├── editor/            # 编辑器集成
│   └── ui/                # 用户界面
├── main.go               # 程序入口
├── Makefile              # 构建配置
└── go.mod                # 依赖管理
```

## 🎯 第一个贡献

### 选择一个简单的任务

查看带有 `good first issue` 标签的 issue，这些通常包括：

- 文档改进
- 小的功能增强
- 代码注释完善
- 测试用例补充

### 贡献示例：改进错误信息

```go
// 原始代码
cmd/create.go
return fmt.Errorf("创建失败")

// 改进后
return fmt.Errorf("创建 worktree 失败: %w", err)
```

### 贡献示例：添加测试

```go
// internal/git/repository_test.go
func TestBranchExists(t *testing.T) {
    repo := setupTestRepo(t)
    
    // 测试存在的分支
    exists, err := repo.BranchExists("main")
    assert.NoError(t, err)
    assert.True(t, exists)
    
    // 测试不存在的分支
    exists, err = repo.BranchExists("non-existent")
    assert.NoError(t, err)
    assert.False(t, exists)
}
```

## 🔍 调试技巧

### 基本调试
```bash
# 查看详细输出
./build/gwt --verbose list

# 使用调试模式
export GWT_DEBUG=1
./build/gwt list
```

### 日志调试
```go
// 在代码中添加日志
import "log"

func YourFunction() {
    log.Printf("调试信息: %v", someVariable)
    // ... 你的代码 ...
}
```

### 使用 Delve 调试器
```bash
# 安装 delve
go install github.com/go-delve/delve/cmd/dlv@latest

# 启动调试
dlv debug main.go -- list

# 在调试器中
(dlv) break main.main
(dlv) continue
(dlv) print variable
```

## 📚 学习资源

### 必读文档
- [CONTRIBUTING.md](../CONTRIBUTING.md) - 贡献指南
- [DEVELOPMENT.md](../DEVELOPMENT.md) - 详细开发文档
- [BUILD_GUIDE.md](BUILD_GUIDE.md) - 构建指南

### 相关技术
- [Go 官方文档](https://golang.org/doc/)
- [Cobra CLI 框架](https://github.com/spf13/cobra)
- [Git Worktree 文档](https://git-scm.com/docs/git-worktree)

### 代码示例
- 查看 `cmd/` 目录下的命令实现
- 查看 `internal/git/` 目录的 Git 操作封装
- 查看 `internal/editor/` 目录的编辑器集成

## 💡 常见问题

### Q: make build 失败怎么办？
```bash
# 尝试清理和重新构建
make clean
make init
make build

# 检查 Go 版本
go version  # 需要 1.21+
```

### Q: 测试失败怎么办？
```bash
# 查看详细错误
make test

# 运行特定测试
go test -v ./internal/git -run TestSpecificFunction

# 检查是否在 Git 仓库中
git status
```

### Q: 如何添加新命令？
```bash
# 1. 在 cmd/ 目录创建新文件
# 2. 参考现有命令的实现
# 3. 在 root.go 中注册命令
# 4. 添加测试
# 5. 更新文档
```

### Q: 如何调试 Git 操作？
```bash
# 启用 Git 调试
export GIT_TRACE=1
export GIT_CURL_VERBOSE=1

# 运行命令
./build/gwt list
```

## 🎉 下一步

完成快速开始后，您可以：

1. **阅读详细文档**
   - [开发文档](../DEVELOPMENT.md)
   - [构建指南](BUILD_GUIDE.md)
   - [贡献指南](../CONTRIBUTING.md)

2. **选择贡献任务**
   - 查看 [Good First Issues](https://github.com/tinsfox/gwt/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
   - 改进文档
   - 添加测试用例
   - 修复已知问题

3. **深入开发**
   - 实现新功能
   - 优化性能
   - 改进用户体验

**欢迎加入 Git Worktree CLI 开发团队！** 🚀