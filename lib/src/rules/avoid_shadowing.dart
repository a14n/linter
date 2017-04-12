// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.avoid_shadowing;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const desc = r'Do not use a name already visible.';

const details = r'''

**DO** Do not use a name already visible.

**BAD:**
```
class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Bad1 extends Base {
  @override
  final field = 'ipsum'; // LINT
}

class Bad2 extends Base {
  @override
  Object something = 'done'; // LINT
}
```

**GOOD:**
```
class Base {
  Object field = 'lorem';

  Object something = 'change';
}

class Ok extends Base {
  Object newField; // OK

  final Object newFinal = 'ignore'; // OK
}
```
''';

class AvoidShadowing extends LintRule {
  _Visitor _visitor;

  AvoidShadowing()
      : super(
            name: 'avoid_shadowing',
            description: desc,
            details: details,
            group: Group.errors) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node,
      [bool debug = false]) {
    try {
      final variables = node.variables.variables;

      AstNode current = node;
      while (current != null) {
        if (debug) print(current.runtimeType);
        if (debug) print(current);
        if (current is ClassDeclaration) {
          _checkClass(current, variables);
        }
        if (current is FunctionExpression) {
          _checkParameters(current.parameters, variables);
        }
        if (current is FunctionDeclaration) {
          _checkParameters(current.functionExpression.parameters, variables);
        }
        if (current is FunctionDeclarationStatement) {
          _checkParameters(
              current.functionDeclaration.functionExpression.parameters,
              variables);
        }
        if (current is MethodDeclaration) {
          _checkParameters(current.parameters, variables);
        }
        if (current.parent is Block) {
          _checkParentBlock(current, variables);
        }
        current = current.parent;
        if (current == null) {
          final library = node.variables.variables.first.element.library;
          _checkLibrary(library, variables);
        }
      }
    } catch (e) {
      if (debug) return;
      print('-------------------- error for:');
      print(node);
      print(e);
      visitVariableDeclarationStatement(node, true);
    }
  }

  void _checkClass(
      ClassDeclaration clazz, List<VariableDeclaration> variables) {
    for (final variable in variables) {
      final name = variable.name.name;
      if (clazz.element.lookUpGetter(name, clazz.element.library) != null)
        rule.reportLint(variable);
    }
  }

  void _checkLibrary(
      LibraryElement library, List<VariableDeclaration> variables) {
    final topLevelVariableNames = library.units
        .expand((u) => u.topLevelVariables)
        .map((e) => e.name)
        .toList();
    for (final variable in variables) {
      final name = variable.name.name;
      if (topLevelVariableNames.contains(name)) {
        rule.reportLint(variable);
      }
    }
  }

  void _checkParameters(
      FormalParameterList parameters, NodeList<VariableDeclaration> variables) {
    if (parameters == null) return;

    final parameterNames =
        parameters.parameterElements.map((e) => e.name).toList();

    for (final variable in variables) {
      final name = variable.name.name;
      if (parameterNames.contains(name)) {
        rule.reportLint(variable);
      }
    }
  }

  void _checkParentBlock(
      AstNode node, NodeList<VariableDeclaration> variables) {
    final block = node.parent as Block;
    final names = <String>[];
    for (final statement in block.statements.takeWhile((n) => n != node)) {
      if (statement is VariableDeclarationStatement) {
        names.addAll(statement.variables.variables.map((e) => e.name.name));
      }
    }
    for (final variable in variables) {
      final name = variable.name.name;
      if (names.contains(name)) {
        rule.reportLint(variable);
      }
    }
  }
}
