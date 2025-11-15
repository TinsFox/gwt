# 🔄 Homebrew Formula 更新指南

本指南详细介绍如何更新 Homebrew Formula 以支持新版本的 Git Worktree CLI。

## 📋 更新流程

### 步骤 1: 获取新版本信息

1. **检查 GitHub 发布**
   - 访问 https://github.com/TinsFox/gwt/releases
   - 确认新版本号和发布说明

2. **获取新版本源码**
   ```bash
   # 下载新版本源码
   wget https://github.com/TinsFox/gwt/archive/vNEW_VERSION.tar.gz
   
   # 计算 SHA256 校验和
   sha256sum vNEW_VERSION.tar.gz
   ```

### 步骤 2: 更新 Formula 文件

#### 方法 1: 手动更新

编辑 `Formula/gwt.rb` 文件：

```ruby
class Gwt < Formula
  desc "Git Worktree CLI - A powerful command-line tool for managing Git worktrees"
  homepage "https://github.com/TinsFox/gwt"
  url "https://github.com/TinsFox/gwt/archive/vNEW_VERSION.tar.gz"
  sha256 "NEW_SHA256"  # ← 更新这里
  license "MIT"
  head "https://github.com/TinsFox/gwt.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")
    
    # Install completion scripts
    output = Utils.safe_popen_read(bin/"gwt", "completion", "bash")
    (bash_completion/"gwt").write output
    
    output = Utils.safe_popen_read(bin/"gwt", "completion", "zsh")
    (zsh_completion/"_gwt").write output
    
    output = Utils.safe_popen_read(bin/"gwt", "completion", "fish")
    (fish_completion/"gwt.fish").write output
  end

  test do
    assert_match "gwt version", shell_output("#{bin}/gwt --version")
    assert_match "Git Worktree CLI", shell_output("#{bin}/gwt --help")
  end
end
```

#### 方法 2: 使用更新脚本

创建更新脚本 `update-formula.sh`：

```bash
#!/bin/bash
# update-formula.sh - 自动更新 Homebrew Formula

set -e

# 检查参数
if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-version>"
    echo "Example: $0 1.1.0"
    exit 1
fi

NEW_VERSION=$1
FORMULA_FILE="Formula/gwt.rb"

echo "🔄 更新 Formula 到 v${NEW_VERSION}..."

# 1. 下载新版本并计算 SHA256
echo "📥 下载新版本 v${NEW_VERSION}..."
wget -q "https://github.com/TinsFox/gwt/archive/v${NEW_VERSION}.tar.gz" -O "/tmp/gwt-${NEW_VERSION}.tar.gz"

# 2. 计算 SHA256
NEW_SHA256=$(sha256sum "/tmp/gwt-${NEW_VERSION}.tar.gz" | cut -d' ' -f1)
echo "📊 新 SHA256: ${NEW_SHA256}"

# 3. 清理下载文件
rm -f "/tmp/gwt-${NEW_VERSION}.tar.gz"

# 4. 更新 Formula
echo "✏️  更新 Formula 文件..."
sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v${NEW_VERSION}/g" "$FORMULA_FILE"
sed -i.bak "s/sha256 \".*\"/sha256 \"${NEW_SHA256}\"/g" "$FORMULA_FILE"

# 5. 清理备份文件
rm -f "$FORMULA_FILE.bak"

echo "✅ Formula 更新完成！"
echo ""
echo "下一步操作："
echo "1. 测试更新后的 Formula"
echo "2. 提交更改"
echo "3. 推送更新"
```

### 步骤 3: 测试更新

#### 本地测试

```bash
# 测试本地公式
brew install --build-from-source ./Formula/gwt.rb

# 验证安装
gwt --version
gwt --help

# 运行测试
brew test ./Formula/gwt.rb
```

#### 使用 GitHub Actions 测试

每次推送都会自动触发测试工作流，确保 Formula 正常工作。

### 步骤 4: 提交和推送

```bash
# 添加更改
git add Formula/gwt.rb

# 提交更改
git commit -m "Update gwt to v${NEW_VERSION}"

# 推送更新
git push origin main
```

### 步骤 5: 验证发布

#### 远程测试

```bash
# 从远程 tap 安装（等待几分钟让 GitHub 同步）
brew update
brew install gwt

# 验证新版本
gwt --version
```

#### 通知用户

在 GitHub 仓库中创建 Release 或 Issue 通知用户新版本可用。

## 🧪 测试指南

### 本地测试

```bash
# 完整的本地测试流程
brew uninstall gwt 2>/dev/null || true
brew install --build-from-source ./Formula/gwt.rb
brew test ./Formula/gwt.rb

# 功能测试
gwt --version
gwt --help
gwt list
```

### 多平台测试

```bash
# 在不同 macOS 版本上测试
# - macOS Intel (x86_64)
# - macOS Apple Silicon (ARM64)
# - 不同 macOS 版本
```

## 🔄 自动化更新

### GitHub Actions 自动化

使用 GitHub Actions 自动检测新版本并创建 PR：

```yaml
# .github/workflows/update-formula.yml
name: Update Formula

on:
  repository_dispatch:
    types: [new-release]
  schedule:
    - cron: '0 0 * * 1'  # 每周一检查

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check for new release
        id: check_release
        run: |
          # 检查是否有新版本
          LATEST_VERSION=$(curl -s https://api.github.com/repos/TinsFox/gwt/releases/latest | jq -r .tag_name | sed 's/v//')
          CURRENT_VERSION=$(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' Formula/gwt.rb | sed 's/v//')
          
          if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
            echo "New version available: $LATEST_VERSION"
            echo "latest_version=$LATEST_VERSION" >> $GITHUB_OUTPUT
            echo "update_needed=true" >> $GITHUB_OUTPUT
          else
            echo "No update needed"
            echo "update_needed=false" >> $GITHUB_OUTPUT
          fi

      - name: Update formula
        if: steps.check_release.outputs.update_needed == 'true'
        run: |
          # 运行更新脚本
          ./update-formula.sh ${{ steps.check_release.outputs.latest_version }}

      - name: Create Pull Request
        if: steps.check_release.outputs.update_needed == 'true'
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: "Update gwt to v${{ steps.check_release.outputs.latest_version }}"
          title: "Update gwt to v${{ steps.check_release.outputs.latest_version }}"
          body: |
            Automated update to gwt v${{ steps.check_release.outputs.latest_version }}
            
            - [ ] Test the formula locally
            - [ ] Verify the SHA256 checksum
            - [ ] Run brew test
            - [ ] Approve and merge if tests pass
          branch: update-gwt-${{ steps.check_release.outputs.latest_version }}
```

## 📊 发布监控

### 监控指标
- **下载量**: GitHub Release 下载统计
- **安装量**: Homebrew 安装统计（可通过 analytics 获取）
- **用户反馈**: Issues、Discussions、社交媒体反馈
- **更新频率**: 版本更新频率和用户接受度

### 成功指标
- [ ] Formula 安装正常工作
- [ ] 用户能够成功安装和使用
- [ ] 获得积极的用户反馈
- [ ] 持续的下载和使用
- [ ] 定期更新和维护

## 🚨 常见问题处理

### 1. SHA256 不匹配
```bash
# 重新计算并更新
wget https://github.com/TinsFox/gwt/archive/vNEW_VERSION.tar.gz
sha256sum vNEW_VERSION.tar.gz
# 更新 Formula 中的 SHA256
```

### 2. 构建失败
```bash
# 检查构建日志
brew install -v gwt
# 检查依赖
brew deps gwt
```

### 3. 测试失败
```bash
# 运行详细测试
brew test -v gwt
# 检查测试环境
brew config
```

### 4. 用户报告问题
```bash
# 收集诊断信息
brew gist-logs gwt
brew doctor
```

## 📞 支持

### 用户支持
- **GitHub Issues**: https://github.com/TinsFox/homebrew-gwt/issues
- **GitHub Discussions**: https://github.com/TinsFox/gwt/discussions
- **Homebrew 社区**: https://github.com/Homebrew/discussions

### 开发支持
- **Homebrew 文档**: https://docs.brew.sh/
- **Formula 指南**: https://docs.brew.sh/Formula-Cookbook
- **Homebrew API**: https://rubydoc.brew.sh/

---

## 🎉 完成！

现在你已经有了完整的 Homebrew 发布和更新系统！用户可以通过以下方式安装你的工具：

```bash
brew tap TinsFox/gwt
brew install gwt
```

**🍺 Happy Brewing with Git Worktree CLI!**