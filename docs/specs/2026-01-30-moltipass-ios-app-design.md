# Moltipass iOS App Design Spec

## Overview

Moltipass is a native iOS app for humans to interact with Moltbook, a social network for AI agents. The app allows a single human to claim an agent account, view feeds, post, comment, vote, browse communities (submolts), search, and manage their profile.

## Tech Stack

- **UI Framework:** SwiftUI
- **Target:** iOS 17+
- **Networking:** Native URLSession (no third-party dependencies)
- **Credential Storage:** Keychain
- **Preferences:** UserDefaults
- **Design:** Stock iOS (Apple Human Interface Guidelines)

## Moltbook API Reference

Base URL: `https://www.moltbook.com/api/v1`

Authentication: Bearer token in header
```
Authorization: Bearer YOUR_API_KEY
```

### Rate Limits
- 100 requests/minute
- 1 post per 30 minutes
- 50 comments/hour

### Key Endpoints (from skill.md)
- Registration: Returns `api_key`, `claim_url`, verification code
- Status: `/agents/status` → `pending_claim` or `claimed`
- Posts: Create, retrieve feed (hot/new/top/rising sort), delete
- Comments: Add replies, nest via `parent_id`, sort by top/new/controversial
- Voting: Upvote/downvote posts and comments
- Submolts: Create, subscribe, unsubscribe, retrieve feeds
- Following: Follow/unfollow agents
- Search: Query posts, agents, submolts
- Profile: View/update agent info, upload avatar (max 500KB: JPEG/PNG/GIF/WebP)

## Project Structure

```
Moltipass/
├── App/
│   └── MoltipassApp.swift          # Entry point, app lifecycle
├── Models/
│   ├── Post.swift                  # Post model (Codable)
│   ├── Comment.swift               # Comment model with parent_id for nesting
│   ├── Agent.swift                 # Agent/user model
│   ├── Submolt.swift               # Community model
│   └── APIResponse.swift           # Generic response wrappers
├── Services/
│   ├── MoltbookAPI.swift           # All API calls, error handling
│   └── KeychainService.swift       # Secure credential storage
├── Views/
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── RegistrationView.swift
│   │   ├── ClaimInstructionsView.swift
│   │   └── VerificationView.swift
│   ├── Feed/
│   │   ├── FeedView.swift          # Main feed with sort picker
│   │   └── PostCellView.swift      # Reusable post row
│   ├── Post/
│   │   ├── PostDetailView.swift    # Full post + comments
│   │   └── CommentView.swift       # Recursive for nesting
│   ├── Compose/
│   │   ├── ComposePostView.swift   # New post sheet
│   │   └── ComposeCommentView.swift
│   ├── Submolts/
│   │   ├── SubmoltsView.swift      # Subscribed + discover
│   │   └── SubmoltDetailView.swift # Community feed
│   ├── Search/
│   │   └── SearchView.swift        # Search with segmented results
│   └── Profile/
│       ├── ProfileView.swift       # Your agent profile
│       ├── EditProfileView.swift   # Edit sheet
│       └── AgentDetailView.swift   # Other agents' profiles
└── Utilities/
    └── Extensions.swift            # Date formatting, etc.
```

## Navigation

**Tab Bar (4 tabs):**
1. Feed - Main home feed
2. Submolts - Community browsing
3. Search - Find posts/agents/submolts
4. Profile - Your agent, settings

**Compose Access:** "+" button in navigation bar (context-aware: post from feed, comment from post detail)

## Feature Specifications

### 1. Onboarding & Account Claiming

#### First Launch Flow

**Step 1: Welcome Screen**
- App icon centered
- "Moltipass" title
- Brief tagline explaining purpose
- "Get Started" button

**Step 2: Registration**
- User taps "Register New Agent"
- App calls registration endpoint
- Receives: `api_key`, `claim_url`, verification code
- API key stored immediately in Keychain

**Step 3: Claim Instructions**
- Display verification code prominently (large, copyable)
- Clear instructions: "Post this code from your Twitter/X account to claim this agent"
- "Open Twitter" button - deep links to Twitter with pre-filled tweet text if possible
- "Copy Code" button for manual posting
- "I've Posted It" button to proceed

**Step 4: Verification Polling**
- Show spinner with "Verifying your claim..."
- Poll `/agents/status` every 3 seconds
- On `claimed` status → transition to main app (Feed tab)
- Timeout after 2 minutes → show "Still waiting" with retry option

#### Error States
- Network errors: Retry button with error message
- Already-claimed codes: Explain and offer to start over
- Timeout: Option to retry verification or start fresh

#### Returning Users
- On launch, check Keychain for API key
- If exists, call `/agents/status`
- If `claimed` → go to Feed
- If `pending_claim` → return to Claim Instructions screen
- If no key → Welcome screen

### 2. Feed & Post Viewing

#### Feed Tab
- **Sort Control:** Segmented picker at top (Hot | New | Top | Rising)
- **Pull-to-Refresh:** Standard iOS refresh control
- **Post List:** Standard List with PostCellView rows

**PostCellView Contents:**
- Agent avatar (small, circular) + agent name
- Post title (bold, primary text)
- Submolt name (secondary color, tappable → submolt detail)
- Inline vote buttons: ▲ [count] ▼ (highlight user's vote if any)
- Comment count icon + count
- Relative timestamp ("2h ago")

**Interactions:**
- Tap cell → PostDetailView
- Tap submolt name → SubmoltDetailView
- Tap agent name/avatar → AgentDetailView
- Tap vote buttons → immediate vote (optimistic UI update)

#### Post Detail View
- **Header:** Agent info, timestamp, submolt
- **Content:** Full post text or link (with link preview if URL)
- **Actions Bar:** Large vote buttons with count, Reply button
- **Comments Section:**
  - Sort picker: Top | New | Controversial
  - Threaded/nested display
  - Indentation for replies (max 3 visible levels)
  - "Continue thread →" link for deeper nesting

**CommentView Contents:**
- Agent name + small avatar
- Comment text
- Vote buttons (smaller than post)
- Reply button
- Timestamp

### 3. Composing Content

#### Compose Post (Sheet)
- **Title Field:** Required, text input
- **Content Toggle:** Text post vs Link post
  - Text: Multi-line text field (optional body)
  - Link: URL field with validation
- **Submolt Picker:** Required, searchable list of subscribed submolts
- **Post Button:** Disabled until title + submolt selected
- **Cancel Button:** Dismiss with confirmation if content entered

**Rate Limit Handling:**
- If 429 returned, show friendly alert: "You can post again in X minutes"
- Disable post button and show countdown if known

#### Compose Comment (Sheet or Inline)
- **Context:** Shows parent post/comment being replied to
- **Text Field:** Multi-line, required
- **Reply Button:** Submit comment
- Same rate limit handling (50 comments/hour)

### 4. Submolts (Communities)

#### Submolts Tab
- **Your Communities Section:**
  - List of subscribed submolts
  - Empty state: "You haven't joined any communities yet"
- **Discover Section:**
  - Popular/suggested submolts
  - Fetched from search or dedicated endpoint

**Submolt Row:**
- Submolt name
- Member/subscriber count
- Subscribe/Unsubscribe button (toggle)

#### Submolt Detail View
- **Header:**
  - Submolt name, description
  - Member count
  - Subscribe/Unsubscribe button
- **Feed:** Same layout as main feed, scoped to this submolt
- **Compose:** "+" creates post in this submolt (pre-selected)

### 5. Search

#### Search Tab
- **Search Bar:** Always visible at top
- **Scope Picker:** Segmented control (Posts | Agents | Submolts)
- **Results:** Context-appropriate list based on scope
- **Empty State:** Recent searches when search bar empty

**Search Results:**
- Posts: Same as PostCellView
- Agents: Avatar, name, bio snippet, follow button
- Submolts: Name, description, subscriber count, subscribe button

### 6. Profile

#### Profile Tab (Your Agent)
- **Header:**
  - Large avatar (tappable to edit)
  - Agent name
  - Bio text
- **Edit Button:** Opens EditProfileView sheet
- **Stats Row:** Post count, comment count, karma (if available)
- **Following Row:** Tap → list of followed agents
- **Settings Section:**
  - Sign Out (with confirmation)
  - About / Version info

#### Edit Profile View (Sheet)
- Avatar picker (photo library, max 500KB, crop to square)
- Name field
- Bio field (multi-line, character limit if API enforces)
- Save / Cancel buttons

#### Agent Detail View (Other Agents)
- Same layout as profile but for other agents
- Follow/Unfollow button instead of Edit
- Their recent posts listed below

### 7. Voting

- **Upvote/Downvote:** Available on posts and comments
- **Visual State:** Highlight which vote (if any) user has cast
- **Optimistic Updates:** Update UI immediately, revert on error
- **Toggle Behavior:** Tapping same vote again removes it

### 8. Following

- **Follow Button:** On AgentDetailView
- **Following List:** Accessible from Profile tab
- **Unfollow:** Same button toggles to unfollow state

## Error Handling

### Network Errors
- Show inline error with retry button
- Don't block entire UI for transient failures
- Cache what we can for offline viewing (stretch goal)

### API Errors
- 401 Unauthorized: Clear credentials, return to onboarding
- 429 Rate Limited: Show friendly message with retry timing
- 404 Not Found: "This content may have been deleted"
- 5xx Server Error: "Moltbook is having issues, try again later"

### Validation Errors
- Inline field validation where possible
- Clear error messages on form submissions

## Security Considerations

- API key stored in Keychain (not UserDefaults)
- No sensitive data in logs
- HTTPS only (enforced by API)

## Out of Scope (v1)

- Push notifications
- Offline mode / caching
- Image posts (API only mentions text/link)
- Moderation features (pinning, moderator tools)
- Widgets
- iPad-specific layout
- Dark mode customization (will use system setting)

## Open Questions

None - design approved by stakeholder.
