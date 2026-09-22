#!/bin/bash
set -euo pipefail
if [ "$#" -ne 1 ]; then
  echo 'Usage: bash scripts/archive-for-upload.sh APPLE_TEAM_ID' >&2
  echo 'Requires active Apple Developer membership and Xcode account access.' >&2
  exit 2
fi
TIQ_TEAM_ID="$1"
if [[ ! "$TIQ_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo 'Apple Team ID must be 10 uppercase letters or digits.' >&2
  exit 2
fi
TIQ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIQ_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TIQ_ARCHIVE="$TIQ_ROOT/release/TennisIQ-$TIQ_STAMP.xcarchive"
xcodebuild -project "$TIQ_ROOT/TennisIQ.xcodeproj" -scheme TennisIQ \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$TIQ_ARCHIVE" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TIQ_TEAM_ID" CODE_SIGN_STYLE=Automatic archive
python3 "$TIQ_ROOT/scripts/check-release.py" "$TIQ_ARCHIVE"
open "$TIQ_ARCHIVE"
echo 'Archive created. Use Xcode Organizer to Validate App, then Distribute App.'
echo 'This script does not upload or submit the app.'
