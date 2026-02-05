#!/bin/bash

# Medical Insights Intelligence - Package Creation Script
# Run this after enabling DevHub in your org

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Medical Insights Intelligence - Package Creator          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if DevHub is configured
echo "🔍 Checking for DevHub..."
DEVHUB_CHECK=$(sf org list --all 2>&1 | grep -i "Default DevHub" || true)

if [ -z "$DEVHUB_CHECK" ]; then
  echo "❌ No DevHub found!"
  echo ""
  echo "Please enable DevHub first:"
  echo "  1. Log into production org or Developer Edition"
  echo "  2. Setup → Development → Dev Hub → Enable"
  echo "  3. Run: sf org login web --set-default-dev-hub --alias devhub-prod"
  echo ""
  echo "See PACKAGE_CREATION_GUIDE.md for details."
  exit 1
fi

echo "✅ DevHub found!"
echo ""

# Package details
PACKAGE_NAME="Medical Insights Intelligence"
PACKAGE_DESC="AI-Powered Field Intelligence Capture for Life Sciences"
VERSION_NAME="Winter 2026"
VERSION_NUMBER="1.0.0.NEXT"

# Ask for package type
echo "Select package type:"
echo "  1) Unlocked Package (recommended for development/testing)"
echo "  2) Managed Package (required for AppExchange)"
echo ""
read -p "Enter choice (1 or 2): " PACKAGE_TYPE_CHOICE

if [ "$PACKAGE_TYPE_CHOICE" = "2" ]; then
  PACKAGE_TYPE="Managed"
  echo ""
  read -p "Enter your registered namespace (e.g., medinsights): " NAMESPACE
  if [ -z "$NAMESPACE" ]; then
    echo "❌ Namespace required for managed packages"
    exit 1
  fi
else
  PACKAGE_TYPE="Unlocked"
  NAMESPACE=""
fi

echo ""
echo "Creating $PACKAGE_TYPE package..."
echo "  Name: $PACKAGE_NAME"
echo "  Description: $PACKAGE_DESC"
if [ -n "$NAMESPACE" ]; then
  echo "  Namespace: $NAMESPACE"
fi
echo ""

# Check if package already exists
EXISTING_PACKAGE=$(sf package list --json 2>/dev/null | jq -r ".result[] | select(.Name == \"$PACKAGE_NAME\") | .Id" || true)

if [ -n "$EXISTING_PACKAGE" ]; then
  echo "⚠️  Package '$PACKAGE_NAME' already exists (ID: $EXISTING_PACKAGE)"
  echo ""
  read -p "Do you want to create a new version of the existing package? (y/n): " CREATE_VERSION
  
  if [ "$CREATE_VERSION" != "y" ]; then
    echo "❌ Cancelled"
    exit 1
  fi
  
  PACKAGE_ID="$EXISTING_PACKAGE"
else
  # Create package
  echo "Creating package..."
  if [ "$PACKAGE_TYPE" = "Managed" ]; then
    CREATE_CMD="sf package create --name \"$PACKAGE_NAME\" --description \"$PACKAGE_DESC\" --package-type Managed --path force-app"
  else
    CREATE_CMD="sf package create --name \"$PACKAGE_NAME\" --description \"$PACKAGE_DESC\" --package-type Unlocked --path force-app"
  fi
  
  PACKAGE_RESULT=$(eval $CREATE_CMD --json)
  PACKAGE_ID=$(echo "$PACKAGE_RESULT" | jq -r '.result.Id')
  
  if [ -z "$PACKAGE_ID" ] || [ "$PACKAGE_ID" = "null" ]; then
    echo "❌ Package creation failed"
    echo "$PACKAGE_RESULT" | jq -r '.message'
    exit 1
  fi
  
  echo "✅ Package created successfully!"
  echo "   Package ID: $PACKAGE_ID"
fi

echo ""
read -p "Do you want to create a package version now? (y/n): " CREATE_VERSION

if [ "$CREATE_VERSION" = "y" ]; then
  echo ""
  echo "Creating package version..."
  echo "⚠️  This may take 10-15 minutes. Please wait..."
  echo ""
  
  VERSION_CMD="sf package version create --package \"$PACKAGE_NAME\" --installation-key-bypass --wait 30 --json"
  
  VERSION_RESULT=$(eval $VERSION_CMD)
  VERSION_STATUS=$(echo "$VERSION_RESULT" | jq -r '.status')
  
  if [ "$VERSION_STATUS" = "0" ]; then
    VERSION_ID=$(echo "$VERSION_RESULT" | jq -r '.result.SubscriberPackageVersionId')
    echo "✅ Package version created successfully!"
    echo "   Version ID: $VERSION_ID"
    echo ""
    echo "Installation URL:"
    echo "   https://login.salesforce.com/packaging/installPackage.apexp?p0=$VERSION_ID"
    echo ""
    echo "Next steps:"
    echo "  1. Test installation in a scratch org or sandbox"
    echo "  2. Run all tests to ensure >75% coverage"
    echo "  3. Promote version when ready: sf package version promote --package $VERSION_ID"
  else
    echo "❌ Package version creation failed or timed out"
    echo ""
    echo "Check status with:"
    echo "  sf package version create report"
  fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Package creation complete!                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📚 See PACKAGE_CREATION_GUIDE.md for full documentation"

