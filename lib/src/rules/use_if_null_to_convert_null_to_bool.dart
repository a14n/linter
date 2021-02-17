// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use if-null operator to convert null to bool.';

const _details = r'''

Use if-null operator to convert null to bool.

**BAD:**
```
if (nullableBool == true) {
}
```

**GOOD:**
```
if (nullableBool ?? false) {
}
```

''';

class UseIfNullToConvertNullToBool extends LintRule implements NodeLintRule {
  UseIfNullToConvertNullToBool()
      : super(
          name: 'use_if_null_to_convert_null_to_bool',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) return;

    final visitor = _Visitor(this, context);
    registry.addBinaryExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var type = node.leftOperand.staticType;
    var right = node.rightOperand;
    if (node.operator.type == TokenType.EQ_EQ &&
        type != null &&
        type.isDartCoreBool &&
        context.typeSystem.isNullable(type) &&
        right is BooleanLiteral &&
        right.value) {
      rule.reportLint(node);
    }
  }
}