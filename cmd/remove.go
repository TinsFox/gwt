package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
)

var (
	removeForce bool
)

// removeCmd 删除 worktree
var removeCmd = &cobra.Command{
	Use:     "remove <path|branch>",
	Aliases: []string{"rm", "delete", "del"},
	Short:   "删除 Git worktree",
	Long:    `删除指定的 Git worktree，可以按路径或分支名删除。`,
	Example: `  # 按路径删除
  gwt remove /path/to/worktree
  
  # 按分支名删除
  gwt remove feature/old-feature
  
  # 强制删除
  gwt remove feature/broken -f`,
	Args: cobra.ExactArgs(1),
	RunE: runRemove,
}

func init() {
	rootCmd.AddCommand(removeCmd)

	removeCmd.Flags().BoolVarP(&removeForce, "force", "f", false, "强制删除")
}

func runRemove(cmd *cobra.Command, args []string) error {
	target := args[0]

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
		return fmt.Errorf("没有 worktree 可删除")
	}

	// 查找要删除的 worktree
	var targetWorktree *git.WorktreeInfo
	var targetPath string

	// 首先尝试按分支名匹配
	for i, wt := range worktrees {
		if wt.Branch == target {
			targetWorktree = &worktrees[i]
			targetPath = wt.Path
			break
		}
	}

	// 如果没有找到，尝试按路径匹配
	if targetWorktree == nil {
		// 尝试作为相对路径
		absPath, err := filepath.Abs(target)
		if err == nil {
			for i, wt := range worktrees {
				if wt.Path == absPath {
					targetWorktree = &worktrees[i]
					targetPath = wt.Path
					break
				}
			}
		}
	}

	// 还是没有找到，尝试部分匹配
	if targetWorktree == nil {
		for i, wt := range worktrees {
			if strings.Contains(wt.Path, target) || strings.Contains(wt.Branch, target) {
				targetWorktree = &worktrees[i]
				targetPath = wt.Path
				break
			}
		}
	}

	if targetWorktree == nil {
		return fmt.Errorf("未找到 worktree: %s", target)
	}

	// 检查是否是主工作区
	if targetWorktree.IsMain {
		return fmt.Errorf("不能删除主工作区")
	}

	// 显示要删除的信息
	if !quiet {
		fmt.Printf("删除 worktree:\n")
		fmt.Printf("  路径: %s\n", color.YellowString(targetPath))
		fmt.Printf("  分支: %s\n", color.CyanString(targetWorktree.Branch))

		if targetWorktree.IsDirty {
			fmt.Printf("  状态: %s\n", color.RedString("有未提交的修改"))
		}

		if !removeForce {
			fmt.Print("确认删除? [y/N]: ")

			var response string
			fmt.Scanln(&response)

			if strings.ToLower(response) != "y" && strings.ToLower(response) != "yes" {
				return fmt.Errorf("取消删除")
			}
		}
	}

	// 执行删除
	if err := repo.RemoveWorktree(targetPath); err != nil {
		if removeForce {
			// 强制删除，尝试手动删除目录
			if err := os.RemoveAll(targetPath); err != nil {
				return fmt.Errorf("强制删除目录失败: %w", err)
			}

			// 清理 git worktree 记录
			if err := repo.PruneWorktrees(); err != nil {
				logWarning(fmt.Sprintf("清理 worktree 记录失败: %v", err))
			}
		} else {
			return err
		}
	}

	if !quiet {
		fmt.Printf("✅ %s\n", color.GreenString("worktree 删除成功"))
	}

	return nil
}

func logWarning(msg string) {
	if !quiet {
		fmt.Printf("⚠️  %s\n", color.YellowString(msg))
	}
}
