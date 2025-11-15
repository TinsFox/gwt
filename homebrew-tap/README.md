# 🍺 Homebrew Tap for Git Worktree CLI

This is the official Homebrew tap for [Git Worktree CLI (gwt)](https://github.com/TinsFox/gwt) - a powerful command-line tool for managing Git worktrees.

## 🚀 Quick Install

```bash
# Add this tap
brew tap TinsFox/gwt

# Install gwt
brew install gwt

# Verify installation
gwt --version
```

## 📦 Formula Information

- **Name**: gwt
- **Description**: Git Worktree CLI - A powerful command-line tool for managing Git worktrees
- **License**: MIT
- **Homepage**: https://github.com/TinsFox/gwt

## 🛠️ Features

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

## 📋 Installation Options

### Option 1: Homebrew Tap (Recommended)
```bash
brew tap TinsFox/gwt
brew install gwt
```

### Option 2: Direct Download
Download the appropriate binary for your platform from the [GitHub Releases](https://github.com/TinsFox/gwt/releases).

### Option 3: Go Install
```bash
go install github.com/tinsfox/gwt@latest
```

## 🛠️ Development

If you want to contribute or modify the formula:

```bash
# Clone this repository
git clone https://github.com/TinsFox/homebrew-gwt.git
cd homebrew-gwt

# Install from local formula
brew install --build-from-source ./Formula/gwt.rb

# Test the formula
brew test ./Formula/gwt.rb
```

## 📊 Formula Information

- **Formula**: `Formula/gwt.rb`
- **Dependencies**: Go (build-time only)
- **Completion**: Bash, Zsh, Fish shell completion included
- **License**: MIT
- **Platforms**: macOS (Intel and Apple Silicon)

## 🔧 Formula Features

- **Cross-platform**: Supports both Intel and Apple Silicon Macs
- **Completion scripts**: Includes shell completion for Bash, Zsh, and Fish
- **Build optimization**: Uses `-s -w` flags for smaller binary size
- **Version information**: Embeds version information in the binary
- **Testing**: Includes comprehensive test suite

## 🔄 Updating the Formula

When a new version of gwt is released, the formula needs to be updated:

1. Download the new release tarball
2. Calculate the new SHA256 checksum
3. Update the version and SHA256 in the formula
4. Test the updated formula
5. Commit and push the changes

See [UPDATE_GUIDE.md](UPDATE_GUIDE.md) for detailed instructions.

## 📞 Support

- **Issues**: https://github.com/TinsFox/gwt/issues
- **Discussions**: https://github.com/TinsFox/gwt/discussions
- **Homebrew Issues**: https://github.com/TinsFox/homebrew-gwt/issues

## 📄 License

This tap and the formula are licensed under the same MIT License as the gwt project itself.

## 🙏 Acknowledgments

- [Homebrew](https://brew.sh/) - The missing package manager for macOS
- [Git Worktree CLI](https://github.com/TinsFox/gwt) - The amazing tool this tap provides
- [Homebrew community](https://github.com/Homebrew) - For the excellent package management system

---

**🍺 Happy Brewing with Git Worktree CLI!**