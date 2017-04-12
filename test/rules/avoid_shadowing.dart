// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_shadowing`

var top = null;

m() {
  f() {
    var top; // LINT
    var a; // OK
  }

  var a; // OK
  var b; // OK
  var top; // LINT

  g() {
    var a; // LINT
    var c; // OK
  }
}

class A {
  var a;
  get b => null;

  ma() {
    var a; // LINT
    var b; // LINT
    var top; // LINT
  }
}

class B extends A {
  mb() {
    var a; // LINT
    var b; // LINT
    var c; // OK
    var ma; // LINT
  }
}

class C extends Object with A {
  mc() {
    var a; // LINT
    var b; // LINT
    var c; // OK
  }
}
