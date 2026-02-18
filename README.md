# JiraSummary

A macOS application for tracking team activity across multiple Jira Cloud, Jira Server/Data Center, and Azure DevOps instances. Built for engineering managers who need weekly/sprint summaries with ticket activity, sprint velocity, and AI-generated natural language insights.

**Current Version**: v1.0.0

## Features

### Multi-System Support
- Connect to **Jira Cloud**, **Jira Server/Data Center**, and **Azure DevOps** simultaneously
- Per-system user tracking with individual activity aggregation
- Parallel data fetching across all connected systems using Swift structured concurrency

### SSO Authentication
- Embedded WKWebView SSO login (Okta, Azure AD, SAML)
- Automatic cookie/token capture per system type
- Secure credential storage in macOS Keychain
- Non-persistent web data store for clean sessions

### Dashboard & Activity Tracking
- Period-based summaries: daily, weekly, sprint, monthly
- Per-person summary cards with ticket counts, velocity gauges, and AI insights
- Aggregate stats: total tickets, completed, in progress, blocked, average velocity
- Sortable ticket tables with search/filter
- Status transition timeline grouped by day
- Sprint velocity bar charts (committed vs completed points, last 8 sprints)

### AI Summaries — Multi-Backend
- **10 AI backends** with auto-fallback:
  - **Local**: Ollama, MLX, TinyLLM, TinyChat, OpenWebUI
  - **Cloud**: OpenAI, Google Cloud, Azure, AWS, IBM Watson
- Automatic fallback chain: Ollama → OpenAI → TinyChat → TinyLLM → OpenWebUI → MLX
- Configurable generation parameters (temperature, max tokens)
- Per-backend usage statistics and performance metrics
- Cost estimation for cloud backends
- Background health monitoring (60-second interval)
- Connection testing per backend
- Ollama model selection with auto-discovery
- Reusable status menu component showing backend status, model picker, and refresh

### Menu Bar Integration
- Quick-access status item with summary counts (completed, in progress, blocked)
- Last refresh time display
- One-click data refresh
- Open main window shortcut

### Glassmorphic Dark Theme
- Modern design system with animated floating blobs
- Glass cards with blur backgrounds and gradient borders
- Circular progress gauges, status badges, color-coded indicators
- Consistent typography with SF Rounded

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later (for building from source)

### Optional (for AI summaries)

| Backend | Install | Notes |
|---------|---------|-------|
| Ollama | `brew install ollama` | Local LLM server, recommended default |
| MLX | `pip install mlx-lm` | Apple Silicon native inference |
| TinyLLM | Self-hosted | OpenAI-compatible local server |
| TinyChat | Self-hosted | Lightweight chat server |
| OpenWebUI | Self-hosted | Web UI with API |
| OpenAI | API key required | GPT-4o-mini, cloud-based |
| Google Cloud | API key required | Gemini, cloud-based |
| Azure | API key + endpoint | Azure OpenAI, cloud-based |
| AWS | Access key + secret | Bedrock, cloud-based |
| IBM Watson | API key + URL | watsonx, cloud-based |

## Installation

Download the latest DMG from Releases, or build from source:

```bash
git clone git@github.com:kochj23/JiraSummary.git
cd JiraSummary

# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build
xcodebuild -project JiraSummary.xcodeproj -scheme JiraSummary -configuration Release build
```

## Usage

1. **Add Systems** — Click "Systems" in the sidebar, then "Add System". Choose your system type (Jira Cloud, Jira Server, or Azure DevOps), enter the URL, and authenticate via SSO.
2. **Add People** — Click "People" in the sidebar, search for team members in connected systems, and add them. Supports user search by name or manual entry.
3. **View Dashboard** — The dashboard shows summary cards for each tracked person with ticket counts, sprint velocity gauges, and AI-generated insights. Use the period selector (daily/weekly/sprint/monthly) to change the time range.
4. **Drill Down** — Click a person card for full activity detail with three tabs: Tickets (sortable table), Timeline (status transitions), and Sprints (velocity charts).
5. **Refresh Data** — Click "Refresh" in the sidebar or configure auto-refresh interval in Settings (15 min, 30 min, 1 hour, 2 hours, or manual only).

## AI Configuration

### Quick Start with Ollama

```bash
brew install ollama
ollama pull llama3
ollama serve
```

Then enable AI summaries in Settings → AI Backend → Enable AI summaries.

### Multi-Backend Setup

In Settings, configure any combination of backends:

- **Local Backends** — Set server URLs for Ollama, TinyLLM, TinyChat, and OpenWebUI. MLX is auto-detected from `/opt/homebrew/bin/mlx_lm` or `/usr/local/bin/mlx_lm`.
- **Cloud Backends** — Enter API keys for OpenAI, Google Cloud, Azure (key + endpoint), AWS (access key + secret + region), or IBM Watson (key + URL).
- **Generation Parameters** — Adjust temperature (0.0–1.0) and max tokens (50–2000).
- **Connection Test** — Test any backend with a single click.
- **Auto-Fallback** — If the active backend fails, JiraSummary automatically tries the next available backend in priority order.

All API keys are stored locally and never transmitted to third parties. Local backends keep all data on your machine.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Views                  │
│  Dashboard │ Systems │ People │ Activity │ Settings│
├─────────────────────────────────────────────────┤
│               Service Layer (Actors)             │
│  DataFetchCoordinator ← SummaryEngine            │
│  JiraCloudService  JiraServerService  AzDOService │
│  AIBackendManager ← AISummaryService             │
│  SSOAuthService    MenuBarManager                │
├─────────────────────────────────────────────────┤
│               Data Layer                         │
│  DataStore (JSON) │ KeychainService (Credentials)│
├─────────────────────────────────────────────────┤
│               AI Backend Abstraction             │
│  Ollama │ MLX │ TinyLLM │ TinyChat │ OpenWebUI   │
│  OpenAI │ Google │ Azure │ AWS │ IBM Watson       │
└─────────────────────────────────────────────────┘
```

- **SwiftUI** with NavigationSplitView and Swift Charts
- **Swift Structured Concurrency** — async/await, actors, withTaskGroup for parallel fetches
- **Observation** framework — @Observable for reactive state management
- **WKWebView** — SSO authentication with cookie extraction
- **macOS Keychain** — Secure credential storage (WhenUnlockedThisDeviceOnly)
- **JSON persistence** — ~/Library/Application Support/JiraSummary/
- **UserDefaults** — AI backend configuration persistence
- **Zero external dependencies** — All native Apple frameworks

## API Integration

| System | API | Auth | Key Features |
|--------|-----|------|-------------|
| Jira Cloud | REST v3 | Cookie (cloud.session.token) | JQL search, changelogs, sprints, boards, user search |
| Jira Server | REST v2 | Cookie (JSESSIONID) | JQL search, changelogs, sprints, boards, user search |
| Azure DevOps | REST 7.1 | Cookie (FedAuth/AadAuth) | WIQL queries, work item updates, iterations, team members |

## Project Structure

```
JiraSummary/
├── JiraSummary/
│   ├── Design/
│   │   └── ModernDesign.swift          # Glassmorphic design system
│   ├── Models/
│   │   ├── SystemConnection.swift      # System types, auth credentials
│   │   ├── TrackedPerson.swift         # Per-system user tracking
│   │   ├── TicketActivity.swift        # Work items and transitions
│   │   ├── PersonSummary.swift         # Aggregated activity summaries
│   │   ├── SprintData.swift            # Sprint velocity data
│   │   ├── JiraModels.swift            # Jira REST API Codables
│   │   └── AzureDevOpsModels.swift     # Azure DevOps API Codables
│   ├── Services/
│   │   ├── DataStore.swift             # JSON persistence
│   │   ├── DataFetchCoordinator.swift  # Parallel multi-system fetch
│   │   ├── SummaryEngine.swift         # Data aggregation engine
│   │   ├── KeychainService.swift       # macOS Keychain wrapper
│   │   ├── SSOAuthService.swift        # WKWebView SSO auth
│   │   ├── JiraCloudService.swift      # Jira Cloud REST v3 client
│   │   ├── JiraServerService.swift     # Jira Server REST v2 client
│   │   ├── AzureDevOpsService.swift    # Azure DevOps REST 7.1 client
│   │   ├── AIBackendManager.swift      # Multi-backend AI orchestration
│   │   ├── AIBackendManager+Generation.swift  # Text generation + fallback
│   │   ├── AISummaryService.swift      # AI summary generation
│   │   └── MenuBarManager.swift        # Menu bar status item
│   ├── Views/
│   │   ├── ContentView.swift           # NavigationSplitView root
│   │   ├── Sidebar/SidebarView.swift   # Navigation sidebar
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift     # Overview with aggregate stats
│   │   │   └── SummaryCardView.swift   # Per-person summary card
│   │   ├── Systems/
│   │   │   ├── SystemsListView.swift   # Connection management
│   │   │   ├── AddSystemView.swift     # New connection wizard
│   │   │   └── SSOWebView.swift        # SSO login WebView
│   │   ├── People/
│   │   │   ├── PeopleListView.swift    # Team member inventory
│   │   │   ├── AddPersonView.swift     # User search and add
│   │   │   └── PersonDetailView.swift  # Full activity detail
│   │   ├── Activity/
│   │   │   ├── TicketListView.swift    # Sortable ticket table
│   │   │   ├── ActivityTimelineView.swift  # Status transitions
│   │   │   └── SprintVelocityView.swift    # Sprint charts
│   │   └── Settings/
│   │       ├── SettingsView.swift      # Full configuration UI
│   │       └── AIBackendStatusMenu.swift   # Reusable backend status
│   ├── JiraSummaryApp.swift            # App entry point + AppDelegate
│   ├── Info.plist                      # Bundle configuration
│   └── JiraSummary.entitlements        # No sandbox, network client
├── project.yml                         # XcodeGen project spec
├── LICENSE                             # MIT License
└── JiraSummary.xcodeproj/              # Generated Xcode project
```

**1 target** | **28 Swift files** | **Zero external dependencies**

## Security

- **No App Sandbox** — Full file system access for system utility functionality
- **macOS Keychain** — All credentials stored securely with WhenUnlockedThisDeviceOnly access
- **Local AI Default** — Ollama and other local backends keep all data on your machine
- **Cloud API Keys** — Stored in UserDefaults locally, never transmitted to third parties
- **SSO Authentication** — No passwords stored; uses session cookies/tokens with natural expiry
- **Network Client** — Outbound connections only, no server component
- **Hardened Runtime** — Enabled for distribution builds

## Troubleshooting

### "Authentication failed" or SSO not working
- Verify your system URL is correct (include `https://`)
- For Jira Cloud: use `https://yourcompany.atlassian.net`
- For Azure DevOps: use `https://dev.azure.com/yourorg`
- Try re-authenticating — session cookies expire naturally

### No data appearing after refresh
- Check that tracked people have the correct user IDs for each system
- Jira Cloud uses `accountId`, Jira Server uses `username`, Azure DevOps uses email
- Verify your session has access to the relevant projects/boards

### AI summaries not generating
- Check Settings → AI Backend for backend availability (green dots)
- For Ollama: ensure `ollama serve` is running and a model is pulled
- Use the "Test Connection" button to verify backend connectivity
- Check that AI summaries are enabled (toggle in Settings)

## Building from Source

### Requirements
- Xcode 16.0+
- XcodeGen (`brew install xcodegen`) — only needed to regenerate the project

### Build Steps

```bash
cd JiraSummary
xcodegen generate
open JiraSummary.xcodeproj
```

Select the JiraSummary scheme and build for "My Mac".

To regenerate after adding/removing files:

```bash
xcodegen generate
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Created by Jordan Koch.
