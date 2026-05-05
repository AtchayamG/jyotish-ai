# push.ps1  — reusable commit+push script
# Usage: powershell -ExecutionPolicy Bypass -File .\push.ps1
# Edit $msg below to change the commit message before running.

Set-Location "D:\Work\Claude\Jyotish"

$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

# Remove junk files from git tracking (safe even if already removed)
$junk = @(
  "DELETE_OLD_GRADLE.bat",
  "DELETE_OLD_GRADLE_FILES.bat",
  "FIX_ANDROID.ps1",
  "GIT_CLEANUP_COMMANDS.md",
  "NUCLEAR_FIX.ps1",
  "PUSH_FRESH_STEPS.md",
  "REGENERATE_ANDROID.ps1",
  "RENDER_ENV_UPDATE.md",
  "SETUP_GITHUB_PAGES.md",
  "SWAGGER_GUIDE.md"
)
foreach ($f in $junk) {
  if (Test-Path $f) {
    git rm --cached $f 2>$null
    Remove-Item $f -Force 2>$null
  } else {
    git rm --cached $f 2>$null
  }
}

# Remove Jyotish/ subfolder from git tracking and local disk (one-time cleanup)
if (Test-Path "Jyotish") {
  git rm -r --cached Jyotish/ 2>$null
  Remove-Item -Recurse -Force "Jyotish"
  Write-Host "Removed Jyotish/ subfolder" -ForegroundColor Yellow
}

git add -A

# Write commit message to a temp file to avoid Unicode/shell parsing issues
$msg = @"
feat: dasha fix, user tiers, settings page, profiles, pricing, web layout

Dasha fix - real Vimshottari computation in Kundli summary:
  - Added _DASHA_SEQUENCE/_NAK_TO_DASHA/_DASHA_YEARS tables to astrology_service.py
  - Added _compute_dasha() - extracts moon longitude, computes correct mahadasha+antardasha
  - get_kundli() now shows e.g. 'Rahu Mahadasha / Venus Antardasha (until Sep 2026)'
  - Fallback to 'Computing...' if Swiss Ephemeris unavailable (never shows ?-? again)

User tier system (backend):
  - UserTier enum: free / premium / max / admin in user_schema.py
  - UserInDB + UserPublic include user_tier field (default: free)
  - user_repository: create() defaults user_tier=free, update_profile() syncs is_premium/is_admin
  - New Firestore 'profiles' collection with list/add/delete endpoints at /user/profiles
  - POST /user/profiles enforces tier limits: free=0, premium=2, max=5, admin=unlimited
  - 403 Forbidden with upgrade message when limit exceeded

Flutter - UserTier propagation:
  - UserEntity: userTier field + UserTierX extension (label, maxProfiles, canAddProfiles)
  - UserModel.fromJson(): parses user_tier string -> enum with fallback to free
  - AuthRepositoryImpl: passes userTier through login/register
  - SecureStorage: saves/loads user_tier; saveUser() accepts userTier param
  - AuthBloc: _onCheck loads tier from storage; login/register save tier

Settings page (Flutter):
  - settings_page.dart: full page with Profile, Account, Astrology Preferences, About sections
  - Profile header: avatar initial, name, email, tier badge with color coding
  - Account section: upgrade banner for free users, plan details, notifications toggle
  - Profiles section: My Profile, Add Profile (tier-gated), Switch Profile
  - About section: version, privacy policy, terms, rate app, feedback
  - Sign Out with confirmation dialog
  - Home profile-menu (avatar tap) updated: Settings + Switch Profile + Upgrade Plan + Sign Out

Pricing page (Flutter):
  - pricing_page.dart: 3-tier comparison (Free/Premium/Max) with feature lists
  - Premium: Rs.199/month, 2 profiles; Max: Rs.499/month, 5 profiles
  - 'Most Popular' badge on Premium tier
  - Subscribe buttons show demo dialog: 'Razorpay integration coming soon'

Add Profile page (Flutter):
  - add_profile_page.dart: name, relationship dropdown, gender selector, DOB picker,
    TOB picker, place of birth field
  - Form validation, save stub with success snackbar

Switch Profile page (Flutter):
  - switch_profile_page.dart: shows own profile (active), family profiles list
  - Empty state with 'Add First Profile' CTA
  - Upgrade prompt for free-tier users with 'View Plans' CTA

Router + Shell:
  - New routes: /settings, /pricing, /settings/add-profile, /settings/profiles
  - Settings pages live outside ShellRoute (full-screen, no bottom nav)

Web layout fix:
  - shell_page.dart: on web wraps scaffold in ConstrainedBox(maxWidth: 430) on dark bg
  - app_widgets.dart: PageLayout widget (kIsWeb-aware 430px cap) + kPageHPad = 16.0 constant
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
