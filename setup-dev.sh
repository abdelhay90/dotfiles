#!/bin/bash
# Developer toolchain for macOS and Linux (apt, dnf, pacman). Idempotent: re-run any time.
#
#   ./setup-dev.sh                 install everything
#   ./setup-dev.sh go rust         only these tools
#   ./setup-dev.sh check           show what is installed, change nothing
#
# Tools: base node pnpm java go rust python
#   base    compilers, openssl/zlib headers, git, curl, jq, ripgrep (+ Homebrew on macOS)
#   node    nvm (pinned) + Node LTS as the default
#   pnpm    via npm into the default Node
#   java    JDK $JAVA_VERSION + jenv + Maven (+ Gradle on macOS; projects normally ship ./gradlew)
#   go      latest stable (Homebrew on macOS, official tarball in ~/.local/go on Linux)
#   rust    rustup, stable toolchain with clippy + rustfmt
#   python  uv + Python $PYTHON_VERSION (uv installs the interpreter; no compiling)
#
# Env overrides: JAVA_VERSION=21 PYTHON_VERSION=3.12 NVM_VERSION=v0.40.3
# PATH wiring for all of this lives in bash/.profile, so no shell rc files are edited here.
set -euo pipefail

JAVA_VERSION="${JAVA_VERSION:-21}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"
OS=$(uname -s)
ARCH=$(uname -m)
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$HOME/.cargo/bin:$HOME/.jenv/bin:$PATH"

log()  { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
die()  { echo "error: $*" >&2; exit 1; }

# ---- helpers -------------------------------------------------------------------------
SUDO=""
if [ "$OS" = Linux ] && [ "$(id -u)" -ne 0 ]; then
    have sudo || die "need root or sudo to install packages"
    SUDO=sudo
fi

PM=""
if [ "$OS" = Darwin ]; then PM=brew
elif have apt-get; then PM=apt
elif have dnf; then PM=dnf
elif have pacman; then PM=pacman
else die "unsupported system: need macOS (brew) or Linux with apt, dnf or pacman"; fi

load_brew() {
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$b" ]; then eval "$("$b" shellenv)"; return 0; fi
    done
    return 1
}

# pkg <apt names> -- <dnf names> -- <pacman names> -- <brew names>
pkg() {
    local apt=() dnf=() pac=() brw=() cur=apt a
    for a in "$@"; do
        if [ "$a" = -- ]; then
            case $cur in apt) cur=dnf ;; dnf) cur=pac ;; pac) cur=brw ;; esac
            continue
        fi
        case $cur in apt) apt+=("$a") ;; dnf) dnf+=("$a") ;; pac) pac+=("$a") ;; brw) brw+=("$a") ;; esac
    done
    case $PM in
        apt)    [ ${#apt[@]} -eq 0 ] || { export DEBIAN_FRONTEND=noninteractive; $SUDO apt-get install -y -qq "${apt[@]}"; } ;;
        dnf)    [ ${#dnf[@]} -eq 0 ] || $SUDO dnf install -y -q "${dnf[@]}" ;;
        pacman) [ ${#pac[@]} -eq 0 ] || $SUDO pacman -S --noconfirm --needed "${pac[@]}" ;;
        brew)   [ ${#brw[@]} -eq 0 ] || brew install "${brw[@]}" ;;
    esac
}

# nvm.sh is not nounset-safe
load_nvm() {
    [ -s "$NVM_DIR/nvm.sh" ] || return 1
    set +u; . "$NVM_DIR/nvm.sh"; set -u
}

# ---- tools ---------------------------------------------------------------------------
setup_base() {
    log "Base tools"
    case $PM in
        brew)
            if ! xcode-select -p >/dev/null 2>&1; then
                xcode-select --install || true
                die "Xcode command line tools are installing; re-run when they finish"
            fi
            if ! have brew && ! load_brew; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                load_brew || die "Homebrew install failed"
            fi
            load_brew || true
            brew update
            pkg -- -- -- git curl jq ripgrep openssl
            ;;
        apt)
            $SUDO apt-get update -qq
            pkg build-essential pkg-config libssl-dev zlib1g-dev git curl ca-certificates jq ripgrep unzip zip xz-utils
            ;;
        dnf)
            pkg -- gcc gcc-c++ make pkgconf-pkg-config openssl-devel zlib-devel git curl jq ripgrep unzip zip xz
            ;;
        pacman)
            pkg -- -- base-devel openssl zlib git curl jq ripgrep unzip zip xz
            ;;
    esac
}

setup_node() {
    log "nvm $NVM_VERSION + Node LTS"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE=/dev/null bash
    fi
    load_nvm
    if [ -z "$(find "$NVM_DIR/versions/node" -maxdepth 1 -name 'v*' 2>/dev/null)" ]; then
        set +u; nvm install --lts; set -u
        # concrete version: bash/.profile resolves the default alias as a version prefix
        set +u; nvm alias default "$(basename "$(find "$NVM_DIR/versions/node" -maxdepth 1 -name 'v*' | sort -V | tail -1)")"; set -u
    fi
}

setup_pnpm() {
    log "pnpm"
    load_nvm || die "run './setup-dev.sh node' first"
    if ! have pnpm; then
        npm install -g pnpm
    fi
    # ponytail: lives in the Node version that was active; reinstall after switching Node versions
}

setup_java() {
    log "JDK $JAVA_VERSION + jenv + Maven"
    case $PM in
        brew)   pkg -- -- -- "openjdk@$JAVA_VERSION" jenv maven gradle ;;
        apt)    pkg "openjdk-$JAVA_VERSION-jdk" maven git ;;
        dnf)    pkg -- "java-$JAVA_VERSION-openjdk-devel" maven git ;;
        pacman) pkg -- -- "jdk$JAVA_VERSION-openjdk" maven git ;;
    esac

    if [ "$PM" != brew ] && [ ! -d "$HOME/.jenv" ]; then
        git clone --depth 1 https://github.com/jenv/jenv "$HOME/.jenv"
    fi
    have jenv || export PATH="$HOME/.jenv/bin:$PATH"

    local home=""
    if [ "$PM" = brew ]; then
        home="$(brew --prefix "openjdk@$JAVA_VERSION")/libexec/openjdk.jdk/Contents/Home"
    else
        home=$(find /usr/lib/jvm -maxdepth 1 \( -type d -o -type l \) -name "*$JAVA_VERSION*openjdk*" 2>/dev/null | sort | head -1)
    fi
    [ -d "$home" ] || die "could not find the JDK $JAVA_VERSION home (looked at: ${home:-/usr/lib/jvm})"

    set +u
    eval "$(jenv init -)"
    jenv enable-plugin export >/dev/null 2>&1 || true
    jenv add "$home" >/dev/null
    jenv global "$JAVA_VERSION"
    set -u
}

setup_go() {
    log "Go"
    if [ "$PM" = brew ]; then
        pkg -- -- -- go
        return
    fi
    local ver arch
    ver=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)
    case $ARCH in x86_64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; *) die "unsupported arch $ARCH" ;; esac
    if have go && [ "$(go version | awk '{print $3}')" = "$ver" ]; then
        echo "go $ver already installed"; return
    fi
    local tmp
    tmp=$(mktemp -d)
    curl -fsSL "https://go.dev/dl/$ver.linux-$arch.tar.gz" | tar -xz -C "$tmp"
    mkdir -p "$HOME/.local"
    rm -rf "$HOME/.local/go"
    mv "$tmp/go" "$HOME/.local/go"
    rmdir "$tmp"
}

setup_rust() {
    log "Rust (rustup)"
    if have rustup; then
        rustup update stable
    else
        curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
    fi
    "$HOME/.cargo/bin/rustup" component add clippy rustfmt >/dev/null
}

setup_python() {
    log "uv + Python $PYTHON_VERSION"
    if ! have uv; then
        if [ "$PM" = brew ]; then
            pkg -- -- -- uv
        else
            curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
        fi
    fi
    uv python install "$PYTHON_VERSION"
}

check() {
    local name out
    printf '%-8s %s\n' tool version
    for name in git jq rg node pnpm java mvn go rustc cargo uv python3 jenv; do
        if ! have "$name"; then printf '%-8s %s\n' "$name" MISSING; continue; fi
        case $name in
            java)    out=$(java -version 2>&1 | head -1) ;;
            go)      out=$(go version) ;;
            rustc)   out=$(rustc --version) ;;
            mvn)     out=$(mvn -B --version 2>&1 | head -1) ;;
            *)       out=$("$name" --version 2>&1 | head -1) ;;
        esac
        printf '%-8s %s\n' "$name" "$out"
    done
    have "python$PYTHON_VERSION" || echo "note: python$PYTHON_VERSION not on PATH (uv python install $PYTHON_VERSION)"
}

# ---- main ----------------------------------------------------------------------------
tools=("$@")
[ ${#tools[@]} -gt 0 ] || tools=(all)
for t in "${tools[@]}"; do
    case $t in
        check) load_brew || true; load_nvm || true; check; exit 0 ;;
        all|base|node|pnpm|java|go|rust|python) ;;
        *) die "unknown tool '$t' (base node pnpm java go rust python | all | check)" ;;
    esac
done

if [ "${tools[0]}" = all ]; then tools=(base node pnpm java go rust python); fi
for t in "${tools[@]}"; do
    if [ "$t" != base ] && [ "$OS" = Darwin ]; then load_brew || true; fi
    "setup_$t"
done

log "Done"
load_nvm || true
check
echo
echo "Open a new terminal (or: rl) so bash/.profile picks up the new PATH entries."
