import 'package:firebase_admob/firebase_admob.dart';

class AdvertisementData {
  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      testDevices: <String>[],
      nonPersonalizedAds: true,
      keywords: <String>[
        'Men',
        'Fun',
        'Love',
        'Cool',
        'Enjoy',
        'Party',
        'Shoes'
      ]);
  BannerAd createBannerAd() {
    return BannerAd(
        adUnitId: 'ca-app-pub-3739926644625425/4515079447',
        size: AdSize.banner,
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print('BannerAd $event');
        });
  }

  InterstitialAd createInterstitialAd() {
    return InterstitialAd(
        adUnitId: 'ca-app-pub-3739926644625425/5636589421',
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print('InterstitialAd $event');
        });
  }
}
