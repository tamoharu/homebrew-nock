class Hati < Formula
  desc "Control your own Codex sessions from an iPhone over SSH"
  homepage "https://github.com/tamoharu/hati-setup"
  url "https://github.com/tamoharu/hati-setup/releases/download/v0.4.1/hati-0.4.1.tar.gz"
  version "0.4.1"
  sha256 "e589ac1c58e488ece5076fe33c567b4859b3d6d2e124ee6c434b0de47ca7b54e"

  depends_on "node@24"
  depends_on "tmux"
  depends_on "openssl@3"
  depends_on "rust" => :build

  def install
    system "cargo", "build", "--release", "--locked", "--manifest-path", "cli/Cargo.toml"
    libexec.install "remote/src", "remote/package.json", "remote/package-lock.json"
    (libexec/"bin").install "cli/target/release/hati-tui"
    (doc/"cli").install "cli/src", "cli/third-party", "cli/Cargo.toml", "cli/Cargo.lock"
    cd libexec do
      system Formula["node@24"].opt_bin/"node", Formula["node@24"].opt_bin/"npm",
             "ci", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    end
    (bin/"hati").write <<~SH
      #!/bin/sh
      export PATH="#{Formula["node@24"].opt_bin}:#{Formula["tmux"].opt_bin}:#{Formula["openssl@3"].opt_bin}:#{HOMEBREW_PREFIX}/bin:$PATH"
      export HATI_APP_ROOT="#{opt_libexec}"
      export HATI_NODE_BIN="#{Formula["node@24"].opt_bin}/node"
      exec "#{Formula["node@24"].opt_bin}/node" "#{opt_libexec}/src/cli.mjs" "$@"
    SH
    (bin/"hati").chmod 0755
    doc.install "README.md", "docs"
  end

  service do
    name macos: "com.deep.hati.daemon", linux: "hati"
    run [opt_bin/"hati", "run"]
    keep_alive successful_exit: false
    environment_variables PATH: std_service_path_env
    log_path var/"log/hati.log"
    error_log_path var/"log/hati.log"
  end

  def caveats
    <<~EOS
      Run hati setup once to create private settings and start the user service.
      Your initial workspace is ~/hatiProjects. Existing settings are preserved.
      One line: brew install tamoharu/hati/hati && hati setup
      Scan the QR using hati on your iPhone. Keys are generated on the phone.
      hati pair                           Show a new 5-minute pairing QR
      hati pair --copy                    Copy a PC invitation link
      hati pair --link                    Show a PC invitation link (for SSH terminals)

      hati doctor                         Check running version, code browsing, SSH and login
      hati login                          Only if Codex is not logged in yet
      hati project add /path/to/project    Add a project immediately, without interrupting work
      hati restart                        Apply other config changes after work finishes

      After brew upgrade, run hati restart when active work finishes.
      Reconnect the iPhone and check matching package/daemon versions in hati doctor.

      iPhone Bundle ID: com.deep.hati
      API credentials are discovered over authenticated SSH; no token copy needed.
      OS Remote Login, Tailscale and Apple APNs credentials need separate setup.
      Pairing appends a phone public key to ~/.ssh/authorized_keys; existing keys are preserved.
      Before uninstalling: brew services stop hati
      Settings, keys, and conversation history are retained on uninstall.
    EOS
  end

  test do
    ENV["HATI_HOME"] = (testpath/"hati-state").to_s
    system bin/"hati", "setup", "--no-start", "--quiet"
    assert_path_exists testpath/"hati-state/config/config.json"
    assert_equal 0600, (testpath/"hati-state/config/api-token").stat.mode & 0777
    report = JSON.parse(shell_output("#{bin}/hati doctor --json"))
    assert_equal version.to_s, report.fetch("installedVersion")
    assert_nil report.fetch("daemonVersion")
    assert_equal false, report.fetch("restartRequired")
    assert_equal true, report.fetch("codexVersion")
    assert_equal false, report.fetch("running")
    assert_equal 1, report.fetch("projects").length
    refute report.key?("token")
  end
end
