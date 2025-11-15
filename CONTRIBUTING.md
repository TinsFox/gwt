# 贡献指南

感谢您对 Git Worktree CLI 项目的关注！我们欢迎各种形式的贡献，包括代码、文档、测试、问题报告和功能建议。

## 🚀 快速开始

### 环境要求
- Go 1.21 或更高版本
- Git 2.6+（支持 worktree 功能）
- Make 工具（可选，用于使用 Makefile）

### 开发环境搭建

1. **Fork 并克隆项目**
```bash
git clone https://github.com/your-username/gwt.git
cd gwt
```

2. **安装依赖**
```bash
go mod download
make init  # 或者手动: go mod tidy
```

3. **验证环境**
```bash
make build
./build/gwt --version
```

## 📋 贡献类型

### 🐛 问题报告
- 使用 [Issue 模板](.github/ISSUE_TEMPLATE/bug_report.md)
- 提供详细的复现步骤
- 包含环境信息（操作系统、Go版本、Git版本）
- 添加相关日志和错误信息

### 💡 功能建议
- 使用 [功能请求模板](.github/ISSUE_TEMPLATE/feature_request.md)
- 描述清楚使用场景和预期行为
- 考虑向后兼容性
- 提供实现建议（如果有）

### 🔧 代码贡献
- 修复已知问题
- 实现新功能
- 优化性能
- 改进代码质量
- 添加测试用例

### 📚 文档贡献
- 修复文档错误
- 添加使用示例
- 改进代码注释
- 翻译文档

## 🔄 开发流程

### 1. 创建分支
```bash
git checkout -b feature/your-feature-name
# 或者
git checkout -b fix/issue-description
```

分支命名规范：
- `feature/功能描述` - 新功能
- `fix/问题描述` - Bug修复
- `docs/文档描述` - 文档更新
- `refactor/重构描述` - 代码重构
- `test/测试描述` - 测试相关

### 2. 开发规范

#### 代码风格
- 遵循 [Effective Go](https://golang.org/doc/effective_go.html)
- 使用 `gofmt` 格式化代码
- 使用 `golint` 检查代码质量
- 保持代码简洁和可读性

#### 提交信息
使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

类型说明：
- `feat`: 新功能
- `fix`: Bug修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

示例：
```
feat(list): 添加 JSON 输出格式支持

- 支持 --json 参数
- 提供结构化的 worktree 信息输出
- 便于脚本集成和自动化处理

Closes #123
```

### 3. 测试

#### 运行测试
```bash
# 运行所有测试
make test

# 运行测试并生成覆盖率报告
make test-coverage

# 运行基准测试
make bench
```

#### 测试要求
- 新功能必须包含单元测试
- 修复Bug必须添加回归测试
- 保持测试覆盖率在80%以上
- 测试用例应该清晰、独立、可重复

### 4. 代码检查

```bash
# 运行所有检查
make check

# 单独检查
make fmt    # 格式化代码
make vet    # 静态检查
make lint   # 代码lint
```

### 5. 构建验证

```bash
# 构建当前平台
make build

# 构建所有平台
make build-all

# 运行程序
make run
```

## 📁 项目结构

```
gwt/
├── cmd/                    # 命令行接口
│   ├── root.go            # 根命令
│   ├── list.go            # list 命令
│   ├── create.go          # create 命令
│   ├── remove.go          # remove 命令
│   ├── edit.go            # edit 命令
│   └── ...
├── internal/              # 内部包
│   ├── git/               # Git 操作封装
│   │   └── repository.go  # 仓库操作
│   ├── editor/            # 编辑器集成
│   │   └── detector.go    # 编辑器检测
│   └── ui/                # 用户界面
│       └── colors.go      # 颜色主题
├── pkg/                   # 可重用的包
├── scripts/               # 脚本文件
│   └── install.sh        # 安装脚本
├── docs/                  # 文档
├── test/                  # 测试文件
├── build/                 # 构建输出
├── dist/                  # 发布文件
├── main.go               # 程序入口
├── Makefile              # 构建配置
├── go.mod                # Go 模块定义
└── README.md             # 项目说明
```

## 🧪 测试指南

### 测试类型
1. **单元测试**：测试单个函数和方法
2. **集成测试**：测试组件之间的交互
3. **端到端测试**：测试完整的用户流程

### 测试文件命名
- 测试文件以 `_test.go` 结尾
- 测试函数以 `Test` 开头
- 基准测试以 `Benchmark` 开头
- 示例测试以 `Example` 开头

### 测试示例
```go
func TestCreateWorktree(t *testing.T) {
    // 准备测试环境
    repo := setupTestRepo(t)
    defer cleanupTestRepo(t)
    
    // 执行测试
    worktree, err := repo.CreateWorktree(git.CreateWorktreeOptions{
        Branch: "test-branch",
        Path:   "./test-worktree",
    })
    
    // 验证结果
    assert.NoError(t, err)
    assert.NotNil(t, worktree)
    assert.Equal(t, "test-branch", worktree.Branch)
    assert.DirExists(t, "./test-worktree")
}
```

## 🚀 发布流程

### 版本管理
我们使用 [Semantic Versioning](https://semver.org/)（语义化版本）：

- `MAJOR.MINOR.PATCH` 格式
- `MAJOR`：不兼容的API修改
- `MINOR`：向下兼容的功能性新增
- `PATCH`：向下兼容的问题修正

### 发布步骤
1. 更新版本号：`make update-version VERSION=x.y.z`
2. 创建发布分支：`git checkout -b release/x.y.z`
3. 更新 CHANGELOG.md
4. 提交并推送：`git commit -m "chore: release x.y.z"`
5. 创建标签：`git tag -a v x.y.z -m "Release version x.y.z"`
6. 推送标签：`git push origin v x.y.z`
7. GitHub Actions 会自动构建和发布

## 📋 代码审查

### 审查标准
- [ ] 代码符合项目规范
- [ ] 测试用例完整
- [ ] 文档更新及时
- [ ] 没有破坏现有功能
- [ ] 性能影响可接受

### 审查流程
1. 创建 Pull Request
2. 自动测试运行
3. 代码审查
4. 必要的修改
5. 合并到主分支

## 🎯 开发目标

### 短期目标
- [ ] 提高测试覆盖率到90%
- [ ] 添加更多编辑器支持
- [ ] 优化性能
- [ ] 完善文档

### 长期目标
- [ ] 支持插件系统
- [ ] 添加图形界面
- [ ] 支持团队协作功能
- [ ] 国际化支持

## 💬 交流沟通

### 讨论渠道
- [GitHub Discussions](https://github.com/tinsfox/gwt/discussions) - 一般讨论
- [GitHub Issues](https://github.com/tinsfox/gwt/issues) - 问题报告
- [Pull Requests](https://github.com/tinsfox/gwt/pulls) - 代码贡献

### 行为准则
我们遵循 [Contributor Covenant](https://www.contributor-covenant.org/) 行为准则。参与项目即表示您同意遵守这些准则。

## 📄 许可证

通过贡献代码，您同意您的贡献将在与项目相同的 [MIT 许可证](LICENSE) 下发布。

## ❓ 常见问题

### Q: 我需要具备什么技能才能贡献？
A: 基本的 Go 语言知识和对 Git worktree 的理解即可。我们也欢迎文档和测试方面的贡献。

### Q: 如何开始我的第一个贡献？
A: 查看带有 `good first issue` 标签的 issue，这些通常比较容易上手。

### Q: 我可以贡献什么？
A: 任何有助于项目改进的内容：代码、文档、测试、issue报告、功能建议等。

### Q: 我的贡献什么时候会被合并？
A: 通过代码审查并满足合并条件后，维护者会尽快合并。

---

**再次感谢您的贡献！** 🎉

如有任何问题，请随时在 [GitHub Issues](https://github.com/tinsfox/gwt/issues) 中提问。