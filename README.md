# JiraSummary

A macOS application for tracking team activity across multiple Jira Cloud, Jira Server/Data Center, and Azure DevOps instances. Built for engineering managers who need to see weekly/sprint summaries with ticket activity, sprint velocity, and AI-generated natural language insights.

## Features

- **Multi-System Support** — Connect to Jira Cloud, Jira Server/Data Center, and Azure DevOps simultaneously
- **SSO Authentication** — Embedded WebView SSO (Okta, Azure AD, SAML) with cookie/token capture
- **Team Tracking** — Track individual team members across different systems
- **Sprint Velocity** — Committed vs completed story points with visual charts
- **Activity Timeline** — Status transition history for all tracked tickets
- **AI Summaries** — Local Ollama LLM generates natural language summaries (data never leaves your machine)
- **Glassmorphic Dark Theme** — Modern dashboard aesthetic with animated floating blobs
- **Menu Bar Integration** — Quick access to summary stats from the menu bar
- **Parallel Data Fetch** — Concurrent multi-system fetch using Swift structured concurrency

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later (for building)
- Ollama (optional, for AI summaries)

## Installation

Download the latest DMG from Releases, or build from source:

```bash
# Clone
git clone git@github.com:kochj23/JiraSummary.git
cd JiraSummary

# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build
xcodebuild -project JiraSummary.xcodeproj -scheme JiraSummary -configuration Release build
```

## Usage

1. **Add Systems** — Click "Systems" in the sidebar, then "Add System". Enter your Jira/Azure DevOps URL and authenticate via SSO.
2. **Add People** — Click "People" in the sidebar, search for team members in connected systems, and add them.
3. **View Dashboard** — The dashboard shows summary cards for each tracked person with ticket counts, sprint velocity, and AI-generated insights.
4. **Refresh Data** — Click "Refresh" or configure auto-refresh interval in Settings.

## AI Summaries

JiraSummary uses [Ollama](https://ollama.ai) for local AI summaries. Install Ollama and pull a model:

```bash
brew install ollama
ollama pull llama3
ollama serve
```

Then enable AI summaries in Settings. All data stays local — nothing is sent to external servers.

## Architecture

- **SwiftUI** with NavigationSplitView
- **Swift Structured Concurrency** (async/await, actors, TaskGroup)
- **Observation** framework for reactive state
- **WKWebView** for SSO authentication flows
- **macOS Keychain** for secure credential storage
- **JSON persistence** in Application Support

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

Created by Jordan Koch.
