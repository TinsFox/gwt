package main

import (
	"fmt"
	"os"

	"github.com/tinsfox/gwt/cmd"
)

var (
	// 这些变量会在构建时通过 ldflags 注入
	Version   = "dev"
	BuildTime = "unknown"
	GitCommit = "unknown"
)

func main() {
	// 设置版本信息到 cmd 包
	cmd.SetVersionInfo(Version, BuildTime, GitCommit)

	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
