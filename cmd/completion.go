package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

// completionCmd 生成自动补全脚本
var completionCmd = &cobra.Command{
	Use:   "completion [bash|zsh|fish|powershell]",
	Short: "生成 shell 自动补全脚本",
	Long: `生成 shell 自动补全脚本。

支持的 shell:
  - bash
  - zsh  
  - fish
  - powershell

使用示例:

# Bash (Linux):
  gwt completion bash > /etc/bash_completion.d/gwt

# Bash (macOS):
  gwt completion bash > /usr/local/etc/bash_completion.d/gwt

# Zsh:
  gwt completion zsh > "${fpath[1]}/_gwt"

# Fish:
  gwt completion fish > ~/.config/fish/completions/gwt.fish

# PowerShell:
  gwt completion powershell > gwt.ps1
  # 然后在 PowerShell 配置文件中添加: . ./gwt.ps1`,
	DisableFlagsInUseLine: true,
	ValidArgs:             []string{"bash", "zsh", "fish", "powershell"},
	Args:                  cobra.ExactValidArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		switch args[0] {
		case "bash":
			cmd.Root().GenBashCompletion(os.Stdout)
		case "zsh":
			cmd.Root().GenZshCompletion(os.Stdout)
		case "fish":
			cmd.Root().GenFishCompletion(os.Stdout, true)
		case "powershell":
			cmd.Root().GenPowerShellCompletionWithDesc(os.Stdout)
		}
	},
}

func init() {
	rootCmd.AddCommand(completionCmd)
}
