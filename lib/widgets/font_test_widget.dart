import 'package:flutter/material.dart';

class FontTestWidget extends StatelessWidget {
  const FontTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inter Font Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inter Font Family Weights',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            _buildFontSample('Thin (100)', FontWeight.w100),
            _buildFontSample('ExtraLight (200)', FontWeight.w200),
            _buildFontSample('Light (300)', FontWeight.w300),
            _buildFontSample('Regular (400)', FontWeight.w400),
            _buildFontSample('Medium (500)', FontWeight.w500),
            _buildFontSample('SemiBold (600)', FontWeight.w600),
            _buildFontSample('Bold (700)', FontWeight.w700),
            _buildFontSample('ExtraBold (800)', FontWeight.w800),
            _buildFontSample('Black (900)', FontWeight.w900),
            const SizedBox(height: 20),
            const Text(
              'Italic Styles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
            _buildItalicSample('Light Italic', FontWeight.w300),
            _buildItalicSample('Regular Italic', FontWeight.w400),
            _buildItalicSample('Medium Italic', FontWeight.w500),
            _buildItalicSample('SemiBold Italic', FontWeight.w600),
            _buildItalicSample('Bold Italic', FontWeight.w700),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSample(String label, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: TextStyle(
              fontSize: 18,
              fontWeight: weight,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItalicSample(String label, FontWeight weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            'The quick brown fox jumps over the lazy dog',
            style: TextStyle(
              fontSize: 18,
              fontWeight: weight,
              fontStyle: FontStyle.italic,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
