# Detect OS and architecture, then install Neovim 0.11.6
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" = "Darwin" ]; then
  # macOS — easiest via Homebrew (installs latest stable, not pinned to 0.11.6)
  if command -v brew >/dev/null 2>&1; then
    brew install neovim
  else
    echo "Homebrew not found. Install it from https://brew.sh first, or use the tarball method below."
  fi

elif [ "$OS" = "Linux" ]; then
  case "$ARCH" in
    x86_64) NVIM_ARCH="linux-x86_64" ;;
    aarch64|arm64) NVIM_ARCH="linux-arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
  esac

  cd /tmp
  curl -LO "https://github.com/neovim/neovim/releases/download/v0.11.6/nvim-${NVIM_ARCH}.tar.gz"
  sudo rm -rf "/opt/nvim-${NVIM_ARCH}"
  sudo tar -C /opt -xzf "nvim-${NVIM_ARCH}.tar.gz"
  sudo ln -sf "/opt/nvim-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim

else
  echo "Unsupported OS: $OS"
  exit 1
fi

nvim --version
