import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight_core.dart' as highlight_core;
import 'package:highlight/languages/bash.dart' as highlight_bash;
import 'package:highlight/languages/cmake.dart' as highlight_cmake;
import 'package:highlight/languages/cpp.dart' as highlight_cpp;
import 'package:highlight/languages/cs.dart' as highlight_cs;
import 'package:highlight/languages/css.dart' as highlight_css;
import 'package:highlight/languages/dart.dart' as highlight_dart;
import 'package:highlight/languages/dockerfile.dart' as highlight_dockerfile;
import 'package:highlight/languages/elixir.dart' as highlight_elixir;
import 'package:highlight/languages/go.dart' as highlight_go;
import 'package:highlight/languages/gradle.dart' as highlight_gradle;
import 'package:highlight/languages/graphql.dart' as highlight_graphql;
import 'package:highlight/languages/ini.dart' as highlight_ini;
import 'package:highlight/languages/java.dart' as highlight_java;
import 'package:highlight/languages/javascript.dart' as highlight_javascript;
import 'package:highlight/languages/json.dart' as highlight_json;
import 'package:highlight/languages/kotlin.dart' as highlight_kotlin;
import 'package:highlight/languages/less.dart' as highlight_less;
import 'package:highlight/languages/lua.dart' as highlight_lua;
import 'package:highlight/languages/makefile.dart' as highlight_makefile;
import 'package:highlight/languages/objectivec.dart' as highlight_objectivec;
import 'package:highlight/languages/php.dart' as highlight_php;
import 'package:highlight/languages/powershell.dart' as highlight_powershell;
import 'package:highlight/languages/protobuf.dart' as highlight_protobuf;
import 'package:highlight/languages/python.dart' as highlight_python;
import 'package:highlight/languages/r.dart' as highlight_r;
import 'package:highlight/languages/ruby.dart' as highlight_ruby;
import 'package:highlight/languages/rust.dart' as highlight_rust;
import 'package:highlight/languages/scala.dart' as highlight_scala;
import 'package:highlight/languages/scss.dart' as highlight_scss;
import 'package:highlight/languages/solidity.dart' as highlight_solidity;
import 'package:highlight/languages/sql.dart' as highlight_sql;
import 'package:highlight/languages/swift.dart' as highlight_swift;
import 'package:highlight/languages/typescript.dart' as highlight_typescript;
import 'package:highlight/languages/vue.dart' as highlight_vue;
import 'package:highlight/languages/xml.dart' as highlight_xml;
import 'package:highlight/languages/yaml.dart' as highlight_yaml;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/theme.dart';

/// A selectable, theme-aware code surface backed by syntax highlighting.
///
/// Parsing runs in a background isolate on native platforms. If highlighting
/// fails, the original source remains available as plain monospace text.
class StarsSyntaxHighlightedCode extends StatefulWidget {
  const StarsSyntaxHighlightedCode({
    super.key,
    required this.source,
    required this.language,
    this.padding = const EdgeInsets.all(16),
    this.framed = true,
  });

  final String source;
  final String language;
  final EdgeInsetsGeometry padding;
  final bool framed;

  @override
  State<StarsSyntaxHighlightedCode> createState() =>
      _StarsSyntaxHighlightedCodeState();
}

class _StarsSyntaxHighlightedCodeState
    extends State<StarsSyntaxHighlightedCode> {
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();
  late Future<List<List<String?>>> _highlightedTokens;

  @override
  void initState() {
    super.initState();
    _highlightedTokens = _highlight();
  }

  @override
  void didUpdateWidget(covariant StarsSyntaxHighlightedCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.language != widget.language) {
      _highlightedTokens = _highlight();
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<List<List<String?>>> _highlight() => compute(
    _highlightSource,
    <String, String>{'source': widget.source, 'language': widget.language},
    debugLabel: 'highlight-${widget.language}',
  );

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final codeView = LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = widget.padding.resolve(
          Directionality.of(context),
        );
        final minimumCodeWidth = math.max(
          0.0,
          constraints.maxWidth - resolvedPadding.horizontal,
        );
        return FutureBuilder<List<List<String?>>>(
          future: _highlightedTokens,
          builder: (context, snapshot) {
            final highlightedTokens = snapshot.data;
            return Scrollbar(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: Scrollbar(
                  controller: _horizontalController,
                  notificationPredicate:
                      (notification) =>
                          notification.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    padding: widget.padding,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minimumCodeWidth),
                      child: SelectionArea(
                        child: Text.rich(
                          key: const ValueKey<String>(
                            'stars-syntax-highlighted-code-text',
                          ),
                          _buildHighlightedText(
                            context,
                            highlightedTokens ??
                                <List<String?>>[
                                  <String?>[null, widget.source],
                                ],
                          ),
                          softWrap: false,
                          style: ShadTheme.of(context).textTheme.p.copyWith(
                            color: tokens.primaryText,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (!widget.framed) {
      return ColoredBox(color: tokens.controlFill, child: codeView);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.controlFill,
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        border: Border.all(color: tokens.separator),
      ),
      child: codeView,
    );
  }
}

TextSpan _buildHighlightedText(
  BuildContext context,
  List<List<String?>> tokens,
) {
  final palette = _SyntaxHighlightPalette.of(context);
  return TextSpan(
    children: [
      for (final token in tokens)
        TextSpan(text: token[1] ?? '', style: palette.styleFor(token[0])),
    ],
  );
}

final class _SyntaxHighlightPalette {
  const _SyntaxHighlightPalette({
    required this.foreground,
    required this.muted,
    required this.keyword,
    required this.string,
    required this.number,
    required this.title,
    required this.meta,
    required this.addition,
    required this.deletion,
  });

  factory _SyntaxHighlightPalette.of(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SyntaxHighlightPalette(
      foreground: tokens.primaryText,
      muted: tokens.secondaryText,
      keyword: isDark ? const Color(0xFFD2A8FF) : const Color(0xFF8250DF),
      string: isDark ? const Color(0xFFA5D6FF) : const Color(0xFF116329),
      number: isDark ? const Color(0xFF79C0FF) : const Color(0xFF0550AE),
      title: isDark ? const Color(0xFFFFA657) : const Color(0xFF953800),
      meta: isDark ? const Color(0xFFE3B341) : const Color(0xFF9A6700),
      addition: tokens.success,
      deletion: tokens.danger,
    );
  }

  final Color foreground;
  final Color muted;
  final Color keyword;
  final Color string;
  final Color number;
  final Color title;
  final Color meta;
  final Color addition;
  final Color deletion;

  TextStyle styleFor(String? scope) => switch (scope) {
    null => TextStyle(color: foreground),
    'comment' ||
    'quote' => TextStyle(color: muted, fontStyle: FontStyle.italic),
    'keyword' ||
    'selector-tag' ||
    'type' ||
    'built_in' ||
    'name' => TextStyle(color: keyword, fontWeight: FontWeight.w600),
    'string' ||
    'regexp' ||
    'symbol' ||
    'bullet' ||
    'template-tag' ||
    'template-variable' => TextStyle(color: string),
    'number' || 'literal' || 'variable' => TextStyle(color: number),
    'title' ||
    'class' ||
    'function' ||
    'section' ||
    'selector-id' ||
    'selector-class' => TextStyle(color: title, fontWeight: FontWeight.w600),
    'meta' ||
    'doctag' ||
    'tag' ||
    'attribute' ||
    'attr' => TextStyle(color: meta),
    'addition' => TextStyle(color: addition),
    'deletion' => TextStyle(color: deletion),
    'emphasis' => TextStyle(color: foreground, fontStyle: FontStyle.italic),
    'strong' => TextStyle(color: foreground, fontWeight: FontWeight.w700),
    _ => TextStyle(color: foreground),
  };
}

List<List<String?>> _highlightSource(Map<String, String> request) {
  final source = request['source'] ?? '';
  final language = request['language'] ?? '';
  _registerLanguages(language);
  final nodes =
      highlight_core.highlight.parse(source, language: language).nodes;
  if (nodes == null || nodes.isEmpty) {
    return <List<String?>>[
      <String?>[null, source],
    ];
  }

  final tokens = <List<String?>>[];
  for (final node in nodes) {
    _flattenNode(node, tokens);
  }
  return tokens;
}

void _flattenNode(
  highlight_core.Node node,
  List<List<String?>> tokens, [
  String? inheritedScope,
]) {
  final scope = node.className ?? inheritedScope;
  final value = node.value;
  if (value != null) {
    if (value.isNotEmpty) {
      if (tokens.isNotEmpty && tokens.last[0] == scope) {
        tokens.last[1] = '${tokens.last[1] ?? ''}$value';
      } else {
        tokens.add(<String?>[scope, value]);
      }
    }
    return;
  }
  for (final child in node.children ?? const <highlight_core.Node>[]) {
    _flattenNode(child, tokens, scope);
  }
}

void _registerLanguages(String requestedLanguage) {
  final languages = <String, highlight_core.Mode>{
    'bash': highlight_bash.bash,
    'cmake': highlight_cmake.cmake,
    'cpp': highlight_cpp.cpp,
    'cs': highlight_cs.cs,
    'css': highlight_css.css,
    'dart': highlight_dart.dart,
    'dockerfile': highlight_dockerfile.dockerfile,
    'elixir': highlight_elixir.elixir,
    'go': highlight_go.go,
    'gradle': highlight_gradle.gradle,
    'graphql': highlight_graphql.graphql,
    'ini': highlight_ini.ini,
    'java': highlight_java.java,
    'javascript': highlight_javascript.javascript,
    'json': highlight_json.json,
    'kotlin': highlight_kotlin.kotlin,
    'less': highlight_less.less,
    'lua': highlight_lua.lua,
    'makefile': highlight_makefile.makefile,
    'objectivec': highlight_objectivec.objectivec,
    'php': highlight_php.php,
    'powershell': highlight_powershell.powershell,
    'protobuf': highlight_protobuf.protobuf,
    'python': highlight_python.python,
    'r': highlight_r.r,
    'ruby': highlight_ruby.ruby,
    'rust': highlight_rust.rust,
    'scala': highlight_scala.scala,
    'scss': highlight_scss.scss,
    'solidity': highlight_solidity.solidity,
    'sql': highlight_sql.sql,
    'swift': highlight_swift.swift,
    'typescript': highlight_typescript.typescript,
    'vue': highlight_vue.vue,
    'xml': highlight_xml.xml,
    'yaml': highlight_yaml.yaml,
  };
  if (!languages.containsKey(requestedLanguage)) {
    throw UnsupportedError('Unsupported syntax language: $requestedLanguage');
  }
  highlight_core.highlight.registerLanguages(languages);
}
