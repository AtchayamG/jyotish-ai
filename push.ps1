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
fix: admin tier not recognized — reconcile user_tier from is_admin flag

Root cause: admin accounts created before user_tier system have is_admin=true
in Firestore but user_tier="free" (field didn't exist yet). Both layers fixed:

Backend (user_schema.py):
  - Added @model_validator on UserPublic.reconcile_tier()
  - is_admin=True → user_tier overridden to UserTier.admin on every response
  - is_premium=True + free tier → promoted to UserTier.premium
  - No DB migration needed — runs at serialization time on every API call

Flutter (auth_bloc.dart _onCheck):
  - isAdmin flag from SecureStorage now overrides parsed tier immediately
  - Admin users see correct tier on app open without re-login required
  - tier = isAdmin ? UserTier.admin : (parsed from storage)

fix: truly responsive shell — width-based breakpoint replaces kIsWeb platform check

Root cause: kIsWeb is true on mobile browsers, so everyone on a narrow screen
got the sidebar layout → unreadable. Fix: LayoutBuilder + 720px breakpoint.

shell_page.dart rewrite:
  - LayoutBuilder checks constraints.maxWidth, not kIsWeb alone
  - < 720px (mobile app + mobile browser): _MobileShell with bottom nav bar
  - >= 720px AND web: _DesktopShell with sidebar + constrained content area
  - Mobile native app always uses _MobileShell (kIsWeb guard preserved)
  - Sidebar: 220px, brand + animated nav items + live indicator footer
  - Content: Expanded → Center → ConstrainedBox(maxWidth: 860)
  - AnimatedContainer on active sidebar item for smooth 180ms transitions

feat: web responsive layout + AI chat overhaul (intent detection, history, auth)

Build fixes (from previous commit):
  - auth_repository_impl.dart: added missing AuthModel import
  - build.gradle.kts + settings.gradle.kts: added jcenter() for flutter_secure_storage

Web responsive design:
  - shell_page.dart: completely redesigned web layout
    * Replaces 430px phone-shell with proper sidebar + content layout
    * Left sidebar (220px): brand logo, nav items (animated highlight), live indicator
    * Content area: Expanded with ConstrainedBox(maxWidth: 860) for readability
    * Mobile unchanged — bottom nav bar untouched
    * AnimatedContainer on active nav item for smooth transitions

AI Chat — full architecture overhaul:
  Backend (ai_chat_service.py):
  - Added _detect_intent(): 17 intent categories (career, marriage, dasha, lagna,
    nakshatra, rasi, gemstone, remedy, timing, forecast, finance, education,
    travel, child, planets, transit, general)
  - Added _build_focused_context(): strips planet list for simple intents
    (lagna/rasi/nakshatra/timing/gemstone/remedy/forecast) to reduce token count
  - Added _build_system_prompt(): injects FOCUSED instruction per intent,
    no more generic responses for every question
  - Added _RESPONSE_TOKENS: intent-aware max_tokens (300–800 depending on complexity)
  - Added _load_history(): fetches last 10 messages from Firestore chats/{user_id}/messages
  - Added _save_messages(): persists user+AI exchange to Firestore after each response
  - chat() now accepts user_id + birth from authenticated endpoint
  - Falls back to client-sent history if Firestore unavailable

  Backend (astrology.py):
  - /chat endpoint now requires CurrentUser authentication
  - Birth details fetched from user's stored profile (no client upload needed)
  - user_id passed to service for Firestore history persistence

  Flutter (datasources/chat_remote_datasource.dart):
  - Removed user_birth_details from request body (backend fetches from profile)
  - Auth token automatically sent by TokenInterceptor

  Flutter (chat_repository.dart, chat_repository_impl.dart, send_message_usecase.dart):
  - Removed userContext param from all layers

  Flutter (chat_bloc.dart):
  - SendMessage event no longer carries userContext
  - Clean, simplified event/state model

  Flutter (ai_chat_page.dart):
  - Removed _userContext() method
  - _send() simplified to just pass message
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
