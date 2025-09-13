# Firebase Console Konfigürasyon Rehberi

Bu doküman, Linkup uygulaması için Firebase Console'da yapılması gereken konfigürasyonları açıklamaktadır.

## 1. Firebase Authentication Setup

### Google Sign-In Aktivasyonu

1. **Firebase Console** → **Authentication** → **Sign-in method** bölümüne gidin
2. **Google** provider'ını seçin
3. **Enable** butonuna tıklayın
4. **Project support email** alanını doldurun (proje sahibinin email'i)
5. **Web SDK configuration** için:
   - **Web client ID** otomatik oluşturulacak
   - Bu ID Android ve iOS konfigürasyonunda kullanılacak

### Facebook Sign-In Aktivasyonu

1. **Firebase Console** → **Authentication** → **Sign-in method** bölümüne gidin
2. **Facebook** provider'ını seçin
3. **Enable** butonuna tıklayın
4. Facebook Developer Console'dan alınacak bilgiler:
   - **App ID**: Facebook uygulamanızın ID'si
   - **App secret**: Facebook uygulamanızın secret key'i

#### Facebook Developer Console Konfigürasyonu

1. [Facebook Developers](https://developers.facebook.com/) sitesine gidin
2. **My Apps** → **Create App** → **Consumer** seçin
3. Uygulama adını girin: "Linkup"
4. **Add Product** → **Facebook Login** ekleyin
5. **Settings** → **Basic** bölümünde:
   - **App Domains**: Firebase hosting domain'inizi ekleyin
   - **Privacy Policy URL**: Gizlilik politika URL'inizi ekleyin
   - **Terms of Service URL**: Kullanım şartları URL'inizi ekleyin

6. **Facebook Login** → **Settings** bölümünde:
   - **Valid OAuth Redirect URIs** ekleyin:
     ```
     https://linkup-project.firebaseapp.com/__/auth/handler
     ```
   - **Use Strict Mode for Redirect URIs**: Enable

## 2. Android Konfigürasyonu

### google-services.json Güncellemesi

1. Firebase Console → **Project Settings** → **Your apps** → Android app
2. **google-services.json** dosyasını indirin
3. `android/app/google-services.json` dosyasını güncelleyin

### Google Sign-In Android Konfigürasyonu

1. `android/app/build.gradle` dosyasında dependencies kontrol edin:
   ```gradle
   implementation 'com.google.android.gms:play-services-auth:20.7.0'
   ```

### Facebook Android Konfigürasyonu

1. `android/app/src/main/res/values/strings.xml` dosyasına ekleyin:
   ```xml
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
   ```

2. `android/app/src/main/AndroidManifest.xml` dosyasına ekleyin:
   ```xml
   <application android:label="linkup_app" ...>
       ...
       <!-- Facebook Configuration -->
       <meta-data android:name="com.facebook.sdk.ApplicationId" 
                  android:value="@string/facebook_app_id"/>
       
       <activity android:name="com.facebook.FacebookActivity"
                 android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
                 android:label="@string/app_name" />
       
       <activity android:name="com.facebook.CustomTabActivity"
                 android:exported="true">
           <intent-filter>
               <action android:name="android.intent.action.VIEW" />
               <category android:name="android.intent.category.DEFAULT" />
               <category android:name="android.intent.category.BROWSABLE" />
               <data android:scheme="@string/fb_login_protocol_scheme" />
           </intent-filter>
       </activity>
   </application>
   ```

## 3. iOS Konfigürasyonu

### GoogleService-Info.plist Güncellemesi

1. Firebase Console → **Project Settings** → **Your apps** → iOS app
2. **GoogleService-Info.plist** dosyasını indirin
3. `ios/Runner/GoogleService-Info.plist` dosyasını güncelleyin

### Google Sign-In iOS Konfigürasyonu

1. `ios/Runner/Info.plist` dosyasına ekleyin:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>BUNDLE_ID</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```
   
   **REVERSED_CLIENT_ID**: GoogleService-Info.plist dosyasından alın

### Facebook iOS Konfigürasyonu

1. `ios/Runner/Info.plist` dosyasına ekleyin:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>fbYOUR_FACEBOOK_APP_ID</string>
           </array>
       </dict>
   </array>
   
   <key>FacebookAppID</key>
   <string>YOUR_FACEBOOK_APP_ID</string>
   <key>FacebookDisplayName</key>
   <string>Linkup</string>
   ```

## 4. Web Konfigürasyonu

### Firebase Web Config

`web/index.html` dosyasında Firebase config'in güncel olduğundan emin olun:

```html
<script type="module">
  import { initializeApp } from "https://www.gstatic.com/firebasejs/10.0.0/firebase-app.js";
  
  const firebaseConfig = {
    // Firebase console'dan alınacak config
  };
  
  initializeApp(firebaseConfig);
</script>
```

## 5. Firestore Security Rules

Authentication ile ilgili Firestore kuralları:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı profilleri - sadece kendi profilini okuyabilir/yazabilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Kullanıcı rozetleri - sadece kendi rozetlerini okuyabilir
    match /user_badges/{document} {
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      allow write: if false; // Sadece server tarafından yazılır
    }
    
    // Rozetler - herkes okuyabilir
    match /badges/{badgeId} {
      allow read: if true;
      allow write: if false; // Sadece admin
    }
    
    // Etkinlikler
    match /events/{eventId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                            request.auth.uid == resource.data.organizerId;
    }
  }
}
```

## 6. Test Adımları

### Development Environment

1. **Test Accounts** oluşturun:
   - Google test hesabı
   - Facebook test hesabı

2. **Console Logs** kontrol edin:
   ```bash
   flutter run --debug
   ```

3. **Firebase Console** → **Authentication** → **Users** bölümünde kullanıcıların oluşturulduğunu kontrol edin

### Production Environment

1. **App Store/Play Store** kayıt bilgilerini Facebook/Google Developer Console'a ekleyin
2. **Production domain** adreslerini OAuth redirect URL'lerine ekleyin
3. **Rate limiting** ve **quota** ayarlarını kontrol edin

## 7. Güvenlik Önerileri

1. **API Keys** güvenli şekilde saklayın
2. **OAuth Redirect URLs** sadece güvenli domain'lere yönlendirin
3. **App secrets** asla client kodda saklayın
4. **Firebase Security Rules** düzenli olarak gözden geçirin
5. **Authentication logs** düzenli olarak kontrol edin

## 8. Troubleshooting

### Sık Karşılaşılan Hatalar

1. **"PlatformException(sign_in_failed)"**
   - google-services.json/GoogleService-Info.plist güncel mi kontrol edin
   - SHA-1 fingerprint doğru mu kontrol edin

2. **"FacebookException: Invalid key hash"**
   - Key hash'i yeniden oluşturun ve Facebook Developer Console'a ekleyin

3. **"FirebaseAuthException: account-exists-with-different-credential"**
   - Hesap linking özelliğini kullanın
   - Kullanıcıya mevcut hesapla bağlama seçeneği sunun

### Debug Komutları

```bash
# Android SHA-1 alma
cd android && ./gradlew signingReport

# iOS bundle ID kontrol
cd ios && cat Runner.xcodeproj/project.pbxproj | grep PRODUCT_BUNDLE_IDENTIFIER

# Key hash oluşturma (Facebook)
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
```

## İletişim

Bu konfigürasyonlar sırasında herhangi bir sorun yaşarsanız, lütfen development ekibi ile iletişime geçin.