# qe - Quick Entry

Capture thoughts to the right destination with minimal friction. Explicit routing when you know where it goes, safe fallback when you don't.

## Installation

### From source

```bash
swift build -c release
cp .build/release/QuickEntry /usr/local/bin/qe
```

### Requirements

- macOS 13+
- [GitHub CLI](https://cli.github.com/) (`gh`) - for GitHub issues
- OmniFocus - for task capture
- Obsidian - for note capture

## Usage

```bash
qe <text>                      # Fallback → OmniFocus inbox
qe of <text>                   # OmniFocus inbox
qe gh <text>                   # GitHub issue (current repo)
qe gh <repo> <text>            # GitHub issue (specific repo)
qe ob <text>                   # Obsidian inbox
```

### Examples

```bash
# Quick capture to OmniFocus (default)
qe remember to call the dentist

# Explicit OmniFocus
qe of buy groceries

# GitHub issue in current repo
cd ~/Developer/myproject
qe gh fix the login bug

# GitHub issue in different repo
qe gh neodeck add dark mode support

# Override repo even when in a git directory
qe gh --repo other-project fix something

# Obsidian note
qe ob interesting idea about productivity
```

### Multiline Input

Use shell quoting for multiline content:

```bash
qe of $'Call dentist\nAsk about scheduling\nBring insurance card'

qe gh $'Bug in login flow\nSteps to reproduce:\n1. Click login\n2. Enter credentials\n3. See error'
```

The first line becomes the title/task name, remaining lines become the body/notes.

### URL Handling

URLs are automatically extracted and handled per destination:

```bash
# OmniFocus: URL added to task notes
qe of check out https://example.com/article

# GitHub: URL added to issue body
qe gh review this https://github.com/org/repo/pull/123

# Obsidian: URL formatted as markdown link [example](https://example.com)
qe ob interesting read https://example.com/article
```

## Destinations

### OmniFocus (`qe of`)

Creates a task in OmniFocus inbox using Omni Automation.

- Single line → task name
- Multiline → first line is name, rest is note
- URL → appended to note

Returns: `omnifocus:///task/<id>`

### GitHub (`qe gh`)

Creates a GitHub issue using the `gh` CLI.

**Repo detection:**
1. If in a git repo with GitHub remote → uses that repo
2. If `--repo <name>` specified → uses that repo
3. Otherwise → first argument is repo name

Repo names can be short (`neodeck`) or full (`owner/neodeck`). Short names are resolved from your GitHub repo list (cached locally).

Returns: GitHub issue URL

### Obsidian (`qe ob`)

Creates a timestamped note in your vault's Inbox folder.

**Sync-safe design:** Instead of appending to the daily note (which can cause sync conflicts), each entry creates its own file in `Inbox/YYYY-MM-DD-HHMMSS.md`. This avoids conflicts when Obsidian isn't running or hasn't synced.

Returns: `obsidian://open?vault=<vault>&file=Inbox/<filename>`

### Fallback

Any text without a recognized subcommand routes to OmniFocus:

```bash
qe random thought I need to capture
# Same as: qe of random thought I need to capture
```

## Configuration

Create `~/.config/qe/config.toml`:

```toml
[obsidian]
vault = "Notes"                                    # Vault name
vault_path = "~/Documents/Obsidian/Notes"          # Optional: override path
inbox_folder = "Inbox"                             # Folder for quick entries

[github]
default_owner = "jrjones"                          # Prefer repos from this owner
```

Default vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/<vault>`

## Project Structure

```
Sources/QuickEntry/
├── QuickEntry.swift              # Main command, fallback routing
├── Commands/
│   ├── GitHubCommand.swift       # qe gh - GitHub issues
│   ├── OmniFocusCommand.swift    # qe of - OmniFocus tasks
│   └── ObsidianCommand.swift     # qe ob - Obsidian notes
├── Services/
│   ├── GitHubService.swift       # GitHub API via gh CLI, repo caching
│   ├── OmniFocusService.swift    # Omni Automation via osascript
│   └── ObsidianService.swift     # File operations, URL formatting
├── Models/
│   ├── ParsedInput.swift         # Parsed text: title, body, URL
│   └── Config.swift              # TOML configuration loading
└── Utilities/
    ├── InputParser.swift         # URL extraction, multiline parsing
    └── Shell.swift               # Process execution, git helpers
```

## Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI parsing
- [TOMLKit](https://github.com/LebJe/TOMLKit) - Configuration file parsing

## License

MIT
