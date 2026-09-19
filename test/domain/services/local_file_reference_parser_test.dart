import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stars/domain/services/local_file_reference_parser.dart';

void main() {
  final parser = LocalFileReferenceParser(
    pathContext: path.Context(style: path.Style.posix),
    baseDirectory: '/chats/current',
    homeDirectory: '/home/user',
  );

  test('finds prose, inline and linked references without duplicates', () {
    expect(
      parser.pathsFromMarkdown('''
已生成：/tmp/调研.md，请预览。
**/tmp/调研.md** and `/tmp/调研.md`
[报告](file:///tmp/%E8%B0%83%E7%A0%94.md)
结果在 reports/summary.txt。
'''),
      ['/tmp/调研.md', '/chats/current/reports/summary.txt'],
    );
  });

  test('distinguishes explicit links from prose and inline code', () {
    expect(
      parser.linkedPathsFromMarkdown('''
准备保存到 report.md 和 `/tmp/plan.md`。
[打开报告](<./report final.md>)
[同一个文件](file:///chats/current/report%20final.md)
![图片](./image.png)
[远程](https://example.com/result.md)
```markdown
[示例](/tmp/sample.md)
```
'''),
      ['/chats/current/report final.md', '/chats/current/image.png'],
    );
  });

  test('resolves spaces, encoded names and source locations', () {
    expect(
      parser.pathsFromMarkdown('''
[报告](<./报告 (final).md>)
`~/notes/学习.md`
`/tmp/main.dart:12:4`
[源代码](/tmp/main.dart#L12-L14)
[附件](sandbox:/tmp/hello%20world.md)
'''),
      [
        '/chats/current/报告 (final).md',
        '/home/user/notes/学习.md',
        '/tmp/main.dart',
        '/tmp/hello world.md',
      ],
    );
    expect(parser.resolve('file:///tmp/100%2520.md'), '/tmp/100%20.md');
    expect(parser.resolve('/tmp/100%.md'), '/tmp/100%.md');
    expect(parser.resolve('`no`'), isNull);
    expect(
      parser.pathsFromMarkdown('文件："/tmp/hello world.md" 和 `/tmp/a&b.md`'),
      ['/tmp/hello world.md', '/tmp/a&b.md'],
    );
  });

  test('does not treat URLs, anchors or code samples as local files', () {
    expect(
      parser.pathsFromMarkdown('''
https://example.com/tmp/file.md
[remote /tmp/link.md](https://example.com/report.md)
[anchor](#report.md)
`https://example.com/report.md`
```text
/tmp/code.txt
```

    /tmp/indented.txt
'''),
      isEmpty,
    );
    expect(parser.resolve('mailto:user@example.com'), isNull);
    expect(parser.resolve('javascript:alert(1)'), isNull);
  });

  test('requires a conversation directory for relative files', () {
    final withoutBase = LocalFileReferenceParser();
    expect(withoutBase.resolve('report.md'), isNull);
    expect(withoutBase.resolve('./report.md'), isNull);
    expect(parser.resolve('./report.md'), '/chats/current/report.md');
    expect(parser.resolve('report.md'), '/chats/current/report.md');
  });

  test('handles native Windows paths and file URIs on any test host', () {
    final windows = LocalFileReferenceParser(
      pathContext: path.Context(style: path.Style.windows),
      baseDirectory: r'C:\chats\current',
      homeDirectory: r'C:\Users\user',
    );
    expect(
      windows.resolve(r'C:\reports\main.dart:12'),
      r'C:\reports\main.dart',
    );
    expect(
      windows.resolve('file:///C:/reports/a%20b.md'),
      r'C:\reports\a b.md',
    );
    expect(windows.resolve(r'.\report.md'), r'C:\chats\current\report.md');
    expect(windows.resolve(r'~\report.md'), r'C:\Users\user\report.md');
  });
}
