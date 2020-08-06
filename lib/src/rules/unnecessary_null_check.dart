// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary null check.';

const _details = r'''

Don't apply null check when nullable value is accepted.

**BAD:**
```
f(int? i);
m() {
  int? j;
  f(j!);
}

```

**GOOD:**
```
f(int? i);
m() {
  int? j;
  f(j);
}
```

''';

class UnnecessaryNullCheck extends LintRule implements NodeLintRule {
  UnnecessaryNullCheck()
      : super(
            name: 'unnecessary_null_check',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this, context);
    registry.addPostfixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type != TokenType.BANG) return;

    var realNode = node
        .thisOrAncestorMatching((e) => e.parent is! ParenthesizedExpression);
    var parent = realNode.parent;

    // in variable declaration
    if (parent is VariableDeclaration) {
      reportIfNullable(node, parent.declaredElement.type);
      return;
    }
    // as right member of binary operator
    if (parent is BinaryExpression && parent.rightOperand == realNode) {
      reportIfNullable(node, parent.staticElement.parameters.first.type);
      return;
    }
    // as parameter of function
    if (parent is NamedExpression) {
      realNode = parent;
      parent = parent.parent;
    }
    if (parent is ArgumentList) {
      reportIfNullable(
          node, (realNode as Expression).staticParameterElement.type);
      return;
    }
  }

  void reportIfNullable(PostfixExpression node, DartType type) {
    if (type != null && context.typeSystem.isNullable(type)) {
      rule.reportLintForToken(node.operator);
    }
  }
}
