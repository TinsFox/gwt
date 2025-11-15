package ui

import (
	"github.com/fatih/color"
	"strings"
)

// 颜色函数
var (
	// 成功/正常状态
	ColorSuccess = color.New(color.FgGreen, color.Bold).SprintFunc()

	// 错误状态
	ColorError = color.New(color.FgRed, color.Bold).SprintFunc()

	// 警告状态
	ColorWarning = color.New(color.FgYellow, color.Bold).SprintFunc()

	// 信息状态
	ColorInfo = color.New(color.FgBlue, color.Bold).SprintFunc()

	// 路径
	ColorPath = color.New(color.FgCyan).SprintFunc()

	// 分支
	ColorBranch = color.New(color.FgMagenta, color.Bold).SprintFunc()

	// 提交哈希
	ColorHash = color.New(color.FgHiBlack).SprintFunc()

	// 高亮
	ColorHighlight = color.New(color.FgWhite, color.Bold).SprintFunc()
)

// StatusColor 根据状态返回颜色函数
func StatusColor(status string) func(...interface{}) string {
	switch status {
	case "clean", "main", "success":
		return ColorSuccess
	case "dirty", "modified", "error":
		return ColorError
	case "locked", "warning":
		return ColorWarning
	case "info", "active":
		return ColorInfo
	default:
		return color.New(color.FgWhite).SprintFunc()
	}
}

// BranchColor 根据分支类型返回颜色
func BranchColor(branch string) func(...interface{}) string {
	if branch == "main" || branch == "master" {
		return color.New(color.FgGreen, color.Bold).SprintFunc()
	}
	if strings.HasPrefix(branch, "feature/") {
		return color.New(color.FgBlue).SprintFunc()
	}
	if strings.HasPrefix(branch, "hotfix/") || strings.HasPrefix(branch, "bugfix/") {
		return color.New(color.FgRed).SprintFunc()
	}
	if strings.HasPrefix(branch, "release/") {
		return color.New(color.FgYellow).SprintFunc()
	}

	return ColorBranch
}
