# ربط الاشتراكات: المتجران + RevenueCat (المهمة الأخيرة)

الكود جاهز بالكامل. ما تحتاجه هو تعبئة لوحات التحكم بهذه **المعرّفات الحرفية** (الكود مبني عليها)، ثم وضع مفتاحين عامّين في التطبيق.

> 🔒 **لا ترسل لأحد ولا تضع في الكود:** ملف ‎`.p8` من Apple، ملف JSON لحساب خدمة Google، مفتاح RevenueCat السري (`sk_…`). هذه تُرفع مباشرة في RevenueCat / Supabase.

---

## المعرّفات التي يعتمد عليها الكود

| الشيء | القيمة |
|---|---|
| Bundle ID / Package | `com.sinkly.app` |
| Entitlement (مستوى الوصول) | `premium` |
| المنتج الأسبوعي | `sinkly_premium_weekly` |
| المنتج السنوي | `sinkly_premium_annual` |
| عرض الخروج السنوي المخفّض | `sinkly_premium_annual_special` |
| Offering الرئيسي (Current) | `default` ← حزمتا Weekly و Annual |
| Offering عرض الخروج | `exit_offer` ← حزمة Annual = المنتج المخفّض |
| Placements (اختيارية، للتجارب لاحقًا) | `onboarding_paywall` · `settings_upgrade` · `paywall_exit_offer` |

الأسعار المقترحة: أسبوعي 4.99$ · سنوي 39.99$ · عرض الخروج 29.99$ (25% أقل من السنوي). تجربة مجانية 3 أيام: أنصح بها على **السنوي وعرض الخروج فقط**. شاشة الدفع تتكيّف تلقائيًا: تعرض التجربة فقط للخطة التي تملكها فعلًا.

---

## 1) App Store Connect
1. **Apps → Sinkly → Monetization → Subscriptions** ← أنشئ Subscription Group باسم `Sinkly Premium`.
2. أنشئ الاشتراكات الثلاثة بالمعرّفات أعلاه (المدة: 1 Week / 1 Year / 1 Year).
3. لكل اشتراك:
   - **Subscription Prices**: اختر الولايات المتحدة بالسعر، وApple تحسب باقي الدول.
   - **Localization**: الاسم والوصف (عربي + إنجليزي على الأقل).
   - **Review Information**: لقطة شاشة لشاشة الدفع + سطر: "Unlocks meal-linked app locking and photo-verified unlocking."
4. التجربة المجانية: **Subscription Prices → Introductory Offers → +** ← كل الدول ← Free ← 3 Days ← بلا تاريخ انتهاء.
5. **Users and Access → Integrations → In-App Purchase → Generate**: نزّل ملف `.p8` (مرة واحدة فقط!) وسجّل **Key ID** و **Issuer ID**.
6. **Users and Access → Sandbox → Test Accounts → +**: حساب اختبار ببريد جديد.
7. (بعد الخطوة 3 في RevenueCat) **App Information → App Store Server Notifications**: ضع رابط RevenueCat في Production و Sandbox، اختر Version 2.
8. انسخ **Apple ID** الرقمي من App Information وأرسله لي (لرابط التقييم وصفحة الدعوة).

## 2) Google Play Console
1. ارفع أول نسخة إلى **Testing → Internal testing** (الأمر: `flutter build appbundle` ثم ارفع الملف من `build/app/outputs/bundle/release/app-release.aab`). Google لا يسمح بإنشاء الاشتراكات قبل ذلك.
2. **Monetize → Products → Subscriptions → Create** بالمعرّفات نفسها. لكل واحد Base plan:
   - `sinkly_premium_weekly` ← base plan `weekly` (Weekly, auto-renewing)
   - `sinkly_premium_annual` ← base plan `annual` (Yearly)
   - `sinkly_premium_annual_special` ← base plan `annual-special` (Yearly)
   - السعر بالدولار ← **Update prices** ← **Activate**.
3. التجربة: داخل الخطة **Add offer** ← `free-trial-3d` ← Eligibility: **New customer acquisition → Never had any subscription** ← Free trial 3 days ← Activate.
4. حساب الخدمة لـ RevenueCat: اتبع دليل RevenueCat "Google Play: Creating Service Account Credentials" (Google Cloud: فعّل Google Play Android Developer API و Google Play Developer Reporting API ← Service Account ← مفتاح JSON ← ادعُ بريده في Play Console بصلاحيات View app information · View financial data · Manage orders and subscriptions). قد يستغرق تفعيله حتى 36 ساعة.
5. **Monetize → Monetization setup → Real-time developer notifications**: ضع الـ Topic الذي يعطيك إياه RevenueCat.
6. **Setup → License testing**: أضف بريد Gmail الذي ستختبر به.

## 3) RevenueCat
1. أنشئ Project باسم Sinkly ← أضف تطبيقين:
   - **App Store**: Bundle ID `com.sinkly.app` ← ارفع `.p8` + Key ID + Issuer ID ← انسخ رابط Server Notifications إلى Apple.
   - **Play Store**: Package `com.sinkly.app` ← ارفع JSON حساب الخدمة ← Connect to Google (RTDN).
2. **Products**: استورد الستة (3 لكل متجر).
3. **Entitlements**: أنشئ `premium` واربط به المنتجات الستة.
4. **Offerings**:
   - `default` ← **Make current** ← حزمة `$rc_weekly` (الأسبوعي في المتجرين) + حزمة `$rc_annual` (السنوي في المتجرين).
   - `exit_offer` ← حزمة `$rc_annual` = `sinkly_premium_annual_special` في المتجرين.
5. **Project settings → API keys**: انسخ المفتاحين العامّين (`appl_…` و `goog_…`) وأرسلهما لي، أو ضعهما في:
   `lib/core/utils/app_constants.dart` → `revenueCatAppleApiKey` و `revenueCatGoogleApiKey`.
   (عامّان بطبيعتهما ويُشحنان داخل كل تطبيق.)
6. أنشئ **Secret API key** (`sk_…`) ونفّذ بنفسك في مجلد المشروع:
   ```
   npx supabase secrets set REVENUECAT_SECRET_KEY=sk_...
   ```
   من هذه اللحظة لا يفحص صور الحوض إلا المشتركون (ثغرة رصيد Gemini تُغلق).

## 4) قبل الإرسال للمراجعة
- في `app_constants.dart`: اجعل `devPaywallBypass = false` (زر "تخطّي الدفع · مطوّر").
- جرّب في بيئة الاختبار: شراء ← استعادة ← إلغاء أثناء التجربة ← انتهاء التجربة ← فشل الدفع.

## ماذا يحدث تلقائيًا في الكود
- الأسعار الحقيقية بعملة كل بلد تأتي من المتجر (لا أرقام ثابتة).
- التجربة تظهر فقط لمن يستحقها (iPhone يتحقق، Google لا يعرضها لغير المستحق).
- تذكير محلي قبل الخصم بيوم، يُلغى تلقائيًا إذا ألغى المستخدم.
- انتهاء الاشتراك يوقف القفل ويحتفظ بالخطة.
- الإعدادات: "إدارة الاشتراك" يفتح صفحة المتجر، و"استعادة" للهاتف الجديد.
