class SpmCache < Formula
  desc "Cache SPM dependencies as xcframeworks to reduce Xcode build times"
  homepage "https://github.com/phuongddx/spm-cache"
  url "https://github.com/phuongddx/spm-cache/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "7455f6873c72f062d668b839b882106eb8958af14a928fbfb6f38a8719572269"
  license "MIT"
  head "https://github.com/phuongddx/spm-cache.git", branch: "main"

  depends_on :macos
  depends_on "ruby@3.3"

  uses_from_macos "swift"

  def install
    # Copy all source into libexec so SPMCache::ROOT (which resolves from the gem location) works correctly
    libexec.mkpath
    cp_r Dir.children("."), libexec

    # Install Ruby gem dependencies into Homebrew's isolated gem dir
    ENV["GEM_HOME"] = libexec/"gems"
    ENV["GEM_PATH"] = libexec/"gems"

    # Install gem and all runtime dependencies into Homebrew's isolated gem dir
    cd libexec do
      system "gem", "build", "spm_cache.gemspec"
      system "gem", "install", "--no-document", "spm-cache-#{version}.gem",
             "--install-dir", libexec/"gems"
    end

    # Build the Swift proxy tool in release mode
    # SPM's sandbox-exec conflicts with Homebrew's sandbox, so disable SPM sandbox
    proxy_dir = libexec/"tools/spm-cache-proxy"
    cd proxy_dir do
      system "swift", "build", "-c", "release", "--disable-sandbox"
    end

    # Remove build artifacts that reference Homebrew internals (keep only the release binary)
    rm_r(proxy_dir/".build/plugins") if (proxy_dir/".build/plugins").exist?
    rm_r(proxy_dir/".build/debug") if (proxy_dir/".build/debug").exist?

    # Install the CLI executable as a wrapper that sets up the Ruby environment
    # Custom wrapper (instead of write_env_script) to suppress Homebrew Ruby's nkf warnings
    (bin/"spm-cache").write <<~SH
      #!/bin/bash
      export GEM_HOME="#{libexec/"gems"}"
      export GEM_PATH="#{libexec/"gems"}"
      export SPM_CACHE_ROOT="#{libexec}"
      exec "#{libexec/"bin/spm-cache"}" "$@" 2> >(grep -v "^Ignoring nkf" >&2)
    SH
  end

  def caveats
    <<~EOS
      spm-cache requires Xcode with command-line tools installed:
        xcode-select --install

      To get started:
        cd /path/to/your/xcode/project
        spm-cache

      Documentation: https://github.com/phuongddx/spm-cache#readme
    EOS
  end

  test do
    assert_match "spm-cache", shell_output("#{bin}/spm-cache --help")
  end
end
