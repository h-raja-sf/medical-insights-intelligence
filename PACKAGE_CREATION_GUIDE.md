# Package Creation Guide - Medical Insights Intelligence

## Current Status
✅ Code complete and committed to Git
✅ Pushed to GitHub
🔴 DevHub not configured (required for package creation)

---

## Prerequisites for Package Creation

### 1. DevHub Org Required

To create Salesforce packages, you need a **DevHub-enabled org**. Options:

#### Option A: Use Production Org as DevHub (Recommended)
**Best for**: AppExchange submission, production packages

**Steps:**
1. Log into your production Salesforce org
2. Go to **Setup → Development → Dev Hub**
3. Click **Enable Dev Hub**
4. Authorize this org with Salesforce CLI:
   ```bash
   sf org login web --set-default-dev-hub --alias devhub-prod
   ```

#### Option B: Enable DevHub in Developer Edition Org
**Best for**: Testing, development

**Steps:**
1. Sign up for a Developer Edition org at: https://developer.salesforce.com/signup
2. Once created, go to **Setup → Development → Dev Hub**
3. Click **Enable Dev Hub**
4. Authorize with CLI:
   ```bash
   sf org login web --set-default-dev-hub --alias devhub-dev
   ```

#### Option C: Use Trailhead Playground (Limited)
**Best for**: Quick testing only (packages created here are temporary)

**Note**: Trailhead Playgrounds have DevHub enabled by default but are not suitable for production packages.

---

## Package Types

### Unlocked Package (Recommended for Development)
**Pros:**
- Easy to iterate and update
- Can deploy to multiple orgs during development
- Source-driven development workflow
- Good for testing before going to managed

**Cons:**
- Not suitable for final AppExchange distribution
- Cannot upgrade to managed package later

**Use case**: Development, testing, internal distribution

### Managed Package (Required for AppExchange)
**Pros:**
- Required for AppExchange submission
- Supports versioning and upgrades
- Can include licensing
- Intellectual property protection

**Cons:**
- Requires namespace (must be registered)
- Some components cannot be deleted in upgrades
- More complex to manage

**Use case**: AppExchange distribution, ISV products

---

## Step-by-Step: Create Unlocked Package (Development)

### Step 1: Enable DevHub
Follow one of the options above to enable DevHub.

### Step 2: Update sfdx-project.json

Run this command:
```bash
cd /Users/harish.raja/med-insights/medical-insights-package
```

Then update `sfdx-project.json`:
```json
{
  "packageDirectories": [
    {
      "path": "package",
      "default": true,
      "package": "Medical Insights Intelligence",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT"
    }
  ],
  "name": "medical-insights-package",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "65.0",
  "packageAliases": {}
}
```

### Step 3: Create the Package

```bash
sf package create \
  --name "Medical Insights Intelligence" \
  --description "AI-Powered Field Intelligence Capture for Life Sciences" \
  --package-type Unlocked \
  --path package \
  --target-dev-hub devhub-prod
```

**Expected output:**
```
Successfully created a package. 0Ho...
Package Id: 0Ho...
```

### Step 4: Create Package Version

```bash
sf package version create \
  --package "Medical Insights Intelligence" \
  --installation-key-bypass \
  --wait 30 \
  --target-dev-hub devhub-prod
```

**Note**: This takes 5-15 minutes. The `--wait 30` means wait up to 30 minutes.

**Expected output:**
```
Package version creation request status: Success
Package Version Id: 04t...
Subscriber Package Version Id: 04t...
```

### Step 5: Promote Package Version (Optional)

Once tested:
```bash
sf package version promote \
  --package "04t..." \
  --target-dev-hub devhub-prod
```

### Step 6: Get Installation URL

```bash
sf package version report \
  --package "04t..." \
  --target-dev-hub devhub-prod
```

Installation URL will be in format:
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04t...
```

---

## Step-by-Step: Create Managed Package (AppExchange)

### Step 1: Register Namespace

**Important**: Namespace registration is **permanent** and **cannot be changed**.

1. Go to your DevHub org
2. Navigate to **Setup → Packages → Package Manager**
3. Click **Edit** next to "Developer Settings"
4. Enter your namespace prefix (e.g., "medinsights" or "mii")
5. Check availability
6. Click **Review My Selections**
7. Accept terms and click **Continue**

**Recommended namespace options:**
- `medinsights` (if available)
- `mii` (Medical Insights Intelligence)
- `miint` (Medical Insights Intelligence)

### Step 2: Update sfdx-project.json with Namespace

```json
{
  "packageDirectories": [
    {
      "path": "package",
      "default": true,
      "package": "Medical Insights Intelligence",
      "versionName": "Winter 2026",
      "versionNumber": "1.0.0.NEXT"
    }
  ],
  "name": "medical-insights-package",
  "namespace": "medinsights",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "65.0",
  "packageAliases": {}
}
```

### Step 3: Add Namespace to All Components

**Apex Classes** (add namespace prefix):
```apex
global with sharing class medinsights.MI_InsightTagWriteback {
    // ...
}
```

**Note**: This is a significant refactoring. All references must be updated.

### Step 4: Create Managed Package

```bash
sf package create \
  --name "Medical Insights Intelligence" \
  --description "AI-Powered Field Intelligence Capture for Life Sciences" \
  --package-type Managed \
  --path package \
  --target-dev-hub devhub-prod
```

### Step 5: Create Managed Package Version

```bash
sf package version create \
  --package "Medical Insights Intelligence" \
  --installation-key-bypass \
  --wait 30 \
  --target-dev-hub devhub-prod
```

### Step 6: Submit for Security Review

Once package version is created and tested:

1. Go to **AppExchange Partner Portal**: https://partners.salesforce.com
2. Navigate to your listing
3. Click **Submit for Security Review**
4. Upload package version ID
5. Wait 2-4 weeks for review

---

## Automated Package Creation Script

Once DevHub is configured, save this script as `create-package.sh`:

```bash
#!/bin/bash

echo "🚀 Creating Medical Insights Intelligence Package"
echo ""

# Check DevHub
echo "Checking DevHub connection..."
sf org list --all | grep DevHub
if [ $? -ne 0 ]; then
  echo "❌ No DevHub found. Please enable DevHub first."
  exit 1
fi

# Create package
echo ""
echo "Creating unlocked package..."
sf package create \
  --name "Medical Insights Intelligence" \
  --description "AI-Powered Field Intelligence Capture for Life Sciences" \
  --package-type Unlocked \
  --path package

if [ $? -ne 0 ]; then
  echo "❌ Package creation failed"
  exit 1
fi

echo ""
echo "✅ Package created successfully!"
echo ""
echo "Next steps:"
echo "1. Create package version: sf package version create --package \"Medical Insights Intelligence\" --wait 30"
echo "2. Test in scratch org"
echo "3. Promote when ready: sf package version promote --package [version-id]"
```

Make executable:
```bash
chmod +x create-package.sh
./create-package.sh
```

---

## Testing the Package

### Step 1: Create Scratch Org

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias mi-test \
  --set-default \
  --duration-days 30
```

### Step 2: Install Package in Scratch Org

```bash
sf package install \
  --package "04t..." \
  --wait 20 \
  --target-org mi-test
```

### Step 3: Test Package Components

```bash
# Assign permission set
sf org assign permset --name MI_Admin --target-org mi-test

# Open org
sf org open --target-org mi-test

# Run tests
sf apex run test --test-level RunLocalTests --target-org mi-test --wait 20
```

### Step 4: Generate Sample Data

In the scratch org:
```apex
MI_SampleDataGenerator.GenerationResult result = MI_SampleDataGenerator.generateAll();
System.debug('Subjects: ' + result.subjectsCreated);
System.debug('Products: ' + result.productsCreated);
System.debug('Insights: ' + result.insightsCreated);
```

---

## Package Dependencies

Medical Insights Intelligence requires:

### Required Dependencies
- **Salesforce Edition**: Enterprise or higher
- **Life Sciences Cloud**: Required (standard objects used)
- **Agentforce**: Required for AI-powered tagging

### Optional Dependencies
- **Einstein Analytics**: For advanced reporting (future)

---

## Troubleshooting

### Error: "No DevHub configured"
**Solution**: Enable DevHub in a production or Developer Edition org, then authorize with CLI.

### Error: "Package name already exists"
**Solution**: Use a different package name or delete the existing package.

### Error: "Namespace required for managed package"
**Solution**: Register a namespace in Setup → Package Manager.

### Error: "Component not found: MedicalInsight"
**Solution**: The target org must have Life Sciences Cloud installed. Create package in an LSC-enabled DevHub.

### Error: "Package version creation timed out"
**Solution**: This is normal for large packages. Check status with:
```bash
sf package version create report --target-dev-hub devhub-prod
```

---

## Next Steps After Package Creation

1. **Test thoroughly** in scratch orgs
2. **Run all tests** (must have >75% coverage)
3. **Create package version** for distribution
4. **Promote package version** when ready
5. **Submit for security review** (managed packages only)
6. **Create AppExchange listing**
7. **Launch!**

---

## Quick Commands Reference

```bash
# List packages
sf package list --target-dev-hub devhub-prod

# List package versions
sf package version list --package "Medical Insights Intelligence"

# View package version details
sf package version report --package "04t..."

# Generate installation URL
sf package version report --package "04t..." --json | jq -r '.result.InstallUrl'

# Delete package (if needed)
sf package delete --package "0Ho..." --target-dev-hub devhub-prod

# Delete package version (if needed)
sf package version delete --package "04t..." --target-dev-hub devhub-prod
```

---

## Recommendation

**For your immediate next step:**

1. ✅ **Enable DevHub** in a production or Developer Edition org
2. ✅ **Create unlocked package** for development/testing
3. ✅ **Test in scratch orgs** to validate everything works
4. ✅ **When ready for AppExchange**: Register namespace and create managed package
5. ✅ **Submit for security review**

**Estimated timeline:**
- DevHub setup: 10 minutes
- Unlocked package creation: 15 minutes
- Testing: 2-4 hours
- Namespace registration: 5 minutes
- Managed package creation: 30 minutes
- Security review: 2-4 weeks

---

*Version 1.0 | Medical Insights Intelligence | Package Creation Guide*
