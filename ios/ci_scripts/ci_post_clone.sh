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

cd ios
pod install
