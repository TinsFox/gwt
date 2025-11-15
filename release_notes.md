# Release v1.0.0

## 🎉 First Release of Git Worktree CLI

Git Worktree CLI (gwt) is a powerful command-line tool for managing Git worktrees, allowing developers to work on multiple branches simultaneously without constantly switching branches.

## ✨ Features

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

## 📋 Supported Editors

### Popular Editors
- **VS Code** (`code`)
- **Vim** / **Neovim** (`vim`, `nvim`)
- **Emacs** (`emacs`)
- **Sublime Text** (`subl`)
- **Nano** (`nano`)

### Professional IDEs
- **IntelliJ IDEA** (`idea`)
- **WebStorm** (`webstorm`)
- **PyCharm** (`pycharm`)
- **CLion** (`clion`)
- **PhpStorm** (`phpstorm`)

## 🔧 Development

This release includes a complete development environment:

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
- 📧 Email: your-email@example.com

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Happy Coding with Git Worktree CLI!** 🚀
