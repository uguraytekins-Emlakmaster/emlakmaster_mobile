#import <Foundation/Foundation.h>
#import <FirebaseCore/FirebaseCore.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
static IMP original_configure_imp = NULL;
static IMP original_pluginConstantsForFIRApp_imp = NULL;
static IMP original_configureWithOptions_imp = NULL;
static IMP original_configureWithName_options_imp = NULL;
static IMP original_addAppToAppDictionary_imp = NULL;
static IMP original_optionsFromFIROptions_imp = NULL;
static IMP original_signInWithCompletion_imp = NULL;

/// [FIRApp configure] ikinci kez çağrıldığında addAppToAppDictionary crash oluyor.
static void SafeFIRAppConfigure(id self, SEL _cmd) {
    if ([FIRApp defaultApp] != nil) {
        return;
    }
    if (original_configure_imp) {
        ((void (*)(id, SEL))original_configure_imp)(self, _cmd);
    }
}

/// FLTFirebaseCorePlugin configureWithOptions: çağırıyor; aynı guard.
static void SafeFIRAppConfigureWithOptions(id self, SEL _cmd, FIROptions *options) {
    if ([FIRApp defaultApp] != nil) {
        return;
    }
    if (original_configureWithOptions_imp) {
        ((void (*)(id, SEL, FIROptions *))original_configureWithOptions_imp)(self, _cmd, options);
    }
}

/// configureWithName:options: — bu isimle app zaten varsa veya default app zaten configure edildiyse tekrar configure etme (appWasConfiguredTwice crash’ını önle).
static void SafeFIRAppConfigureWithNameOptions(id self, SEL _cmd, NSString *name, FIROptions *options) {
    if (name && [FIRApp appNamed:name] != nil) {
        return;
    }
    // Default app (nil/empty/__FIRAPP_DEFAULT) zaten varsa ikinci configure’ı atla.
    BOOL isDefaultName = (name == nil || name.length == 0 || [name isEqualToString:@"__FIRAPP_DEFAULT"]);
    if (isDefaultName && [FIRApp defaultApp] != nil) {
        return;
    }
    if (original_configureWithName_options_imp) {
        ((void (*)(id, SEL, NSString *, FIROptions *))original_configureWithName_options_imp)(self, _cmd, name, options);
    }
}

/// addAppToAppDictionary: — aynı isimle app zaten kayıtlıysa eklemeyi atla (duplicate exception’ı önle).
static void SafeFIRAppAddAppToAppDictionary(id self, SEL _cmd, id app) {
    NSString *name = nil;
    if (app && [app respondsToSelector:@selector(name)]) {
        name = [app name];
    }
    if (!name) {
        name = @"__FIRAPP_DEFAULT";
    }
    if ([FIRApp appNamed:name] != nil) {
        return;
    }
    if ([name isEqualToString:@"__FIRAPP_DEFAULT"] && [FIRApp defaultApp] != nil) {
        return;
    }
    if (original_addAppToAppDictionary_imp) {
        ((void (*)(id, SEL, id))original_addAppToAppDictionary_imp)(self, _cmd, app);
    }
}

/// Zorunlu alanlar nil ise plist’ten doldur (Dart CoreFirebaseOptions.decode crash önlemi).
static void FillOptionsFromPlist(id result) {
    if (!result) return;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (!path.length) return;
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!plist) return;
    static NSString * const keys[] = { @"apiKey", @"appId", @"messagingSenderId", @"projectId" };
    static NSString * const plistKeys[] = { @"API_KEY", @"GOOGLE_APP_ID", @"GCM_SENDER_ID", @"PROJECT_ID" };
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) {
        id val = [result valueForKey:keys[i]];
        if (val == nil || val == [NSNull null]) {
            NSString *p = plist[plistKeys[i]];
            if (p.length) [result setValue:p forKey:keys[i]];
        }
    }
}

/// FLTFirebaseCorePlugin optionsFromFIROptions: — zorunlu alan nil ise plist’ten doldur.
static id SafeOptionsFromFIROptions(id self, SEL _cmd, id options) {
    id result = original_optionsFromFIROptions_imp
        ? ((id (*)(id, SEL, id))original_optionsFromFIROptions_imp)(self, _cmd, options)
        : nil;
    FillOptionsFromPlist(result);
    return result;
}

/// FLTFirebaseAuthPlugin pluginConstantsForFIRApp: — app nil ise Auth.auth(app:) crash’ını önlemek için defaultApp kullan.
static NSDictionary *SafeFLTFirebaseAuthPlugin_pluginConstantsForFIRApp(id self, SEL _cmd, id app) {
    if (app == nil) {
        app = [FIRApp defaultApp];
    }
    if (app == nil) {
        return @{};
    }
    if (original_pluginConstantsForFIRApp_imp) {
        return ((NSDictionary * (*)(id, SEL, id))original_pluginConstantsForFIRApp_imp)(self, _cmd, app);
    }
    return @{};
}

#if TARGET_OS_IOS
// FLTGoogleSignInPlugin signInWithCompletion: plugin [e raise] ile exception yeniden firlatiyor; yakalayip yut, crash onle.
static void SafeSignInWithCompletion(id self, SEL _cmd, id completionBlock) {
    @try {
        if (original_signInWithCompletion_imp && completionBlock) {
            ((void (*)(id, SEL, id))original_signInWithCompletion_imp)(self, _cmd, completionBlock);
        }
    } @catch (NSException *e) {
        // Plugin already called completion(nil, error) before [e raise]. Just swallow so app does not abort.
    }
}
#endif

static int guardInstalled = 0;
static int corePluginPatchInstalled = 0;
#if TARGET_OS_IOS
static int gsiSwizzleInstalled = 0;
static int gsiSwizzleRetryScheduled = 0;

/// Returns 1 if swizzle was installed, 0 if class/method not found.
static int InstallGoogleSignInSwizzle(void) {
    if (gsiSwizzleInstalled) return 1;
    Class gsiPlugin = NSClassFromString(@"FLTGoogleSignInPlugin");
    if (!gsiPlugin) return 0;
    SEL selSignIn = NSSelectorFromString(@"signInWithCompletion:");
    Method mSignIn = class_getInstanceMethod(gsiPlugin, selSignIn);
    if (!mSignIn) return 0;
    original_signInWithCompletion_imp = method_getImplementation(mSignIn);
    if (!original_signInWithCompletion_imp) return 0;
    method_setImplementation(mSignIn, (IMP)SafeSignInWithCompletion);
    gsiSwizzleInstalled = 1;
    return 1;
}
#endif

void FirebaseConfigureGuardInstallCorePluginPatch(void) {
    if (corePluginPatchInstalled) return;
    corePluginPatchInstalled = 1;
    Class corePlugin = NSClassFromString(@"FLTFirebaseCorePlugin");
    if (corePlugin) {
        SEL selOptions = NSSelectorFromString(@"optionsFromFIROptions:");
        Method mOptions = class_getInstanceMethod(corePlugin, selOptions);
        if (mOptions) {
            original_optionsFromFIROptions_imp = method_getImplementation(mOptions);
            if (original_optionsFromFIROptions_imp) {
                method_setImplementation(mOptions, (IMP)SafeOptionsFromFIROptions);
            }
        }
    }
#if TARGET_OS_IOS
    if (!InstallGoogleSignInSwizzle() && !gsiSwizzleRetryScheduled) {
        gsiSwizzleRetryScheduled = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            InstallGoogleSignInSwizzle();
        });
    }
#endif
}

void FirebaseConfigureGuardRetryGoogleSignInPatch(void) {
#if TARGET_OS_IOS
    InstallGoogleSignInSwizzle();
#endif
}

void FirebaseConfigureGuardInstall(void) {
    if (guardInstalled) return;
    guardInstalled = 1;

    Class firApp = NSClassFromString(@"FIRApp");
    if (!firApp) return;

    SEL selConfigure = @selector(configure);
    Method mConfigure = class_getClassMethod(firApp, selConfigure);
    if (mConfigure) {
        original_configure_imp = method_getImplementation(mConfigure);
        if (original_configure_imp) {
            method_setImplementation(mConfigure, (IMP)SafeFIRAppConfigure);
        }
    }

    SEL selOptions = @selector(configureWithOptions:);
    Method mOptions = class_getClassMethod(firApp, selOptions);
    if (mOptions) {
        original_configureWithOptions_imp = method_getImplementation(mOptions);
        if (original_configureWithOptions_imp) {
            method_setImplementation(mOptions, (IMP)SafeFIRAppConfigureWithOptions);
        }
    }

    SEL selNameOptions = @selector(configureWithName:options:);
    Method mNameOptions = class_getClassMethod(firApp, selNameOptions);
    if (mNameOptions) {
        original_configureWithName_options_imp = method_getImplementation(mNameOptions);
        if (original_configureWithName_options_imp) {
            method_setImplementation(mNameOptions, (IMP)SafeFIRAppConfigureWithNameOptions);
        }
    }

    SEL selAddDict = NSSelectorFromString(@"addAppToAppDictionary:");
    Method mAddDict = class_getClassMethod(firApp, selAddDict);
    if (mAddDict) {
        original_addAppToAppDictionary_imp = method_getImplementation(mAddDict);
        if (original_addAppToAppDictionary_imp) {
            method_setImplementation(mAddDict, (IMP)SafeFIRAppAddAppToAppDictionary);
        }
    }

    // FLTFirebaseCorePlugin patch plugin yüklendikten sonra FirebaseConfigureGuardInstallCorePluginPatch() ile kurulur.

    // FLTFirebaseAuthPlugin — pluginConstantsForFIRApp: nil app ile çağrılırsa Auth.auth(app:) crash’ı önle.
    Class authPlugin = NSClassFromString(@"FLTFirebaseAuthPlugin");
    if (authPlugin) {
        SEL selConstants = NSSelectorFromString(@"pluginConstantsForFIRApp:");
        Method mConstants = class_getInstanceMethod(authPlugin, selConstants);
        if (mConstants) {
            original_pluginConstantsForFIRApp_imp = method_getImplementation(mConstants);
            if (original_pluginConstantsForFIRApp_imp) {
                method_setImplementation(mConstants, (IMP)SafeFLTFirebaseAuthPlugin_pluginConstantsForFIRApp);
            }
        }
    }
}

void FirebaseConfigureFromPlistIfNeeded(void) {
    if ([FIRApp defaultApp] != nil) return;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    if (!path || path.length == 0) return;
    FIROptions *options = [[FIROptions alloc] initWithContentsOfFile:path];
    if (!options) return;
    [FIRApp configureWithOptions:options];
}

__attribute__((constructor(101)))
static void FirebaseConfigureGuardInstallEarly(void) {
    // Disabled: historical swizzle guard caused unstable Firebase init on recent iOS/Flutter.
}
