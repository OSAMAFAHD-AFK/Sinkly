# حجب التطبيقات على iPhone — خطوات Xcode (مرة واحدة على Mac)

كل الكود جاهز في المستودع. هذه الخطوات تُنشئ "أهداف" الإضافات الثلاث في Xcode (لا يمكن إنشاؤها من Windows) وتربطها بالملفات الجاهزة.

| المجلد | الوظيفة |
|---|---|
| `ios/Shared/` | قاعدة القفل (`SinklyLockEngine.swift`) + التخزين المشترك والحجب والجدولة (`SinklyBlockingCore.swift`). **مضافة مسبقاً لهدف Runner.** |
| `ios/SinklyMonitorExtension/` | يستيقظ في موعد الوجبة والتطبيق مغلق، ويطبّق الحجب |
| `ios/SinklyShieldConfiguration/` | شكل شاشة الحجب (ألوان Sinkly + البطلة + النصوص بلغة التطبيق) |
| `ios/SinklyShieldAction/` | زر "نظّف الحوض" في شاشة الحجب (إشعار يفتح شاشة القفل الكاملة في Sinkly) |
| `ios/RunnerTests/SinklyLockEngineTests.swift` | نفس حالات الاختبار المشتركة مع Dart وKotlin |

---

## 1) Apple Developer (مرة واحدة)
1. في **Certificates, Identifiers & Profiles → Identifiers** أنشئ App Group: `group.com.sinkly.app`.
2. أنشئ App IDs للإضافات (أو اتركها لـ Xcode مع Automatic Signing):
   - `com.sinkly.app.MonitorExtension`
   - `com.sinkly.app.ShieldConfiguration`
   - `com.sinkly.app.ShieldAction`
3. فعّل لكل App ID (الرئيسي + الثلاثة): **Family Controls** و **App Groups** (اختر المجموعة أعلاه).
4. موافقة Apple على Family Controls للتوزيع يجب أن تشمل **كل** Bundle ID من الأربعة. إن كانت موافقتك للتطبيق الرئيسي فقط، اطلب إضافة الثلاثة: developer.apple.com/contact/request/family-controls-distribution

## 2) إنشاء الأهداف في Xcode
افتح `ios/Runner.xcworkspace` ثم لكل إضافة: **File → New → Target…**

| القالب (Template) | Product Name | Bundle Identifier |
|---|---|---|
| Device Activity Monitor Extension | `SinklyMonitorExtension` | `com.sinkly.app.MonitorExtension` |
| Shield Configuration Extension | `SinklyShieldConfiguration` | `com.sinkly.app.ShieldConfiguration` |
| Shield Action Extension | `SinklyShieldAction` | `com.sinkly.app.ShieldAction` |

- Language: Swift. إن سأل "Activate scheme?" اختر **Cancel** (نبقى على Runner).
- **Embed in Application: Runner** (افتراضي).

## 3) استبدال الملفات المولّدة بملفاتنا
Xcode يولّد لكل هدف ملف Swift وInfo.plist داخل مجلد بنفس الاسم — وهو نفس مجلدنا:
1. احذف ملف Swift الذي ولّده Xcode (Move to Trash) **إن لم يكن ملفنا**، ثم اسحب ملفنا من Finder إلى المجموعة مع تحديد الهدف الصحيح فقط:
   - `SinklyMonitorExtension/DeviceActivityMonitorExtension.swift`
   - `SinklyShieldConfiguration/ShieldConfigurationExtension.swift` + `lock_heroine.png` (هدف ShieldConfiguration)
   - `SinklyShieldAction/ShieldActionExtension.swift`
2. Info.plist: استخدم ملفاتنا (فيها NSExtensionPointIdentifier واسم الكلاس الصحيح). في **Build Settings → Info.plist File** لكل هدف: `SinklyMonitorExtension/Info.plist` … إلخ.
3. Entitlements: في **Build Settings → Code Signing Entitlements** لكل هدف: `SinklyMonitorExtension/SinklyMonitorExtension.entitlements` … إلخ.

## 4) الملفات المشتركة
حدد `ios/Shared/SinklyLockEngine.swift` و`SinklyBlockingCore.swift` ← **File Inspector → Target Membership**: فعّل **Runner + الإضافات الثلاث**.

## 5) Signing & Capabilities
لكل هدف من الأربعة (Runner + 3):
- **Signing**: Automatic، نفس الـ Team.
- **+ Capability → Family Controls** و **+ Capability → App Groups** ← `group.com.sinkly.app`.
- **Deployment Target**: iOS 16.0 أو أعلى (نفس Runner).

## 6) التجربة
- **الحجب لا يعمل على المحاكي** (Simulator) — Apple لا تشغّل Screen Time فيه. المحاكي يصلح فقط لاختبار `SinklyLockEngineTests` والواجهة.
- على **iPhone حقيقي** (بحساب المطوّر يكفي للتجربة؛ TestFlight يحتاج موافقة التوزيع):
  1. أكمل الإعداد في التطبيق: اختيار التطبيقات + إذن Screen Time.
  2. من تبويب الخطة: **"جرّب القفل الآن"** ← افتح تطبيقاً محجوباً ← يجب أن تظهر شاشة Sinkly الثابتة (البطلة + "نظّف الحوض")، بنفس نصوص Android.
  3. اضغط "نظّف الحوض" ← إشعار ← اضغطه ← يفتح Sinkly على شاشة القفل الكاملة (المتحركة).
  4. صوّر الحوض ← يجب أن يُرفع الحجب فوراً.
  5. جرّب موعد وجبة بعد دقيقتين والتطبيق مغلق تماماً.
- اختبارات القاعدة: `Product → Test` على Runner (تشغّل `SinklyLockEngineTests`).

## نقاط تحتاج تحققاً على جهاز حقيقي (لم تُجرَّب بعد)
- عدد الجداول المسموح (نستخدم نافذة متجددة من 14 موعداً، تتجدد عند كل قفل وكل فتح للتطبيق).
- دقة توقيت iOS في إطلاق `intervalDidStart` (يحددها النظام).
- إشعار زر الشاشة يحتاج إذن الإشعارات للتطبيق (يُطلب في مرحلة الإشعارات). بدونه يفتح المستخدم Sinkly يدوياً فتظهر شاشة القفل الكاملة.
