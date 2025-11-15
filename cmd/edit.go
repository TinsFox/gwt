package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/fatih/color"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	editorpkg "github.com/tinsfox/gwt/internal/editor"
	"github.com/tinsfox/gwt/internal/git"
)

var (
	editEditor    string
	editWait      bool
	editNewWindow bool
)

// editCmd 使用编辑器打开 worktree
var editCmd = &cobra.Command{
	Use:     "edit <branch|path>",
	Aliases: []string{"open", "code"},
	Short:   "使用编辑器打开 worktree",
	Long: `使用指定的编辑器打开 worktree 目录。
	
如果没有指定编辑器，会使用默认编辑器或自动检测。`,
	Example: `  # 使用默认编辑器打开
  gwt edit main
  
  # 使用 VS Code 打开
  gwt edit feature/new-ui -e code
  
  # 使用 Vim 打开
  gwt edit hotfix/critical -e vim
  
  # 在新窗口中打开
  gwt edit develop --new-window`,
	Args: cobra.ExactArgs(1),
	RunE: runEdit,
}

// 快捷命令
var codeCmd = &cobra.Command{
	Use:   "code <branch|path>",
	Short: "使用 VS Code 打开 worktree",
	Long:  "快捷命令，等同于 'gwt edit <branch|path> -e code'",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		editEditor = "code"
		return runEdit(cmd, args)
	},
}

var ideaCmd = &cobra.Command{
	Use:   "idea <branch|path>",
	Short: "使用 IntelliJ IDEA 打开 worktree",
	Long:  "快捷命令，等同于 'gwt edit <branch|path> -e idea'",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		editEditor = "idea"
		return runEdit(cmd, args)
	},
}

var vimCmd = &cobra.Command{
	Use:   "vim <branch|path>",
	Short: "使用 Vim 打开 worktree",
	Long:  "快捷命令，等同于 'gwt edit <branch|path> -e vim'",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		editEditor = "vim"
		return runEdit(cmd, args)
	},
}

func init() {
	rootCmd.AddCommand(editCmd)
	rootCmd.AddCommand(codeCmd)
	rootCmd.AddCommand(ideaCmd)
	rootCmd.AddCommand(vimCmd)

	editCmd.Flags().StringVarP(&editEditor, "editor", "e", "", "指定编辑器")
	editCmd.Flags().BoolVar(&editWait, "wait", false, "等待编辑器关闭后返回")
	editCmd.Flags().BoolVar(&editNewWindow, "new-window", false, "在新窗口中打开")
}

func runEdit(cmd *cobra.Command, args []string) error {
	target := args[0]

	// 检查是否在 git 仓库中
	repo, err := git.OpenRepository(".")
	if err != nil {
		return fmt.Errorf("不是 Git 仓库: %w", err)
	}

	// 确定要打开的目录
	var targetPath string

	// 首先检查是否是已存在的 worktree 路径
	worktrees, err := repo.GetWorktrees()
	if err == nil {
		for _, wt := range worktrees {
			if wt.Branch == target {
				targetPath = wt.Path
				break
			}
			// 检查路径匹配
			if strings.Contains(wt.Path, target) {
				targetPath = wt.Path
				break
			}
		}
	}

	// 如果没有找到，检查是否是相对路径
	if targetPath == "" {
		if _, err := os.Stat(target); err == nil {
			// 是一个存在的路径
			absPath, err := filepath.Abs(target)
			if err == nil {
				targetPath = absPath
			}
		}
	}

	// 如果还是没找到，尝试创建 worktree
	if targetPath == "" {
		// 检查是否是分支名
		branchExists, err := repo.BranchExists(target)
		if err != nil {
			return fmt.Errorf("检查分支失败: %w", err)
		}

		if branchExists {
			// 询问是否创建 worktree
			fmt.Printf("分支 '%s' 存在但没有对应的 worktree。\n", color.CyanString(target))
			fmt.Print("是否创建 worktree? [y/N]: ")

			var response string
			fmt.Scanln(&response)

			if strings.ToLower(response) == "y" || strings.ToLower(response) == "yes" {
				// 创建 worktree
				worktree, err := repo.CreateWorktree(git.CreateWorktreeOptions{
					Branch: target,
					Path:   target,
				})
				if err != nil {
					return fmt.Errorf("创建 worktree 失败: %w", err)
				}
				targetPath = worktree.Path
			} else {
				return fmt.Errorf("取消操作")
			}
		} else {
			return fmt.Errorf("找不到分支或路径: %s", target)
		}
	}

	// 验证目录存在
	if _, err := os.Stat(targetPath); os.IsNotExist(err) {
		return fmt.Errorf("目录不存在: %s", targetPath)
	}

	// 确定编辑器
	editor := editEditor
	if editor == "" {
		editor = viper.GetString("editor.default")
	}

	// 检测编辑器
	editorInfo, err := editorpkg.DetectEditor(editor)
	if err != nil {
		return fmt.Errorf("检测编辑器失败: %w", err)
	}

	if !quiet {
		fmt.Printf("使用编辑器打开:\n")
		fmt.Printf("  目录: %s\n", color.YellowString(targetPath))
		fmt.Printf("  编辑器: %s\n", color.CyanString(editorInfo.Name))
		if editorInfo.Command != "" {
			fmt.Printf("  命令: %s\n", editorInfo.Command)
		}
	}

	// 构建命令参数
	args = []string{targetPath}

	// 添加编辑器特定的参数
	if editNewWindow && editorInfo.SupportsNewWindow {
		args = append([]string{editorInfo.NewWindowFlag}, args...)
	}

	if editWait && editorInfo.SupportsWait {
		args = append(args, editorInfo.WaitFlag)
	}

	// 执行编辑器
	cmdExec := exec.Command(editorInfo.Command, args...)
	cmdExec.Stdout = os.Stdout
	cmdExec.Stderr = os.Stderr
	cmdExec.Stdin = os.Stdin

	if err := cmdExec.Run(); err != nil {
		return fmt.Errorf("启动编辑器失败: %w", err)
	}

	return nil
}
