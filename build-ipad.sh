#!/bin/bash

# Build iPad IPA
echo "Building Secondary Screen iPad App..."

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
IPAD_PROJECT="$PROJECT_DIR/iPadApp/SecondaryScreen.xcodeproj"
BUILD_DIR="$PROJECT_DIR/Build/iPad"
SCHEME="SecondaryScreen"

# Clean previous build
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed or xcodebuild is not in PATH"
    exit 1
fi

# Clean build folder
echo "Cleaning previous builds..."
xcodebuild clean -project "$IPAD_PROJECT" -scheme "$SCHEME" -configuration Release

# Build archive
echo "Creating archive..."
xcodebuild archive \
    -project "$IPAD_PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$SCHEME.xcarchive" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -eq 0 ]; then
    echo ""
    echo "Archive created successfully!"
    echo "Location: $BUILD_DIR/$SCHEME.xcarchive"
    echo ""
    echo "To create an IPA:"
    echo "1. Open Xcode"
    echo "2. Go to Window > Organizer"
    echo "3. Select the archive"
    echo "4. Click 'Distribute App'"
    echo "5. Follow the prompts to create your IPA"
    echo ""
    echo "Or use the Xcode command with proper signing:"
    echo "xcodebuild -exportArchive \\"
    echo "  -archivePath $BUILD_DIR/$SCHEME.xcarchive \\"
    echo "  -exportPath $BUILD_DIR \\"
    echo "  -exportOptionsPlist ExportOptions.plist"
else
    echo "Build failed!"
    exit 1
fi

# Create export options template
cat > "$BUILD_DIR/ExportOptions.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

echo "Export options template created at: $BUILD_DIR/ExportOptions.plist"
echo "Edit this file with your Team ID before exporting the IPA"
