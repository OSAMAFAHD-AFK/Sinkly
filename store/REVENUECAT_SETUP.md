# ربط الاشتراكات: RevenueCat + المتجران

الكود مربوط الآن بمشروعك في RevenueCat عبر **Test Store** (شراء تجريبي من RevenueCat نفسه، بدون Apple أو Google).
المتبقي لاحقًا: ربط App Store و Google Play داخل RevenueCat، ثم استبدال المفتاح.

> 🔒 **لا ترسل لأحد ولا تضع في الكود:** ملف ‎`.p8` من Apple، ملف JSON لحساب خدمة Google، مفتاح RevenueCat السري (`sk_…`). هذه تُرفع مباشرة في RevenueCat / Supabase.

---

## المعرّفات التي يعتمد عليها الكود (مطابقة لمشروعك الآن)

| الشيء | القيمة |
|---|---|
| Bundle ID / Package | `com.sinkly.app` |
| Entitlement | `sinkly_premium` (التطبيق + خادم فحص الصورة) |
| المنتج الأسبوعي | `weekly` |
| المنتج السنوي | `annual` |
| عرض الخروج (السنوي المخفّض) | `annual_special` |
| Offering الرئيسي (Current) | `default` |
| حزم `default` | `$rc_weekly` ← `weekly` · `$rc_annual` ← `annual` · `custom_annual_special` ← `annual_special` |
| Placements (اختيارية، للتجارب لاحقًا) | `onboarding_paywall` · `settings_upgrade` · `paywall_exit_offer` |

كيف يقرأ الكود هذا الترتيب:
- **شاشة الدفع:** تعرض الأسبوعي والسنوي فقط (تخفي `annual_special` تلقائيًا).
- **عرض الخروج (زر X):** يعرض `annual_special` فقط، ويحسب نسبة الخصم مقارنة بالسنوي العادي.
- يعمل أيضًا لو نقلت `annual_special` لاحقًا إلى Offering مستقل اسمه `exit_offer`.
- المطابقة بنوع الحزمة واسمها، فلا تحتاج تغيير الكود عند إضافة منتجات Apple و Google.

تم التحقق (20 أكتوبر 2026) من لوحة مشروعك: الـ Offering `default` موجود بالحزم الثلاث، والمنتجات الثلاثة كلها تفتح `sinkly_premium`.

---

## 0) كيف يختار الكود المفتاح (جاهز)
- **نسخ Debug** (`flutter run`): مفتاح Test Store `test_…`. الشراء يُظهر نافذة RevenueCat التجريبية (نجاح / فشل / إلغاء) بدون دفع.
- **نسخ Release** (APK / AAB / App Store): المفتاحان الحقيقيان `appl_…` و `goog_…` تلقائيًا. مكتبة RevenueCat ترفض مفتاح `test_…` في Release أصلًا، فلا يمكن أن يصل Premium مجاني للمستخدمين.
- المفاتيح في `lib/core/utils/app_constants.dart`.
- نتيجة ذلك: نسخة Release لا تُظهر الخطط إلا بعد أن تكون منتجات المتجر منشأة ومربوطة في RevenueCat (الخطوات 1 إلى 3). قبل ذلك جرّب الدفع بنسخة Debug.
- الأسعار ومدة التجربة في Debug هي ما ضبطته لمنتجات Test Store في لوحة RevenueCat.

## 1) App Store Connect (لاحقًا)
1. **Apps → Sinkly → Monetization → Subscriptions** ← Subscription Group باسم `Sinkly Premium`.
2. أنشئ 3 اشتراكات: `weekly` (1 Week) · `annual` (1 Year) · `annual_special` (1 Year).
3. لكل اشتراك: **Prices** (السعر الأمريكي، Apple تحسب الباقي) · **Localization** (عربي + إنجليزي) · **Review Information** (لقطة شاشة الدفع + سطر: "Unlocks meal-linked app locking and photo-verified unlocking.").
4. التجربة المجانية: **Introductory Offers → +** ← كل الدول ← Free ← 3 Days (على `annual` و `annual_special`).
5. **Users and Access → Integrations → In-App Purchase → Generate**: نزّل `.p8` (مرة واحدة فقط!) وسجّل **Key ID** و **Issuer ID**.
6. **Users and Access → Sandbox → Test Accounts → +**: حساب اختبار.
7. بعد إضافة التطبيق في RevenueCat: **App Information → App Store Server Notifications** ← رابط RevenueCat في Production و Sandbox (Version 2).

## 2) Google Play Console (لاحقًا)
1. ارفع أول نسخة إلى **Testing → Internal testing** (`flutter build appbundle` ← `build/app/outputs/bundle/release/app-release.aab`). Google لا يسمح بإنشاء الاشتراكات قبل ذلك.
2. **Monetize → Products → Subscriptions → Create**: `weekly` · `annual` · `annual_special`، لكل واحد Base plan (Weekly / Yearly / Yearly، auto-renewing) ← السعر ← **Activate**.
3. التجربة: داخل الخطة **Add offer** ← Eligibility: **New customer acquisition** ← Free trial 3 days ← Activate.
4. حساب خدمة لـ RevenueCat: دليل RevenueCat "Google Play: Creating Service Account Credentials" (قد يستغرق التفعيل حتى 36 ساعة).
5. **Monetization setup → Real-time developer notifications**: الـ Topic الذي يعطيك إياه RevenueCat.
6. **Setup → License testing**: أضف بريد Gmail الذي ستختبر به.

## 3) RevenueCat (لاحقًا، بعد 1 و 2)
1. **Apps**: أضف **App Store** (Bundle `com.sinkly.app` + `.p8`) و **Play Store** (Package `com.sinkly.app` + JSON حساب الخدمة).
2. **Products**: استورد منتجات كل متجر (3 لكل متجر).
3. **Entitlements → `sinkly_premium`**: اربط به المنتجات الجديدة أيضًا.
4. **Offerings → `default`**: داخل كل حزمة أضف منتج كل متجر بجانب منتج Test Store:
   `$rc_weekly` ← weekly · `$rc_annual` ← annual · `custom_annual_special` ← annual_special.
5. **Customer Center** (Tools → Customer Center): فعّله واضبط بريد الدعم `osamadeveloper0@gmail.com`. هو ما يفتح من الإعدادات ← «إدارة الاشتراك» (تفاصيل الخطة، الإلغاء، الاستعادة، طلب استرداد على iPhone). إن لم يكن متاحًا يفتح التطبيق صفحة اشتراكات المتجر تلقائيًا.
6. **Project settings → API keys**: انسخ `appl_…` و `goog_…`.
7. أنشئ **Secret API key** (`sk_…`) ونفّذ بنفسك في مجلد المشروع:
   ```
   npx supabase secrets set REVENUECAT_SECRET_KEY=sk_...
   ```
   من هذه اللحظة لا يفحص صور الحوض إلا المشتركون.

## 4) قبل الإرسال للمراجعة (إلزامي)
1. تأكد أن Customer Center مفعّل وأن مفتاح الخادم `REVENUECAT_SECRET_KEY` موضوع، وأن `verify-sink-photo` منشورة:
   ```
   npx supabase functions deploy verify-sink-photo
   ```
2. جرّب ببيئة الاختبار: شراء ← استعادة ← إلغاء أثناء التجربة ← انتهاء التجربة ← فشل الدفع ← «إدارة الاشتراك».

## ماذا يحدث تلقائيًا في الكود
- الأسعار بعملة كل بلد تأتي من المتجر (لا أرقام ثابتة)، ونسب التوفير تُحسب منها.
- التجربة تظهر فقط لمن يستحقها (iPhone يتحقق، Google لا يعرضها لغير المستحق).
- كل تغيير في الاشتراك (تجديد، إلغاء، استرداد، انتهاء) يصل التطبيق فورًا ويحدّث القفل.
- تذكير محلي قبل الخصم بيوم، يُلغى تلقائيًا إذا ألغى المستخدم.
- انتهاء الاشتراك يوقف القفل ويحتفظ بالخطة.
- شاشة الدفع تبقى تصميمنا الخاص (قرار المنتج)؛ RevenueCat يوفّر المنتجات والشراء والإحصاءات فقط.
