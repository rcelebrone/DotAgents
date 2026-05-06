# Implementation Plan - Unified Root Memories

The goal is to move the `memorys/` directory to the project root and ensure it is shared across all tool installations (Gemini, Claude, Cursor, Antigravity). This makes the project memory tool-agnostic and persistent.

## Proposed Changes

### 1. Update Source Markdown Files
Replace all occurrences of `{{AGENTS_ROOT}}/memorys/` with `memorys/` in the following directories:
- `agents/`
- `commands/`
- `skills/`
- `memorys/`

This ensures that when agents or skills are running, they look for the memory files at the project root regardless of which tool is being used.

### 2. Update Installer Scripts
Modify `instalador-gemini-cli.sh`, `instalador-claude.sh`, `instalador-cursor.sh`, and `instalador-antigravity.sh`:
- **Location Change**: Change the installation target for memories from `$TARGET_DIR/memorys/` to `./memorys/` (relative to where the script is run, typically the project root).
- **Protection Logic**: Add a check to only copy files to `memorys/` if they don't already exist, or simply ensure the directory is created at the root.
- **Cleanup**: Remove the creation of tool-specific memory directories (e.g., `$GEMINI_DIR/memorys`).
- **Placeholder Replacement**: Skip the `sed` replacement of `{{AGENTS_ROOT}}` for files in the root `memorys/` directory to keep them tool-agnostic.

### 3. Verification Plan
- **File Content Check**: Verify that `{{AGENTS_ROOT}}/memorys/` has been removed from source files.
- **Installer Logic Check**: Review the updated shell scripts to ensure they target the root `memorys/` directory.
- **Manual Verification (Simulated)**:
    - Run the installer in a dummy project and verify `memorys/` is created at the root.
    - Verify tool-specific folders (e.g., `.gemini/`) do NOT contain a `memorys/` folder.
    - Verify agents in tool-specific folders point to `memorys/` at the root.

## Phased Implementation Plan

### Phase 1: Batch Reference Update
- Use a sub-agent or batch `sed` to update all markdown files.
- Manually verify a few key files (e.g., `agents/architect.md`, `commands/manager.md`).

### Phase 2: Installer Script Refactoring
- Update each of the 4 installer scripts.
- Ensure the logic for `memorys/` is consistent across all of them.

### Phase 3: Final Review
- Review the entire codebase for any remaining hardcoded tool-specific memory paths.
- Update `README.md` if any documentation still points to the old structure.

## Rollback Plan
- Revert the `sed` changes in the markdown files.
- Restore the original installer scripts from git history.
