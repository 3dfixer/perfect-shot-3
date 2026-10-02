# Perfect Shot

Electronic target system app for Air Pistol and Air Rifle. Connects to the
target over Wi-Fi, scores shots as they arrive, and reviews the session.

## Running

```
flutter pub get
flutter run -d <device id>      # see `flutter devices`
```

Tap the play button in the app bar to run a simulated session without a target.

## Running on an iPad / iPhone (needs a Mac with Xcode)

1. Install Flutter and Xcode on the Mac, then `git clone` this repo.
2. `flutter pub get`, then `open ios/Runner.xcworkspace`.
3. In Xcode select the **Runner** target > **Signing & Capabilities**, tick
   *Automatically manage signing* and choose your Apple ID as the Team. If the
   bundle identifier `com.fixer3d.perfectshot` is taken, change it to something
   unique.
4. Plug in the iPad, select it as the run destination and press Run
   (or `flutter run -d <ipad id>`).
5. First launch: on the iPad go to Settings > General > VPN & Device Management,
   trust your Apple ID, and enable Developer Mode (Settings > Privacy & Security).
6. When the app first connects to the target, allow the **Local Network**
   permission prompt.

With a free Apple ID the install expires after 7 days and has to be re-run from
Xcode.

## Connecting to the target

1. Power on the target and wait for it to start up.
2. Join the target's Wi-Fi network (name starts with `FET-`).
3. Open the app; the IP and port are pre-filled. Press the connect button.
