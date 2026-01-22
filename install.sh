#!/bin/bash
set -e

echo "Installing Ralph..."

# Create a temporary directory
TMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Download and extract to temp dir
# We strip components=1 because github archive puts everything in a root folder like ralph-main
curl -sL "https://github.com/jckw/ralph/archive/main.tar.gz" | tar xz -C "$TMP_DIR" --strip-components=1

# Copy ralph directory
echo "Copying ralph core files..."
cp -R "$TMP_DIR/ralph" .

# Copy .claude/skills directory
# We merge into existing .claude if it exists
echo "Copying skills..."
mkdir -p .claude/skills
if [ -d "$TMP_DIR/.claude/skills" ]; then
    # copy contents of skills to .claude/skills
    cp -R "$TMP_DIR/.claude/skills/" .claude/skills/
fi

# Make run script executable
chmod +x ralph/run.sh

echo "Ralph installed successfully!"
echo "Run ./ralph/run.sh to start."
