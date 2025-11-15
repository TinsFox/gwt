class Gwt < Formula
  desc "Git Worktree CLI - A powerful command-line tool for managing Git worktrees"
  homepage "https://github.com/TinsFox/gwt"
  url "https://github.com/TinsFox/gwt/archive/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/TinsFox/gwt.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")
    
    # Install completion scripts
    output = Utils.safe_popen_read(bin/"gwt", "completion", "bash")
    (bash_completion/"gwt").write output
    
    output = Utils.safe_popen_read(bin/"gwt", "completion", "zsh")
    (zsh_completion/"_gwt").write output
    
    output = Utils.safe_popen_read(bin/"gwt", "completion", "fish")
    (fish_completion/"gwt.fish").write output
  end

  test do
    assert_match "gwt version", shell_output("#{bin}/gwt --version")
    assert_match "Git Worktree CLI", shell_output("#{bin}/gwt --help")
  end
end