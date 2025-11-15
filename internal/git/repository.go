package git

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Repository 表示 Git 仓库
type Repository struct {
	Path     string
	gitDir   string
	worktree string
}

// WorktreeInfo 表示 worktree 信息
type WorktreeInfo struct {
	Path       string
	Branch     string
	IsMain     bool
	IsLocked   bool
	IsDirty    bool
	CreatedAt  time.Time
	LastCommit CommitInfo
}

// CommitInfo 表示提交信息
type CommitInfo struct {
	Hash    string
	Subject string
	Author  string
	Date    time.Time
}

// CreateWorktreeOptions 创建 worktree 的选项
type CreateWorktreeOptions struct {
	Branch       string
	Path         string
	BaseBranch   string
	CreateBranch bool
	Force        bool
}

// Worktree 表示创建的 worktree
type Worktree struct {
	Path   string
	Branch string
}

// OpenRepository 打开 Git 仓库
func OpenRepository(path string) (*Repository, error) {
	// 检查路径是否存在
	if _, err := os.Stat(path); err != nil {
		return nil, fmt.Errorf("路径不存在: %s", path)
	}

	// 查找 .git 目录
	gitDir, err := findGitDir(path)
	if err != nil {
		return nil, fmt.Errorf("不是 Git 仓库: %s", path)
	}

	// 获取仓库根目录
	repoPath := filepath.Dir(gitDir)
	if filepath.Base(gitDir) == ".git" {
		repoPath = filepath.Dir(gitDir)
	}

	return &Repository{
		Path:   repoPath,
		gitDir: gitDir,
	}, nil
}

// findGitDir 查找 .git 目录
func findGitDir(path string) (string, error) {
	// 尝试直接查找 .git 目录
	gitPath := filepath.Join(path, ".git")
	if info, err := os.Stat(gitPath); err == nil {
		if info.IsDir() {
			return gitPath, nil
		}
		// 可能是 gitfile
		content, err := os.ReadFile(gitPath)
		if err == nil {
			line := strings.TrimSpace(string(content))
			if strings.HasPrefix(line, "gitdir: ") {
				gitdir := strings.TrimPrefix(line, "gitdir: ")
				if filepath.IsAbs(gitdir) {
					return gitdir, nil
				}
				return filepath.Join(path, gitdir), nil
			}
		}
	}

	// 向上查找
	parent := filepath.Dir(path)
	if parent == path {
		return "", fmt.Errorf("未找到 .git 目录")
	}

	return findGitDir(parent)
}

// GetWorktrees 获取所有 worktree
func (r *Repository) GetWorktrees() ([]WorktreeInfo, error) {
	cmd := exec.Command("git", "worktree", "list", "--porcelain")
	cmd.Dir = r.Path

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("执行 git worktree list 失败: %w", err)
	}

	return parseWorktreeList(string(output))
}

// parseWorktreeList 解析 worktree 列表输出
func parseWorktreeList(output string) ([]WorktreeInfo, error) {
	var worktrees []WorktreeInfo
	var current *WorktreeInfo

	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			if current != nil {
				worktrees = append(worktrees, *current)
				current = nil
			}
			continue
		}

		if current == nil {
			current = &WorktreeInfo{}
		}

		// 解析字段
		if strings.HasPrefix(line, "worktree ") {
			current.Path = strings.TrimPrefix(line, "worktree ")
		} else if strings.HasPrefix(line, "HEAD ") {
			head := strings.TrimPrefix(line, "HEAD ")
			current.LastCommit.Hash = head
		} else if strings.HasPrefix(line, "branch ") {
			branch := strings.TrimPrefix(line, "branch ")
			current.Branch = filepath.Base(branch)
		} else if strings.HasPrefix(line, "locked ") {
			current.IsLocked = true
		} else if strings.HasPrefix(line, "prunable ") {
			// 忽略可清理的 worktree
			current = nil
		}
	}

	if current != nil {
		worktrees = append(worktrees, *current)
	}

	// 补充信息
	for i := range worktrees {
		wt := &worktrees[i]

		// 检查是否是主工作区
		wt.IsMain = isMainWorktree(wt.Path)

		// 检查是否有修改
		wt.IsDirty = isWorktreeDirty(wt.Path)

		// 获取最后提交信息
		commit, err := getLastCommit(wt.Path)
		if err == nil {
			wt.LastCommit = commit
		}
	}

	return worktrees, nil
}

// isMainWorktree 检查是否是主工作区
func isMainWorktree(path string) bool {
	gitPath := filepath.Join(path, ".git")
	info, err := os.Stat(gitPath)
	if err != nil {
		return false
	}
	return info.IsDir()
}

// isWorktreeDirty 检查 worktree 是否有修改
func isWorktreeDirty(path string) bool {
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = path

	output, err := cmd.Output()
	if err != nil {
		return false
	}

	return len(strings.TrimSpace(string(output))) > 0
}

// getLastCommit 获取最后提交信息
func getLastCommit(path string) (CommitInfo, error) {
	cmd := exec.Command("git", "log", "-1", "--pretty=format:%H|%s|%an|%ai", "HEAD")
	cmd.Dir = path

	output, err := cmd.Output()
	if err != nil {
		return CommitInfo{}, err
	}

	parts := strings.Split(string(output), "|")
	if len(parts) < 4 {
		return CommitInfo{}, fmt.Errorf("解析提交信息失败")
	}

	commitTime, err := time.Parse("2006-01-02 15:04:05 -0700", parts[3])
	if err != nil {
		commitTime = time.Now()
	}

	return CommitInfo{
		Hash:    parts[0],
		Subject: parts[1],
		Author:  parts[2],
		Date:    commitTime,
	}, nil
}

// BranchExists 检查分支是否存在
func (r *Repository) BranchExists(branch string) (bool, error) {
	cmd := exec.Command("git", "branch", "--list", branch)
	cmd.Dir = r.Path

	output, err := cmd.Output()
	if err != nil {
		return false, err
	}

	return len(strings.TrimSpace(string(output))) > 0, nil
}

// CreateWorktree 创建 worktree
func (r *Repository) CreateWorktree(options CreateWorktreeOptions) (*Worktree, error) {
	args := []string{"worktree", "add"}

	if options.Force {
		args = append(args, "--force")
	}

	if options.CreateBranch {
		args = append(args, "-b", options.Branch)
	}

	if options.BaseBranch != "" {
		args = append(args, options.BaseBranch)
	}

	args = append(args, options.Path)

	cmd := exec.Command("git", args...)
	cmd.Dir = r.Path

	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("创建 worktree 失败: %w\n输出: %s", err, string(output))
	}

	return &Worktree{
		Path:   options.Path,
		Branch: options.Branch,
	}, nil
}

// RemoveWorktree 删除 worktree
func (r *Repository) RemoveWorktree(path string) error {
	cmd := exec.Command("git", "worktree", "remove", path)
	cmd.Dir = r.Path

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("删除 worktree 失败: %w\n输出: %s", err, string(output))
	}

	return nil
}

// PruneWorktrees 清理无效的 worktree
func (r *Repository) PruneWorktrees() error {
	cmd := exec.Command("git", "worktree", "prune")
	cmd.Dir = r.Path

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("清理 worktree 失败: %w\n输出: %s", err, string(output))
	}

	return nil
}
