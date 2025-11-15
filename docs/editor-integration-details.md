# 编辑器集成功能详细设计

## 支持的编辑器列表

### 1. 主流代码编辑器
- **VS Code**: `code` 命令
- **Visual Studio Code Insiders**: `code-insiders`
- **Sublime Text**: `subl`
- **Atom**: `atom`
- **Brackets**: `brackets`

### 2. 专业IDE
- **IntelliJ IDEA**: `idea`
- **WebStorm**: `webstorm`
- **PyCharm**: `pycharm`
- **CLion**: `clion`
- **PhpStorm**: `phpstorm`
- **RubyMine**: `rubymine`
- **DataGrip**: `datagrip`
- **Rider**: `rider`
- **GoLand**: `goland`

### 3. 终端编辑器
- **Vim**: `vim`
- **Neovim**: `nvim`
- **Emacs**: `emacs`
- **Nano**: `nano`
- **Micro**: `micro`

### 4. 其他编辑器
- **Notepad++** (Windows): `notepad++`
- **TextMate** (macOS): `mate`
- **BBEdit** (macOS): `bbedit`
- **Kate** (Linux): `kate`
- **Gedit** (Linux): `gedit`

## 编辑器检测机制

### 1. 自动检测流程
```go
func detectEditors() []Editor {
    // 1. 检查系统PATH中的编辑器命令
    // 2. 检查注册表/配置文件中的安装信息
    // 3. 检查常见安装路径
    // 4. 返回可用的编辑器列表
}
```

### 2. 优先级排序
1. 用户配置的默认编辑器
2. 项目级配置的编辑器
3. 系统检测到的最新安装的编辑器
4. 按流行度排序的备用编辑器

## 命令实现细节

### gwt edit 命令
```bash
# 基本用法
gwt edit <branch|path>              # 使用默认编辑器打开
gwt edit <branch|path> -e vim       # 指定编辑器
gwt edit <branch|path> --editor=code # 长格式指定

# 高级选项
gwt edit <branch> --new-window       # 在新窗口中打开
gwt edit <branch> --wait            # 等待编辑器关闭后返回
```

### 快捷命令
```bash
gwt code <branch|path>              # VS Code 快捷方式
gwt idea <branch|path>              # IntelliJ IDEA 快捷方式
gwt vim <branch|path>               # Vim 快捷方式
gwt subl <branch|path>              # Sublime Text 快捷方式
```

### 交互式浏览
```bash
gwt browse                          # 显示所有 worktree 列表
# 用户选择后自动用默认编辑器打开

# 带过滤的浏览
gwt browse --filter="feature/*"     # 只显示 feature 分支
gwt browse --sort=modified          # 按修改时间排序
```

## 配置系统

### 用户配置 (~/.gwt/config)
```yaml
editor:
  default: "code"                    # 默认编辑器
  fallback: ["vim", "nano"]         # 备用编辑器
  options:
    code: "--new-window --wait"      # VS Code 选项
    idea: "--line 1"                 # IDEA 选项
    vim: "+set number"               # Vim 选项

# 项目特定配置
projects:
  - path: "/path/to/project"
    default_editor: "idea"
    auto_detect: true
```

### 项目配置 (.gwt/config)
```yaml
editor:
  default: "webstorm"                # 项目默认编辑器
  workspace_file: ".idea/workspace.xml" # 工作区文件
```

## 跨平台支持

### Windows
- 检测注册表中的安装信息
- 支持 Windows Store 安装的编辑器
- 处理路径中的空格和特殊字符
- PowerShell 和 CMD 兼容性

### macOS
- 检测 Applications 文件夹
- 支持 Homebrew 安装的编辑器
- 处理 .app 包结构
- 支持 Spotlight 搜索

### Linux
- 检测常见安装路径 (/usr/bin, /opt, /snap)
- 支持 Flatpak 和 AppImage
- 处理桌面文件 (.desktop)
- 发行版特定检测

## 高级功能

### 1. 工作区恢复
```bash
# 保存当前工作区状态
gwt edit <branch> --save-workspace

# 恢复工作区（打开所有相关文件）
gwt edit <branch> --restore-workspace
```

### 2. 多窗口管理
```bash
# 在分屏中打开多个 worktree
gwt edit main feature/1 feature/2 --split

# 使用标签页打开
gwt edit branch1 branch2 --tabs
```

### 3. 智能打开策略
- 如果编辑器已打开该项目，切换到对应窗口
- 如果 worktree 有未保存更改，提示用户
- 根据文件类型选择最佳的编辑器
- 支持项目特定的编辑器配置

## 错误处理

### 常见错误场景
1. **编辑器未安装**: 提供安装建议和备用选项
2. **命令未找到**: 检查 PATH 和安装状态
3. **权限不足**: 提示使用 sudo 或检查权限
4. **工作区损坏**: 提供修复选项

### 用户友好的错误信息
```
错误: VS Code 未安装或不在 PATH 中
建议: 
  1. 安装 VS Code: https://code.visualstudio.com/
  2. 使用备用编辑器: gwt edit main -e vim
  3. 设置默认编辑器: gwt config set default-editor vim
```

## 性能优化

### 1. 缓存机制
- 缓存编辑器检测结果
- 缓存工作区状态
- 定期更新缓存

### 2. 并发处理
- 并行检测多个编辑器
- 异步打开编辑器
- 后台更新状态

### 3. 资源管理
- 限制同时打开的编辑器数量
- 内存使用优化
- 清理临时文件

## 安全考虑

### 1. 命令执行安全
- 验证编辑器命令路径
- 防止命令注入
- 沙箱环境执行

### 2. 权限管理
- 最小权限原则
- 敏感操作确认
- 审计日志记录

## 测试策略

### 1. 单元测试
- 编辑器检测逻辑
- 配置解析
- 命令构建

### 2. 集成测试
- 实际编辑器调用
- 跨平台兼容性
- 错误处理场景

### 3. 用户测试
- 不同技术背景的用户
- 各种开发环境
- 真实工作流程