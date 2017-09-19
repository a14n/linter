// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid import cycles.';

const _details = r'''

**AVOID** import library that depends on the current one.

''';

class AvoidImportCycles extends LintRule {
  _Visitor _visitor;
  AvoidImportCycles()
      : super(
            name: 'avoid_import_cycles',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitImportDirective(ImportDirective node) {
    final currentLib = node.element.library;
    final checkedLibraries = <LibraryElement>[];
    List<LibraryElement> libraries =
        node?.uriElement?.unit?.element?.library?.importedLibraries;

    if (libraries == null) return;

    while (libraries.isNotEmpty) {
      if (libraries.contains(currentLib)) {
        rule.reportLint(node);
        return;
      }
      checkedLibraries.addAll(libraries);
      libraries = libraries
          .expand((l) => l.importedLibraries)
          .where((l) => l != null)
          .where((l) => !checkedLibraries.contains(l))
          .toList();
    }
  }
}
