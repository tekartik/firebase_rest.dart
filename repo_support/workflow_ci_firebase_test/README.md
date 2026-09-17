# workflow_ci_firebase_test

Run the firebase_rest env test only (used by the `run_ci_firebase_test` github workflow).

It sets `TEKARTIK_GITHUB_ACTIONS_ENV_TEST` so that `test/firebase_rest_env_io_test.dart`
is run here, while it is skipped in the regular `run_ci` workflow.

```
dart run tool/run_ci.dart
```
