package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/fatih/color"
	"github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"
	"github.com/tinsfox/gwt/internal/git"
)

// browseCmd 交互式浏览 worktree
var browseCmd = &cobra.Command{
	Use:     "browse",
	Aliases: []string{"open", "select"},
	Short:   "交互式浏览和选择 worktree",
	Long:    `以交互式表格形式显示所有 worktree，让用户选择要打开的 worktree。`,
	Example: `  # 交互式浏览
  gwt browse
  
  # 使用默认编辑器打开
  gwt browse --edit`,
	RunE: runBrowse,
}

var (
	browseEdit bool
)

func init() {
	rootCmd.AddCommand(browseCmd)

	browseCmd.Flags().BoolVarP(&browseEdit, "edit", "e", false, "选择后用默认编辑器打开")
}

func runBrowse(cmd *cobra.Command, args []string) error {
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
		fmt.Println("当前仓库没有 worktree")
		return nil
	}

	// 显示交互式表格
	selectedIndex, err := showInteractiveTable(worktrees)
	if err != nil {
		return err
	}

	if selectedIndex == -1 {
		return nil // 用户取消
	}

	selectedWorktree := worktrees[selectedIndex]

	if !quiet {
		fmt.Printf("选择: %s (%s)\n", selectedWorktree.Branch, selectedWorktree.Path)
	}

	// 根据选项执行操作
	if browseEdit {
		// 使用编辑器打开
		return openWithEditor(selectedWorktree.Path)
	} else {
		// 切换到目录
		return changeDirectoryBrowse(selectedWorktree.Path)
	}
}

// showInteractiveTable 显示交互式表格
func showInteractiveTable(worktrees []git.WorktreeInfo) (int, error) {
	fmt.Println()
	fmt.Println("选择要打开的 worktree (输入数字，按 Enter 确认，按 q 退出):")
	fmt.Println()

	// 创建表格
	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"编号", "分支", "路径", "状态"})

	// 设置样式
	table.SetBorder(true)
	table.SetAlignment(tablewriter.ALIGN_LEFT)
	table.SetHeaderAlignment(tablewriter.ALIGN_CENTER)

	// 添加数据
	for i, wt := range worktrees {
		status := getWorktreeStatusBrowse(&wt)
		table.Append([]string{
			strconv.Itoa(i + 1),
			wt.Branch,
			wt.Path,
			status,
		})
	}

	table.Render()

	fmt.Println()
	fmt.Print("输入编号: ")

	var input string
	fmt.Scanln(&input)

	// 处理输入
	input = strings.TrimSpace(input)

	if input == "q" || input == "quit" || input == "exit" {
		return -1, nil
	}

	// 解析数字
	var index int
	if _, err := fmt.Sscanf(input, "%d", &index); err != nil {
		return -1, fmt.Errorf("无效的输入: %s", input)
	}

	// 验证范围
	if index < 1 || index > len(worktrees) {
		return -1, fmt.Errorf("编号超出范围: %d (有效范围: 1-%d)", index, len(worktrees))
	}

	return index - 1, nil
}

// getWorktreeStatusBrowse 获取 worktree 状态显示
func getWorktreeStatusBrowse(wt *git.WorktreeInfo) string {
	if wt.IsLocked {
		return color.YellowString("已锁定")
	}

	if wt.IsDirty {
		return color.RedString("已修改")
	}

	if wt.IsMain {
		return color.GreenString("主工作区")
	}

	return color.GreenString("清洁")
}

// openWithEditor 使用编辑器打开目录
func openWithEditor(path string) error {
	// 这里简化处理，实际应该调用 edit 命令的逻辑
	fmt.Printf("使用默认编辑器打开: %s\n", path)

	// 获取默认编辑器
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "vi"
	}

	cmd := exec.Command(editor, path)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

// changeDirectoryBrowse 切换目录
func changeDirectoryBrowse(path string) error {
	fmt.Printf("切换到目录: %s\n", path)

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

	return cmd.Run()
}
