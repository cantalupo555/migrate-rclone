#!/bin/bash

# ============================================================================
# RCLONE MIGRATION TOOL
# ============================================================================
# Generic tool for migrating between any rclone remotes.
# Automatically detects configured remotes and allows interactive
# selection of source and destination.
#
# Usage: ./migrate-rclone.sh [--dry-run] [--skip-check]
#
# Options:
#   --dry-run     Simulate migration without transferring files
#   --skip-check  Skip integrity verification
# ============================================================================

set -euo pipefail

# ==================== COLORS ====================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==================== CONFIGURATION ====================

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_DIR="$HOME/rclone-logs"
LOG_FILE="$LOG_DIR/migration-$TIMESTAMP.log"
CHECK_LOG="$LOG_DIR/verification-$TIMESTAMP.log"
TRANSFERS=5
CHECKERS=8
RETRIES=3
RETRIES_SLEEP="10s"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Folders to EXCLUDE from migration (optional)
EXCLUDE=(
    # "FolderToExclude"
)

# ==================== FUNCTIONS ====================

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    RCLONE MIGRATION TOOL                     ║"
    echo "║               Cloud Storage Migration Utility                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_separator() {
    echo -e "${BLUE}──────────────────────────────────────────────────────────────────${NC}"
}

# ==================== ARGUMENTS ====================

DRY_RUN=""
SKIP_CHECK=""

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN="--dry-run"
            ;;
        --skip-check)
            SKIP_CHECK="true"
            ;;
        --help|-h)
            echo "Usage: ./migrate-rclone.sh [--dry-run] [--skip-check]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Simulate migration without transferring files"
            echo "  --skip-check  Skip integrity verification"
            echo "  --help, -h    Show this help message"
            exit 0
            ;;
    esac
done

# ==================== CHECKS ====================

print_header

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo -e "${RED}❌ Error: rclone is not installed.${NC}"
    echo ""
    echo "   Install rclone:"
    echo "   • Linux/macOS/WSL: sudo -v ; curl https://rclone.org/install.sh | sudo bash"
    echo "   • Other platforms:     https://rclone.org/downloads/"
    exit 1
fi

echo -e "${GREEN}✓ rclone found${NC}"
echo ""

# ==================== DETECT REMOTES ====================

echo -e "${YELLOW}🔍 Detecting configured remotes...${NC}"
echo ""

# List all remotes (remove trailing ":")
mapfile -t ALL_REMOTES < <(rclone listremotes | sed 's/:$//')

TOTAL_REMOTES=${#ALL_REMOTES[@]}

if [ "$TOTAL_REMOTES" -eq 0 ]; then
    echo -e "${RED}❌ No remotes configured in rclone.${NC}"
    echo "   Configure with: rclone config"
    exit 1
elif [ "$TOTAL_REMOTES" -eq 1 ]; then
    echo -e "${RED}❌ Only 1 remote configured: ${BOLD}${ALL_REMOTES[0]}${NC}"
    echo ""
    echo -e "${YELLOW}To perform migration, you need at least 2 remotes.${NC}"
    echo "   Configure another remote with: rclone config"
    exit 1
fi

echo -e "${GREEN}✓ Found $TOTAL_REMOTES remotes:${NC}"
echo ""

# Show list of remotes with info
for i in "${!ALL_REMOTES[@]}"; do
    remote="${ALL_REMOTES[$i]}"
    # Get remote type
    type=$(rclone config show "$remote" 2>/dev/null | grep "^type" | cut -d'=' -f2 | tr -d ' ' || echo "unknown")
    echo -e "  ${BOLD}$((i+1)).${NC} ${CYAN}$remote${NC} (${type})"
done

echo ""
print_separator

# ==================== SOURCE SELECTION ====================

echo ""
echo -e "${BOLD}📤 SELECT SOURCE (copy from):${NC}"
echo ""

while true; do
    read -rp "Enter source remote number (1-$TOTAL_REMOTES): " source_num
    
    if [[ "$source_num" =~ ^[0-9]+$ ]] && [ "$source_num" -ge 1 ] && [ "$source_num" -le "$TOTAL_REMOTES" ]; then
        SOURCE="${ALL_REMOTES[$((source_num-1))]}"
        echo -e "${GREEN}✓ Source selected: ${BOLD}$SOURCE${NC}"
        break
    else
        echo -e "${RED}Invalid number. Please try again.${NC}"
    fi
done

echo ""
print_separator

# ==================== DESTINATION SELECTION ====================

echo ""
echo -e "${BOLD}📥 SELECT DESTINATION (copy to):${NC}"
echo ""

# Show available remotes (excluding source)
echo "Available remotes:"
for i in "${!ALL_REMOTES[@]}"; do
    remote="${ALL_REMOTES[$i]}"
    if [ "$remote" != "$SOURCE" ]; then
        type=$(rclone config show "$remote" 2>/dev/null | grep "^type" | cut -d'=' -f2 | tr -d ' ' || echo "unknown")
        echo -e "  ${BOLD}$((i+1)).${NC} ${CYAN}$remote${NC} (${type})"
    fi
done
echo ""

while true; do
    read -rp "Enter destination remote number (1-$TOTAL_REMOTES): " dest_num
    
    if [[ "$dest_num" =~ ^[0-9]+$ ]] && [ "$dest_num" -ge 1 ] && [ "$dest_num" -le "$TOTAL_REMOTES" ]; then
        DESTINATION="${ALL_REMOTES[$((dest_num-1))]}"
        
        if [ "$DESTINATION" == "$SOURCE" ]; then
            echo -e "${RED}❌ Destination cannot be the same as source. Please try again.${NC}"
        else
            echo -e "${GREEN}✓ Destination selected: ${BOLD}$DESTINATION${NC}"
            break
        fi
    else
        echo -e "${RED}Invalid number. Please try again.${NC}"
    fi
done

echo ""
print_separator

# ==================== TRANSFER SETTINGS ====================

echo ""
echo -e "${BOLD}⚙️  TRANSFER SETTINGS:${NC}"
echo ""
read -rp "Simultaneous transfers (default: $TRANSFERS): " custom_transfers

if [[ -n "$custom_transfers" ]]; then
    if [[ "$custom_transfers" =~ ^[0-9]+$ ]] && [ "$custom_transfers" -ge 1 ] && [ "$custom_transfers" -le 32 ]; then
        TRANSFERS="$custom_transfers"
        echo -e "${GREEN}✓ Transfers set to: ${BOLD}$TRANSFERS${NC}"
    else
        echo -e "${YELLOW}⚠️  Invalid value. Using default: $TRANSFERS${NC}"
    fi
else
    echo -e "${GREEN}✓ Using default: ${BOLD}$TRANSFERS${NC}"
fi

echo ""
print_separator

# ==================== DISCOVER FOLDERS ====================

echo ""
echo -e "${YELLOW}🔍 Detecting folders in ${BOLD}$SOURCE${NC}${YELLOW}...${NC}"
echo ""

# List all folders in source remote root
mapfile -t all_folders < <(rclone lsd "$SOURCE:" 2>/dev/null | awk '{print $NF}')

if [ ${#all_folders[@]} -eq 0 ]; then
    echo -e "${RED}❌ No folders found in $SOURCE.${NC}"
    exit 1
fi

# Filter excluded folders
folders=()
for folder in "${all_folders[@]}"; do
    excluded=false
    for exc in "${EXCLUDE[@]}"; do
        if [[ "$folder" == "$exc" ]]; then
            excluded=true
            break
        fi
    done
    if [[ "$excluded" == false ]]; then
        folders+=("$folder")
    fi
done

# ==================== CONFIRMATION ====================

echo -e "${GREEN}✓ Found ${#folders[@]} folders to migrate${NC}"
echo ""

if [[ -n "$DRY_RUN" ]]; then
    echo -e "${YELLOW}⚠️  DRY-RUN MODE: No files will be transferred${NC}"
fi

if [[ -n "$SKIP_CHECK" ]]; then
    echo -e "${YELLOW}⚠️  Integrity verification disabled${NC}"
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    MIGRATION SUMMARY                         ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║${NC}  📤 Source:      ${CYAN}$SOURCE${NC}                                      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  📥 Destination: ${CYAN}$DESTINATION${NC}                                      ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  📁 Folders:     ${#folders[@]}                                           ${BOLD}║${NC}"
echo -e "${BOLD}║${NC}  📄 Log:         (see below)                                 ${BOLD}║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Folders to migrate:"
for f in "${folders[@]}"; do
    echo -e "  ${BLUE}•${NC} $f"
done
echo ""

read -rp "Do you want to continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${YELLOW}Operation cancelled by user.${NC}"
    exit 0
fi

echo ""
print_separator

# ==================== MIGRATION ====================

# Counters
copy_success=0
copy_error=0
check_success=0
check_error=0
declare -a folders_with_errors=()

total=${#folders[@]}
current=0

echo ""
echo -e "${BOLD}🚀 Starting migration: $SOURCE → $DESTINATION${NC}"
echo ""

for folder in "${folders[@]}"; do
    ((current++)) || true
    echo -e "${BOLD}[$current/$total]${NC} 📁 Folder: ${CYAN}$folder${NC}"
    print_separator
    
    # Step 1: Copy
    echo -e "  ${YELLOW}📤 Copying...${NC}"
    rclone copy "$SOURCE:$folder" "$DESTINATION:$folder" \
        --progress \
        --transfers "$TRANSFERS" \
        --retries "$RETRIES" \
        --retries-sleep "$RETRIES_SLEEP" \
        --low-level-retries 10 \
        --log-file "$LOG_FILE" \
        --log-level INFO \
        $DRY_RUN || true
    
    copy_status=$?
    
    if [ $copy_status -eq 0 ]; then
        echo -e "  ${GREEN}✓ Copy completed!${NC}"
        ((copy_success++)) || true
        
        # Step 2: Integrity Verification
        if [[ -z "$DRY_RUN" ]] && [[ -z "$SKIP_CHECK" ]]; then
            echo -e "  ${YELLOW}🔍 Verifying integrity...${NC}"
            rclone check "$SOURCE:$folder" "$DESTINATION:$folder" \
                --checkers "$CHECKERS" \
                --log-file "$CHECK_LOG" \
                --log-level INFO \
                2>&1 | tail -5 || true
            
            check_status=$?
            
            if [ $check_status -eq 0 ]; then
                echo -e "  ${GREEN}✓ Integrity OK!${NC}"
                ((check_success++)) || true
            else
                echo -e "  ${YELLOW}⚠️  Differences found (check $CHECK_LOG)${NC}"
                ((check_error++)) || true
                folders_with_errors+=("$folder (verification)")
            fi
        fi
    else
        echo -e "  ${RED}✗ Copy error (check $LOG_FILE)${NC}"
        ((copy_error++)) || true
        folders_with_errors+=("$folder (copy)")
    fi
    echo ""
done

# ==================== FINAL REPORT ====================

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                      📊 FINAL REPORT                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}Migration:${NC} $SOURCE → $DESTINATION"
echo ""
echo -e "  ${BOLD}Copy:${NC}"
echo -e "    ${GREEN}✓ Success:${NC} $copy_success/$total"
echo -e "    ${RED}✗ Error:${NC}   $copy_error/$total"
echo ""

if [[ -z "$DRY_RUN" ]] && [[ -z "$SKIP_CHECK" ]]; then
    echo -e "  ${BOLD}Integrity Verification:${NC}"
    echo -e "    ${GREEN}✓ OK:${NC}               $check_success/$total"
    echo -e "    ${YELLOW}⚠️  With differences:${NC} $check_error/$total"
    echo ""
fi

if [ ${#folders_with_errors[@]} -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  Folders with issues:${NC}"
    for f in "${folders_with_errors[@]}"; do
        echo -e "      ${RED}•${NC} $f"
    done
    echo ""
fi

echo -e "  ${BOLD}📄 Logs saved to:${NC}"
echo "      $LOG_FILE"
if [[ -z "$DRY_RUN" ]] && [[ -z "$SKIP_CHECK" ]]; then
    echo "      $CHECK_LOG"
fi
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   ✅ MIGRATION COMPLETED!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
