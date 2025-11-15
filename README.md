# Git Worktree CLI (gwt)

一个强大的命令行工具，用于简化 Git worktree 的管理。让你能够更高效地同时处理多个分支，避免频繁切换分支的麻烦。

## 🌟 特性

- **🚀 快速创建**: 一键创建基于任意分支的 worktree
- **📝 智能编辑**: 集成主流编辑器（VS Code、Vim、IDEA 等）
- **🔍 交互浏览**: 可视化浏览和选择 worktree
- **🎨 美观输出**: 彩色终端输出，信息一目了然
- **⚡ 快捷命令**: 简化的命令别名，提高操作效率
- **🔧 跨平台**: 支持 Windows、macOS、Linux

## 📦 安装

### 使用安装脚本（推荐）

```bash
# 安装最新版本
curl -fsSL https://raw.githubusercontent.com/tinsfox/gwt/main/scripts/install.sh | bash

# 或者使用 wget
wget -qO- https://raw.githubusercontent.com/tinsfox/gwt/main/scripts/install.sh | bash
```

### 从源码安装

```bash
git clone https://github.com/tinsfox/gwt.git
cd git-worktree-cli
make install
```

### 手动下载

从 [Releases](https://github.com/tinsfox/gwt/releases) 页面下载对应平台的二进制文件，解压后移动到 PATH 中。

## 🚀 快速开始

### 1. 查看 worktree 列表
```bash
gwt list
# 或者简写: gwt ls
```

### 2. 创建新的 worktree
```bash
# 基于 main 分支创建
gwt create main

# 创建新分支并建立 worktree
gwt create feature/new-feature

# 指定路径
gwt create hotfix/critical /tmp/hotfix
```

### 3. 使用编辑器打开
```bash
# 使用默认编辑器
gwt edit main

# 使用 VS Code
gwt edit feature/new-ui -e code
# 或者快捷命令: gwt code feature/new-ui

# 使用 Vim
gwt edit hotfix/critical -e vim
# 或者快捷命令: gwt vim hotfix/critical
```

### 4. 交互式浏览
```bash
gwt browse
# 显示所有 worktree，输入数字选择
```

### 5. 删除 worktree
```bash
gwt remove feature/old-feature
gwt rm /path/to/worktree
```

### 6. 清理无效的 worktree
```bash
gwt prune
```

## 📖 命令参考

### 基础命令

| 命令 | 别名 | 描述 |
|------|------|------|
| `gwt list` | `ls` | 列出所有 worktree |
| `gwt create <branch>` | `add`, `new` | 创建新的 worktree |
| `gwt remove <path\|branch>` | `rm`, `delete` | 删除 worktree |
| `gwt prune` | - | 清理无效的 worktree |

### 编辑器集成

| 命令 | 描述 |
|------|------|
| `gwt edit <branch\|path>` | 使用编辑器打开 worktree |
| `gwt code <branch\|path>` | 使用 VS Code 打开 |
| `gwt idea <branch\|path>` | 使用 IntelliJ IDEA 打开 |
| `gwt vim <branch\|path>` | 使用 Vim 打开 |

### 高级功能

| 命令 | 别名 | 描述 |
|------|------|------|
| `gwt switch <branch>` | `sw`, `checkout` | 切换到指定分支的 worktree |
| `gwt browse` | `open`, `select` | 交互式浏览和选择 |
| `gwt config` | - | 管理配置 |
| `gwt tutorial` | - | 显示使用教程 |
| `gwt completion` | - | 生成 shell 自动补全 |

## ⚙️ 配置

### 设置默认编辑器
```bash
gwt config set editor.default code
gwt config set editor.default vim
```

### 查看配置
```bash
gwt config list
```

### 环境变量
- `EDITOR`: 默认编辑器
- `GWT_EDITOR`: 覆盖默认编辑器

## 🎯 使用场景

### 场景 1: 同时处理多个功能
```bash
# 修复紧急 bug
gwt create hotfix/login-bug
cd hotfix/login-bug
# ... 修复工作 ...

# 同时开发新功能
gwt create feature/new-dashboard
gwt code feature/new-dashboard
# ... 开发工作 ...
```

### 场景 2: 代码审查
```bash
# 为 PR 创建 worktree 进行审查
gwt create review/pr-123
gwt code review/pr-123
# ... 审查代码 ...
```

### 场景 3: 快速切换分支
```bash
# 使用交互式浏览
gwt browse

# 或者使用 switch 命令
gwt switch main
gwt switch feature/new-ui
```

## 🛠️ 支持的编辑器

### 主流编辑器
- **VS Code** (`code`)
- **Vim** / **Neovim** (`vim`, `nvim`)
- **Emacs** (`emacs`)
- **Sublime Text** (`subl`)
- **Nano** (`nano`)

### 专业 IDE
- **IntelliJ IDEA** (`idea`)
- **WebStorm** (`webstorm`)
- **PyCharm** (`pycharm`)
- **CLion** (`clion`)
- **PhpStorm** (`phpstorm`)

## 🔧 开发

### 构建
```bash
# 构建当前平台
make build

# 构建所有平台
make build-all

# 运行测试
make test
```

### 开发模式
```bash
# 使用热重载运行
make dev

# 或者手动构建运行
make build
./build/gwt --help
```

## 🐛 故障排除

### 常见问题

**Q: 编辑器无法打开**
A: 确保编辑器已安装并在 PATH 中，或手动指定编辑器路径：
```bash
gwt edit main -e /usr/local/bin/code
```

**Q: 权限错误**
A: 某些操作可能需要管理员权限，使用 `sudo` 运行：
```bash
sudo gwt create main /system/path
```

**Q: 无法找到 Git 仓库**
A: 确保在 Git 仓库目录中运行命令：
```bash
cd your-git-repo
gwt list
```

## 🤝 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Cobra](https://github.com/spf13/cobra) - CLI 框架
- [Viper](https://github.com/spf13/viper) - 配置管理
- [go-git](https://github.com/go-git/go-git) - Git 操作库
- [color](https://github.com/fatih/color) - 终端颜色

## 📞 支持

- 💬 [GitHub Discussions](https://github.com/tinsfox/gwt/discussions)
- 🐛 [Issue Tracker](https://github.com/tinsfox/gwt/issues)
- 📧 邮件: your-email@example.com

---

⭐ 如果这个项目对你有帮助，请给个 Star！