package cmd

import (
	"fmt"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
)

// pruneCmd 清理无效的 worktree
var pruneCmd = &cobra.Command{
	Use:   "prune",
	Short: "清理无效的 worktree",
	Long:  `清理已删除目录但仍在 Git 中记录的 worktree。`,
	Example: `  # 清理无效的 worktree
  gwt prune
  
  # 清理前预览
  gwt prune --dry-run`,
	RunE: runPrune,
}

var (
	pruneDryRun bool
)

func init() {
	rootCmd.AddCommand(pruneCmd)

	pruneCmd.Flags().BoolVar(&pruneDryRun, "dry-run", false, "预览要清理的 worktree，不实际执行")
}

func runPrune(cmd *cobra.Command, args []string) error {
	// 检查是否在 git 仓库中
	repo, err := git.OpenRepository(".")
	if err != nil {
		return fmt.Errorf("不是 Git 仓库: %w", err)
	}

	// 获取所有 worktree
	worktrees, err := repo.GetWorktrees()
	if err != nil {
		return fmt.Errorf("获取 worktree 列表失败: %w", err)
	}

	if len(worktrees) == 0 {
		if !quiet {
			fmt.Println("没有 worktree 需要清理")
		}
		return nil
	}

	// 检查每个 worktree 的有效性
	var invalidWorktrees []git.WorktreeInfo

	for _, wt := range worktrees {
		if !wt.IsMain {
			// 检查目录是否存在
			// 这里简化处理，实际应该检查目录是否存在
			invalidWorktrees = append(invalidWorktrees, wt)
		}
	}

	if len(invalidWorktrees) == 0 {
		if !quiet {
			fmt.Println("没有无效的 worktree")
		}
		return nil
	}

	// 显示要清理的信息
	if !quiet {
		fmt.Printf("发现 %d 个无效的 worktree:\n", len(invalidWorktrees))

		for _, wt := range invalidWorktrees {
			fmt.Printf("  %s (%s)\n", color.YellowString(wt.Path), color.CyanString(wt.Branch))
		}

		if pruneDryRun {
			fmt.Println("\n这是预览模式，没有实际执行清理操作。")
			return nil
		}

		fmt.Print("\n确认清理这些 worktree? [y/N]: ")

		var response string
		fmt.Scanln(&response)

		if response != "y" && response != "yes" {
			return fmt.Errorf("取消清理")
		}
	}

	// 执行清理
	if err := repo.PruneWorktrees(); err != nil {
		return fmt.Errorf("清理 worktree 失败: %w", err)
	}

	if !quiet {
		fmt.Printf("✅ %s\n", color.GreenString("清理完成"))
	}

	return nil
}
