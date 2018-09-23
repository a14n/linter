// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_num`

num n; // LINT

num get g => 1; // LINT

num f1() => 1; // LINT
void f2(num x) {} // LINT

T f3<T>(T a, T b) => a;

m() {
  f3<num>(1, 2); // LINT
  f3<int>(1, 2); // OK
  f3(1, 2.0); // LINT

  if (null is num) {} // OK
}

// num used as upper bound is ok
T f4<T extends num>(T a, T b) => a; // OK

class A<T extends num> {} // OK
