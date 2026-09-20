---
name: tekartik-firebase-ai-logic-rest-setup
description: >-
  Use when asked to use, depend on or implement tekartik_firebase_ai_logic_rest
  (Firebase AI Logic / Vertex AI over REST): the package is still an empty
  scaffold whose only public API is the generated `Awesome` class exported by
  package:tekartik_firebase_ai_logic_rest/tekartik_firebase_ai_logic_rest.dart.
  Read this before importing it, calling a generative model through it, or
  inventing an aiLogicServiceRest/FirebaseAiLogicRest symbol: the real model
  API lives in tekartik_firebase_vertex_ai (package:tekartik_firebase_vertex_ai/vertex_ai.dart).
---

# tekartik_firebase_ai_logic_rest: unimplemented scaffold

`tekartik_firebase_ai_logic_rest` is the placeholder for a REST (pure Dart,
`googleapis` based) implementation of Firebase AI Logic. Today its `lib/`
still holds the `dart create` template: the only exported type is `Awesome`.
No AI Logic service, model or client exists in it yet.

## Guidelines

* Check `lib/` before writing code against this package. As of version
  `1.0.0` the whole public surface is:
  `package:tekartik_firebase_ai_logic_rest/tekartik_firebase_ai_logic_rest.dart`
  exporting `src/tekartik_firebase_ai_logic_rest_base.dart`, which declares
  `class Awesome` with a single `bool get isAwesome`. Nothing else compiles.
* Never write `FirebaseAiLogicRest`, `aiLogicServiceRest`,
  `firebaseAiLogicServiceRest`, `generateContent` or any similar name against
  this package: those symbols do not exist and the analyzer will reject them.
* The generative-model API this package is meant to implement lives in
  `tekartik_firebase_vertex_ai` (a declared dependency here, so it resolves
  transitively). Import
  `package:tekartik_firebase_vertex_ai/vertex_ai.dart` for real work and keep
  `tekartik_firebase_ai_logic_rest` out of the dependency list until it has
  an implementation.
* Not on pub.dev (`publish_to: none`) and, unlike its siblings in the repo,
  **not** part of the repo pub workspace: it has its own `pubspec.lock` and
  resolves on its own with `dart pub get` in `ai_logic_rest/`. Depend on it
  with a git dependency pinned to the repo path:
  ```yaml
  dependencies:
    tekartik_firebase_ai_logic_rest:
      git:
        url: https://github.com/tekartik/firebase_rest.dart
        path: ai_logic_rest
  ```
* Dependencies already declared for the future implementation:
  `googleapis`, `googleapis_auth` (REST transport and OAuth2 credentials, the
  same pipeline the sibling `tekartik_firebase_rest` uses) and
  `tekartik_firebase_vertex_ai`. Follow that shape when implementing: an
  authenticated `googleapis_auth` client built from a service account or
  access token, wrapped behind the `tekartik_firebase_vertex_ai`
  abstractions.
* When implementing, mirror the sibling REST packages of this repo
  (`firebase_rest`, `auth_rest`, `firestore_rest`): a `*ServiceRest` top-level
  singleton created from a `FirebaseApp`, an `lib/ai_logic_rest.dart` entry
  library, and shared tests from the abstraction's `*_test` package. Add the
  package to the root `pubspec.yaml` `workspace:` list at that point.
* `test/tekartik_firebase_ai_logic_rest_test.dart` and
  `example/tekartik_firebase_ai_logic_rest_example.dart` are the untouched
  template files; do not treat them as usage documentation.

## Examples

### Everything the package exports today

```dart
import 'package:tekartik_firebase_ai_logic_rest/tekartik_firebase_ai_logic_rest.dart';

void main() {
  var awesome = Awesome();
  print('awesome: ${awesome.isAwesome}');
}
```

### What to use instead for generative AI

```dart
// tekartik_firebase_ai_logic_rest has no model API yet; the abstraction it
// depends on does. Add tekartik_firebase_vertex_ai (git:
// https://github.com/tekartik/firebase_vertex_ai.dart, path: vertex_ai) to
// your own pubspec before using this import.
import 'package:tekartik_firebase_vertex_ai/vertex_ai.dart';

void describeApi() {
  print('$FirebaseVertexAi'); // see the vertex_ai package for the real usage
}
```
