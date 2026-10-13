/// App categories used to group installed apps in the picker — the same
/// grouping (and order) people know from iOS Screen Time.
enum AppCategory {
  social('social', '💬'),
  games('games', '🚀'),
  entertainment('entertainment', '🍿'),
  utilities('utilities', '🧮'),
  creativity('creativity', '🎨'),
  productivity('productivity', '📨'),
  shoppingFood('shopping_food', '🛍️'),
  education('education', '🌍'),
  travel('travel', '🏝️'),
  health('health', '🚲'),
  reading('reading', '📖'),
  other('other', '📱');

  const AppCategory(this.id, this.emoji);

  final String id;
  final String emoji;

  String get translationKey => 'app_category_$id';

  static AppCategory byId(String id) => values.firstWhere((category) => category.id == id, orElse: () => other);

  /// Maps Android's `ApplicationInfo.category` (API 26+) to our groups.
  /// −1 undefined · 0 game · 1 audio · 2 video · 3 image · 4 social · 5 news
  /// · 6 maps · 7 productivity · 8 accessibility.
  static AppCategory fromAndroid(int category, String packageName) {
    final known = _knownPackages[packageName];
    if (known != null) return known;
    return switch (category) {
      0 => games,
      1 || 2 => entertainment,
      3 => creativity,
      4 => social,
      5 => reading,
      6 => travel,
      7 => productivity,
      8 => utilities,
      _ => _guessFromPackage(packageName),
    };
  }

  /// Many apps don't declare a category: popular ones are mapped explicitly.
  static const Map<String, AppCategory> _knownPackages = {
    'com.zhiliaoapp.musically': social,
    'com.ss.android.ugc.trill': social,
    'com.instagram.android': social,
    'com.instagram.barcelona': social,
    'com.twitter.android': social,
    'com.snapchat.android': social,
    'com.facebook.katana': social,
    'com.facebook.lite': social,
    'com.facebook.orca': social,
    'com.whatsapp': social,
    'com.whatsapp.w4b': social,
    'org.telegram.messenger': social,
    'com.reddit.frontpage': social,
    'com.pinterest': social,
    'com.discord': social,
    'com.linkedin.android': social,
    'com.google.android.youtube': entertainment,
    'tv.twitch.android.app': entertainment,
    'com.netflix.mediaclient': entertainment,
    'com.spotify.music': entertainment,
    'com.amazon.avod.thirdpartyclient': entertainment,
    'com.disney.disneyplus': entertainment,
    'com.anghami': entertainment,
    'com.shahid.app': entertainment,
    'com.amazon.mShop.android.shopping': shoppingFood,
    'com.talabat': shoppingFood,
    'com.noon.buyerapp': shoppingFood,
    'com.alibaba.aliexpresshd': shoppingFood,
    'com.einnovation.temu': shoppingFood,
    'com.zzkko': shoppingFood,
    'com.ubercab.eats': shoppingFood,
    'com.duolingo': education,
    'com.google.android.apps.classroom': education,
    'com.ubercab': travel,
    'com.booking': travel,
    'com.airbnb.android': travel,
    'com.google.android.apps.fitness': health,
    'com.strava': health,
    'com.amazon.kindle': reading,
    'com.google.android.apps.magazines': reading,
    'com.canva.editor': creativity,
    'com.adobe.lrmobile': creativity,
    'com.google.android.calculator': utilities,
    'com.android.chrome': utilities,
    'com.google.android.gm': productivity,
    'com.microsoft.office.outlook': productivity,
  };

  static AppCategory _guessFromPackage(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('game') || name.contains('.games.') || name.contains('supercell') || name.contains('king.')) {
      return games;
    }
    if (name.contains('calculator') || name.contains('clock') || name.contains('camera') || name.contains('files')) {
      return utilities;
    }
    return other;
  }
}
