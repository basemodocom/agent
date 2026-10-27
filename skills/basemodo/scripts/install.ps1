# Installs the Basemodo CLI, `basemodo`, on Windows (spec #518), from PowerShell:
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
#
# It downloads the Windows build from the CLI's releases (github.com/basemodocom/cli),
# checks it against the release's checksums, puts `basemodo.exe` in the user's local
# programs folder (%LOCALAPPDATA%\Programs\basemodo) and adds that folder to the user's
# PATH when it is not there. Running it again installs the latest version over the one
# there. It never needs an administrator.
#
# Then it runs `basemodo setup`, which sets the Person's agents up and signs them in
# (#543), when there is a terminal to ask its questions in; with none (an agent, CI, a
# server), it says in one line to run it.
#
# A version, another folder, or no setup:
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -Version 0.2.0 -InstallDir C:\tools\basemodo -NoSetup
#
# The same as environment variables: BASEMODO_VERSION, BASEMODO_INSTALL_DIR,
# BASEMODO_NO_SETUP=1. And
# BASEMODO_RELEASES_URL, where the releases are (https://github.com/basemodocom/cli/releases):
# CI serves the builds of the commit it tests from there.
#
# Run by `iex` in the Person's own PowerShell: it never calls `exit`, which would close
# their window, and it is one script block run in a scope of its own, which leaves
# their session as it found it but for `basemodo` on its PATH: no variable, function
# or preference of its own, nor the TLS protocols it turns on. Its arguments reach it as the script's own when it runs as a
# file or a script block. Written for Windows PowerShell 5.1 as well as PowerShell 7,
# in ASCII alone, which 5.1 reads right.

& {
  param(
    [string]$Version = $env:BASEMODO_VERSION,
    [string]$InstallDir = $env:BASEMODO_INSTALL_DIR,
    [switch]$NoSetup
  )

  $ErrorActionPreference = 'Stop'
  # Windows PowerShell 5.1 draws a progress bar per downloaded block, slowly.
  $ProgressPreference = 'SilentlyContinue'

  # The reason, as one plain line; then a stop, which ends `iex` (and fails a CI step)
  # without closing the window.
  function Fail([string]$Message) {
    $Host.UI.WriteErrorLine("basemodo install: $Message")
    throw 'basemodo install stopped.'
  }

  if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    Fail 'on macOS and Linux, install basemodo with: sh install.sh, beside this script'
  }
  # A 32-bit PowerShell on 64-bit Windows says so in PROCESSOR_ARCHITEW6432. Windows on
  # ARM runs the x86_64 build.
  $arch = $env:PROCESSOR_ARCHITEW6432
  if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
  if ($arch -ne 'AMD64' -and $arch -ne 'ARM64') {
    Fail "there is no build of basemodo for this processor ($arch)."
  }
  $target = 'x86_64-pc-windows-msvc'
  $archive = "basemodo-$target.zip"

  $releases = $env:BASEMODO_RELEASES_URL
  if (-not $releases) { $releases = 'https://github.com/basemodocom/cli/releases' }
  $releases = $releases.TrimEnd('/')
  if ($Version) {
    $Version = $Version.TrimStart('v')
    $download = "$releases/download/v$Version"
    $which = "basemodo $Version"
  } else {
    $download = "$releases/latest/download"
    $which = 'the latest basemodo'
  }
  if (-not $InstallDir) { $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\basemodo' }
  # A folder given as relative is relative to where the Person is.
  $InstallDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($InstallDir).TrimEnd('\')

  Write-Host "Downloading $which for Windows..."
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('basemodo-' + [Guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  # GitHub answers TLS 1.2 and up, which Windows PowerShell 5.1 may not offer by itself:
  # turned on for the downloads, and the session's own protocols put back after.
  $protocols = [Net.ServicePointManager]::SecurityProtocol
  try {
    [Net.ServicePointManager]::SecurityProtocol = $protocols -bor [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $tmp $archive
    try {
      Invoke-WebRequest -UseBasicParsing -Uri "$download/$archive" -OutFile $zip
    } catch {
      if ($Version) {
        Fail "could not download basemodo $Version from ${download}: is $Version one of the releases at ${releases}? Nothing was installed."
      }
      Fail "could not download $download/$archive ($($_.Exception.Message)). Nothing was installed."
    }
    $sums = Join-Path $tmp 'checksums.txt'
    try {
      Invoke-WebRequest -UseBasicParsing -Uri "$download/checksums.txt" -OutFile $sums
    } catch {
      Fail "could not download the release's checksums, $download/checksums.txt. Nothing was installed."
    }

    # sha256sum's lines: "<hex>  <name>", or "<hex> *<name>".
    $expected = $null
    foreach ($line in Get-Content -LiteralPath $sums) {
      $parts = $line.Trim() -split '\s+', 2
      if ($parts.Count -eq 2 -and ($parts[1] -eq $archive -or $parts[1] -eq "*$archive")) {
        $expected = $parts[0]
        break
      }
    }
    if (-not $expected) {
      Fail "the release's checksums do not list $archive. Nothing was installed."
    }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash
    if ($actual -ne $expected) {
      Fail "$archive does not match the release's checksum: it may be damaged or not the release's own. Nothing was installed."
    }

    $unpacked = Join-Path $tmp 'unpacked'
    Expand-Archive -LiteralPath $zip -DestinationPath $unpacked -Force
    $exe = Join-Path $unpacked 'basemodo.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
      Fail "$archive holds no basemodo.exe. Nothing was installed."
    }
    try {
      $installed = (& $exe --version | Out-String).Trim()
    } catch {
      $installed = $null
    }
    if ($LASTEXITCODE -ne 0 -or -not $installed) {
      Fail 'the basemodo downloaded does not run on this computer. Nothing was installed.'
    }

    # Windows lets a running program be renamed but not replaced: the one there moves
    # aside, the new one takes its name, and what moved aside goes when nothing runs it.
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $program = Join-Path $InstallDir 'basemodo.exe'
    Get-ChildItem -LiteralPath $InstallDir -Filter 'basemodo.exe.*.old' |
      Remove-Item -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $exe -Destination "$program.new" -Force
    if (Test-Path -LiteralPath $program) {
      $old = "$program.$([Guid]::NewGuid()).old"
      Move-Item -LiteralPath $program -Destination $old
      Remove-Item -LiteralPath $old -Force -ErrorAction SilentlyContinue
    }
    Move-Item -LiteralPath "$program.new" -Destination $program
    Write-Host "Installed $installed in $program."
  } finally {
    [Net.ServicePointManager]::SecurityProtocol = $protocols
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }

  # The user's PATH, as the registry keeps it (with %VARIABLES% unexpanded), gets the
  # folder unless it, or the computer's PATH, has it already.
  $onPath = {
    param([string]$Value)
    foreach ($entry in ($Value -split ';')) {
      if ($entry -and [Environment]::ExpandEnvironmentVariables($entry).TrimEnd('\') -ieq $InstallDir) { return $true }
    }
    return $false
  }
  $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
  try {
    $userPath = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ((& $onPath $userPath) -or (& $onPath $machinePath)) {
      # On the PATH of new terminals, and now of this window too.
      if (-not (& $onPath $env:Path)) { $env:Path = "$InstallDir;$env:Path" }
    } else {
      if ($userPath) { $userPath = $userPath.TrimEnd(';') + ";$InstallDir" } else { $userPath = $InstallDir }
      $key.SetValue('Path', $userPath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
      # Setting a variable through .NET tells Windows the environment changed, so
      # terminals opened from now on read the new PATH; this window's is set here.
      [Environment]::SetEnvironmentVariable('BASEMODO_INSTALLING', '1', 'User')
      [Environment]::SetEnvironmentVariable('BASEMODO_INSTALLING', $null, 'User')
      $env:Path = "$InstallDir;$env:Path"
      Write-Host "Added $InstallDir to your PATH."
      Write-Host 'basemodo works in this window and in new terminals.'
    }
  } finally {
    $key.Close()
  }

  # `basemodo setup`: the program just installed and checked, by its path, never another
  # `basemodo` on the PATH. Its questions and its sign-in are the Person's, at their
  # console; with none to ask in (an agent, CI, a server), it is left to the Person.
  # BASEMODO_NO_SETUP=1, or any value but 0 and false.
  if ($NoSetup -or ($env:BASEMODO_NO_SETUP -and $env:BASEMODO_NO_SETUP -notin '0', 'false')) { return }
  if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and -not [Console]::IsErrorRedirected) {
    Write-Host ''
    try {
      & $program setup
      $finished = $LASTEXITCODE -eq 0
    } catch {
      $finished = $false
    }
    if (-not $finished) {
      Write-Host 'basemodo is installed, but setup did not finish: run `basemodo setup` again.'
    }
  } else {
    Write-Host 'Run `basemodo setup` in a terminal next: it sets your agents up and signs you in.'
  }
} @args
