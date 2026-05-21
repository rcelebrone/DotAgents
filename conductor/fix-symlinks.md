# Update Installer Scripts to Use Symlinks

## Objective
Update the installation scripts to create symbolic links for their main orchestrator files in the root directory, instead of creating independent file copies. This ensures updates to the manager command file are automatically reflected in the main orchestrator file.

## Key Files & Context
- `instalador-gemini-cli.sh`
- `instalador-claude.sh`
- `instalador-antigravity.sh`
- `instalador-cursor.sh`

## Implementation Steps

1. **Modify `instalador-gemini-cli.sh`**:
   Replace the step 5 code block:
   ```bash
   # 5. Set up GEMINI.md (Main Manager)
   if [ -f "$COMMANDS_SRC/manager.md" ]; then
       echo "🔗 Linking manager to GEMINI.md..."
       copy_and_replace "$COMMANDS_SRC/manager.md" "GEMINI.md"
       echo "  ✅ GEMINI.md created from manager.md"
   fi
   ```
   With:
   ```bash
   # 5. Set up GEMINI.md (Main Manager)
   if [ -f "$GEMINI_DIR/commands/manager.md" ]; then
       echo "🔗 Linking manager to GEMINI.md..."
       ln -sf "$GEMINI_DIR/commands/manager.md" "GEMINI.md"
       echo "  ✅ GEMINI.md linked to $GEMINI_DIR/commands/manager.md"
   fi
   ```

2. **Modify `instalador-claude.sh`**:
   Replace the step 5 code block:
   ```bash
   # 5. Set up CLAUDE.md (Main Manager)
   if [ -f "$COMMANDS_SRC/manager.md" ]; then
       echo "🔗 Linking manager to CLAUDE.md..."
       copy_and_replace "$COMMANDS_SRC/manager.md" "CLAUDE.md"
       echo "  ✅ CLAUDE.md created from manager.md"
   fi
   ```
   With:
   ```bash
   # 5. Set up CLAUDE.md (Main Manager)
   if [ -f "$TARGET_DIR/commands/manager.md" ]; then
       echo "🔗 Linking manager to CLAUDE.md..."
       ln -sf "$TARGET_DIR/commands/manager.md" "CLAUDE.md"
       echo "  ✅ CLAUDE.md linked to $TARGET_DIR/commands/manager.md"
   fi
   ```

3. **Modify `instalador-antigravity.sh`**:
   Replace the step 5 code block:
   ```bash
   # 5. Set up AG.md (Main Manager)
   if [ -f "$COMMANDS_SRC/manager.md" ]; then
       echo "🔗 Linking manager to AG.md..."
       copy_and_replace "$COMMANDS_SRC/manager.md" "AG.md"
       echo "  ✅ AG.md created from manager.md"
   fi
   ```
   With:
   ```bash
   # 5. Set up AG.md (Main Manager)
   if [ -f "$TARGET_DIR/commands/manager.md" ]; then
       echo "🔗 Linking manager to AG.md..."
       ln -sf "$TARGET_DIR/commands/manager.md" "AG.md"
       echo "  ✅ AG.md linked to $TARGET_DIR/commands/manager.md"
   fi
   ```

4. **Modify `instalador-cursor.sh`**:
   Add a new step 4:
   ```bash
   # 4. Set up CURSOR.md (Main Manager Link for documentation)
   if [ -f "$RULES_DIR/manager.mdc" ]; then
       echo "🔗 Linking manager to CURSOR.md (for documentation)..."
       ln -sf "$RULES_DIR/manager.mdc" "CURSOR.md"
       echo "  ✅ CURSOR.md linked to $RULES_DIR/manager.mdc"
   fi
   ```

5. **Modify `instalador-antigravity-cli.sh`**:
   Ensure it follows the same symlink pattern for `AGY.md`:
   ```bash
   # 5. Set up AGY.md (Main Manager)
   if [ -f "$TARGET_DIR/commands/manager.md" ]; then
       echo "🔗 Linking manager to AGY.md..."
       ln -sf "$TARGET_DIR/commands/manager.md" "AGY.md"
       echo "  ✅ AGY.md linked to $TARGET_DIR/commands/manager.md"
   fi
   ```

## Verification & Testing
- Run `./instalador-gemini-cli.sh` and verify that `GEMINI.md` is correctly symlinked to `.gemini/commands/manager.md`.
- Run `./instalador-claude.sh` and verify that `CLAUDE.md` is correctly symlinked to `.claude/commands/manager.md`.
- Run `./instalador-antigravity.sh` and verify that `AG.md` is correctly symlinked to `.agents/commands/manager.md`.
- Run `./instalador-cursor.sh` and verify that `CURSOR.md` is correctly symlinked to `.cursor/rules/manager.mdc`.
