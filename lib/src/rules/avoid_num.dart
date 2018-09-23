// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid using num type.';

const _details = r'''

Avoid using num type.

''';

class AvoidNum extends LintRule implements NodeLintRule {
  AvoidNum()
      : super(
            name: 'avoid_num',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addTypeName(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitTypeName(TypeName node) {
    if (_isNum(node.type)) {
      if (_isUsedAsExtends(node)) {
        return;
      }
      if (_isUsedInIsCheck(node)) {
        return;
      }
      rule.reportLint(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.typeArguments == null) {
      final element = node.methodName.staticElement;
      if (element is FunctionTypedElement &&
          element.typeParameters.isNotEmpty &&
          (node.staticInvokeType as FunctionType).typeArguments.any(_isNum)) {
        rule.reportLint(node);
      }
    }
  }

  bool _isNum(DartType type) =>
      DartTypeUtilities.isClass(type, 'num', 'dart.core');

  bool _isUsedAsExtends(TypeName node) {
    final parent = node.parent;
    return parent is TypeParameter && _isNum(parent.bound.type);
  }

  bool _isUsedInIsCheck(TypeName node) => node.parent is IsExpression;
}
