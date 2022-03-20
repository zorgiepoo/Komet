#!/usr/bin/env bash

rm -rf Sparkle.framework/Resources/*.lproj
rm -rf Sparkle.framework/Resources/ReleaseNotesColorStyle.css
rm -rf Sparkle.framework/Resources/SUStatus.nib
rm -rf Sparkle.framework/Updater.app/Contents/Resources/*.lproj
rm -rf Sparkle.framework/Updater.app/Contents/Resources/*.lproj
codesign -f -s "-" -o runtime --preserve-metadata=entitlements Sparkle.framework/Versions/B/Updater.app
codesign -f -s "-" -o runtime Sparkle.framework
