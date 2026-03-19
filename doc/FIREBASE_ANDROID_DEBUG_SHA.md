# Android debug SHA-1 (Firebase / Google Sign-In)

Bu makinede `./gradlew :app:signingReport` ile üretildi.

| Alan | Değer |
|------|--------|
| **Paket adı** | `com.example.emlakmaster_mobile` |
| **Debug SHA-1** | `85:1A:07:87:06:92:CD:72:DF:05:90:7F:44:86:6C:8E:22:BB:9B:FE` |
| **Debug SHA-256** | `F7:C4:7C:4A:E1:AF:A8:91:9D:44:DA:7B:C2:53:3A:8E:D6:5C:C7:82:50:FB:F3:44:37:AE:D6:FA:B2:A0:53:73` |

**Firebase:** Bu makinede `firebase apps:android:sha:create` ile debug SHA-1 zaten eklendi. Yeni bilgisayarda aynı SHA’yı Console’dan veya bu komutla ekleyin.

**Google Cloud Console:** APIs & Services → Credentials → Android OAuth client → aynı SHA-1.

Gradle tekrar çalıştırmak için (Homebrew OpenJDK 17):

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
cd android && ./gradlew :app:signingReport
```
