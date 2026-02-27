#!/bin/bash
set -e

# ----------------------------
# 1. Validate Arguments
# ----------------------------

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "❌ ERROR: Missing arguments."
  echo "Usage: ./release.sh <version_name> \"commit message\""
  echo "Example: ./release.sh 1.2.0 \"Add mosque search\""
  exit 1
fi

VERSION_NAME=$1
COMMIT_MESSAGE=$2

# ----------------------------
# 2. Validate Version Name Format (x.y.z)
# ----------------------------

if ! [[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ ERROR: Version name must be in format x.y.z"
  echo "Example: 1.2.0"
  exit 1
fi

# ----------------------------
# 3. Block If Uncommitted Changes
# ----------------------------

if ! git diff-index --quiet HEAD --; then
  echo "❌ ERROR: You have uncommitted changes."
  echo "Commit or stash them before releasing."
  exit 1
fi

# ----------------------------
# 4. Read Current Build Number
# ----------------------------

current=$(grep '^version:' pubspec.yaml | awk '{print $2}')

if [[ "$current" != *"+"* ]]; then
  echo "❌ ERROR: pubspec.yaml must contain build number (x.y.z+build)"
  exit 1
fi

current_build=$(echo $current | cut -d'+' -f2)

if ! [[ "$current_build" =~ ^[0-9]+$ ]]; then
  echo "❌ ERROR: Existing build number is invalid."
  exit 1
fi

# Auto increment
NEW_BUILD=$((current_build + 1))

# ----------------------------
# 5. Update pubspec.yaml
# ----------------------------

sed -i "s/^version:.*/version: ${VERSION_NAME}+${NEW_BUILD}/" pubspec.yaml

echo "✅ Updated version to ${VERSION_NAME}+${NEW_BUILD}"

# ----------------------------
# 6. Commit Version Bump
# ----------------------------

git add pubspec.yaml
git commit -m "Release ${VERSION_NAME}+${NEW_BUILD} - ${COMMIT_MESSAGE}"

# ----------------------------
# 7. Build Release Bundle
# ----------------------------

flutter clean
flutter build appbundle --release

echo ""
echo "🚀 Release build complete."
echo "📦 File: build/app/outputs/bundle/release/app-release.aab"