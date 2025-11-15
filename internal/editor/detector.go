package editor

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

// EditorInfo 表示编辑器信息
type EditorInfo struct {
	Name              string
	Command           string
	SupportsNewWindow bool
	NewWindowFlag     string
	SupportsWait      bool
	WaitFlag          string
}

// DetectEditor 检测编辑器
func DetectEditor(editorName string) (*EditorInfo, error) {
	// 获取编辑器配置
	editorConfig := getEditorConfig(editorName)
	if editorConfig == nil {
		return nil, fmt.Errorf("不支持的编辑器: %s", editorName)
	}

	// 检查编辑器是否可用
	if !isEditorAvailable(editorConfig.Command) {
		// 尝试检测已安装的其他编辑器
		fallback := detectAvailableEditor()
		if fallback != nil {
			return fallback, nil
		}
		return nil, fmt.Errorf("编辑器 '%s' 未安装或不在 PATH 中", editorName)
	}

	return editorConfig, nil
}

// getEditorConfig 获取编辑器配置
func getEditorConfig(editorName string) *EditorInfo {
	configs := getEditorConfigs()

	// 精确匹配
	if config, ok := configs[editorName]; ok {
		return config.EditorInfo
	}

	// 尝试别名匹配
	for _, config := range configs {
		for _, alias := range config.Aliases {
			if alias == editorName {
				return config.EditorInfo
			}
		}
	}

	return nil
}

// EditorConfig 内部编辑器配置
type EditorConfig struct {
	*EditorInfo
	Aliases []string
	Paths   []string // 可能的安装路径
}

// getEditorConfigs 获取所有编辑器配置
func getEditorConfigs() map[string]*EditorConfig {
	return map[string]*EditorConfig{
		"code": {
			EditorInfo: &EditorInfo{
				Name:              "Visual Studio Code",
				Command:           "code",
				SupportsNewWindow: true,
				NewWindowFlag:     "--new-window",
				SupportsWait:      true,
				WaitFlag:          "--wait",
			},
			Aliases: []string{"vscode", "vs-code"},
			Paths:   getVSCodePaths(),
		},
		"vim": {
			EditorInfo: &EditorInfo{
				Name:              "Vim",
				Command:           "vim",
				SupportsNewWindow: false,
				NewWindowFlag:     "",
				SupportsWait:      true,
				WaitFlag:          "",
			},
			Aliases: []string{"vi"},
			Paths:   []string{"/usr/bin/vim", "/bin/vim"},
		},
		"nvim": {
			EditorInfo: &EditorInfo{
				Name:              "Neovim",
				Command:           "nvim",
				SupportsNewWindow: false,
				NewWindowFlag:     "",
				SupportsWait:      true,
				WaitFlag:          "",
			},
			Aliases: []string{"neovim"},
			Paths:   []string{"/usr/bin/nvim", "/usr/local/bin/nvim"},
		},
		"emacs": {
			EditorInfo: &EditorInfo{
				Name:              "Emacs",
				Command:           "emacs",
				SupportsNewWindow: false,
				NewWindowFlag:     "",
				SupportsWait:      true,
				WaitFlag:          "",
			},
			Aliases: []string{},
			Paths:   []string{"/usr/bin/emacs", "/usr/local/bin/emacs"},
		},
		"nano": {
			EditorInfo: &EditorInfo{
				Name:              "Nano",
				Command:           "nano",
				SupportsNewWindow: false,
				NewWindowFlag:     "",
				SupportsWait:      true,
				WaitFlag:          "",
			},
			Aliases: []string{},
			Paths:   []string{"/usr/bin/nano", "/bin/nano"},
		},
		"subl": {
			EditorInfo: &EditorInfo{
				Name:              "Sublime Text",
				Command:           "subl",
				SupportsNewWindow: true,
				NewWindowFlag:     "-n",
				SupportsWait:      false,
				WaitFlag:          "",
			},
			Aliases: []string{"sublime"},
			Paths:   getSublimeTextPaths(),
		},
		"idea": {
			EditorInfo: &EditorInfo{
				Name:              "IntelliJ IDEA",
				Command:           "idea",
				SupportsNewWindow: true,
				NewWindowFlag:     "",
				SupportsWait:      false,
				WaitFlag:          "",
			},
			Aliases: []string{"intellij", "jetbrains"},
			Paths:   getIntelliJPaths(),
		},
		"webstorm": {
			EditorInfo: &EditorInfo{
				Name:              "WebStorm",
				Command:           "webstorm",
				SupportsNewWindow: true,
				NewWindowFlag:     "",
				SupportsWait:      false,
				WaitFlag:          "",
			},
			Aliases: []string{},
			Paths:   getWebStormPaths(),
		},
	}
}

// getVSCodePaths 获取 VS Code 可能的路径
func getVSCodePaths() []string {
	paths := []string{}

	switch runtime.GOOS {
	case "windows":
		paths = append(paths,
			"C:\\Program Files\\Microsoft VS Code\\bin\\code.exe",
			"C:\\Program Files (x86)\\Microsoft VS Code\\bin\\code.exe",
			filepath.Join(os.Getenv("LOCALAPPDATA"), "Programs", "Microsoft VS Code", "bin", "code.exe"),
		)
	case "darwin":
		paths = append(paths,
			"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
			"/usr/local/bin/code",
		)
	case "linux":
		paths = append(paths,
			"/usr/bin/code",
			"/usr/local/bin/code",
			"/snap/bin/code",
		)
	}

	return paths
}

// getSublimeTextPaths 获取 Sublime Text 可能的路径
func getSublimeTextPaths() []string {
	paths := []string{}

	switch runtime.GOOS {
	case "windows":
		paths = append(paths,
			"C:\\Program Files\\Sublime Text\\subl.exe",
			"C:\\Program Files (x86)\\Sublime Text\\subl.exe",
		)
	case "darwin":
		paths = append(paths,
			"/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl",
		)
	case "linux":
		paths = append(paths,
			"/usr/bin/subl",
			"/usr/local/bin/subl",
			"/opt/sublime_text/subl",
		)
	}

	return paths
}

// getIntelliJPaths 获取 IntelliJ IDEA 可能的路径
func getIntelliJPaths() []string {
	paths := []string{}

	switch runtime.GOOS {
	case "windows":
		paths = append(paths,
			"C:\\Program Files\\JetBrains\\IntelliJ IDEA*\\bin\\idea.exe",
		)
	case "darwin":
		paths = append(paths,
			"/Applications/IntelliJ IDEA.app/Contents/MacOS/idea",
		)
	case "linux":
		paths = append(paths,
			"/usr/local/bin/idea",
			"/opt/idea*/bin/idea.sh",
		)
	}

	return paths
}

// getWebStormPaths 获取 WebStorm 可能的路径
func getWebStormPaths() []string {
	paths := []string{}

	switch runtime.GOOS {
	case "windows":
		paths = append(paths,
			"C:\\Program Files\\JetBrains\\WebStorm*\\bin\\webstorm.exe",
		)
	case "darwin":
		paths = append(paths,
			"/Applications/WebStorm.app/Contents/MacOS/webstorm",
		)
	case "linux":
		paths = append(paths,
			"/usr/local/bin/webstorm",
			"/opt/webstorm*/bin/webstorm.sh",
		)
	}

	return paths
}

// isEditorAvailable 检查编辑器是否可用
func isEditorAvailable(command string) bool {
	// 检查 PATH
	if _, err := exec.LookPath(command); err == nil {
		return true
	}

	return false
}

// detectAvailableEditor 检测可用的编辑器
func detectAvailableEditor() *EditorInfo {
	configs := getEditorConfigs()

	// 按优先级检测
	priority := []string{"code", "vim", "nvim", "subl", "nano", "emacs"}

	for _, editorName := range priority {
		if config, ok := configs[editorName]; ok {
			if isEditorAvailable(config.Command) {
				return config.EditorInfo
			}
		}
	}

	return nil
}

// GetAvailableEditors 获取所有可用的编辑器
func GetAvailableEditors() []*EditorInfo {
	configs := getEditorConfigs()
	var available []*EditorInfo

	for _, config := range configs {
		if isEditorAvailable(config.Command) {
			available = append(available, config.EditorInfo)
		}
	}

	return available
}
