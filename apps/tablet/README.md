# Punit ERP Android app

The Android project has three installable editions:

- `classic`: the existing Punit ERP application, including app-managed labels.
- `webLabel`: a separate application that prints only the active web template
  marked **Make default**. It does not expose the app label designer.
- `qrDiagnostic`: a temporary, separately installable Web Label diagnostic
  edition. It exposes three QR transport tests on the weighing screen and does
  not save a weighment when those tests are used.

The Web Label package ID is
`com.punittechnologies.puniterp.weblabel`, so it can coexist with the classic
application.

## Validation

```sh
flutter analyze
flutter test
flutter test --dart-define=PUNIT_WEB_LABEL_EDITION=true
flutter build apk --debug --flavor classic
flutter build apk --debug --flavor qrDiagnostic \
  --dart-define=PUNIT_WEB_LABEL_EDITION=true \
  --dart-define=PUNIT_QR_DIAGNOSTIC=true
```

## Signed Web Label release

The release signing key and password must stay outside the repository. Supply
them only through the build environment:

```sh
PUNIT_WEBLABEL_STORE_FILE=/secure/path/punit-weblabel-release.jks \
PUNIT_WEBLABEL_STORE_PASSWORD='...' \
PUNIT_WEBLABEL_KEY_ALIAS=punit-weblabel \
PUNIT_WEBLABEL_KEY_PASSWORD='...' \
flutter build apk \
  --release \
  --flavor webLabel \
  --dart-define=PUNIT_WEB_LABEL_EDITION=true
```

Back up the release keystore securely. Future APK updates for the Web Label
package must be signed by the same key.
