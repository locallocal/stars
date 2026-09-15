import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('JsonSchemaValidator', () {
    test('validates required properties, types, and additional fields', () {
      const validator = JsonSchemaValidator();
      final issues = validator.validate(
        {'name': 3, 'extra': true},
        const {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'count': {'type': 'integer'},
          },
          'required': ['name', 'count'],
          'additionalProperties': false,
        },
      );

      expect(
        issues.map((issue) => issue.code),
        containsAll(['required', 'type', 'additional_property']),
      );
    });

    test('fails closed for unsupported schema constraints', () {
      const validator = JsonSchemaValidator();

      final issues = validator.validate('value', const {
        'type': 'string',
        r'$ref': '#/definitions/value',
      });

      expect(
        issues.map((issue) => issue.code),
        contains('unsupported_schema_keyword'),
      );
    });
  });
}
