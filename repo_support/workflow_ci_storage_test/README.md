# workflow_ci_storage_test

Run the storage_rest env test only (used by the `run_ci_storage_test` github workflow).

It sets `TEKARTIK_GITHUB_ACTIONS_ENV_TEST` so that `test/storage_rest_io_env_test.dart`
is run here, while it is skipped in the regular `run_ci` workflow.

```
dart run tool/run_ci.dart
```
