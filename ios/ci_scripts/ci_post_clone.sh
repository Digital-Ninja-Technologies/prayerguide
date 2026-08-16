#!/bin/sh

# Xcode Cloud runs this automatically after cloning the repo, before the
# build/archive step — see
# https://docs.flutter.dev/deployment/cd#xcode-cloud
#
# Xcode Cloud's macOS images have Xcode itself but not Flutter, and a fresh
# git clone never includes ios/Flutter/ephemeral/ (it's generated locally by
# `flutter pub get`, not committed) — that's exactly the folder
# ios/Runner.xcodeproj references as a local Swift Package
# (FlutterGeneratedPluginSwiftPackage), so without this script `xcodebuild`
# fails immediately with "Could not resolve package dependencies ... doesn't
# exist in file system" before it ever gets to compiling anything.

set -e

# The default working directory for this script is ios/ci_scripts/ itself —
# move to the repo root Xcode Cloud checked out.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# pubspec.yaml bundles `.env` as a Flutter asset (flutter_dotenv reads it at
# runtime) — it's correctly gitignored, so a fresh checkout doesn't have
# one, and the Flutter build phase that runs later inside Xcode fails
# outright looking for a declared asset file that doesn't exist. Generate
# one from Xcode Cloud's own Environment Variables instead of committing
# secrets: App Store Connect → this app → Xcode Cloud → the workflow →
# Environment → Environment Variables. Add SUPABASE_URL and
# SUPABASE_ANON_KEY there (mark SUPABASE_ANON_KEY as Secret) — Xcode Cloud
# injects whatever's configured into every script phase's environment,
# including this one. The rest are optional, same names as .env.example.
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
GOOGLE_OAUTH_CLIENT_ID=${GOOGLE_OAUTH_CLIENT_ID:-}
CHURCH_YOUTUBE_CHANNEL_URL=${CHURCH_YOUTUBE_CHANNEL_URL:-}
IOS_APP_STORE_ID=${IOS_APP_STORE_ID:-}
LIVEKIT_URL=${LIVEKIT_URL:-}
EOF

# Install Flutter (stable channel — matches this repo's .metadata) via a
# shallow clone, since Xcode Cloud's VM is thrown away after every run.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Pulls down the iOS engine artifacts for this Flutter version.
flutter precache --ios

# Regenerates ios/Flutter/ephemeral/ — this is the step that actually fixes
# the missing-package error above.
flutter pub get

# Xcode Cloud images generally already have CocoaPods, but installing
# defensively here matches Flutter's own documented Xcode Cloud recipe and
# avoids a stale/missing version being the next failure.
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# ios/Podfile.lock is intentionally not committed (see ios/.gitignore) — it
# can only be correctly regenerated with a real CocoaPods toolchain, and a
# stale committed one (missing pods for a plugin added without one) is
# worse than none: Xcode's "[CP] Check Pods Manifest.lock" build phase
# fails the whole build if Podfile.lock and the freshly-installed
# Pods/Manifest.lock disagree. Resolving fresh here every run avoids that
# entirely.
cd ios
pod install
