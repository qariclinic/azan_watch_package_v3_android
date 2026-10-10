#!/usr/bin/env bash
# ویب فائلوں سے اینڈرائیڈ پروجیکٹ بناتا ہے (Capacitor)۔ CI اور لوکل (Git Bash/Linux/Mac) دونوں پر چلتا ہے۔
set -e
rm -rf www android
mkdir -p www
cp azan-watch.html www/index.html
cp azan-watch.html adhan.js manifest.json service-worker.js icon.svg icon-192.png icon-512.png azan_alert.wav www/

npx cap add android

# مقام اور اسکرین آن رکھنے کی اجازتیں
MF=android/app/src/main/AndroidManifest.xml
sed -i 's#<uses-permission android:name="android.permission.INTERNET" />#&\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.WAKE_LOCK" />#' "$MF"
grep -q ACCESS_FINE_LOCATION "$MF" || { echo "manifest patch failed"; exit 1; }

# آواز بغیر ٹچ کے چلے + اسکرین آن رہے (مسجد ڈسپلے کے لیے)
JAVA_DIR=android/app/src/main/java/com/shuaib/azanwatch
mkdir -p "$JAVA_DIR"
cat > "$JAVA_DIR/MainActivity.java" <<'JAVA'
package com.shuaib.azanwatch;

import android.os.Bundle;
import android.view.WindowManager;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override
    public void onStart() {
        super.onStart();
        if (getBridge() != null && getBridge().getWebView() != null) {
            getBridge().getWebView().getSettings().setMediaPlaybackRequiresUserGesture(false);
        }
    }
}
JAVA

# آئیکن (ناکام ہو تو ڈیفالٹ آئیکن رہے گا، بلڈ نہیں رکتا)
npx --yes @capacitor/assets generate --android --iconBackgroundColor '#0b3a5b' --iconBackgroundColorDark '#0b3a5b' || echo "icon generation skipped"

# ڈیفالٹ Capacitor adaptive آئیکن ہٹائیں تاکہ ہمارا آئیکن نظر آئے
rm -rf android/app/src/main/res/mipmap-anydpi-v26

npx cap sync android
echo "Android project ready"
