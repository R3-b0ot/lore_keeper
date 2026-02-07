// ignore_for_file: avoid_print
import 'package:lore_keeper/utils/text_utils.dart';

void main() {
  print('Starting word count tests...');

  void check(String input, int expected) {
    int result = TextUtils.countWords(input);
    if (result != expected) {
      print('FAIL: "$input" -> got $result, expected $expected');
    } else {
      print('PASS: "$input" -> $result');
    }
  }

  check('', 0);
  check('Hello', 1);
  check('Hello world', 2);
  check('Hello   world', 2);
  check('Hello, world!', 2);
  check('Hello\nworld', 2);
  check('The quick brown fox jumps over the lazy dog.', 9);
  check('Hello world 123', 3);

  // Check typical typing scenario
  check('H', 1);
  check('He', 1);
  check('Hel', 1);
  check('Hell', 1);
  check('Hello ', 1);
  check('Hello w', 2);
  check('Hello wo', 2);
}
