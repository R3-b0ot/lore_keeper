// Test file to verify word counting functionality
import 'package:lore_keeper/utils/text_utils.dart';

void main() {
  // Test TextUtils.countWords with various inputs
  // All test cases should pass: empty, single word, multiple words, spaces, punctuation, unicode, HTML

  // Test 1: Empty string
  assert(TextUtils.countWords('') == 0);

  // Test 2: Single word
  assert(TextUtils.countWords('Hello') == 1);

  // Test 3: Two words with space
  assert(TextUtils.countWords('Hello world') == 2);

  // Test 4: Multiple spaces
  assert(TextUtils.countWords('Hello   world') == 2);

  // Test 5: Leading/trailing spaces
  assert(TextUtils.countWords('  Hello   world  ') == 2);

  // Test 6: With punctuation
  assert(TextUtils.countWords('One, two, three.') == 3);

  // Test 7: Unicode characters
  assert(TextUtils.countWords('Unicode: 你好世界') == 3);

  // Test 8: HTML tags
  assert(TextUtils.countWords('HTML <b>bold</b> text') == 2);

  // Test 9: Multiple consecutive spaces
  assert(TextUtils.countWords('Multiple   spaces    between words') == 4);
}
