#!/bin/bash
set -e

# ----------------------------
# 1. Validate Arguments
# ----------------------------

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "❌ ERROR: Missing arguments."
  echo "Usage: ./release.sh <version_name> <build_number> \"commit message\""
  echo "Example: ./release.sh 1.2.0 7 \"Add mosque search\""
  exit 1
fi

VERSION_NAME=$1
BUILD_NUMBER=$2
COMMIT_MESSAGE=$3

# ----------------------------
# 2. Validate Version Name Format (x.y.z)
# ----------------------------

if ! [[ "$VERSION_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ ERROR: Version name must be in format x.y.z"
  echo "Example: 1.2.0"
  exit 1
fi

# ----------------------------
# 3. Validate Build Number
# ----------------------------

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "❌ ERROR: Build number must be an integer."
  exit 1
fi

# ----------------------------
# 4. Block If Uncommitted Changes
# ----------------------------

if ! git diff-index --quiet HEAD --; then
  echo "❌ ERROR: You have uncommitted changes."
  echo "Commit or stash them before releasing."
  exit 1
fi

# ----------------------------
# 5. Update pubspec.yaml
# ----------------------------

sed -i "s/^version:.*/version: ${VERSION_NAME}+${BUILD_NUMBER}/" pubspec.yaml

echo "✅ Updated version to ${VERSION_NAME}+${BUILD_NUMBER}"

# ----------------------------
# 6. Commit Version Bump
# ----------------------------

git add pubspec.yaml
git commit -m "Release ${VERSION_NAME}+${BUILD_NUMBER} - ${COMMIT_MESSAGE}"

# ----------------------------
# 7. Build Release Bundle
# ----------------------------

flutter clean
flutter build appbundle --release

echo ""
echo "🚀 Release build complete."
echo "📦 File: build/app/outputs/bundle/release/app-release.aab"