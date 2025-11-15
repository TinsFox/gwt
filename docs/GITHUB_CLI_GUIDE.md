# GitHub CLI 使用指南

本指南详细介绍如何使用 GitHub CLI (gh) 和自动化脚本来管理 GitHub 仓库、发布版本和 CI/CD 流程。

## 📋 目录

1. [GitHub CLI 安装与配置](#github-cli-安装与配置)
2. [基础命令使用](#基础命令使用)
3. [自动化脚本使用](#自动化脚本使用)
4. [仓库管理](#仓库管理)
5. [发布管理](#发布管理)
6. [CI/CD 集成](#cicd-集成)
7. [高级功能](#高级功能)
8. [故障排除](#故障排除)

## 🔧 GitHub CLI 安装与配置

### 安装 GitHub CLI

#### macOS
```bash
# 使用 Homebrew
brew install gh

# 或者使用 MacPorts
port install gh
```

#### Ubuntu/Debian
```bash
# 添加 GitHub CLI 仓库
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 安装
sudo apt update
sudo apt install gh -y
```

#### Windows
```powershell
# 使用 winget
winget install --id GitHub.cli

# 或者使用 Chocolatey
choco install gh

# 或者使用 Scoop
scoop install gh
```

#### 其他系统
参见官方安装指南：https://cli.github.com/manual/installation

### 配置认证

#### 交互式认证
```bash
# 基本认证
gh auth login

# 选择认证方式
# ? What account do you want to log into? GitHub.com
# ? What is your preferred protocol for Git operations? HTTPS
# ? How would you like to authenticate GitHub CLI? Login with a web browser
```

#### 使用 Token 认证
```bash
# 使用个人访问令牌
echo "YOUR_GITHUB_TOKEN" | gh auth login --with-token

# 或者设置环境变量
export GITHUB_TOKEN="your_github_token"
```

#### 获取个人访问令牌
1. 访问 GitHub Settings > Developer settings > Personal access tokens
2. 点击 "Generate new token"
3. 选择所需的权限范围：
   - `repo` - 完整的仓库访问权限
   - `workflow` - 更新 GitHub Action 工作流
   - `write:packages` - 上传包
   - `delete:packages` - 删除包

### 验证安装
```bash
# 检查版本
gh --version

# 验证认证状态
gh auth status

# 测试基本功能
gh repo view $(gh repo view --json nameWithOwner -q .nameWithOwner)
```

## 🎯 基础命令使用

### 仓库操作

#### 查看仓库信息
```bash
# 查看当前仓库
gh repo view

# 查看指定仓库
gh repo view owner/repo-name

# 以 JSON 格式查看
gh repo view owner/repo-name --json name,description,stargazerCount
```

#### 克隆仓库
```bash
# 克隆当前仓库
gh repo clone owner/repo-name

# 克隆并进入目录
gh repo clone owner/repo-name && cd repo-name
```

#### 创建仓库
```bash
# 创建新仓库
gh repo create my-new-repo --public --description "My new repository"

# 从模板创建
gh repo create my-new-repo --template owner/template-repo --public
```

### Issue 管理

#### 查看 Issues
```bash
# 列出当前仓库的 Issues
gh issue list

# 列出指定仓库的 Issues
gh issue list --repo owner/repo-name

# 按标签过滤
gh issue list --label "bug"

# 按状态过滤
gh issue list --state closed
```

#### 创建 Issue
```bash
# 创建新 Issue
gh issue create --title "Bug report" --body "Something is not working"

# 带标签创建
gh issue create --title "Feature request" --body "New feature" --label "enhancement"
```

#### 处理 Issues
```bash
# 查看 Issue 详情
gh issue view 123

# 关闭 Issue
gh issue close 123

# 重新打开 Issue
gh issue reopen 123

# 添加评论
gh issue comment 123 --body "This is a comment"
```

### Pull Request 管理

#### 查看 PR
```bash
# 列出 PR
gh pr list

# 查看 PR 详情
gh pr view 123

# 查看 PR 差异
gh pr diff 123
```

#### 创建 PR
```bash
# 创建 PR
gh pr create --title "My changes" --body "Description of changes"

# 指定分支
gh pr create --base main --head feature-branch --title "New feature"
```

#### 处理 PR
```bash
# 合并 PR
gh pr merge 123

# 关闭 PR
gh pr close 123

# 添加评论
gh pr comment 123 --body "LGTM!"
```

## 🤖 自动化脚本使用

### 脚本概述

我们提供了几个自动化脚本来简化常见的 GitHub 操作：

1. **`github-automation.sh`** - 主要的 GitHub 自动化脚本
2. **`build-utils.sh`** - 构建和发布工具
3. **`setup-dev.sh`** - 开发环境设置

### 使用 GitHub 自动化脚本

#### 基本用法
```bash
# 显示帮助信息
./scripts/github-automation.sh help

# 查看仓库状态
./scripts/github-automation.sh status

# 同步标签
./scripts/github-automation.sh sync-labels
```

#### 仓库管理
```bash
# 创建新仓库
./scripts/github-automation.sh create-repo my-new-repo \
  "My new repository description" \
  --owner your-username

# 设置仓库配置
./scripts/github-automation.sh setup-repo

# 列出用户仓库
./scripts/github-automation.sh list-repos --owner your-username
```

#### 发布管理
```bash
# 创建发布版本
./scripts/github-automation.sh create-release 1.0.0 \
  "Release v1.0.0" \
  "This is a new release" \
  --repo your-username/your-repo

# 列出发布版本
./scripts/github-automation.sh list-releases

# 上传发布资产
./scripts/github-automation.sh upload-asset v1.0.0 path/to/file.zip
```

#### Issue 管理
```bash
# 创建 Issue
./scripts/github-automation.sh create-issue \
  "Bug: Something is broken" \
  "Detailed description of the bug" \
  "bug,high-priority"

# 列出 Issues
./scripts/github-automation.sh list-issues

# 关闭 Issue
./scripts/github-automation.sh close-issue 123
```

#### CI/CD 管理
```bash
# 触发 CI
./scripts/github-automation.sh trigger-ci ci.yml main

# 检查 CI 状态
./scripts/github-automation.sh check-status ci.yml

# 取消工作流运行
./scripts/github-automation.sh cancel-run 123456789
```

## 📦 发布管理

### 自动化发布流程

#### 1. 准备工作
```bash
# 确保代码已提交并推送
git add .
git commit -m "Prepare for release"
git push origin main
```

#### 2. 创建发布版本
```bash
# 使用自动化脚本创建发布
./scripts/github-automation.sh create-release 1.0.0 \
  "Release v1.0.0" \
  "New features and bug fixes"

# 或者手动创建标签和发布
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

#### 3. 构建和上传资产
```bash
# 构建所有平台
make build-all

# 生成校验和
cd dist && sha256sum * > checksums.txt && cd ..

# 上传资产
./scripts/github-automation.sh upload-asset v1.0.0 dist/gwt-linux-amd64.tar.gz
./scripts/github-automation.sh upload-asset v1.0.0 dist/checksums.txt
```

### 使用 GitHub Actions 自动发布

#### 触发自动发布
```bash
# 使用 GitHub CLI 触发工作流
gh workflow run release.yml \
  --ref main \
  --field version="1.0.0" \
  --field prerelease="false"

# 或者创建标签触发自动发布
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

#### 监控发布状态
```bash
# 查看工作流状态
gh run list --workflow=release.yml

# 查看具体运行详情
gh run view 123456789

# 查看日志
gh run view 123456789 --log
```

## 🔄 CI/CD 集成

### 工作流管理

#### 查看工作流
```bash
# 列出工作流
gh workflow list

# 查看工作流详情
gh workflow view ci.yml
```

#### 触发工作流
```bash
# 手动触发工作流
gh workflow run ci.yml --ref feature-branch

# 触发特定工作流
gh workflow run release.yml \
  --field version="1.0.0" \
  --field prerelease="false"
```

#### 监控工作流运行
```bash
# 查看运行历史
gh run list

# 查看运行详情
gh run view 123456789

# 查看运行日志
gh run view 123456789 --log

# 取消运行
gh run cancel 123456789
```

### 环境管理

#### 管理 Secrets
```bash
# 列出 secrets
gh secret list

# 添加 secret
echo "secret-value" | gh secret set MY_SECRET

# 删除 secret
gh secret delete MY_SECRET
```

#### 管理环境
```bash
# 创建环境
gh api repos/{owner}/{repo}/environments/production \
  --method PUT \
  --input - <<< '{
    "wait_timer": 5,
    "reviewers": [{"type": "User", "id": 123}],
    "deployment_branch_policy": {
      "protected_branches": true,
      "custom_branch_policies": false
    }
  }'
```

## 🚀 高级功能

### 批量操作

#### 批量创建 Issues
```bash
#!/bin/bash
# 批量创建 Issues
issues=(
  "Feature: Add dark mode support"
  "Bug: Fix memory leak in list command"
  "Enhancement: Improve error messages"
)

for issue in "${issues[@]}"; do
  ./scripts/github-automation.sh create-issue \
    "$issue" \
    "Automated issue for tracking" \
    "enhancement"
done
```

#### 批量更新标签
```bash
#!/bin/bash
# 批量更新多个仓库的标签
repos=(
  "user/repo1"
  "user/repo2"
  "user/repo3"
)

for repo in "${repos[@]}"; do
  ./scripts/github-automation.sh sync-labels "$repo"
done
```

### 自动化部署

#### 创建部署脚本
```bash
#!/bin/bash
# deploy.sh - 自动化部署脚本

set -e

# 配置
VERSION="$1"
REPO="${2:-tinsfox/gwt}"

echo "🚀 Starting deployment of version $VERSION"

# 1. 运行测试
make test

# 2. 构建所有平台
make build-all

# 3. 创建发布
./scripts/github-automation.sh create-release "$VERSION" \
  "Release v$VERSION" \
  "Automated deployment release" \
  --repo "$REPO"

# 4. 上传构建产物
cd dist
for file in *.tar.gz *.zip; do
  echo "📦 Uploading $file..."
  ../scripts/github-automation.sh upload-asset "v$VERSION" "$file" "$REPO"
done

echo "✅ Deployment completed successfully!"
```

### 监控和通知

#### 设置 Webhook
```bash
# 创建 webhook
gh api repos/{owner}/{repo}/hooks \
  --method POST \
  --input - <<< '{
    "name": "web",
    "active": true,
    "events": ["push", "pull_request", "release"],
    "config": {
      "url": "https://your-webhook-url.com/webhook",
      "content_type": "json",
      "secret": "your-webhook-secret"
    }
  }'
```

#### 获取通知
```bash
# 查看通知
gh api notifications

# 标记通知为已读
gh api notifications --method PUT --input - <<< '{"read": true}'
```

## 🔍 故障排除

### 常见问题和解决方案

#### 认证失败
```bash
# 问题: gh: To get started with GitHub CLI, please run: gh auth login
# 解决:
gh auth login

# 或者使用 Token
echo "your_token" | gh auth login --with-token
```

#### 权限不足
```bash
# 问题: HTTP 403: Forbidden
# 解决: 检查 Token 权限
gh auth status

# 重新认证并选择正确的权限
gh auth login --scopes "repo,workflow,write:packages"
```

#### 工作流触发失败
```bash
# 问题: workflow not found
# 解决: 检查工作流文件是否存在
gh workflow list

# 确保工作流文件在 .github/workflows/ 目录
ls -la .github/workflows/
```

#### 发布创建失败
```bash
# 问题: Tag already exists
# 解决: 删除现有标签或创建新标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# 或者创建新版本
./scripts/github-automation.sh create-release 1.0.1
```

### 调试技巧

#### 启用详细模式
```bash
# 显示详细输出
./scripts/github-automation.sh --verbose status

# 试运行模式（不实际执行）
./scripts/github-automation.sh --dry-run create-release 1.0.0
```

#### 查看 API 调用
```bash
# 启用调试模式
export GH_DEBUG=true

# 查看详细的 API 调用
gh api repos/tinsfox/gwt --verbose
```

#### 检查网络连接
```bash
# 测试 GitHub API 连接
curl -I https://api.github.com

# 检查 DNS 解析
nslookup api.github.com
```

## 📊 最佳实践

### 1. 安全最佳实践
- 使用个人访问令牌而不是密码
- 定期轮换访问令牌
- 为不同用途创建不同权限的令牌
- 不要在代码中硬编码令牌

### 2. 工作流最佳实践
- 使用语义化版本号
- 自动化测试和构建
- 创建详细的发布说明
- 保持工作流简单明了

### 3. 协作最佳实践
- 使用分支保护规则
- 要求代码审查
- 自动化标签管理
- 及时响应 Issues 和 PRs

### 4. 监控和日志
- 设置适当的通知
- 监控 CI/CD 状态
- 记录重要的操作
- 定期检查安全扫描结果

## 🎯 快速参考

### 常用命令速查
```bash
# 认证
gh auth login                                    # 登录
git auth status                                  # 查看状态

# 仓库操作
gh repo view                                     # 查看仓库信息
gh repo clone owner/repo                         # 克隆仓库
gh repo create name --public                     # 创建仓库

# Issue 操作
gh issue list                                    # 列出 Issues
gh issue create --title "Title" --body "Body"    # 创建 Issue
gh issue close 123                               # 关闭 Issue

# PR 操作
gh pr list                                       # 列出 PRs
gh pr create --title "Title" --body "Body"       # 创建 PR
gh pr merge 123                                  # 合并 PR

# 发布操作
gh release list                                  # 列出发布版本
gh release create v1.0.0 --title "Release"       # 创建发布
gh release upload v1.0.0 file.zip                # 上传资产

# 工作流操作
gh workflow list                                 # 列出工作流
gh workflow run ci.yml --ref branch              # 触发工作流
gh run list                                      # 查看运行历史
```

---

## 📞 获取帮助

- [GitHub CLI 官方文档](https://cli.github.com/manual/)
- [GitHub CLI 问题反馈](https://github.com/cli/cli/issues)
- [项目文档](../README.md)
- [开发文档](DEVELOPMENT.md)

**Happy Automating!** 🤖