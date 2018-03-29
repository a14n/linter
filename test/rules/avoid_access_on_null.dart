// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_access_on_null`

getter_on_null() {
  String a = null;
  a.length; // LINT
}

nullsafe_getter_on_null() {
  String a = null;
  a?.length; // OK
}

method_on_null() {
  int i = null;
  i.round(); // LINT
}

nullsafe_method_on_null() {
  int i = null;
  i?.round(); // OK
}

cascade_on_null() {
  int i = null;
  i // LINT
    ..round()
    ..round();
}

parenthesis_ignored() {
  String a = null;
  (a).length; // LINT
  (a)?.length; // OK
  (a)..length; // LINT
}

uninitialized() {
  String a;
  a.length; // LINT
}

nonnull_init() {
  String a = '';
  a.length; // OK
}

nullsafe_init(p) {
  String a = p?.m;
  a.length; // LINT
}

assignment_cancel_checks() {
  String a;
  a.length; // LINT
  a = '';
  a.length; // OK
}

closure_without_var_assignment_doesnt_matter() {
  String a;
  f() {
  }
  a.length; // LINT
}

closure_with_var_assignment_stop_analyze() {
  String a;
  f() {
    a = '';
  }
  a.length; // OK
}

usage_in_closure_should_not_be_linted() {
  String a;
  f() {
    a.substring(1); // OK
  }
  a.length; // LINT
}

if_null_return() {
  String a;
  if (a == null) {
    return;
  }
  a.length; // LINT
}
