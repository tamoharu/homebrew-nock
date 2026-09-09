class Xroam < Formula
  desc "Control your own Codex sessions from an iPhone over SSH"
  homepage "https://github.com/tamoharu/xroam-setup"
  url "https://github.com/tamoharu/xroam-setup/releases/download/v0.4.0/xroam-0.4.0.tar.gz"
  version "0.4.0"
  sha256 "1b3eafb1e887c0292199aa93dec722d364c960471f2c31ff23898608e9870b37"

  depends_on "node@24"
  depends_on "tmux"
  depends_on "openssl@3"

  def install
    libexec.install "remote/src", "remote/package.json", "remote/package-lock.json"
    cd libexec do
      system Formula["node@24"].opt_bin/"node", Formula["node@24"].opt_bin/"npm",
             "ci", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    end
    (bin/"xroam").write <<~SH
      #!/bin/sh
      export PATH="#{Formula["node@24"].opt_bin}:#{Formula["tmux"].opt_bin}:#{Formula["openssl@3"].opt_bin}:#{HOMEBREW_PREFIX}/bin:$PATH"
      export XROAM_APP_ROOT="#{opt_libexec}"
      export XROAM_NODE_BIN="#{Formula["node@24"].opt_bin}/node"
      exec "#{Formula["node@24"].opt_bin}/node" "#{opt_libexec}/src/cli.mjs" "$@"
    SH
    (bin/"xroam").chmod 0755
    doc.install "README.md", "docs"
  end

  service do
    name macos: "com.deep.xroam.daemon", linux: "xroam"
    run [opt_bin/"xroam", "run"]
    keep_alive successful_exit: false
    environment_variables PATH: std_service_path_env
    log_path var/"log/xroam.log"
    error_log_path var/"log/xroam.log"
  end

  def caveats
    <<~EOS
      Run xroam setup once to create private settings and start the user service.
      Your initial workspace is ~/xroamProjects. Existing settings are preserved.
      One line: brew install tamoharu/xroam/xroam && xroam setup
      Scan the QR using xroam on your iPhone. Keys are generated on the phone.
      xroam pair                           Show a new 5-minute pairing QR

      xroam doctor                         Check running version, code browsing, SSH and login
      xroam login                          Only if Codex is not logged in yet
      xroam project add /path/to/project    Add a project immediately, without interrupting work
      xroam restart                        Apply other config changes after work finishes

      After brew upgrade, run xroam restart when active work finishes.
      Reconnect the iPhone and check matching package/daemon versions in xroam doctor.

      iPhone Bundle ID: com.deep.xroam
      API credentials are discovered over authenticated SSH; no token copy needed.
      OS Remote Login, Tailscale and Apple APNs credentials need separate setup.
      Pairing appends a phone public key to ~/.ssh/authorized_keys; existing keys are preserved.
      Before uninstalling: brew services stop xroam
      Settings, keys, and conversation history are retained on uninstall.
    EOS
  end

  test do
    ENV["XROAM_HOME"] = (testpath/"xroam-state").to_s
    system bin/"xroam", "setup", "--no-start", "--quiet"
    assert_path_exists testpath/"xroam-state/config/config.json"
    assert_equal 0600, (testpath/"xroam-state/config/api-token").stat.mode & 0777
    report = JSON.parse(shell_output("#{bin}/xroam doctor --json"))
    assert_equal version.to_s, report.fetch("installedVersion")
    assert_nil report.fetch("daemonVersion")
    assert_equal false, report.fetch("restartRequired")
    assert_equal true, report.fetch("codexVersion")
    assert_equal false, report.fetch("running")
    assert_equal 1, report.fetch("projects").length
    refute report.key?("token")
  end
end
