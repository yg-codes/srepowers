---
name: playground-tutorial
description: Use when learning SREPowers for the first time or wanting to practice the Test-Driven Operation workflow safely without risking actual infrastructure
---

# SREPowers Playground Tutorial

## Overview

Learn SREPowers concepts safely using local file operations. No infrastructure required, no risk of breaking production.

**Core principle:** Learn by doing - practice TDO with harmless local operations.

**Announce at start:** "I'm using the playground-tutorial skill to learn SREPowers safely."

## When to Use

**For:**
- First-time SREPowers users
- Learning Test-Driven Operation workflow
- Understanding verification concepts
- Practicing before real infrastructure work
- Team training sessions

**Not for:**
- Real infrastructure operations (use `test-driven-operation`)
- Production changes

## Tutorial Overview

This tutorial walks through a complete TDO cycle using local files:

1. **RED** - Create a failing verification
2. **Verify RED** - Watch it fail
3. **GREEN** - Create the file
4. **Verify GREEN** - Watch it pass
5. **REFACTOR** - Improve the file

## Prerequisites

```bash
# Verify you have a safe workspace
echo "Tutorial workspace: $HOME/.srepowers-playground"
mkdir -p "$HOME/.srepowers-playground"
cd "$HOME/.srepowers-playground"
```

## Tutorial Steps

### Step 1: Setup (RED Phase)

**Goal:** Create a verification that will fail (because the file doesn't exist yet).

```bash
# Define what we want to create
TARGET_FILE="$HOME/.srepowers-playground/hello.txt"
EXPECTED_CONTENT="Hello, SREPowers!"

# RED: Write the verification command
echo "=== RED: Verification Command ==="
echo "Command: cat $TARGET_FILE"
echo "Expected: $EXPECTED_CONTENT"
echo "Actual:"
cat "$TARGET_FILE" 2>&1 || echo "Error: File does not exist"
```

**Expected Result:** Error - file does not exist.

**This is GOOD!** We've written a verification that correctly fails because the feature (the file) doesn't exist yet.

### Step 2: Verify RED

Confirm the verification fails correctly:

```bash
# Run the verification and capture output
if cat "$TARGET_FILE" 2>/dev/null | grep -q "$EXPECTED_CONTENT"; then
    echo "❌ Verification passed unexpectedly - file already exists!"
    exit 1
else
    echo "✅ Verification failed as expected - file doesn't exist"
fi
```

**Key Learning:** We must see the verification fail to know it tests the right thing.

### Step 3: Execute Operation (GREEN Phase)

Now create the minimal file to pass verification:

```bash
# GREEN: Create the file with expected content
echo "$EXPECTED_CONTENT" > "$TARGET_FILE"

echo "✅ Created: $TARGET_FILE"
echo "Content:"
cat "$TARGET_FILE"
```

### Step 4: Verify GREEN

Run the same verification and watch it pass:

```bash
# Verify GREEN: Same command should now pass
echo "=== Verify GREEN ==="
if cat "$TARGET_FILE" 2>/dev/null | grep -q "$EXPECTED_CONTENT"; then
    echo "✅ Verification passed - file exists with correct content"
else
    echo "❌ Verification failed - something went wrong"
    exit 1
fi
```

**Key Learning:** The same verification that failed before now passes.

### Step 5: Document (REFACTOR Phase)

Add metadata to the file:

```bash
# REFACTOR: Add documentation
cat > "$TARGET_FILE" <<EOF
# SREPowers Tutorial Output
# Created: $(date -Iseconds)
# Tutorial: playground-tutorial

$EXPECTED_CONTENT

This file was created using Test-Driven Operation:
1. RED: Verified file didn't exist
2. GREEN: Created the file
3. Verified: Confirmed file exists with correct content
4. REFACTOR: Added this documentation
EOF

echo "✅ Enhanced file with documentation"
```

### Step 6: Extended Verification

Add additional verifications:

```bash
# Verify file has documentation
if grep -q "Test-Driven Operation" "$TARGET_FILE"; then
    echo "✅ File contains documentation"
else
    echo "❌ File missing documentation"
    exit 1
fi

# Verify file is readable
if [ -r "$TARGET_FILE" ]; then
    echo "✅ File is readable"
else
    echo "❌ File not readable"
    exit 1
fi

echo ""
echo "=== Final File Contents ==="
cat "$TARGET_FILE"
```

## Practice Exercises

### Exercise 1: Directory Verification

Practice TDO with directories:

```bash
# RED: Verify directory doesn't exist
DIR="$HOME/.srepowers-playground/myapp"
ls "$DIR" 2>&1 || echo "Expected: Directory doesn't exist"

# GREEN: Create directory
mkdir -p "$DIR/config"

# Verify GREEN
ls "$DIR/config"
```

### Exercise 2: Configuration File

Practice with a config file:

```bash
CONFIG="$HOME/.srepowers-playground/config/app.conf"

# RED
cat "$CONFIG" 2>&1 || echo "Expected: Config doesn't exist"

# GREEN
mkdir -p "$(dirname "$CONFIG")"
cat > "$CONFIG" <<EOF
# Application Configuration
version=1.0.0
environment=tutorial
EOF

# Verify GREEN
cat "$CONFIG"
```

### Exercise 3: Multi-step Operation

Chain multiple verifications:

```bash
# Define targets
FILES=("file1.txt" "file2.txt" "file3.txt")

# RED: Verify none exist
for f in "${FILES[@]}"; do
    ls "$HOME/.srepowers-playground/$f" 2>&1 || true
done

# GREEN: Create all
for f in "${FILES[@]}"; do
    echo "Content of $f" > "$HOME/.srepowers-playground/$f"
done

# Verify GREEN: Count files
COUNT=$(ls "$HOME/.srepowers-playground"/*.txt 2>/dev/null | wc -l)
echo "Created $COUNT files"
```

## Key Concepts Demonstrated

| Concept | Tutorial Example | Real Infrastructure |
|---------|-----------------|---------------------|
| RED | `cat file.txt` fails | `kubectl get pod` returns "not found" |
| GREEN | `echo "content" > file.txt` | `kubectl apply -f deployment.yaml` |
| Verify | `cat file.txt` shows content | `kubectl get pod` shows "Running" |
| REFACTOR | Add comments to file | Document in runbook |

## SRE Principles in Practice

### Safety First
- **Tutorial:** Uses `$HOME/.srepowers-playground` - completely isolated
- **Real:** Always use dry-run before actual execution

### Structured Output
- **Tutorial:** Clear step-by-step with verification results
- **Real:** Command/Expected/Result format in runbooks

### Evidence-Driven
- **Tutorial:** Shows actual file contents
- **Real:** Shows actual kubectl/API output

### Audit-Ready
- **Tutorial:** File contains timestamp and documentation
- **Real:** Git commits with change tickets

### Communication
- **Tutorial:** Explains each step clearly
- **Real:** Business impact in stakeholder updates

## Common Mistakes (and How to Avoid Them)

### Mistake 1: Skipping RED Verification

**❌ Wrong:**
```bash
# Create file first
echo "content" > file.txt

# Then write verification
cat file.txt  # Passes immediately - proves nothing!
```

**✅ Correct:**
```bash
# Write verification first
cat file.txt  # Fails - good!

# Then create file
echo "content" > file.txt

# Verify it passes
cat file.txt  # Passes - proves verification works!
```

### Mistake 2: Verification Too Broad

**❌ Wrong:**
```bash
# Verification that always passes
ls "$HOME/.srepowers-playground"  # Passes even if file doesn't exist
```

**✅ Correct:**
```bash
# Specific verification
cat "$HOME/.srepowers-playground/hello.txt" | grep "Hello, SREPowers!"
```

### Mistake 3: Not Cleaning Up

**After tutorial:**
```bash
# Clean up playground
cd "$HOME"
rm -rf "$HOME/.srepowers-playground"
echo "Tutorial workspace cleaned up"
```

## Next Steps

After completing this tutorial:

1. **Practice more:** Try the exercises above
2. **Real TDO:** Use `test-driven-operation` for actual infrastructure
3. **Plan operations:** Use `writing-operation-plans` for complex changes
4. **Learn subagents:** Use `subagent-driven-operation` for multi-task operations

## Integration

**Pairs with:**
- `test-driven-operation` - Real infrastructure TDO
- `writing-operation-plans` - Create operation plans
- `brainstorming-operations` - Design operations

**Before using:**
- No prerequisites - this is the starting point!

## Quick Reference

| Command | Purpose |
|---------|---------|
| `mkdir -p` | Create directory (safe if exists) |
| `cat > file` | Create/overwrite file |
| `cat file` | Read file (verification) |
| `grep "text" file` | Verify content exists |
| `ls path` | Verify path exists |
| `wc -l` | Count lines/files |

---

**Remember:** This tutorial is completely safe. The playground directory is isolated in your home directory and only affects files you create there. Practice freely!
