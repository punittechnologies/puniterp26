class AppEdition {
  AppEdition._();

  static const webManagedLabels = bool.fromEnvironment(
    'PUNIT_WEB_LABEL_EDITION',
  );

  static const qrDiagnostic = bool.fromEnvironment('PUNIT_QR_DIAGNOSTIC');

  static const appTitle = qrDiagnostic
      ? 'Punit ERP QR Diagnostic'
      : webManagedLabels
      ? 'Punit ERP Web Label'
      : 'Punit ERP';

  static const deviceNamePrefix = qrDiagnostic
      ? 'Punit QR Diagnostic'
      : webManagedLabels
      ? 'Punit Web Label'
      : 'Punit Tablet';
}
