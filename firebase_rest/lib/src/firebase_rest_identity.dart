/// Rest identity (service account or user)
abstract class FirebaseRestIdentity {}

/// Service account
abstract class FirebaseRestIdentifyServiceAccount
    implements FirebaseRestIdentity {}

/// Service account implementation
class FirebaseRestIdentifyServiceAccountImpl
    implements FirebaseRestIdentifyServiceAccount {}
