package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
)

var (
	createBranch string
	createPath   string
	createForce  bool
)

// createCmd 创建新的 worktree
var createCmd = &cobra.Command{
	Use:     "create <branch> [path]",
	Aliases: []string{"add", "new"},
	Short:   "创建新的 Git worktree",
	Long: `创建一个新的 Git worktree，基于指定的分支。
	
如果分支不存在，会自动创建新分支。
如果没有指定路径，会使用分支名作为目录名。`,
	Example: `  # 创建基于 main 分支的 worktree
  gwt create main
  
  # 创建新分支并建立 worktree
  gwt create feature/new-feature
  
  # 指定路径
  gwt create feature/login /tmp/login-feature
  
  # 强制创建（如果目录已存在）
  gwt create hotfix/critical -f`,
	Args: cobra.RangeArgs(1, 2),
	RunE: runCreate,
}

func init() {
	rootCmd.AddCommand(createCmd)

	createCmd.Flags().StringVarP(&createBranch, "branch", "b", "", "基于的分支（默认: 当前分支）")
	createCmd.Flags().StringVarP(&createPath, "path", "p", "", "worktree 路径（默认: 分支名）")
	createCmd.Flags().BoolVarP(&createForce, "force", "f", false, "强制创建，即使目录已存在")
}

func runCreate(cmd *cobra.Command, args []string) error {
	branch := args[0]

	// 确定路径
	path := createPath
	if path == "" {
		if len(args) > 1 {
			path = args[1]
		} else {
			// 使用分支名作为路径
			path = branch
		}
	}

	// 转换为绝对路径
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("转换路径失败: %w", err)
	}

	// 检查是否在 git 仓库中
	repo, err := git.OpenRepository(".")
	if err != nil {
		return fmt.Errorf("不是 Git 仓库: %w", err)
	}

	// 检查分支是否存在
	branchExists, err := repo.BranchExists(branch)
	if err != nil {
		return fmt.Errorf("检查分支失败: %w", err)
	}

	// 显示操作信息
	if !quiet {
		fmt.Printf("创建 worktree:\n")
		fmt.Printf("  分支: %s\n", color.CyanString(branch))
		fmt.Printf("  路径: %s\n", color.YellowString(absPath))

		if !branchExists {
			fmt.Printf("  操作: %s\n", color.YellowString("创建新分支"))
		}
	}

	// 检查目标目录
	if _, err := os.Stat(absPath); err == nil {
		if !createForce {
			return fmt.Errorf("目录已存在: %s，使用 -f 强制创建", absPath)
		}

		if !quiet {
			fmt.Printf("  警告: %s\n", color.YellowString("目录已存在，强制创建"))
		}
	}

	// 创建 worktree
	options := git.CreateWorktreeOptions{
		Branch:       branch,
		Path:         absPath,
		CreateBranch: !branchExists,
		Force:        createForce,
	}

	if createBranch != "" {
		options.BaseBranch = createBranch
	}

	worktree, err := repo.CreateWorktree(options)
	if err != nil {
		return fmt.Errorf("创建 worktree 失败: %w", err)
	}

	// 显示成功信息
	if !quiet {
		fmt.Println()
		fmt.Printf("✅ %s\n", color.GreenString("worktree 创建成功！"))
		fmt.Printf("   路径: %s\n", worktree.Path)
		fmt.Printf("   分支: %s\n", color.CyanString(worktree.Branch))
		fmt.Println()
		fmt.Printf("💡 %s\n", color.BlueString("提示:"))
		fmt.Printf("   cd %s    # 进入 worktree 目录\n", worktree.Path)
		fmt.Printf("   gwt edit %s  # 用编辑器打开\n", worktree.Branch)
	}

	return nil
}
