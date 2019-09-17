// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_trailing_commas`

void f1() => null; // OK
void f2(int a) => null; // OK
void f3(int a, int b) => null; // OK
void f4a(
  int a, int b // LINT
) => null;
void f4b(
  int a, int b, // OK
) => null;
void f5a(
  int a,
  int b // LINT
) => null;
void f5b(
  int a,
  int b, // OK
) => null;
void f6a(
  int a, {
  int b // LINT
}) => null;
void f6b(
  int a, {
  int b, // OK
}) => null;

class A {
  A(int a, int b); // OK
  A.c1a(
    int a,
    int b // LINT
  );
  A.c1b(
    int a,
    int b, // OK
  );

  m1a() {
    A(
      1, 2 // LINT
    );
  }
  m1b() {
    A(
      1, 2, // OK
    );
  }
  m2a() {
    A(
      1,
      2 // LINT
    );
  }
  m2b() {
    A(
      1,
      2, // OK
    );
  }
}

var a1 = []; // OK
var a2 = [1]; // OK
var a3 = [1, 2]; // OK
var a4a = [
  1, 2 // LINT
];
var a4b = [
  1, 2, // OK
];
var a5a = [
  1,
  2 // LINT
];
var a5b = [
  1,
  2, // OK
];

var m1 = {}; // OK
var m2 = {1: 1}; // OK
var m3 = {1: 1, 2: 2}; // OK
var m4a = {
  1: 1, 2: 2 // LINT
};
var m4b = {
  1: 1, 2: 2, // OK
};
var m5a = {
  1: 1,
  2: 2 // LINT
};
var m5b = {
  1: 1,
  2: 2, // OK
};
