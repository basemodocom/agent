#!/bin/sh
# Installs the Basemodo CLI, `basemodo`, on macOS and Linux (spec #518):
#
#   sh install.sh
#
# It picks the build for this computer from the CLI's releases (github.com/basemodocom/cli),
# checks it against the release's checksums, and puts `basemodo` in ~/.basemodo/bin.
# Running it again installs the latest version over the one there. It never needs root.
#
# Then it runs `basemodo setup`, which sets the Person's agents up and signs them in
# (#543), when there is a terminal to ask its questions in; with none (an agent, CI, a
# server), it says in one line to run it.
#
#   sh install.sh [<version>] [--dir <folder>] [--no-setup]
#
#   <version>                 a version to install (`0.2.0`), instead of the latest
#   --dir <folder>            where to put `basemodo`, instead of ~/.basemodo/bin
#   --no-setup                install `basemodo` alone, without running `basemodo setup`
#
# The same as environment variables: BASEMODO_VERSION, BASEMODO_INSTALL_DIR,
# BASEMODO_NO_SETUP=1. And
# BASEMODO_RELEASES_URL, where the releases are (https://github.com/basemodocom/cli/releases):
# CI serves the builds of the commit it tests from there.
#
# Plain POSIX sh, since it is piped to `sh`; everything is in main, run on the last line,
# so a download cut short runs nothing.
set -eu

say() { printf '%s\n' "$*"; }
fail() {
  printf 'basemodo install: %s\n' "$*" >&2
  exit 1
}

# The target triple of this computer's build, as scripts/build-cli names the archives.
target() {
  os=$(uname -s)
  arch=$(uname -m)
  case $arch in
    x86_64 | amd64) arch=x86_64 ;;
    arm64 | aarch64) arch=aarch64 ;;
    *) fail "there is no build of basemodo for this processor ($arch)." ;;
  esac
  # A shell run by Rosetta 2 on Apple silicon reads x86_64: the native build is better.
  if [ "$os" = Darwin ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = 1 ]; then
    arch=aarch64
  fi
  case $os in
    Darwin) echo "$arch-apple-darwin" ;;
    Linux) echo "$arch-unknown-linux-musl" ;;
    MINGW* | MSYS* | CYGWIN*)
      fail "on Windows, install basemodo from PowerShell: install.ps1, beside this script"
      ;;
    *) fail "there is no build of basemodo for $os." ;;
  esac
}

# fetch <url> <file>: downloads with curl, or wget where there is no curl. Only https,
# redirects included, unless the releases are elsewhere on purpose (CI's own server).
# GNU wget is told to refuse a redirect to http; BusyBox's wget (Alpine's, where there
# is no curl) refuses `--https-only`, so it starts from the https URL alone.
fetch() {
  if command -v curl >/dev/null 2>&1; then
    case $1 in
      https://*) curl --proto '=https' --tlsv1.2 -fsSL --retry 3 -o "$2" "$1" ;;
      *) curl -fsSL --retry 3 -o "$2" "$1" ;;
    esac
  elif command -v wget >/dev/null 2>&1; then
    case $1 in
      https://*)
        if wget --help 2>&1 | grep -q -- --https-only; then
          wget -q --https-only -O "$2" "$1"
        else
          wget -q -O "$2" "$1"
        fi
        ;;
      *) wget -q -O "$2" "$1" ;;
    esac
  else
    fail "downloading needs curl or wget, and this computer has neither."
  fi
}

# sha256 <file>: its SHA-256 in hex. macOS has shasum and no sha256sum.
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    openssl dgst -sha256 -r "$1" | cut -d ' ' -f 1
  fi
}

# verify <file> <checksums.txt>: the file's SHA-256 is the one the release lists for its
# name, in `sha256sum`'s lines ("<hex>  <name>", or "<hex> *<name>").
verify() {
  name=$(basename "$1")
  expected=$(tr -d '\r' <"$2" | awk -v name="$name" '$2 == name || $2 == "*" name { print $1; exit }')
  [ -n "$expected" ] || fail "the release's checksums do not list $name. Nothing was installed."
  actual=$(sha256 "$1")
  [ "$actual" = "$expected" ] ||
    fail "$name does not match the release's checksum: it may be damaged or not the release's own. Nothing was installed."
}

# The file the Person's shell reads as it starts, where the PATH gets `basemodo`'s folder.
profile() {
  case ${SHELL:-} in
    */zsh) echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
    # Terminal on macOS starts bash as a login shell, which reads ~/.bash_profile.
    */bash) if [ "$(uname -s)" = Darwin ]; then echo "$HOME/.bash_profile"; else echo "$HOME/.bashrc"; fi ;;
    */fish) echo "${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/basemodo.fish" ;;
    *) echo "$HOME/.profile" ;;
  esac
}

# on_path <dir>: tells, in plain words, how the terminal finds `basemodo` in <dir>, adding
# it to the PATH in the shell's profile when neither the PATH nor the profile has it.
on_path() {
  case :${PATH}: in
    *:"$1":* | *:"$1"/:*) return ;;
  esac
  file=$(profile)
  # The profile says `$HOME/...` where it can, as a Person would write it.
  shown=$1
  # shellcheck disable=SC2016
  case $1 in
    "$HOME"/*) shown='$HOME'${1#"$HOME"} ;;
  esac
  case $file in
    *.fish) line="set -gx PATH \"$shown\" \$PATH" ;;
    *) line="export PATH=\"$shown:\$PATH\"" ;;
  esac
  if [ -f "$file" ] && grep -qxF "$line" "$file"; then
    say "$file puts $1 on your PATH: open a new terminal for \`basemodo\` to be found."
    return
  fi
  mkdir -p "$(dirname "$file")"
  printf '\n# basemodo, put here by https://basemodo.com/install\n%s\n' "$line" >>"$file"
  say "Added $1 to your PATH in $file."
  say "Open a new terminal for \`basemodo\` to be found."
}

usage() {
  cat >&2 <<'EOF'
usage: sh install.sh [<version>] [--dir <folder>] [--no-setup]

  <version>        a version to install (0.2.0), instead of the latest
  --dir <folder>   where to put basemodo, instead of ~/.basemodo/bin
  --no-setup       install basemodo alone, without running basemodo setup
EOF
  exit 2
}

main() {
  releases=${BASEMODO_RELEASES_URL:-https://github.com/basemodocom/cli/releases}
  version=${BASEMODO_VERSION:-}
  dir=${BASEMODO_INSTALL_DIR:-}
  # BASEMODO_NO_SETUP=1, or any value but 0 and false.
  case ${BASEMODO_NO_SETUP:-} in
    '' | 0 | false) no_setup= ;;
    *) no_setup=1 ;;
  esac
  while [ $# -gt 0 ]; do
    case $1 in
      --dir)
        [ $# -ge 2 ] || usage
        dir=$2
        shift 2
        ;;
      --dir=*)
        dir=${1#--dir=}
        shift
        ;;
      --no-setup)
        no_setup=1
        shift
        ;;
      -h | --help) usage ;;
      -*) usage ;;
      *)
        version=$1
        shift
        ;;
    esac
  done
  [ -n "$dir" ] || dir=$HOME/.basemodo/bin
  version=${version#v}

  target=$(target)
  archive=basemodo-$target.tar.gz
  if [ -n "$version" ]; then
    download=$releases/download/v$version
    wanted="basemodo $version"
  else
    download=$releases/latest/download
    wanted="the latest basemodo"
  fi

  case $target in
    aarch64-apple-darwin) computer='macOS on Apple silicon' ;;
    x86_64-apple-darwin) computer='macOS on Intel' ;;
    aarch64-*) computer='Linux on ARM' ;;
    *) computer='Linux on x86_64' ;;
  esac
  say "Downloading $wanted for $computer..."
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  fetch "$download/$archive" "$tmp/$archive" || {
    if [ -n "$version" ]; then
      fail "could not download basemodo $version from $download: is $version one of the releases at $releases? Nothing was installed."
    fi
    fail "could not download $download/$archive. Nothing was installed."
  }
  fetch "$download/checksums.txt" "$tmp/checksums.txt" ||
    fail "could not download the release's checksums, $download/checksums.txt. Nothing was installed."
  verify "$tmp/$archive" "$tmp/checksums.txt"
  tar -xzf "$tmp/$archive" -C "$tmp" basemodo || fail "$archive holds no basemodo. Nothing was installed."
  installed=$("$tmp/basemodo" --version) || fail "the basemodo downloaded does not run on this computer. Nothing was installed."

  # Copied beside the old one, then renamed over it: a basemodo running meanwhile goes on
  # running, and the folder never holds half a program.
  mkdir -p "$dir" || fail "could not make the folder $dir."
  dir=$(cd "$dir" && pwd)
  cp "$tmp/basemodo" "$dir/basemodo.new"
  chmod 755 "$dir/basemodo.new"
  mv -f "$dir/basemodo.new" "$dir/basemodo"
  say "Installed $installed in $dir/basemodo."
  on_path "$dir"

  # `basemodo setup`: the program just installed and checked, by its path, never another
  # `basemodo` on the PATH. Its questions and its sign-in are the Person's, at their
  # terminal, which is not stdin when the script is piped to `sh` (stdin is the script)
  # but /dev/tty. With no terminal (an agent, CI, a server), it is left to the Person.
  [ -z "$no_setup" ] || return 0
  if [ -t 2 ] && (: </dev/tty) 2>/dev/null; then
    say ''
    "$dir/basemodo" setup </dev/tty ||
      say "basemodo is installed, but setup did not finish: run \`basemodo setup\` again."
  else
    say "Run \`basemodo setup\` in a terminal next: it sets your agents up and signs you in."
  fi
}

main "$@"
