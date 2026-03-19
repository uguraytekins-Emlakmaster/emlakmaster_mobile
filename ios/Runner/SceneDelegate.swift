import Flutter
import UIKit

/// UIScene yaşam döngüsü (iOS 26+ hazırlığı). GSI swizzle yeniden denemesi burada.
final class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    FirebaseConfigureGuardRetryGoogleSignInPatch()
  }
}
