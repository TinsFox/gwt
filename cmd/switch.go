package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
)

// switchCmd 切换到指定分支的 worktree
var switchCmd = &cobra.Command{
	Use:     "switch <branch>",
	Aliases: []string{"sw", "checkout", "co"},
	Short:   "切换到指定分支的 worktree",
	Long:    `快速切换到指定分支的 worktree，如果不存在则询问是否创建。`,
	Example: `  # 切换到 main 分支的 worktree
  gwt switch main
  
  # 切换到功能分支
  gwt switch feature/new-ui
  
  # 如果不存在则自动创建
  gwt switch hotfix/critical`,
	Args: cobra.ExactArgs(1),
	RunE: runSwitch,
}

func init() {
	rootCmd.AddCommand(switchCmd)
}

func runSwitch(cmd *cobra.Command, args []string) error {
	branch := args[0]

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

	// 查找指定分支的 worktree
	var targetWorktree *git.WorktreeInfo

	for i, wt := range worktrees {
		if wt.Branch == branch {
			targetWorktree = &worktrees[i]
			break
		}
	}

	// 如果找到，直接切换到该目录
	if targetWorktree != nil {
		if !quiet {
			fmt.Printf("切换到 worktree:\n")
			fmt.Printf("  分支: %s\n", color.CyanString(branch))
			fmt.Printf("  路径: %s\n", color.YellowString(targetWorktree.Path))
		}

		// 使用 cd 命令切换目录
		return changeDirectory(targetWorktree.Path)
	}

	// 没有找到，询问是否创建
	fmt.Printf("分支 '%s' 的 worktree 不存在。\n", color.CyanString(branch))
	fmt.Print("是否创建 worktree? [y/N]: ")

	var response string
	fmt.Scanln(&response)

	if response != "y" && response != "yes" {
		return fmt.Errorf("取消操作")
	}

	// 创建 worktree
	worktree, err := repo.CreateWorktree(git.CreateWorktreeOptions{
		Branch: branch,
		Path:   branch,
	})
	if err != nil {
		return fmt.Errorf("创建 worktree 失败: %w", err)
	}

	if !quiet {
		fmt.Printf("✅ worktree 创建成功，路径: %s\n", color.YellowString(worktree.Path))
	}

	// 切换到新创建的目录
	return changeDirectory(worktree.Path)
}

// changeDirectory 切换目录（通过执行 shell 的 cd 命令）
func changeDirectory(path string) error {
	// 获取当前 shell
	shell := os.Getenv("SHELL")
	if shell == "" {
		shell = "/bin/bash"
	}

	// 构建命令
	cmd := exec.Command(shell, "-c", fmt.Sprintf("cd %s && exec $SHELL", path))
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// 执行命令
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("切换目录失败: %w", err)
	}

	return nil
}
