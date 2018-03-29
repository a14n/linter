// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid access on null.';

const _details = r'''

**AVOID** access on null.

**BAD:**
```
String a = null;
a.length;
```

**GOOD:**
```
String a = null;
a?.length;
```

''';

class AvoidAccessOnNull extends LintRule {
  AvoidAccessOnNull()
      : super(
            name: 'avoid_access_on_null',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    try {
      new _NullCheckVisitor(rule).visitBlockFunctionBody(node);
    } catch (e, s) {
      print('---');
      print(node);
      print(e);
      print(s);
    }
  }
}

class _NullCheckVisitor extends RecursiveAstVisitor {
  _NullCheckVisitor(this.rule);

  final LintRule rule;

  final vars = <String, bool>{};
  final closures = <String, FunctionBody>{};

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    vars[node.name.name] = _isNullable(node.initializer, vars);
    return super.visitVariableDeclaration(node);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    final leftHandSide = node.leftHandSide;
    if (leftHandSide is SimpleIdentifier &&
        vars.containsKey(leftHandSide.name)) {
      // TODO(a14n) implement some branch tracking
      vars[leftHandSide.name] = false;
    }
    return super.visitAssignmentExpression(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget?.unParenthesized;
    if (target != null &&
        node.operator.type != TokenType.QUESTION_PERIOD &&
        target is SimpleIdentifier &&
        vars[target.name] == true) {
      rule.reportLint(target);
    }
    return super.visitMethodInvocation(node);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    final target = node.prefix.unParenthesized;
    if (target is SimpleIdentifier && vars[target.name] == true) {
      rule.reportLint(target);
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    final target = node.realTarget?.unParenthesized;
    if (target != null &&
        node.operator.type != TokenType.QUESTION_PERIOD &&
        target is SimpleIdentifier &&
        vars[target.name] == true) {
      rule.reportLint(target);
    }
    return super.visitPropertyAccess(node);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    final varsInScope = vars.keys.toList();
    node.functionDeclaration.functionExpression.parameters.parameters
        .map((e) => e.identifier.name)
        .forEach(varsInScope.remove);
    final visitor = new _IsAssignedVisitor(
        varsInScope, node.functionDeclaration.functionExpression.body);
    for (final String v in visitor.computeAssignedVars()) {
      vars[v] = false;
    }
  }

  @override
  visitIfStatement(IfStatement node) {
    Map<String, bool> getNullAssertions(Expression condition) {
      condition = condition.unParenthesized;
      if (condition is BinaryExpression) {} else if (condition
              is PrefixExpression &&
          condition.operator.type == TokenType.BANG) {
        final operand = condition.operand;
        if (operand is BinaryExpression) {
          if (operand.operator.type == TokenType.BANG_EQ){
            final expressions = [operand.leftOperand, operand.rightOperand];
            if (expressions.any((e)=>e is NullLiteral) && vars.keys)
          }
        }
      }
    }

    final condition = node.condition.unParenthesized;
    return super.visitIfStatement(node);
  }
}

class _IsAssignedVisitor extends RecursiveAstVisitor {
  _IsAssignedVisitor(this.varsInScope, this.body);

  final List<String> varsInScope;
  final FunctionBody body;
  final assignedVarsInScope = <String>[];

  List<String> computeAssignedVars() {
    if (body is ExpressionFunctionBody) visitExpressionFunctionBody(body);
    if (body is BlockFunctionBody)
      visitBlock((body as BlockFunctionBody).block);
    return assignedVarsInScope;
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    varsInScope.remove(node.name.name);
    return super.visitVariableDeclaration(node);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    final leftHandSide = node.leftHandSide;
    if (leftHandSide is SimpleIdentifier &&
        varsInScope.contains(leftHandSide.name)) {
      assignedVarsInScope.add(leftHandSide.name);
    }
    return super.visitAssignmentExpression(node);
  }
}

bool _isNullable(Expression initializer, Map<String, bool> vars) =>
    initializer == null ||
    initializer is NullLiteral ||
    initializer is MethodInvocation &&
        initializer.operator?.type == TokenType.QUESTION_PERIOD ||
    initializer is PropertyAccess &&
        initializer.operator?.type == TokenType.QUESTION_PERIOD ||
    initializer is SimpleIdentifier && (vars[initializer.name] ?? false);
