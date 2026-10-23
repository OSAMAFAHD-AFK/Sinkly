# ربط الاشتراكات: RevenueCat + المتجران

الحالة (22 أكتوبر 2026): الربط مكتمل في RevenueCat و App Store Connect و Google Play Console، ومتحقَّق منه بالمفاتيح الحقيقية.
المتبقي: اختبار شراء حقيقي على جهاز (Google: Internal testing، Apple: بناء iOS + Sandbox) — انظر آخر الملف.

> 🔒 **لا ترسل لأحد ولا تضع في الكود:** ملفات ‎`.p8` من Apple، ملف JSON لحساب خدمة Google، مفتاح RevenueCat السري (`sk_…`). هذه تُرفع مباشرة في RevenueCat / Supabase.

---

## المعرّفات (مطابقة للوحات الآن)

| الشيء | القيمة |
|---|---|
| Bundle ID / Package | `com.sinkly.app` |
| Entitlement | `sinkly_premium` (التطبيق + خادم فحص الصورة) |
| Offering الرئيسي (Current) | `default` |
| مجموعة اشتراكات Apple | `Sinkly Premium` |

| الخطة | الحزمة في `default` | App Store | Google Play (منتج:خطة أساسية) | Test Store |
|---|---|---|---|---|
| أسبوعي | `$rc_weekly` | `sinkly_premium_weekly` | `sinkly_premium_weekly:weekly` | `weekly` |
| سنوي | `$rc_annual` | `sinkly_premium_annual` | `sinkly_premium_annual:annual` | `annual` |
| عرض الخروج (سنوي مخفّض) | `custom_annual_special` | `sinkly_premium_annual_special` | `sinkly_premium_annual_special:annual-special` | `annual_special` |

- التجربة المجانية: **3 أيام، مرة واحدة لكل مستخدم**، على الخطط الثلاث.
  - Apple: Introductory Offer «Free for the first 3 days» في الدول الـ175 (مرة واحدة لكل Apple ID داخل المجموعة).
  - Google: عرض `free-trial-3d` لكل خطة أساسية، الأهلية: «لم يحصل مطلقًا على أي اشتراك».
- Placements (اختيارية، للتجارب لاحقًا): `onboarding_paywall` · `settings_upgrade` · `paywall_exit_offer`.

كيف يقرأ الكود هذا الترتيب:
- **شاشة الدفع:** الأسبوعي والسنوي فقط (تخفي عرض الخروج تلقائيًا).
- **عرض الخروج (زر X):** السنوي المخفّض فقط، ونسبة الخصم محسوبة من السعر الحقيقي للسنوي.
- التعرّف على عرض الخروج بالحزمة `custom_annual_special` أو بمعرّف المنتج (`AppConstants.exitOfferProductIds`).
- يعمل أيضًا لو نُقل عرض الخروج لاحقًا إلى Offering مستقل اسمه `exit_offer`.

## المفاتيح (`lib/core/utils/app_constants.dart`)
- **Debug** (`flutter run`): مفتاح Test Store `test_…` ← نافذة شراء تجريبية من RevenueCat (نجاح / فشل / إلغاء) بلا دفع.
- **Release** (APK / AAB / App Store): `appl_…` و `goog_…` تلقائيًا. مكتبة RevenueCat ترفض `test_…` في Release، فلا يصل Premium مجاني للمستخدمين.

---

## ما تم ضبطه

### App Store Connect
- [x] Paid Apps Agreement (النسخة الجديدة، 22 أكتوبر 2026) + الحساب البنكي + النماذج الضريبية: Active.
- [x] Small Business Program: مقبول (بريد Apple، 25 سبتمبر 2026) ← عمولة 15%.
- [x] المجموعة `Sinkly Premium` + اسم العرض (English U.S.).
- [x] 3 اشتراكات بالأسعار + الاسم والوصف + Review Information (لقطات: `store/app_store/iap_review_paywall.png` و `iap_review_exit_offer.png`) ← Ready to Submit.
- [x] Introductory Offer: مجاني 3 أيام على الثلاثة.
- [x] Billing Grace Period: Production and Sandbox، All Renewals.
- [x] App Store Server Notifications ← رابط RevenueCat (Production + Sandbox).
- [ ] **إرسال الاشتراكات للمراجعة مع أول نسخة iOS** (Apple تشترط ذلك لأول مجموعة).

### Google Play Console
- [x] نسخة مرفوعة (لفتح قسم الاشتراكات).
- [x] 3 اشتراكات، خطط أساسية نشطة في 175 بلدًا، وعرض `free-trial-3d` نشط.
- [x] Real-time developer notifications ← Topic من RevenueCat (إشعار الاختبار وصل).
- [x] صلاحيات حساب الخدمة (RevenueCat: Valid credentials).
- [ ] **License testing:** بريدك وبريد كل مختبر (بدونه يدفع المختبر مالًا حقيقيًا).
- [ ] **Payments profile:** تأكد أنه مكتمل وفيه الحساب البنكي.

### RevenueCat
- [x] تطبيقا App Store و Play Store (بيانات اعتماد صالحة، مفتاح In-App Purchase، مفتاح App Store Connect API + Vendor number).
- [x] 9 منتجات (3 لكل متجر + Test Store) مرتبطة بـ `sinkly_premium`، والحزم الثلاث مربوطة لكل متجر.
- [x] «Track new purchases from server-to-server notifications» مفعّل للمتجرين، و App User ID مجهول.
- [x] Customer Center: الإعدادات الافتراضية، بريد الدعم `osamadeveloper0@gmail.com` لكل العملاء، بلا عروض خصم عند الإلغاء.
- [x] Secret API key في Supabase (`REVENUECAT_SECRET_KEY`) + دالة `verify-sink-photo` منشورة.
- [ ] **Billing:** أضف بطاقة قبل أن يتجاوز الإيراد الشهري 2,500$ (بعدها 1%).

---

## الاختبار الحقيقي (التالي)
1. **Android:** ثبّت النسخة من رابط Internal testing بحساب مضاف في License testing ← اشترِ ← افحص صورة حوض (يجب أن تمر) ← تأكد أن العميل ظهر في RevenueCat ← ألغِ من Google Play ← «استعادة».
2. **iPhone:** يحتاج بناء iOS سحابيًا (لا يوجد Mac) ← TestFlight / حساب Sandbox ← نفس الخطوات.
3. **قبل الإطلاق:** `npx supabase functions deploy verify-sink-photo` إن تغيّرت الدالة.

## ماذا يحدث تلقائيًا في الكود
- الأسعار بعملة كل بلد تأتي من المتجر، ونسب التوفير تُحسب منها.
- التجربة تظهر فقط لمن يستحقها (iPhone يسأل Apple، Google لا يعرضها لغير المستحق).
- كل تغيير في الاشتراك (تجديد، إلغاء، استرداد، انتهاء، فترة سماح) يصل التطبيق ويحدّث القفل.
- **دفع معلّق** (Google: نقدًا / عبر شركة الاتصالات…): رسالة «بانتظار تأكيد المتجر»؛ وبعد الموافقة يضغط المستخدم «استعادة» (أو يعيد فتح التطبيق) فيُفتح Premium. لا يتجاوز التطبيق شاشة الدفع وحده أبدًا: المرور بشراء أو استعادة فقط.
- فشل تحميل الخطط أو الشراء أو الاستعادة يُسجَّل في Crashlytics (إلغاء المستخدم والدفع المعلّق لا يُسجَّلان).
- تذكير «تجربتك تنتهي غدًا» قبل الخصم بيوم **دائمًا** (حتى لو أُطفئت «التذكيرات»؛ فقط إذن الإشعارات في الجوال يمنعه)، ويُلغى إذا ألغى المستخدم.
- انتهاء الاشتراك يوقف القفل ويحتفظ بالخطة.
- **جدار الدفع عند الفتح:** بعد الإعداد الأول، عند كل فتح للتطبيق (وعند الرجوع إليه من الخلفية على أحد التبويبات) يُسأل المتجر عبر RevenueCat:
  - نشط (ومنه التجربة وفترة السماح) ← الرئيسية.
  - غير نشط **ومؤكَّد** (رد حديث من المتجر) ← شاشة الدفع الإجبارية: X = عرض الخروج، و«استعادة» موجود؛ بعد الشراء أو الاستعادة ← الرئيسية ويستأنف القفل.
  - تعذّر التحقق (بلا إنترنت / عطل / تأخر أكثر من 4 ثوانٍ) ← آخر رد مؤكَّد محفوظ، وإن لم يوجد ← الرئيسية. لا يُمنع مشترك بسبب عطل.
  - السؤال يبدأ مع شاشة البداية، فلا يرى المشترك الجدار لحظةً ثم يختفي.
  - المستخدم الجديد بلا تغيير: الإعداد ثم الدفع.
- **عنوان شاشة الدفع:** «ابدأ تجربتك المجانية لمدة 3 أيام» فقط إن كان للخطة المختارة تجربة؛ وإلا «اشترك في Sinkly Premium» (بلا كلمة مجانًا)، والزر والسطر السفلي يتبعانها.
- شاشة الدفع تصميمنا الخاص (قرار المنتج)؛ RevenueCat يوفّر المنتجات والشراء والإحصاءات و Customer Center.
