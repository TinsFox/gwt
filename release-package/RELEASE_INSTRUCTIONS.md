# 🎉 Git Worktree CLI v1.0.0 发布指南

恭喜！Git Worktree CLI 已经准备好发布了。由于网络连接问题，我无法直接通过 GitHub CLI 完成发布，但我已经为你准备好了所有发布所需的文件和详细的操作步骤。

## 📦 发布包内容

我已经为你准备好了以下发布文件：

### 构建产物（位于 `dist/` 目录）
```
dist/
├── gwt-linux-amd64.tar.gz      (5.6MB)  - Linux x86_64
├── gwt-linux-arm64.tar.gz      (5.1MB)  - Linux ARM64
├── gwt-darwin-amd64.zip        (5.8MB)  - macOS x86_64
├── gwt-darwin-arm64.zip        (5.5MB)  - macOS ARM64 (M1/M2)
├── gwt-windows-amd64.zip       (5.9MB)  - Windows x86_64
└── checksums.txt               (498 bytes) - SHA256 校验和
```

### 发布说明
- [`release_notes.md`](release_notes.md) - 完整的发布说明文档

## 🚀 手动发布步骤

### 步骤 1: 推送代码到 GitHub

由于网络连接问题，你需要手动推送代码：

```bash
# 确保远程仓库已设置
git remote add origin https://github.com/TinsFox/gwt.git

# 推送代码（如果网络正常）
git push -u origin main

# 如果 HTTPS 有问题，可以尝试 SSH
git remote set-url origin git@github.com:TinsFox/gwt.git
git push -u origin main
```

### 步骤 2: 创建 GitHub Release

#### 方法 A: 使用 GitHub 网页界面
1. 访问 https://github.com/TinsFox/gwt/releases
2. 点击 "Draft a new release"
3. 输入标签版本: `v1.0.0`
4. 输入发布标题: `Release v1.0.0`
5. 复制下面的发布说明内容

#### 方法 B: 使用 GitHub CLI（如果网络恢复）
```bash
# 创建标签
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 创建发布
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --notes-file release_notes.md \
  --repo TinsFox/gwt
```

### 步骤 3: 上传构建产物

在 GitHub Release 页面创建后，上传以下文件：

1. **Linux 构建**: 
   - `gwt-linux-amd64.tar.gz`
   - `gwt-linux-arm64.tar.gz`

2. **macOS 构建**:
   - `gwt-darwin-amd64.zip` (Intel Mac)
   - `gwt-darwin-arm64.zip` (M1/M2 Mac)

3. **Windows 构建**:
   - `gwt-windows-amd64.zip`

4. **校验和文件**:
   - `checksums.txt`

### 步骤 4: 验证发布

上传完成后，验证以下内容：

1. **文件完整性**: 检查所有文件是否上传成功
2. **校验和**: 用户可以验证下载文件的完整性
3. **发布说明**: 确保发布说明完整且格式正确
4. **标签**: 确认标签正确关联到提交

## 📋 发布说明内容

复制以下内容到 GitHub Release 的说明中：

```markdown
# 🎉 Release v1.0.0

## ✨ First Release of Git Worktree CLI

Git Worktree CLI (gwt) is a powerful command-line tool for managing Git worktrees, allowing developers to work on multiple branches simultaneously without constantly switching branches.

## 🚀 Features

### Core Functionality
- **🚀 Quick Creation**: Create worktrees based on any branch with a single command
- **📝 Smart Editing**: Integration with popular editors (VS Code, Vim, IntelliJ IDEA, etc.)
- **🔍 Interactive Browsing**: Visual browsing and selection of worktrees
- **🎨 Beautiful Output**: Colorful terminal output with clear information display
- **⚡ Shortcut Commands**: Simplified command aliases for improved efficiency
- **🔧 Cross-Platform**: Support for Windows, macOS, and Linux

### Advanced Features
- **🔄 Quick Switching**: Fast switching between worktrees
- **📊 Status Checking**: View status of all worktrees at a glance
- **🧹 Cleanup Tools**: Prune invalid worktrees and manage workspace
- **⚙️ Configuration Management**: Customizable settings and preferences
- **📚 Built-in Tutorial**: Interactive tutorial for new users
- **🎯 Editor Integration**: Seamless integration with 10+ editors and IDEs

## 📦 Installation

### Using Install Script (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/tinsfox/gwt/main/scripts/install.sh | bash
```

### Manual Download
Download the appropriate binary for your platform from the assets below.

### Using Go Install
```bash
go install github.com/tinsfox/gwt@latest
```

## 🚀 Quick Start

```bash
# List all worktrees
gwt list

# Create a new worktree
gwt create feature/new-feature

# Open worktree in your editor
gwt edit feature/new-feature

# Interactive browsing
gwt browse

# Remove worktree
gwt remove feature/new-feature
```

## 🛠️ Supported Platforms

- **Linux**: amd64, arm64
- **macOS**: amd64 (Intel), arm64 (M1/M2)
- **Windows**: amd64

## 🔧 Development Environment

This release includes a complete development environment with:

- **📖 Comprehensive Documentation**: Development guides, build instructions, and contribution guidelines
- **🛠️ Build System**: Cross-platform build with Make and advanced build utilities
- **🧪 Testing Framework**: Unit tests, integration tests, and performance benchmarks
- **🔄 CI/CD Pipeline**: Automated testing, building, and releasing with GitHub Actions
- **🤖 Automation Scripts**: GitHub CLI integration and repository management tools

## 📊 Build Information

- **Go Version**: 1.21
- **Build Time**: $(date)
- **Git Commit**: $(git rev-parse --short HEAD)
- **Supported Platforms**: 5 (Linux amd64/arm64, macOS amd64/arm64, Windows amd64)

## 🔒 Verification

Download the appropriate binary for your platform and verify the checksum using the provided `checksums.txt` file:

```bash
sha256sum -c checksums.txt
```

## 🙏 Acknowledgments

This project is built with excellent open-source tools:
- [Cobra](https://github.com/spf13/cobra) - CLI framework
- [Viper](https://github.com/spf13/viper) - Configuration management
- [go-git](https://github.com/go-git/go-git) - Git operations
- [color](https://github.com/fatih/color) - Terminal colors

## 📞 Support

- 💬 [GitHub Discussions](https://github.com/tinsfox/gwt/discussions)
- 🐛 [Issue Tracker](https://github.com/tinsfox/gwt/issues)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Happy Coding with Git Worktree CLI!** 🚀
```

## 🔧 技术细节

### 构建信息
- **构建时间**: $(date)
- **Go 版本**: 1.21
- **Git 提交**: $(git rev-parse --short HEAD)
- **支持平台**: 5 个平台 (Linux amd64/arm64, macOS amd64/arm64, Windows amd64)
- **二进制大小**: 10-11MB (根据平台不同)

### 校验和验证
```bash
# 验证所有文件
cd dist && sha256sum -c checksums.txt

# 应该看到类似输出:
# checksums.txt: OK
# gwt-linux-amd64.tar.gz: OK
# gwt-linux-arm64.tar.gz: OK
# ...
```

## 🎯 下一步操作

完成发布后，建议进行以下操作：

1. **测试安装**: 从发布页面下载并测试安装脚本
2. **验证功能**: 测试主要功能是否正常工作
3. **通知用户**: 通过适当渠道通知潜在用户
4. **监控反馈**: 关注用户反馈和问题报告
5. **文档更新**: 根据需要更新文档

## 📞 获取帮助

如果在发布过程中遇到问题：

1. **检查网络连接**: 确保能够正常访问 GitHub
2. **验证权限**: 确认有仓库的写入权限
3. **查看日志**: 检查 GitHub Actions 运行日志
4. **文件验证**: 确认构建产物的完整性
5. **社区支持**: 在 GitHub Discussions 寻求帮助

---

**🎉 恭喜！Git Worktree CLI v1.0.0 已经准备好发布了！**

所有构建产物已经准备就绪，发布说明已经写好，你只需要按照上面的步骤完成 GitHub 上的发布操作即可。

**Happy Releasing!** 🚀