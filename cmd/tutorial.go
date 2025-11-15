package cmd

import (
	"fmt"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
)

// tutorialCmd 显示使用教程
var tutorialCmd = &cobra.Command{
	Use:   "tutorial",
	Short: "显示 Git worktree 使用教程",
	Long:  `为新手用户提供 Git worktree 的概念介绍和本工具的使用指南。`,
	RunE:  runTutorial,
}

func init() {
	rootCmd.AddCommand(tutorialCmd)
}

func runTutorial(cmd *cobra.Command, args []string) error {
	fmt.Println()
	fmt.Println(color.CyanString("🌟 Git Worktree 使用教程"))
	fmt.Println(color.BlueString("========================"))
	fmt.Println()

	// 基本概念
	fmt.Println(color.YellowString("📚 基本概念:"))
	fmt.Println("Git worktree 允许你在同一个仓库中创建多个工作目录，每个目录可以切换到不同的分支。")
	fmt.Println("这样你就可以同时处理多个分支，而不需要频繁地切换分支。")
	fmt.Println()

	// 常用命令
	fmt.Println(color.YellowString("🔧 常用命令:"))
	fmt.Println()

	// 列出 worktree
	fmt.Println(color.GreenString("1. 查看所有 worktree:"))
	fmt.Println("   gwt list")
	fmt.Println("   # 或者简写: gwt ls")
	fmt.Println()

	// 创建 worktree
	fmt.Println(color.GreenString("2. 创建新的 worktree:"))
	fmt.Println("   gwt create <分支名>")
	fmt.Println("   gwt create feature/new-feature")
	fmt.Println("   gwt create hotfix/critical /tmp/hotfix")
	fmt.Println()

	// 使用编辑器打开
	fmt.Println(color.GreenString("3. 使用编辑器打开 worktree:"))
	fmt.Println("   gwt edit <分支名>")
	fmt.Println("   gwt edit main -e code    # 使用 VS Code")
	fmt.Println("   gwt edit feature -e vim  # 使用 Vim")
	fmt.Println("   gwt code feature         # VS Code 快捷命令")
	fmt.Println("   gwt idea feature         # IDEA 快捷命令")
	fmt.Println()

	// 交互式浏览
	fmt.Println(color.GreenString("4. 交互式浏览 worktree:"))
	fmt.Println("   gwt browse")
	fmt.Println("   # 显示所有 worktree，输入数字选择")
	fmt.Println()

	// 删除 worktree
	fmt.Println(color.GreenString("5. 删除 worktree:"))
	fmt.Println("   gwt remove <分支名或路径>")
	fmt.Println("   gwt remove feature/old-feature")
	fmt.Println("   gwt remove /path/to/worktree")
	fmt.Println()

	// 清理
	fmt.Println(color.GreenString("6. 清理无效的 worktree:"))
	fmt.Println("   gwt prune")
	fmt.Println()

	// 实际使用场景
	fmt.Println(color.YellowString("💡 实际使用场景:"))
	fmt.Println()

	fmt.Println(color.CyanString("场景 1: 同时处理多个功能"))
	fmt.Println("# 在 main 分支上修复 bug")
	fmt.Println("gwt create hotfix/login-bug")
	fmt.Println("cd hotfix/login-bug")
	fmt.Println("# ... 修复工作 ...")
	fmt.Println()
	fmt.Println("# 同时开发新功能")
	fmt.Println("gwt create feature/new-dashboard")
	fmt.Println("gwt edit feature/new-dashboard -e code")
	fmt.Println("# ... 开发工作 ...")
	fmt.Println()

	fmt.Println(color.CyanString("场景 2: 代码审查"))
	fmt.Println("# 为同事的 PR 创建 worktree 进行审查")
	fmt.Println("gwt create review/pr-123")
	fmt.Println("gwt code review/pr-123")
	fmt.Println("# ... 审查代码 ...")
	fmt.Println()

	fmt.Println(color.CyanString("场景 3: 快速切换"))
	fmt.Println("# 使用交互式浏览快速切换")
	fmt.Println("gwt browse")
	fmt.Println("# 或者使用 switch 命令")
	fmt.Println("gwt switch main")
	fmt.Println("gwt switch feature/new-ui")
	fmt.Println()

	// 最佳实践
	fmt.Println(color.YellowString("✨ 最佳实践:"))
	fmt.Println("1. 使用描述性的分支名和目录名")
	fmt.Println("2. 定期清理不再使用的 worktree (gwt prune)")
	fmt.Println("3. 为不同类型的任务使用不同的命名约定")
	fmt.Println("   - feature/*: 新功能开发")
	fmt.Println("   - hotfix/*: 紧急修复")
	fmt.Println("   - bugfix/*: 普通 bug 修复")
	fmt.Println("   - review/*: 代码审查")
	fmt.Println("4. 使用编辑器快捷命令提高效率")
	fmt.Println("5. 配置默认编辑器避免重复输入")
	fmt.Println()

	// 配置建议
	fmt.Println(color.YellowString("⚙️  配置建议:"))
	fmt.Println("# 设置默认编辑器")
	fmt.Println("gwt config set editor.default code")
	fmt.Println()
	fmt.Println("# 查看当前配置")
	fmt.Println("gwt config list")
	fmt.Println()

	// 获取帮助
	fmt.Println(color.YellowString("❓ 获取帮助:"))
	fmt.Println("gwt --help              # 查看所有命令")
	fmt.Println("gwt help <command>      # 查看具体命令帮助")
	fmt.Println("gwt completion bash     # 生成 bash 补全")
	fmt.Println()

	fmt.Println(color.GreenString("🎉 恭喜！现在你可以开始使用 gwt 来管理你的 Git worktree 了！"))
	fmt.Println()

	return nil
}
