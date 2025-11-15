# Git Worktree CLI 工具需求文档

## 项目背景

Git worktree 是 Git 的一个强大功能，允许开发者在同一个仓库中创建多个工作目录，每个工作目录可以切换到不同的分支。这对于需要同时处理多个分支的开发者来说非常有用，避免了频繁切换分支的麻烦。

## 目标用户

- 需要同时处理多个分支的开发者
- 对 Git worktree 功能不熟悉但想快速上手的用户
- 希望通过命令行工具简化 worktree 操作的用户

## 核心功能需求

### 1. 基础功能

#### 1.1 查看 Worktree 列表
```bash
gwt list          # 显示所有 worktree 及其状态
gwt ls            # list 的简写
```
**输出示例：**
```
路径                  分支         状态
/Users/dev/project-a  main        清洁
/Users/dev/project-b  feature-1   已修改
/Users/dev/project-c  hotfix-2    清洁
```

#### 1.2 创建 Worktree
```bash
gwt create <branch-name> [path]     # 基于指定分支创建 worktree
gwt add <branch-name> [path]        # create 的别名
```
**参数说明：**
- `branch-name`: 分支名称（如果不存在则自动创建）
- `path`: 可选，worktree 路径（默认为当前目录下的分支名）

#### 1.3 删除 Worktree
```bash
gwt remove <path|branch>            # 删除指定 worktree
gwt rm <path|branch>                # remove 的简写
gwt delete <path|branch>            # remove 的别名
```

#### 1.4 清理无效的 Worktree
```bash
gwt prune                            # 清理已删除目录的 worktree 记录
```

### 2. 进阶功能

#### 2.1 快速切换分支
```bash
gwt switch <branch-name>            # 快速切换到指定分支的 worktree
```
- 如果 worktree 不存在，询问是否创建
- 如果已存在，直接打开该目录

#### 2.2 批量操作
```bash
gwt create-all                      # 为所有远程分支创建 worktree
gwt clean-all                       # 删除所有 worktree（保留主分支）
```

#### 2.3 Worktree 状态检查
```bash
gwt status                          # 显示所有 worktree 的 git 状态
gwt diff <worktree1> <worktree2>    # 比较两个 worktree 的差异
```

#### 2.4 编辑器集成
```bash
gwt edit <branch|path>              # 使用默认编辑器打开指定 worktree
gwt edit <branch|path> -e <editor>  # 指定编辑器打开 worktree
gwt code <branch|path>              # 使用 VS Code 打开（快捷命令）
gwt idea <branch|path>              # 使用 IntelliJ IDEA 打开（快捷命令）
```

#### 2.5 Worktree 浏览器
```bash
gwt browse                            # 交互式浏览和选择 worktree 打开
gwt open                              # browse 的别名
```

### 3. 辅助功能

#### 3.1 配置管理
```bash
gwt config set default-path <path>      # 设置默认创建路径
gwt config get default-path             # 获取默认路径配置
gwt config set default-editor <editor>  # 设置默认编辑器
gwt config get default-editor           # 获取默认编辑器配置
gwt config list                         # 显示所有配置
```

#### 3.2 帮助和文档
```bash
gwt help                            # 显示帮助信息
gwt help <command>                  # 显示指定命令的详细帮助
gwt tutorial                        # 显示 worktree 使用教程
```

#### 3.3 交互模式
```bash
gwt interactive                     # 进入交互式操作模式
gwt i                               # interactive 的简写
```

## 用户体验设计

### 1. 智能提示
- 命令补全支持
- 分支名称自动补全
- 路径建议

### 2. 错误处理
- 友好的错误提示信息
- 操作建议
- 自动修复建议

### 3. 输出格式
- 清晰的表格格式
- 颜色编码（绿色=清洁，红色=有修改，黄色=警告）
- JSON 输出支持（用于脚本集成）

## 技术实现要求

### 1. 基础架构
- 使用 Go 语言开发
- 支持跨平台（Windows、macOS、Linux）
- 单二进制文件，无依赖
- 支持主流编辑器（VS Code、IntelliJ IDEA、Vim、Emacs等）

### 2. Git 集成
- 使用 go-git 库或调用系统 git 命令
- 支持 Git 2.6+（worktree 功能最低要求）
- 自动检测 Git 仓库

### 3. 配置存储
- 用户级配置文件（~/.gwt/config）
- 项目级配置文件（.gwt/config）
- 环境变量支持

## 命令行接口设计

### 全局选项
```bash
--verbose, -v     # 详细输出
--quiet, -q       # 安静模式
--dry-run         # 试运行，不实际执行
--force, -f       # 强制操作
--editor, -e      # 指定编辑器
--help, -h        # 帮助信息
```

### 子命令结构
```
gwt
├── list/ls          # 列出 worktree
├── create/add       # 创建 worktree
├── remove/rm/delete # 删除 worktree
├── prune            # 清理无效 worktree
├── switch           # 切换分支
├── status           # 状态检查
├── diff             # 比较差异
├── config           # 配置管理
├── edit             # 编辑器打开
├── code             # VS Code 快捷打开
├── idea             # IDEA 快捷打开
├── browse/open      # 交互式浏览
├── help             # 帮助
└── tutorial         # 教程
```

## 使用场景示例

### 场景1：快速创建功能分支
```bash
# 创建新功能分支的 worktree
gwt create feature/login-page

# 进入目录开始开发
cd feature/login-page
```

### 场景2：同时处理多个分支
```bash
# 查看所有 worktree
gwt list

# 快速切换到热修复分支
gwt switch hotfix/critical-bug
```

### 场景3：快速编辑和浏览
```bash
# 使用默认编辑器打开主分支
gwt edit main

# 使用 VS Code 打开功能分支
gwt code feature/new-ui

# 交互式选择并打开 worktree
gwt browse

# 使用特定编辑器打开
gwt edit hotfix/critical-bug -e vim
```

### 场景4：清理和整理
```bash
# 清理已删除的 worktree
gwt prune

# 删除特定 worktree
gwt rm feature/old-feature
```

## 扩展功能（未来版本）

### 1. 编辑器深度集成
- 自动检测已安装的编辑器
- 支持自定义编辑器命令
- 工作区保存和恢复
- 多窗口管理

### 2. 图形界面
- Web 界面管理 worktree
- 可视化分支关系
- 编辑器集成界面

### 2. 团队协作
- 共享 worktree 配置
- 团队 worktree 模板

### 3. 高级集成
- IDE 插件支持
- CI/CD 集成
- 钩子脚本支持

## 开发优先级

### 第一阶段（MVP）
- [ ] list 命令
- [ ] create 命令
- [ ] remove 命令
- [ ] prune 命令
- [ ] edit 命令（基础编辑器支持）
- [ ] 基础帮助系统

### 第二阶段（增强功能）
- [ ] switch 命令
- [ ] status 命令
- [ ] config 命令
- [ ] 交互模式
- [ ] code/idea 快捷命令
- [ ] browse 交互式浏览

### 第三阶段（高级功能）
- [ ] 批量操作
- [ ] diff 功能
- [ ] 高级配置
- [ ] 插件系统

## 成功标准

1. **易用性**：新用户可以在5分钟内上手基本操作
2. **效率**：比手动使用原生 git worktree 命令节省50%时间
3. **稳定性**：99.9%的命令执行成功率
4. **性能**：列表操作在100个worktree内响应时间<1秒
5. **编辑器支持**：支持10+种主流编辑器和IDE

## 总结

这个 CLI 工具旨在简化 Git worktree 的使用，让开发者能够更高效地管理多个分支的开发工作。通过直观的命令设计和智能的辅助功能，降低 worktree 的使用门槛，提升开发效率。