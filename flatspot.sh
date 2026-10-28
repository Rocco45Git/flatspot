#!/usr/bin/env bash

# ==============================================================================
# FlatSpot CLI - The Independent Package Manager for Linux
# ==============================================================================

# Directory structure
FLATSPOT_DIR="$HOME/.local/share/flatspot"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$FLATSPOT_DIR/apps"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure local directories exist
mkdir -p "$APPS_DIR"
mkdir -p "$BIN_DIR"

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "${BLUE}[FlatSpot Notice]${NC} Adding $BIN_DIR to PATH recommended."
fi

show_help() {
    echo -e "${GREEN}FlatSpot CLI Manager${NC}"
    echo "Usage: flatspot <command> [argument]"
    echo ""
    echo "Commands:"
    echo "  install <url/file>   Install a .flatpak bundle or .sh script"
    echo "  remove <app-name>    Remove an installed FlatSpot package"
    echo "  list                 List all locally installed FlatSpot packages"
    echo "  version              Show FlatSpot CLI version"
    echo "  help                 Show this help menu"
}

install_pkg() {
    TARGET="$1"

    if [ -z "$TARGET" ]; then
        echo -e "${RED}Error:${NC} Please specify a URL or local file path to install."
        exit 1
    fi

    # Case 1: Local .flatpak file
    if [[ "$TARGET" == *.flatpak ]] && [ -f "$TARGET" ]; then
        echo -e "${BLUE}Installing Flatpak bundle:${NC} $TARGET"
        flatpak install --user -y "$TARGET"
        echo -e "${GREEN}Successfully installed $(basename "$TARGET")!${NC}"
        exit 0
    fi

    # Case 2: Remote URL (.flatpak or .sh)
    if [[ "$TARGET" == http* ]]; then
        FILENAME=$(basename "$TARGET")
        TEMP_FILE="$APPS_DIR/$FILENAME"
        
        echo -e "${BLUE}Downloading $FILENAME from FlatSpot...${NC}"
        curl -sL "$TARGET" -o "$TEMP_FILE"

        if [ ! -s "$TEMP_FILE" ]; then
            echo -e "${RED}Error:${NC} Failed to download file from $TARGET"
            rm -f "$TEMP_FILE"
            exit 1
        fi

        if [[ "$FILENAME" == *.flatpak ]]; then
            echo -e "${BLUE}Installing Flatpak bundle...${NC}"
            flatpak install --user -y "$TEMP_FILE"
            rm -f "$TEMP_FILE"
            echo -e "${GREEN}Successfully installed $FILENAME!${NC}"
        elif [[ "$FILENAME" == *.sh ]]; then
            APP_NAME="${FILENAME%.sh}"
            chmod +x "$TEMP_FILE"
            ln -sf "$TEMP_FILE" "$BIN_DIR/$APP_NAME"
            echo -e "${GREEN}Successfully installed $APP_NAME to $BIN_DIR/$APP_NAME!${NC}"
        fi
        exit 0
    fi

    echo -e "${RED}Error:${NC} Unsupported file or invalid link. Provide a valid .flatpak or .sh target."
}

remove_pkg() {
    APP="$1"
    if [ -z "$APP" ]; then
        echo -e "${RED}Error:${NC} Please specify the package name to remove."
        exit 1
    fi

    # Check Flatpak system/user apps
    if flatpak list --app | grep -q "$APP"; then
        echo -e "${BLUE}Removing Flatpak package $APP...${NC}"
        flatpak uninstall -y "$APP"
    fi

    # Check local scripts
    if [ -f "$APPS_DIR/$APP.sh" ]; then
        rm -f "$APPS_DIR/$APP.sh"
        rm -f "$BIN_DIR/$APP"
        echo -e "${GREEN}Removed local script $APP.${NC}"
    fi
}

list_pkgs() {
    echo -e "${GREEN}Installed FlatSpot Scripts & Tools:${NC}"
    ls -1 "$APPS_DIR" 2>/dev/null || echo "No custom scripts installed."
    echo ""
    echo -e "${GREEN}Installed User Flatpaks:${NC}"
    flatpak list --user --app
}

case "$1" in
    "install"|"i")
        install_pkg "$2"
        ;;
    "remove"|"u"|"uninstall")
        remove_pkg "$2"
        ;;
    "list"|"ls")
        list_pkgs
        ;;
    "version"|"-v")
        echo "FlatSpot CLI v1.0.0"
        ;;
    *)
        show_help
        ;;
esac
