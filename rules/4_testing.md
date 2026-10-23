## Testing methodology

1. Tests should be specific and test one behavior at a time
2. Run tests to confirm they fail (this validates the test is actually testing something)
	- temporarily mutating production code to see a failure is allowed, revert the change after
3. Tests should almost never include branching - we control inputs
4. Focus on the interface and expected behavior, not implementation details
	- Test through public interfaces, not private methods directly
	- Private methods are implementation details - they should be tested indirectly through public method tests
	- If a private method is complex enough to need its own test, that's a code smell - extract it to a separate class instead
	- Never make a method public just to test it
5. Test each behavior at the level it lives, and don't duplicate it across levels
	- Test a shared function directly, once. Don't rely on route A's integration test to prove behavior on route B, and don't claim coverage from a higher-level test - that reverses the pyramid
	- Integration tests prove wiring and real side-effects (data round-trips, the real schema is hit), not the call chain. They don't replay a case matrix already covered by unit tests
	- When unit and integration cover the same thing, lean unit - same purpose, lower maintenance
	- How much wiring coverage to keep is a judgment call (cost to write/read/run, how cleanly it tests), not a fixed number

