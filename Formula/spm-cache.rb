class SpmCache < Formula
  desc "Cache SPM dependencies as xcframeworks to reduce Xcode build times"
  homepage "https://github.com/phuongddx/spm-cache"
  url "https://github.com/phuongddx/spm-cache/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "6474e868467cb9a9f7e8d69ff21452d67fc4a875ee9b3f19771ce7775bfcb2aa"
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

    # Use the gemspec to resolve and install all runtime dependencies
    cd libexec do
      system "gem", "build", "spm_cache.gemspec"
      system "gem", "install", "--no-document", "--local", "spm-cache-#{version}.gem",
             "--install-dir", libexec/"gems"
    end

    # Build the Swift proxy tool in release mode
    cd libexec/"tools/spm-cache-proxy" do
      system "swift", "build", "-c", "release"
    end

    # Install the CLI executable as a shim that sets up the Ruby environment
    env = {
      GEM_HOME:       libexec/"gems",
      GEM_PATH:       libexec/"gems",
      SPM_CACHE_ROOT: libexec.to_s,
    }
    (bin/"spm-cache").write_env_script(libexec/"bin/spm-cache", env)
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
