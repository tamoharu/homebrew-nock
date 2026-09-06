class Nock < Formula
  desc "Control your own Codex sessions from an iPhone over SSH"
  homepage "https://github.com/tamoharu/nock-setup"
  url "https://github.com/tamoharu/nock-setup/releases/download/v0.2.0/nock-0.2.0.tar.gz"
  version "0.2.0"
  sha256 "655234ed6aa4c30c846608acec423b92527c3b272fb145897cf58d2fdeecbecb"

  depends_on "node@24"
  depends_on "tmux"

  def install
    libexec.install "remote/src", "remote/package.json", "remote/package-lock.json"
    cd libexec do
      system Formula["node@24"].opt_bin/"node", Formula["node@24"].opt_bin/"npm",
             "ci", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    end
    (bin/"nock").write <<~SH
      #!/bin/sh
      export PATH="#{Formula["node@24"].opt_bin}:#{Formula["tmux"].opt_bin}:#{HOMEBREW_PREFIX}/bin:$PATH"
      export NOCK_APP_ROOT="#{opt_libexec}"
      export NOCK_NODE_BIN="#{Formula["node@24"].opt_bin}/node"
      exec "#{Formula["node@24"].opt_bin}/node" "#{opt_libexec}/src/cli.mjs" "$@"
    SH
    (bin/"nock").chmod 0755
    doc.install "README.md", "docs"
  end

  service do
    name macos: "com.deep.nock.daemon", linux: "nock"
    run [opt_bin/"nock", "run"]
    keep_alive successful_exit: false
    environment_variables PATH: std_service_path_env
    log_path var/"log/nock.log"
    error_log_path var/"log/nock.log"
  end

  def caveats
    <<~EOS
      Run nock setup once to create private settings and start the user service.
      Your initial workspace is ~/NockProjects. Existing settings are preserved.
      One line: brew install tamoharu/nock/nock && nock setup

      nock doctor                         Check SSH, Tailscale and Codex login
      nock login                          Only if Codex is not logged in yet
      nock project add /path/to/project    Add a project immediately, without interrupting work
      nock restart                        Apply other config changes after work finishes

      iPhone Bundle ID: com.deep.nock
      API credentials are discovered over authenticated SSH; no token copy needed.
      SSH keys, OS Remote Login, and Apple APNs credentials cannot be provisioned by brew.
      Before uninstalling: brew services stop nock
      Settings, keys, and conversation history are retained on uninstall.
    EOS
  end

  test do
    ENV["NOCK_HOME"] = (testpath/"nock-state").to_s
    system bin/"nock", "setup", "--no-start", "--quiet"
    assert_path_exists testpath/"nock-state/config/config.json"
    assert_equal 0600, (testpath/"nock-state/config/api-token").stat.mode & 0777
    report = JSON.parse(shell_output("#{bin}/nock doctor --json"))
    assert_equal true, report.fetch("codexVersion")
    assert_equal false, report.fetch("running")
    assert_equal 1, report.fetch("projects").length
    refute report.key?("token")
  end
end
