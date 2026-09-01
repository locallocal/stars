part of 'message_list.dart';

const _maximumUrlPreviewsPerMessage = 4;

final class _UrlPreviewDescriptor {
  const _UrlPreviewDescriptor({required this.uri, required this.title});

  final Uri uri;
  final String title;

  String get displayTitle {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || normalizedTitle == uri.toString()) {
      return uri.host;
    }
    return normalizedTitle;
  }

  String get displayUrl {
    final port = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path == '/' ? '' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${uri.host}$port$path$query';
  }
}

List<_UrlPreviewDescriptor> _urlPreviewsFromMarkdown(String markdown) {
  if (markdown.trim().isEmpty) return const [];
  final previews = <_UrlPreviewDescriptor>[];
  final seen = <String>{};

  void add(String href, String title) {
    if (previews.length >= _maximumUrlPreviewsPerMessage) return;
    final uri = Uri.tryParse(_trimUrlPunctuation(href.trim()));
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return;
    }
    final normalized =
        uri
            .replace(
              scheme: uri.scheme.toLowerCase(),
              host: uri.host.toLowerCase(),
              fragment: '',
            )
            .toString();
    if (!seen.add(normalized)) return;
    previews.add(_UrlPreviewDescriptor(uri: uri, title: title));
  }

  try {
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ).parseLines(markdown.split('\n'));
    for (final node in nodes) {
      _collectUrlPreviews(node, add);
      if (previews.length >= _maximumUrlPreviewsPerMessage) break;
    }
  } on Object {
    return const [];
  }
  return List.unmodifiable(previews);
}

void _collectUrlPreviews(
  md.Node node,
  void Function(String href, String title) add, {
  bool insideCode = false,
  bool insideLink = false,
}) {
  if (node is md.Text) {
    if (!insideCode && !insideLink) {
      for (final match in _plainUrlPattern.allMatches(node.text)) {
        add(match.group(0) ?? '', '');
      }
    }
    return;
  }
  if (node is! md.Element) return;
  final isCode = insideCode || node.tag == 'pre' || node.tag == 'code';
  final isLink = insideLink || node.tag == 'a';
  if (node.tag == 'a' && !isCode) {
    add(node.attributes['href'] ?? '', node.textContent);
  }
  for (final child in node.children ?? const <md.Node>[]) {
    _collectUrlPreviews(child, add, insideCode: isCode, insideLink: isLink);
  }
}

final _plainUrlPattern = RegExp(
  r'''https?://[^\s<>\[\]{}"'，。；：！？、（）【】《》〈〉「」『』“”‘’]+''',
);

String _trimUrlPunctuation(String value) {
  var result = value;
  while (result.isNotEmpty && '.,;:!?'.contains(result[result.length - 1])) {
    result = result.substring(0, result.length - 1);
  }
  while (result.endsWith(')') &&
      '('.allMatches(result).length < ')'.allMatches(result).length) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

class _UrlPreviewList extends StatelessWidget {
  const _UrlPreviewList({
    required this.previews,
    required this.isDesktop,
    required this.actionViewModel,
  });

  final List<_UrlPreviewDescriptor> previews;
  final bool isDesktop;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < previews.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _UrlPreviewCard(
              preview: previews[index],
              actionViewModel: actionViewModel,
            ),
          ],
        ],
      ),
    );
  }
}

class _UrlPreviewCard extends StatelessWidget {
  const _UrlPreviewCard({required this.preview, required this.actionViewModel});

  final _UrlPreviewDescriptor preview;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final href = preview.uri.toString();
    return ShadTooltip(
      builder: (context) => Text(S.of(context).openLink),
      child: ShadButton.outline(
        key: ValueKey<String>('message-url-preview-$href'),
        height: 76,
        padding: const EdgeInsets.all(10),
        backgroundColor: theme.colorScheme.card,
        foregroundColor: theme.colorScheme.cardForeground,
        hoverBackgroundColor: theme.colorScheme.accent,
        hoverForegroundColor: theme.colorScheme.accentForeground,
        mainAxisAlignment: MainAxisAlignment.start,
        expands: true,
        onPressed:
            () => unawaited(_openMarkdownLink(context, href, actionViewModel)),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: theme.radius,
          ),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              LucideIcons.globe2,
              size: 20,
              color: theme.colorScheme.secondaryForeground,
            ),
          ),
        ),
        trailing: Icon(
          LucideIcons.externalLink,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: theme.textTheme.small,
            ),
            const SizedBox(height: 3),
            Text(
              preview.displayUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: theme.textTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}
