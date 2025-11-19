#### Refactor and Clean Up

Apply ALL of the following rules during cleanup:

**Test Quality Rules:**

1. **No Test Branching** - Tests should almost never include branching since we control inputs
2. **Richer Assertions** - Tests should favor richer assertions over many simple assertions
3. **Remove Duplicate Tests** - Remove tests that test the same thing or don't test anything
4. **Controlled Inputs** - We control test inputs, so tests should be deterministic

**Code Quality Rules:**
5. **Defensive Programming** - Only when interacting with external systems, only once per case
6. **Reduce Duplication** - Reduce duplication during cleanup (both tests and production code)
7. **Trim Dead Code** - Remove unused code, variables, imports, and functionality
8. **Replace Comments** - Either remove comments or replace them with appropriately named methods/functions
9. **Single Line Methods** - Only create methods/functions for single line actions if it cannot be easily inferred what that line does or the line is used more than once

**Final Cleanup:**
10. **Run Linter** - At the end of the cleanup we should run the linter and fix all violations
11. **Remove Debug Files** - Cleanup includes removing temporary debug files
12. **Clean Formatting** - Ensure clean code formatting and consistent style
13. **Verify All Tests Pass** - Confirm all tests still pass after cleanup
