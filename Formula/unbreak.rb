# Homebrew formula for unbreak (PRD v2 §9).
#
# This is the TAP copy (bart-turczynski/homebrew-tap), the one users install from:
#
#   brew install bart-turczynski/tap/unbreak
#
# It mirrors Formula/unbreak.rb in the unbreak repo on every release. The only
# difference: the source `sha256` below is the REAL digest of the tagged tarball
# (the in-repo copy can't be self-consistent, since it ships inside that tarball).
#
# Installs come from a prebuilt **bottle** (see the `bottle do` block) so users
# need no Swift toolchain. The `install` recipe below still builds from source —
# it is both how the release workflow *produces* the bottle and the automatic
# fallback for any platform without a matching bottle (then the Xcode Command
# Line Tools are required). On each tagged release, bump `version`, `url`, and
# `sha256` (source tarball) together, then paste the workflow-generated bottle
# block — see docs/RELEASING.md.
class Unbreak < Formula
  desc "Repair terminal-wrapped clipboard commands from TUI coding agents"
  homepage "https://github.com/bart-turczynski/unbreak"
  # Source tarball for the tagged release. `version` is explicit so users update
  # only on a bump, not on every tap refresh.
  url "https://github.com/bart-turczynski/unbreak/archive/refs/tags/v0.6.0.tar.gz"
  version "0.6.0"
  # Real digest of the v0.6.0 source tarball:
  #   curl -fsSL .../v0.6.0.tar.gz | shasum -a 256
  sha256 "0515519e29eb46d6108c40929c0bdd2b36219cba644cac9caaacb6e3cbea8629"
  license "MIT"

  # Prebuilt binary, hosted as a GitHub release asset (see .github/workflows/
  # release.yml). The job builds a UNIVERSAL (arm64 + x86_64) binary on the
  # macos-26 runner, then relabels it to the OLDEST supported macOS — ventura =
  # Package.swift .macOS(.v13) — under both arch tags, because Homebrew reuses a
  # bottle on a newer OS within the same arch (never older, never across archs).
  # `arm64_ventura` serves Apple Silicon macOS 13+, `ventura` serves Intel 13+.
  # The two release assets are byte-identical copies of the one universal tarball,
  # so they share a sha256.
  # `:any_skip_relocation` is correct: the binary hardcodes no Cellar path (links
  # only system libs + the OS Swift runtime).
  bottle do
    root_url "https://github.com/bart-turczynski/unbreak/releases/download/v0.6.0"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "316a228b483dae023fd13b757e670fa9e7f50aa733ac38c2ed787526d7ae978c"
    sha256 cellar: :any_skip_relocation, ventura:       "316a228b483dae023fd13b757e670fa9e7f50aa733ac38c2ed787526d7ae978c"
  end

  depends_on :macos

  def install
    # Self-contained SwiftPM package (no external deps): a release build with the
    # sandbox disabled so SwiftPM can write its build products. Build a universal
    # (arm64 + x86_64) binary so the one bottle this recipe produces serves both
    # Mac architectures — Homebrew reuses a bottle only within an arch, so without
    # the x86_64 slice Intel Macs fall back to the source build. SwiftPM runs the
    # `lipo` merge itself for a multi-`--arch` build; the fat binary lands under
    # `.build/apple/Products/Release` (not the single-arch `.build/release`). Both
    # slices target Package.swift's .macOS(.v13) floor.
    system "swift", "build", "--disable-sandbox", "-c", "release",
           "--arch", "arm64", "--arch", "x86_64"
    bin.install ".build/apple/Products/Release/unbreak"
  end

  # `brew services start unbreak` generates the per-user launchd plist — no
  # hardcoded path or username (§9). The watcher only mutates the clipboard when
  # every §7 gate passes.
  service do
    run [opt_bin/"unbreak", "--watch"]
    run_type :immediate
    keep_alive true
    log_path var/"log/unbreak.watch.log"
    error_log_path var/"log/unbreak.watch.log"
  end

  def caveats
    <<~EOS
      The clipboard watcher is OFF until you opt in — `brew install` only puts the
      CLI on your PATH. Turn it on with either:

        brew services start unbreak     # run the watcher at login (launchd)

      or the guided setup, which detects your terminals and writes a config first:

        unbreak setup

      One-shot use never needs the watcher:

        pbpaste | unbreak -             # repair clipboard text, print to stdout

      To remove everything unbreak wrote (login watcher, logs, undo socket, config)
      before `brew uninstall unbreak`, run:

        unbreak uninstall               # `brew uninstall` alone leaves this state behind
    EOS
  end

  test do
    # Exercise the core repair path over stdin: §6.1 normalize must strip ANSI
    # escapes (the stdin->stdout surface never touches the real clipboard).
    assert_equal "git status",
      pipe_output("#{bin}/unbreak -", "\e[31mgit status\e[0m\n").strip
  end
end
