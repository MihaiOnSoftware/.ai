# Example: Presenting a Chunk

```
## Chunk 1: Add validation for user input

**Purpose**: Ensure user input is sanitized before processing
**Files affected**:
- lib/user_input.rb
- test/user_input_test.rb

### Changes:

diff --git a/lib/user_input.rb b/lib/user_input.rb
--- a/lib/user_input.rb
+++ b/lib/user_input.rb
@@ -10,5 +10,12 @@ class UserInput
   def process(input)
     return nil if input.nil?
+    return nil if input.empty?
+
+    sanitized = input.strip
+    sanitized = sanitized.gsub(/[<>]/, '')
+
+    sanitized
   end
 end

diff --git a/test/user_input_test.rb b/test/user_input_test.rb
--- a/test/user_input_test.rb
+++ b/test/user_input_test.rb
@@ -15,4 +15,14 @@ class UserInputTest < Minitest::Test
     assert_nil result
   end
+
+  def test_strips_whitespace
+    result = UserInput.new.process("  hello  ")
+    assert_equal "hello", result
+  end
+
+  def test_removes_html_brackets
+    result = UserInput.new.process("<script>alert('xss')</script>")
+    assert_equal "scriptalert('xss')/script", result
+  end
 end

### Context:

This follows the validation pattern used throughout the codebase - sanitize
at the boundary before processing.

Ready for your feedback on this chunk:
- Type "approve" or "next" to continue
- Ask questions about the changes
- Request modifications
- Type "skip" to move to next chunk without approval
```
