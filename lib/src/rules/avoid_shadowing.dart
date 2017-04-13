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
var k = null;

class A {
  var a;
}

class B extends A {
  get b => null;

  m() {
    var a; // LINT
    var b; // LINT
    var k; // LINT
  }
}
```

**GOOD:**
```
var k = null;

class A {
  var a;
}

class B extends A {
  get b => null;

  m() {
    var c; // OK
    var d; // OK
    var e; // OK
  }
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
  visitFormalParameterList(FormalParameterList node) {
    if (node.parameterElements.isEmpty) return;
    if (node.parent is ConstructorDeclaration) return;
    final library = node.parameterElements.first.library;
    _visit(library, node, node.parameters, (p) => p.identifier.name);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    final library = node.variables.variables.first.element.library;
    _visit(library, node, node.variables.variables, (v) => v.name.name);
  }

  _visit<T extends AstNode>(LibraryElement library, final AstNode node,
      List<T> nodesWithName, String getName(T node)) {
    AstNode current = node;
    while (current != null) {
      if (current is ClassDeclaration) {
        _checkClass(current, nodesWithName, getName);
      }
      if (node.parent != current) {
        if (current is FunctionExpression) {
          _checkParameters(current.parameters, nodesWithName, getName);
        }
        if (current is FunctionDeclaration) {
          _checkParameters(
              current.functionExpression.parameters, nodesWithName, getName);
        }
        if (current is FunctionDeclarationStatement) {
          _checkParameters(
              current.functionDeclaration.functionExpression.parameters,
              nodesWithName,
              getName);
        }
        if (current is MethodDeclaration) {
          _checkParameters(current.parameters, nodesWithName, getName);
        }
      }
      if (current.parent is Block) {
        _checkParentBlock(current, nodesWithName, getName);
      }
      current = current.parent;
      if (current == null) {
        _checkLibrary(library, nodesWithName, getName);
      }
    }
  }

  void _checkClass<T extends AstNode>(
      ClassDeclaration clazz, List<T> nodesWithName, String getName(T node)) {
    for (final node in nodesWithName) {
      final name = getName(node);
      final getterWithSameName =
          clazz.element.lookUpGetter(name, clazz.element.library);
      final methodWithSameName =
          clazz.element.lookUpMethod(name, clazz.element.library);
      if (getterWithSameName != null || methodWithSameName != null)
        rule.reportLint(node);
    }
  }

  void _checkLibrary<T extends AstNode>(
      LibraryElement library, List<T> nodesWithName, String getName(T node)) {
    final topLevelVariableNames = library.units
        .expand((u) => u.topLevelVariables)
        .map((e) => e.name)
        .toList();
    final functionNames =
        library.units.expand((u) => u.functions).map((e) => e.name).toList();
    for (final node in nodesWithName) {
      final name = getName(node);
      if (topLevelVariableNames.contains(name) ||
          functionNames.contains(name)) {
        rule.reportLint(node);
      }
    }
  }

  void _checkParameters<T extends AstNode>(FormalParameterList parameters,
      List<T> nodesWithName, String getName(T node)) {
    if (parameters == null) return;

    final parameterNames =
        parameters.parameterElements.map((e) => e.name).toList();

    for (final node in nodesWithName) {
      final name = getName(node);
      if (parameterNames.contains(name)) {
        rule.reportLint(node);
      }
    }
  }

  void _checkParentBlock<T extends AstNode>(
      AstNode currentNode, List<T> nodesWithName, String getName(T node)) {
    final block = currentNode.parent as Block;
    final names = <String>[];
    for (final statement
        in block.statements.takeWhile((n) => n != currentNode)) {
      if (statement is VariableDeclarationStatement) {
        names.addAll(statement.variables.variables.map((e) => e.name.name));
      }
      if (statement is FunctionDeclarationStatement) {
        names.add(statement.functionDeclaration.name.name);
      }
    }
    for (final node in nodesWithName) {
      final name = getName(node);
      if (names.contains(name)) {
        rule.reportLint(node);
      }
    }
  }
}
