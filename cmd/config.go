package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// configCmd 配置管理
var configCmd = &cobra.Command{
	Use:   "config",
	Short: "管理配置",
	Long:  `查看和修改 gwt 的配置。`,
}

var (
	configSet   bool
	configGet   bool
	configList  bool
	configKey   string
	configValue string
)

func init() {
	rootCmd.AddCommand(configCmd)

	configCmd.AddCommand(&cobra.Command{
		Use:   "set <key> <value>",
		Short: "设置配置项",
		Args:  cobra.ExactArgs(2),
		RunE:  runConfigSet,
	})

	configCmd.AddCommand(&cobra.Command{
		Use:   "get <key>",
		Short: "获取配置项",
		Args:  cobra.ExactArgs(1),
		RunE:  runConfigGet,
	})

	configCmd.AddCommand(&cobra.Command{
		Use:   "list",
		Short: "列出所有配置",
		RunE:  runConfigList,
	})
}

func runConfigSet(cmd *cobra.Command, args []string) error {
	key := args[0]
	value := args[1]

	viper.Set(key, value)

	// 保存配置
	if err := viper.WriteConfig(); err != nil {
		// 如果配置文件不存在，创建新的
		if err := viper.SafeWriteConfig(); err != nil {
			return fmt.Errorf("保存配置失败: %w", err)
		}
	}

	fmt.Printf("设置 %s = %s\n", key, value)
	return nil
}

func runConfigGet(cmd *cobra.Command, args []string) error {
	key := args[0]
	value := viper.Get(key)

	if value == nil {
		return fmt.Errorf("配置项不存在: %s", key)
	}

	fmt.Printf("%s = %v\n", key, value)
	return nil
}

func runConfigList(cmd *cobra.Command, args []string) error {
	settings := viper.AllSettings()

	if len(settings) == 0 {
		fmt.Println("没有配置项")
		return nil
	}

	fmt.Println("当前配置:")
	for key, value := range settings {
		fmt.Printf("  %s = %v\n", key, value)
	}

	return nil
}
