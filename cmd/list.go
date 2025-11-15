package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"text/tabwriter"

	"github.com/fatih/color"
	"github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
	"github.com/tinsfox/gwt/internal/ui"
)

var (
	listAll    bool
	listJSON   bool
	listFormat string
)

// listCmd 列出所有 worktree
var listCmd = &cobra.Command{
	Use:     "list",
	Aliases: []string{"ls"},
	Short:   "列出所有 Git worktree",
	Long:    `显示当前仓库中所有的 worktree，包括路径、分支、状态等信息。`,
	RunE:    runList,
}

func init() {
	rootCmd.AddCommand(listCmd)

	listCmd.Flags().BoolVarP(&listAll, "all", "a", false, "显示所有 worktree（包括已删除的）")
	listCmd.Flags().BoolVar(&listJSON, "json", false, "以 JSON 格式输出")
	listCmd.Flags().StringVarP(&listFormat, "format", "f", "table", "输出格式: table, simple, json")
}

func runList(cmd *cobra.Command, args []string) error {
	// 检查是否在 git 仓库中
	repo, err := git.OpenRepository(".")
	if err != nil {
		return fmt.Errorf("不是 Git 仓库: %w", err)
	}

	// 获取 worktree 列表
	worktrees, err := repo.GetWorktrees()
	if err != nil {
		return fmt.Errorf("获取 worktree 列表失败: %w", err)
	}

	if len(worktrees) == 0 {
		fmt.Println("当前仓库没有 worktree")
		return nil
	}

	// 根据格式输出
	switch listFormat {
	case "json":
		return outputJSON(worktrees)
	case "simple":
		return outputSimple(worktrees)
	case "table":
		return outputTable(worktrees)
	default:
		return fmt.Errorf("不支持的输出格式: %s", listFormat)
	}
}

// outputTable 以表格形式输出
func outputTable(worktrees []git.WorktreeInfo) error {
	// 创建表格
	table := tablewriter.NewWriter(os.Stdout)

	// 设置表头
	headers := []string{"路径", "分支", "状态", "上次提交"}
	if verbose {
		headers = append(headers, "创建时间", "锁定状态")
	}
	table.SetHeader(headers)

	// 设置样式
	table.SetBorder(true)
	table.SetRowLine(false)
	table.SetCenterSeparator("|")
	table.SetColumnSeparator("|")
	table.SetRowSeparator("-")
	table.SetAlignment(tablewriter.ALIGN_LEFT)
	table.SetHeaderAlignment(tablewriter.ALIGN_LEFT)

	// 添加数据
	for _, wt := range worktrees {
		row := make([]string, 0)

		// 路径（相对路径）
		relPath, _ := filepath.Rel(".", wt.Path)
		if relPath == "" {
			relPath = "."
		}
		row = append(row, ui.ColorPath(relPath))

		// 分支
		branch := wt.Branch
		if branch == "" {
			branch = "(分离 HEAD)"
		}
		row = append(row, ui.ColorBranch(branch))

		// 状态
		status := getWorktreeStatus(&wt)
		row = append(row, status)

		// 上次提交
		commitInfo := formatCommitInfo(wt.LastCommit)
		row = append(row, commitInfo)

		// 详细信息
		if verbose {
			row = append(row, wt.CreatedAt.Format("2006-01-02 15:04"))
			row = append(row, getLockStatus(wt.IsLocked))
		}

		table.Append(row)
	}

	table.Render()
	return nil
}

// outputSimple 以简单格式输出
func outputSimple(worktrees []git.WorktreeInfo) error {
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)

	for _, wt := range worktrees {
		relPath, _ := filepath.Rel(".", wt.Path)
		if relPath == "" {
			relPath = "."
		}

		branch := wt.Branch
		if branch == "" {
			branch = "(detached)"
		}

		status := getSimpleStatus(&wt)

		fmt.Fprintf(w, "%s\t%s\t%s\n", relPath, branch, status)
	}

	return w.Flush()
}

// outputJSON 以 JSON 格式输出
func outputJSON(worktrees []git.WorktreeInfo) error {
	// 这里需要实现 JSON 输出
	// 为了简化，先用简单格式代替
	return outputSimple(worktrees)
}

// getWorktreeStatus 获取 worktree 状态
func getWorktreeStatus(wt *git.WorktreeInfo) string {
	if wt.IsLocked {
		return ui.ColorWarning("已锁定")
	}

	if wt.IsDirty {
		return ui.ColorError("已修改")
	}

	if wt.IsMain {
		return ui.ColorSuccess("主工作区")
	}

	return ui.ColorSuccess("清洁")
}

// getSimpleStatus 获取简化状态
func getSimpleStatus(wt *git.WorktreeInfo) string {
	if wt.IsLocked {
		return "locked"
	}
	if wt.IsDirty {
		return "dirty"
	}
	if wt.IsMain {
		return "main"
	}
	return "clean"
}

// getLockStatus 获取锁定状态
func getLockStatus(locked bool) string {
	if locked {
		return color.YellowString("已锁定")
	}
	return color.GreenString("未锁定")
}

// formatCommitInfo 格式化提交信息
func formatCommitInfo(commit git.CommitInfo) string {
	if commit.Hash == "" {
		return "无提交记录"
	}

	shortHash := commit.Hash[:7]
	subject := commit.Subject
	if len(subject) > 30 {
		subject = subject[:27] + "..."
	}

	return fmt.Sprintf("%s %s", shortHash, subject)
}
