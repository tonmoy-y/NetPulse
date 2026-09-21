cask "netpulse" do
  version "1.0.0"
  sha256 :no_check # replace with the real sha256 of the notarized DMG before publishing

  url "https://github.com/tonmoy-y/NetPulse/releases/download/v#{version}/NetPulse-#{version}.dmg"
  name "NetPulse"
  desc "Lightweight, privacy-first network speed monitor for the macOS menu bar"
  homepage "https://github.com/tonmoy-y/NetPulse"

  depends_on macos: ">= :ventura"

  app "NetPulse.app"

  zap trash: [
    "~/Library/Application Support/NetPulse",
    "~/Library/Preferences/com.tonmoysarkersourav.netpulse.plist",
  ]
end
