# إجابات نماذج المتجرين + ملاحظات المراجعة

الروابط (بعد تفعيل الموقع):
- سياسة الخصوصية: `https://sinkly.osamafahd.com/privacy/`
- شروط الاستخدام: `https://sinkly.osamafahd.com/terms/`
- الدعم: `https://sinkly.osamafahd.com/support/`
- بريد الدعم: `osamadeveloper0@gmail.com`

---

## Apple — App Privacy (App Store Connect → App Privacy)

**Do you or your third-party partners collect data from this app?** → **Yes**

| نوع البيانات (Apple) | مُجمَّعة؟ | الغرض | مرتبطة بهوية المستخدم؟ | تتبّع (Tracking)؟ |
|---|---|---|---|---|
| Photos or Videos → **Photos** | نعم (صورة الحوض تُرسل للفحص) | App Functionality | No | No |
| Purchases → **Purchase History** | نعم (RevenueCat) | App Functionality | No | No |
| Identifiers → **User ID** | نعم (معرّف مجهول) | App Functionality | No | No |
| User Content → **Other User Content** | نعم (نص الاقتراحات فقط) | App Functionality | No | No |
| Diagnostics → **Crash Data** | نعم (Crashlytics) | App Functionality | No | No |

- لا Contact Info، لا Location، لا Browsing History، لا Usage Data (قفل iPhone يتم عبر Screen Time من Apple ولا يرسل شيئًا).
- **Tracking: No** ← لا حاجة لنافذة App Tracking Transparency.
- Privacy Policy URL: رابط الخصوصية أعلاه. وفي وصف التطبيق أضف سطرًا: `Terms of Use: https://sinkly.osamafahd.com/terms/`

## Google Play — Data safety (App content → Data safety)

- **Does your app collect or share any of the required user data types?** → Yes
- **Is all of the user data collected by your app encrypted in transit?** → Yes
- **Do you provide a way for users to request that their data is deleted?** → Yes (رابط الدعم: `https://sinkly.osamafahd.com/support/`)

| الفئة → النوع | Collected | Shared | Processed ephemerally | Required/Optional | الغرض |
|---|---|---|---|---|---|
| Photos and videos → **Photos** | Yes | No* | **Yes** | Required | App functionality |
| Financial info → **Purchase history** | Yes | No* | No | Required | App functionality |
| App activity → **Other user-generated content** | Yes | No | No | Optional | App functionality |
| App info and performance → **Crash logs** | Yes | No* | No | Required | Analytics |
| App info and performance → **Diagnostics** | Yes | No* | No | Required | Analytics |
| Device or other IDs | Yes | No* | No | Required | App functionality, Fraud prevention |

\* المعالجة عند مزوّدي الخدمة (Google Gemini، RevenueCat، Firebase، Supabase) لا تُعدّ "Sharing" في تعريف Google.

- **App activity → Installed apps / App interactions**: **لا تختر** — قائمة التطبيقات ومعرفة التطبيق المفتوح تبقى على الهاتف ولا تُرسل.

## Google Play — أذونات تحتاج تصريحًا (App content)

**Foreground service permissions** → النوع: **Special use**
> Sinkly keeps the meal-time app-lock plan that the user sets up. While a lock is active, a foreground service detects when one of the apps the user chose to lock comes to the foreground and immediately shows Sinkly's lock screen over it, until the user completes their task (a photo of a clean sink). The user starts this by choosing apps and meal times, sees an ongoing notification ("Sinkly is keeping your plan"), and can change or stop the plan at any time. Without a foreground service Android stops the check and the user's lock plan stops working.

- **فيديو** (مطلوب): سجّل شاشة جوالك 30–60 ثانية: اختيار تطبيق في الخطة ← "جرّب القفل الآن" ← فتح التطبيق المقفل ← ظهور شاشة القفل ← "نظّف الحوض". ارفعه على YouTube كـ Unlisted وضع الرابط.

**SYSTEM_ALERT_WINDOW / Usage access**: لا يوجد نموذج خاص، لكن شاشة الإذن في التطبيق تشرح السبب قبل فتح الإعدادات (موجودة).

## ملاحظات المراجعة — Apple (App Review Information → Notes)
```
Sinkly helps users stop avoiding the dishes: after the meal times they choose, it locks the apps they picked (Screen Time / FamilyControls, .individual authorization) and unlocks them when a photo of a clean kitchen sink is verified.

How to test:
1. Complete onboarding, allow Screen Time, pick any app (e.g. Safari).
2. Start the free trial (sandbox).
3. Plan tab → "Test the lock now", then open the picked app: the Sinkly shield appears.
4. Tap "Clean my sink" → a notification opens Sinkly's lock screen → start the sprint → take a photo of a clean sink to unlock.
A demo video is attached: <YouTube unlisted link>.

FamilyControls is used only to shield apps the user selects themselves; we never read app usage or content.
```

## ملاحظات المراجعة — Google (App access)
```
All features require a subscription with a 3-day free trial. Reviewers can start the trial with a test account.
To try the lock: Plan tab → "Test the lock now", open a locked app → Sinkly's lock screen appears → "Clean my sink" → take a photo of a clean sink.
Demo video: <YouTube unlisted link>
```

## صفحة المتجر
- **App name:** Sinkly
- **Subtitle (Apple, 30 حرفًا):** `Clean sink. Clear mind.`
- **Category:** Productivity (ثانوي: Lifestyle)
- **Age rating:** 4+ / Everyone (لا محتوى حساس)
- **Support URL / Marketing URL:** روابط الموقع أعلاه
