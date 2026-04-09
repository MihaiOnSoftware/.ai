# Example Session

**Starting state**:
- Modified: `bin/cache_helper.rb` (added schema hash calculation)
- Modified: `test/cache_helper_test.rb` (added tests for schema hash)
- Untracked: None

**Command actions**:
1. Reads commit rules and writing style rules
2. Runs `git status` → sees 2 modified files
3. Runs `git diff HEAD` → sees schema hash code added
4. Runs `git log -3 --online` → sees recent commit style
5. Stages all changes: `git add -A`
6. Drafts message: "Add schema hash to cache keys"
7. Creates commit with proper format
8. Posts confirmation

**Output**:
```
✅ Commit created: a1b2c3d4 Add schema hash to cache keys
```
