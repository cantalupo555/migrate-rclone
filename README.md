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
║  📤 Source:      yandex
║  📥 Destination: gdrive
║  📁 Folders:     13
║  📄 Log:         /home/user/rclone-logs/migration-20251216.log
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

Logs are stored in `~/rclone-logs/`:

```
~/rclone-logs/
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
