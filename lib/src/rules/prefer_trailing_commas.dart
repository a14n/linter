// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/flutter_utils.dart';

const _desc = r'Perfer trailing commas.';

const _details = r'''

Use a trailing comma for arguments, parameters, and list items when elements are
on multiple lines.

**BAD:**
```
int f(
    int a, {
    int b
}) => null;
```

**GOOD:**
```
int f(
    int a, {
    int b,
}) => null;
```

''';

class PreferTrailingCommas extends LintRule implements NodeLintRule {
  PreferTrailingCommas()
      : super(
          name: 'prefer_trailing_commas',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final LintRule rule;

  LineInfo lineInfo;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _visitNodeList(node.parameters);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (node.argumentList.arguments.length > 1) {
      _visitNodeList(node.argumentList.arguments);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.argumentList.arguments.length > 1) {
      _visitNodeList(node.argumentList.arguments);
    } else if (node.argumentList.arguments.length == 1) {
      var arg = node.argumentList.arguments.first;
      if (arg is NamedExpression) arg = (arg as NamedExpression).expression;
      if (isWidgetType(node.staticType) && isWidgetProperty(arg.staticType) ||
          arg is InstanceCreationExpression &&
              arg.argumentList.arguments.isNotEmpty &&
              arg.argumentList.arguments.last.endToken?.next?.type ==
                  TokenType.COMMA) {
        _visitNodeList(node.argumentList.arguments);
      }
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _visitNodeList(node.elements);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _visitNodeList(node.elements);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.length > 1) {
      _visitNodeList(node.argumentList.arguments);
    }
  }

  void _visitNodeList<T extends AstNode>(NodeList<T> list) {
    if (list.isEmpty) return;

    if (list.last.endToken?.next?.type != TokenType.COMMA &&
        _lineOf(list.last.end) != _lineOf(list.owner.end)) {
      rule.reporter.reportErrorForOffset(rule.lintCode, list.last.end, 0);
    }
  }

  int _lineOf(int offset) => lineInfo.getLocation(offset).lineNumber;
}
