# migrate-rclone

A generic command-line tool for migrating data between any cloud storage services configured in rclone.

First, get the script and make it executable:

```bash
wget https://raw.githubusercontent.com/cantalupo555/migrate-rclone/master/migrate-rclone.sh
chmod +x migrate-rclone.sh
```

Then run it:

```bash
./migrate-rclone.sh
```

## Features

- 🔍 **Auto-detection** - Automatically detects all configured rclone remotes
- ✅ **Validation** - Ensures at least 2 remotes are available before proceeding
- 🎯 **Interactive selection** - Choose source and destination interactively
- 🔄 **Integrity verification** - Verifies copied files using `rclone check`
- 🔁 **Retry mechanism** - Automatic retries on network failures
- 📊 **Progress tracking** - Real-time progress with colorful output
- 📝 **Detailed logging** - Separate logs for copy and verification operations
- 🚫 **Exclusion list** - Easily exclude specific folders from migration

## Requirements

- [rclone](https://rclone.org/) installed and configured with at least 2 remotes
- Bash 4.0 or later

### Installing rclone

**Linux / macOS / Windows (WSL):**
```bash
sudo -v ; curl https://rclone.org/install.sh | sudo bash
```

**Windows (native):**
```powershell
# Via Scoop
scoop install rclone

# Or via Chocolatey
choco install rclone

# Or download from: https://rclone.org/downloads/
```

## Compatibility

| Operating System | x86_64 | ARM64 | Notes |
|------------------|--------|-------|-------|
| Linux            | ✅     | ✅    | Native support |
| macOS            | ✅     | ✅    | Requires Bash 4+ (`brew install bash`) |
| Windows (WSL)    | ✅     | ✅    | Via Windows Subsystem for Linux |

## Platform Notes

**macOS:** Ships with Bash 3.2, but this script requires Bash 4+ for `mapfile`. Install with `brew install bash` and run:
```bash
$(brew --prefix)/bin/bash migrate-rclone.sh
```

**Windows:** Use [WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/install). Windows files are accessible via `/mnt/c/`.

## Usage

```bash
# Interactive migration with integrity check
./migrate-rclone.sh

# Simulate migration without transferring files (dry-run)
./migrate-rclone.sh --dry-run

# Skip integrity verification (faster)
./migrate-rclone.sh --skip-check

# Combine options
./migrate-rclone.sh --dry-run --skip-check

# Show help
./migrate-rclone.sh --help
```

## Screenshot

```
╔══════════════════════════════════════════════════════════════╗
║                    RCLONE MIGRATION TOOL                     ║
║               Cloud Storage Migration Utility                ║
╚══════════════════════════════════════════════════════════════╝

✓ rclone found

🔍 Detecting configured remotes...

✓ Found 3 remotes:

  1. gdrive (drive)
  2. yandex (yandex)
  3. protondrive (protondrive)

──────────────────────────────────────────────────────────────────

📤 SELECT SOURCE (copy from):

Enter source remote number (1-3): 2
✓ Source selected: yandex

──────────────────────────────────────────────────────────────────

📥 SELECT DESTINATION (copy to):

Enter destination remote number (1-3): 1
✓ Destination selected: gdrive

╔══════════════════════════════════════════════════════════════╗
║                    MIGRATION SUMMARY                         ║
╠══════════════════════════════════════════════════════════════╣
║  📤 Source:      yandex                                      ║
║  📥 Destination: gdrive                                      ║
║  📁 Folders:     13                                          ║
║  📄 Log:         /home/user/migrate-rclone-logs/migration-20251216.log║
╚══════════════════════════════════════════════════════════════╝

Do you want to continue? (y/N): y

🚀 Starting migration: yandex → gdrive
```

## Configuration

### Exclusion List

Edit the script to exclude specific folders from migration:

```bash
# Folders to EXCLUDE from migration (optional)
EXCLUDE=(
    "FolderToExclude"
    "AnotherFolder"
)
```

### Transfer Settings

Adjust these variables in the script to tune performance:

```bash
TRANSFERS=4          # Number of parallel file transfers
CHECKERS=8           # Number of parallel integrity checkers
RETRIES=3            # Number of retry attempts on failure
RETRIES_SLEEP="10s"  # Wait time between retries
```

## Logs

Logs are stored in `~/migrate-rclone-logs/`:

```
~/migrate-rclone-logs/
├── migration-20251216-103000.log      # Copy operation log
├── verification-20251216-103000.log   # Integrity verification log
└── ...
```

## Supported Cloud Services

This tool works with any cloud storage service supported by rclone, including:

- Google Drive
- Dropbox
- OneDrive
- Amazon S3
- Yandex Disk
- Proton Drive
- Backblaze B2
- SFTP/FTP
- And [many more](https://rclone.org/overview/)

## Feedback

Any suggestions are welcome: [Click here](https://github.com/cantalupo555/migrate-rclone/issues/new)

## A problem?

Please fill a report [here](https://github.com/cantalupo555/migrate-rclone/issues/new)

## License

MIT License - See [LICENSE](LICENSE) for details.
