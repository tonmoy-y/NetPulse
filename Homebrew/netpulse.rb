cask "netpulse" do
  version "2.0.0"
  sha256 "5409249ab071bb756b8460fd50b198c914241d955a0f48046d6a7a75e20c5e1e"

  url "https://github.com/tonmoy-y/NetPulse/releases/download/v#{version}/NetPulse-#{version}.dmg"
  name "NetPulse"
  desc "Lightweight, privacy-first network speed monitor for the macOS menu bar"
  homepage "https://github.com/tonmoy-y/NetPulse"

  depends_on macos: :ventura

  app "NetPulse.app"

  # NOTE: `postflight do ... end` is deprecated in favor of
  # `postflight_steps do ... end` on newer Homebrew, but `appdir` is not
  # defined inside that new block on the Homebrew version this was tested
  # against, which made the whole cask fail to parse ("undefined local
  # variable or method 'appdir'") — breaking `brew tap`/`brew install`
  # entirely, not just producing a warning. Keeping the working `postflight`
  # form until `postflight_steps` support stabilizes; verified working by
  # actually running `brew install --cask netpulse` end to end.
  postflight do
    # NetPulse is ad-hoc signed, not notarized with a paid Apple Developer
    # ID. Clearing quarantine here is the Homebrew-standard equivalent of
    # the one-time Right-click → Open step a manual .dmg install needs.
    system_command "/usr/bin/xattr",
                    args: ["-dr", "com.apple.quarantine", "#{appdir}/NetPulse.app"],
                    sudo: false
  end

  zap trash: [
    "~/Library/Application Support/NetPulse",
    "~/Library/Preferences/com.tonmoysarkersourav.netpulse.plist",
  ]
end
