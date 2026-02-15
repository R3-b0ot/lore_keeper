import 'dart:io';

import 'package:xml/xml.dart';

class SvgStyleInlinerResult {
  final String svg;
  final bool updated;
  final List<String> warnings;

  const SvgStyleInlinerResult({
    required this.svg,
    required this.updated,
    required this.warnings,
  });
}

class SvgStyleInliner {
  /// Inlines styles from <style> blocks and linked CSS files into SVG elements.
  /// This enables SVG renderers that only support inline styles.
  static SvgStyleInlinerResult inlineSvg(
    String svgContent, {
    String? baseDirectory,
  }) {
    final warnings = <String>[];
    XmlDocument document;
    try {
      document = XmlDocument.parse(svgContent);
    } catch (_) {
      return SvgStyleInlinerResult(
        svg: svgContent,
        updated: false,
        warnings: const ['Failed to parse SVG.'],
      );
    }

    final cssBuffer = StringBuffer();
    final styles = document.findAllElements('style').toList();
    for (final style in styles) {
      cssBuffer.writeln(style.innerText);
      style.parent?.children.remove(style);
    }

    final links = document.findAllElements('link').toList();
    for (final link in links) {
      final rel = link.getAttribute('rel')?.toLowerCase();
      if (rel != 'stylesheet') continue;
      final href = link.getAttribute('href');
      if (href == null || href.isEmpty) continue;
      final css = _readCssFile(href, baseDirectory);
      if (css == null) {
        warnings.add('Missing CSS file: $href');
        continue;
      }
      cssBuffer.writeln(css);
      link.parent?.children.remove(link);
    }

    final cssText = cssBuffer.toString();
    if (cssText.trim().isEmpty) {
      return SvgStyleInlinerResult(
        svg: document.toXmlString(pretty: false),
        updated: styles.isNotEmpty || links.isNotEmpty,
        warnings: warnings,
      );
    }

    final rules = _parseCssRules(cssText, warnings);
    if (rules.isEmpty) {
      return SvgStyleInlinerResult(
        svg: document.toXmlString(pretty: false),
        updated: true,
        warnings: warnings,
      );
    }

    for (final element in document.descendants.whereType<XmlElement>()) {
      final styleMap = <String, String>{};
      for (final rule in rules) {
        if (_matchesAnySelector(element, rule.selectors)) {
          styleMap.addAll(rule.declarations);
        }
      }

      final inlineStyle = element.getAttribute('style');
      if (inlineStyle != null) {
        styleMap.addAll(_parseDeclarations(inlineStyle));
      }

      if (styleMap.isNotEmpty) {
        element.setAttribute('style', _serializeDeclarations(styleMap));
      }
    }

    return SvgStyleInlinerResult(
      svg: document.toXmlString(pretty: false),
      updated: true,
      warnings: warnings,
    );
  }

  /// Reads an SVG file, inlines CSS, and writes a new SVG file.
  static Future<String> inlineFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return filePath;
    final svg = await file.readAsString();
    final result = inlineSvg(svg, baseDirectory: file.parent.path);
    if (!result.updated) return filePath;

    final inlinePath = filePath.replaceFirst(
      RegExp(r'\.svg$', caseSensitive: false),
      '_inline.svg',
    );

    final inlineFile = File(inlinePath);
    await inlineFile.writeAsString(result.svg);
    return inlinePath;
  }

  static String? _readCssFile(String href, String? baseDirectory) {
    final normalized = href.replaceAll('\\', '/');
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:')) {
      return null;
    }
    if (baseDirectory == null) return null;
    final resolved = File('$baseDirectory${Platform.pathSeparator}$href');
    if (!resolved.existsSync()) return null;
    return resolved.readAsStringSync();
  }

  static List<_CssRule> _parseCssRules(String css, List<String> warnings) {
    final cleaned = _stripCssComments(
      css,
    ).replaceAll(RegExp(r'@import[^;]+;'), '').trim();
    if (cleaned.isEmpty) return [];

    final rules = <_CssRule>[];
    final matches = RegExp(r'([^{}]+)\{([^{}]+)\}').allMatches(cleaned);
    for (final match in matches) {
      final selectorText = match.group(1);
      final declarationText = match.group(2);
      if (selectorText == null || declarationText == null) continue;
      final selectors = <_ParsedSelector>[];
      for (final rawSelector in selectorText.split(',')) {
        final trimmed = rawSelector.trim();
        if (trimmed.isEmpty) continue;
        final parsed = _parseSelector(trimmed, warnings);
        if (parsed != null) {
          selectors.add(parsed);
        }
      }
      if (selectors.isEmpty) continue;
      final declarations = _parseDeclarations(declarationText);
      if (declarations.isEmpty) continue;
      rules.add(_CssRule(selectors, declarations));
    }
    return rules;
  }

  static String _stripCssComments(String css) {
    return css.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  }

  static Map<String, String> _parseDeclarations(String raw) {
    final declarations = <String, String>{};
    for (final part in raw.split(';')) {
      final split = part.split(':');
      if (split.length < 2) continue;
      final property = split.first.trim();
      final value = split.sublist(1).join(':').trim();
      if (property.isEmpty || value.isEmpty) continue;
      declarations[property] = value;
    }
    return declarations;
  }

  static String _serializeDeclarations(Map<String, String> styleMap) {
    return styleMap.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('; ');
  }

  static bool _matchesAnySelector(
    XmlElement element,
    List<_ParsedSelector> selectors,
  ) {
    for (final selector in selectors) {
      if (_matchesSelector(element, selector)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesSelector(XmlElement element, _ParsedSelector selector) {
    if (selector.segments.isEmpty) return false;

    var current = element;
    final last = selector.segments.last;
    if (!_matchesSimpleSelector(current, last.selector)) {
      return false;
    }

    for (var i = selector.segments.length - 2; i >= 0; i--) {
      final segment = selector.segments[i];
      if (segment.combinator == _SelectorCombinator.child) {
        final parent = current.parent;
        if (parent is! XmlElement) return false;
        if (!_matchesSimpleSelector(parent, segment.selector)) {
          return false;
        }
        current = parent;
      } else {
        var parent = current.parent;
        var found = false;
        while (parent != null) {
          if (parent is XmlElement &&
              _matchesSimpleSelector(parent, segment.selector)) {
            current = parent;
            found = true;
            break;
          }
          parent = parent.parent;
        }
        if (!found) return false;
      }
    }

    return true;
  }

  static _ParsedSelector? _parseSelector(
    String selector,
    List<String> warnings,
  ) {
    if (selector.contains('+') || selector.contains('~')) {
      warnings.add('Unsupported selector combinator in: $selector');
      return null;
    }

    final normalized = selector.replaceAll('>', ' > ');
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    final segments = <_SelectorSegment>[];
    var nextCombinator = _SelectorCombinator.descendant;
    for (final token in tokens) {
      if (token == '>') {
        nextCombinator = _SelectorCombinator.child;
        continue;
      }

      final simple = _parseSimpleSelector(token, warnings);
      if (simple == null) {
        warnings.add('Unsupported selector: $selector');
        return null;
      }
      final combinator = segments.isEmpty
          ? _SelectorCombinator.none
          : nextCombinator;
      segments.add(_SelectorSegment(combinator, simple));
      nextCombinator = _SelectorCombinator.descendant;
    }

    return _ParsedSelector(segments);
  }

  static _SimpleSelector? _parseSimpleSelector(
    String token,
    List<String> warnings,
  ) {
    if (token.contains(':')) {
      warnings.add('Unsupported pseudo-selector in: $token');
      return null;
    }

    final attributes = <_AttributeSelector>[];
    var working = token;
    final attrMatches = RegExp(r'\[([^\]]+)\]').allMatches(token);
    for (final match in attrMatches) {
      final raw = match.group(1);
      if (raw == null || raw.trim().isEmpty) continue;
      final parts = raw.split('=');
      final name = parts.first.trim();
      String? value;
      if (parts.length > 1) {
        value = parts.sublist(1).join('=').trim();
        value = value.replaceAll('"', '').replaceAll("'", '');
      }
      attributes.add(_AttributeSelector(name, value));
    }
    working = working.replaceAll(RegExp(r'\[[^\]]+\]'), '');

    String? tag;
    var rest = working;
    if (!rest.startsWith('.') && !rest.startsWith('#')) {
      final match = RegExp(r'^([a-zA-Z0-9:_*-]+)').firstMatch(rest);
      if (match != null) {
        tag = match.group(1);
        rest = rest.substring(match.group(1)!.length);
      }
    }

    String? id;
    final classes = <String>[];
    final matcher = RegExp(r'([.#])([a-zA-Z0-9:_-]+)').allMatches(rest);
    for (final match in matcher) {
      final prefix = match.group(1);
      final value = match.group(2);
      if (prefix == '#' && value != null) {
        id = value;
      } else if (prefix == '.' && value != null) {
        classes.add(value);
      }
    }

    if (tag == null && id == null && classes.isEmpty && attributes.isEmpty) {
      return null;
    }

    return _SimpleSelector(
      tag: tag == '*' ? null : tag,
      id: id,
      classes: classes,
      attributes: attributes,
    );
  }

  static bool _matchesSimpleSelector(
    XmlElement element,
    _SimpleSelector selector,
  ) {
    final tag = selector.tag;
    if (tag != null && tag.toLowerCase() != element.name.local.toLowerCase()) {
      return false;
    }

    if (selector.id != null && element.getAttribute('id') != selector.id) {
      return false;
    }

    if (selector.classes.isNotEmpty) {
      final classAttr = element.getAttribute('class') ?? '';
      final classList = classAttr
          .split(RegExp(r'\s+'))
          .where((c) => c.isNotEmpty)
          .toSet();
      for (final cls in selector.classes) {
        if (!classList.contains(cls)) return false;
      }
    }

    for (final attr in selector.attributes) {
      final value = element.getAttribute(attr.name);
      if (value == null) return false;
      if (attr.value != null && value != attr.value) return false;
    }

    return true;
  }
}

class _CssRule {
  final List<_ParsedSelector> selectors;
  final Map<String, String> declarations;

  _CssRule(this.selectors, this.declarations);
}

class _ParsedSelector {
  final List<_SelectorSegment> segments;

  _ParsedSelector(this.segments);
}

class _SelectorSegment {
  final _SelectorCombinator combinator;
  final _SimpleSelector selector;

  _SelectorSegment(this.combinator, this.selector);
}

enum _SelectorCombinator { none, descendant, child }

class _SimpleSelector {
  final String? tag;
  final String? id;
  final List<String> classes;
  final List<_AttributeSelector> attributes;

  _SimpleSelector({
    required this.tag,
    required this.id,
    required this.classes,
    required this.attributes,
  });
}

class _AttributeSelector {
  final String name;
  final String? value;

  _AttributeSelector(this.name, this.value);
}
