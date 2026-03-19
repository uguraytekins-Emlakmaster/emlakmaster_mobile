#import <Foundation/Foundation.h>

/// Call before registering plugins to avoid duplicate FIRApp configure crash.
void FirebaseConfigureGuardInstall(void);

/// Default app yoksa plist ile tek seferlik configure et (decode crash önlemi).
void FirebaseConfigureFromPlistIfNeeded(void);

/// Plugin kaydından sonra çağır: optionsFromFIROptions apiKey yaması (Dart decode crash önlemi).
void FirebaseConfigureGuardInstallCorePluginPatch(void);

/// GSI swizzle henüz kurulmadıysa tekrar dene (applicationDidBecomeActive’te çağrılabilir).
void FirebaseConfigureGuardRetryGoogleSignInPatch(void);
