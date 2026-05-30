#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROJO="rojo"
BUILD_DIR="./build"
SYNC_DIR="$(pwd)/sync/ServerScriptService/Clanning terminal"
TEMP_DIR=$(mktemp -d)

trap "rm -rf $TEMP_DIR" EXIT

mkdir -p "$BUILD_DIR"

# Clean old files from previous naming scheme
rm -f "$BUILD_DIR"/* 2>/dev/null

echo -e "${BLUE}=== ClanningTerminal RBXM Builder (Rojo) ===${NC}\n"

# Prompt for version
read -p "Enter version (e.g., 1.0.0): " VERSION
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi
VERSION_SUFFIX=" v$VERSION"

echo ""

build_rbxm() {
    local component_type=$1
    local component_name=$2
    local source_path=$3
    local output_file="$BUILD_DIR/$component_name.rbxm"

    echo -e "${BLUE}Building $component_type: $component_name${NC}"

    # Create temporary Rojo project directory
    local project_dir="$TEMP_DIR/$component_name"
    mkdir -p "$project_dir"

    # Create Rojo project file with absolute paths
    cat > "$project_dir/default.project.json" << EOF
{
	"name": "$component_name",
	"tree": {
		"\$path": "$source_path"
	}
}
EOF

    # Build with Rojo
    if $ROJO build "$project_dir/default.project.json" -o "$output_file" 2>&1; then
        local size=$(du -h "$output_file" | cut -f1)
        echo -e "${GREEN}✓ Generated $component_name.rbxm ($size)${NC}\n"
    else
        echo -e "${YELLOW}✗ Failed to generate $component_name.rbxm${NC}\n"
        return 1
    fi
}

# Build Core Terminal
build_rbxm "Core" "Core$VERSION_SUFFIX" "$SYNC_DIR/Main"

# Build Full
echo -e "${BLUE}Building Full...${NC}"
build_rbxm "Full" "Full$VERSION_SUFFIX" "$SYNC_DIR"
echo ""

# Build Addons
echo -e "${BLUE}Building Addons...${NC}"
for addon_dir in "$SYNC_DIR/Addons"/Addon-*/; do
    [ -d "$addon_dir" ] || continue
    addon_full_name=$(basename "$addon_dir")
    # Extract addon name after the prefix (e.g., "Addon-Default-Black and gold ui" -> "Black and gold ui")
    addon_display_name=$(echo "$addon_full_name" | sed 's/^Addon-[^-]*-//')
    addon_output_name="Addon - $addon_display_name"
    build_rbxm "Addon" "$addon_output_name" "$addon_dir"
done
echo ""

# Build Terminals
echo -e "${BLUE}Building Terminals...${NC}"
for terminal_dir in "$SYNC_DIR/Terminals"/Terminal-*/; do
    [ -d "$terminal_dir" ] || continue
    terminal_full_name=$(basename "$terminal_dir")
    # Extract terminal name (e.g., "Terminal-Default" -> "Default")
    terminal_display_name=$(echo "$terminal_full_name" | sed 's/^Terminal-//')
    terminal_output_name="Terminal - $terminal_display_name"
    build_rbxm "Terminal" "$terminal_output_name" "$terminal_dir"
done

echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "Output: ${BLUE}$BUILD_DIR/${NC}\n"

if ls "$BUILD_DIR"/*v*.rbxm 1> /dev/null 2>&1; then
    echo -e "${YELLOW}Generated RBXM files:${NC}"
    ls -lh "$BUILD_DIR"/*v*.rbxm 2>/dev/null | while read -r line; do
        file=$(echo "$line" | awk '{print $NF}')
        size=$(echo "$line" | awk '{print $5}')
        echo "  $(basename "$file") ($size)"
    done
else
    echo -e "${YELLOW}No RBXM files generated${NC}"
fi
