package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	// 版本信息
	version   string
	buildTime string
	gitCommit string

	// 全局配置
	cfgFile string
	verbose bool
	quiet   bool
)

// rootCmd 是主命令
var rootCmd = &cobra.Command{
	Use:   "gwt",
	Short: "Git Worktree CLI - 简化 Git worktree 操作",
	Long: `Git Worktree CLI (gwt) 是一个命令行工具，用于简化 Git worktree 的管理。
	
它提供了直观的命令来创建、管理、切换和编辑多个 worktree，
让你能够更高效地同时处理多个分支。`,
	Version: getVersion(),
}

// Execute 执行根命令
func Execute() error {
	return rootCmd.Execute()
}

// SetVersionInfo 设置版本信息
func SetVersionInfo(v, bt, gc string) {
	version = v
	buildTime = bt
	gitCommit = gc
	// Cobra snapshots Version at startup, so update it after ldflags injection.
	rootCmd.Version = getVersion()
}

func getVersion() string {
	if version == "" {
		return "dev"
	}
	return fmt.Sprintf("%s (build: %s, commit: %s)", version, buildTime, gitCommit)
}

func init() {
	cobra.OnInitialize(initConfig)

	// 全局 flags
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "配置文件路径 (默认: $HOME/.gwt.yaml)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "详细输出")
	rootCmd.PersistentFlags().BoolVarP(&quiet, "quiet", "q", false, "安静模式，只显示错误信息")

	// 绑定到 viper
	viper.BindPFlag("verbose", rootCmd.PersistentFlags().Lookup("verbose"))
	viper.BindPFlag("quiet", rootCmd.PersistentFlags().Lookup("quiet"))
}

// initConfig 读取配置文件
func initConfig() {
	if cfgFile != "" {
		// 使用指定的配置文件
		viper.SetConfigFile(cfgFile)
	} else {
		// 查找配置文件
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
			os.Exit(1)
		}

		// 搜索路径
		viper.AddConfigPath(home)
		viper.AddConfigPath(".")
		viper.AddConfigPath("./config")

		// 配置文件名
		viper.SetConfigName(".gwt")
		viper.SetConfigType("yaml")
	}

	// 读取环境变量
	viper.SetEnvPrefix("GWT")
	viper.AutomaticEnv()

	// 设置默认值
	setDefaults()

	// 读取配置文件
	if err := viper.ReadInConfig(); err == nil {
		if verbose {
			fmt.Println("Using config file:", viper.ConfigFileUsed())
		}
	}
}

// setDefaults 设置配置默认值
func setDefaults() {
	// 编辑器配置
	viper.SetDefault("editor.default", detectDefaultEditor())
	viper.SetDefault("editor.fallback", []string{"vim", "nano", "code"})

	// 路径配置
	viper.SetDefault("paths.default", "")
	viper.SetDefault("paths.base", "")

	// 显示配置
	viper.SetDefault("display.color", true)
	viper.SetDefault("display.icons", true)
	viper.SetDefault("display.table_style", "default")
}

// detectDefaultEditor 检测默认编辑器
func detectDefaultEditor() string {
	// 检查环境变量
	editors := []string{
		os.Getenv("EDITOR"),
		os.Getenv("VISUAL"),
	}

	for _, editor := range editors {
		if editor != "" {
			return editor
		}
	}

	// 检测常见编辑器
	commonEditors := []string{"code", "vim", "nvim", "emacs", "nano", "subl"}
	for _, editor := range commonEditors {
		if _, err := os.Stat("/usr/bin/" + editor); err == nil {
			return editor
		}
	}

	return "vi" // 最基础的备用方案
}
