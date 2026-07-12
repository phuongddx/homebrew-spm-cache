# homebrew-spm-cache

Homebrew tap for [spm-cache](https://github.com/phuongddx/spm-cache) - cache SPM dependencies as xcframeworks to reduce Xcode build times.

## Installation

```bash
brew tap phuongddx/spm-cache
brew install spm-cache
```

Or directly:

```bash
brew install phuongddx/spm-cache/spm-cache
```

## Requirements

- macOS (required - uses Xcode toolchain)
- Xcode with command-line tools (`xcode-select --install`)
- Swift 6.0+

## How It Works

The formula installs the Ruby gem and its dependencies into Homebrew's isolated environment, then compiles the bundled Swift proxy tool (`spm-cache-proxy`) in release mode during installation.

## Updating the Formula

The formula is automatically updated when a new version is tagged in the main repository via GitHub Actions. See `.github/workflows/update-tap.yml`.

## License

MIT
