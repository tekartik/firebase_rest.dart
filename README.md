# firebase_rest.dart

Firebase over REST in pure Dart (Dart VM, servers, CLI tools, and the web for
the packages that support it): implementations of the tekartik firebase
abstractions on the Google REST APIs, no native SDK.

## Packages

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_rest` | [firebase_rest](firebase_rest) | the app and its credentials (service account, access token); start here |
| `tekartik_firebase_auth_rest` | [auth_rest](auth_rest) | Firebase Auth (sign in, users) |
| `tekartik_firebase_firestore_rest` | [firestore_rest](firestore_rest) | Firestore |
| `tekartik_firebase_firestore_grpc_rest` | [firestore_grpc_rest](firestore_grpc_rest) | Firestore listen (gRPC) |
| `tekartik_firebase_storage_rest` | [storage_rest](storage_rest) | Cloud Storage |
| `tekartik_firebase_functions_call_rest` | [functions_call_rest](functions_call_rest) | callable functions |
| `tekartik_firebase_ai_logic_rest` | [ai_logic_rest](ai_logic_rest) | placeholder, not implemented |

Git packages, not on pub.dev, for example:

```yaml
dependencies:
  tekartik_firebase_rest:
    git:
      url: https://github.com/tekartik/firebase_rest.dart
      path: firebase_rest
```

See the [firebase_rest README](firebase_rest/README.md) for a first program.
Each package ships agent skills in its `skills/` folder.
