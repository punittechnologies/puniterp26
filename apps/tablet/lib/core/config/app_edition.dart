class AppEdition {
  AppEdition._();

  static const webManagedLabels = bool.fromEnvironment(
    'PUNIT_WEB_LABEL_EDITION',
  );

  static const appTitle = webManagedLabels
      ? 'Punit ERP Web Label'
      : 'Punit ERP';

  static const deviceNamePrefix = webManagedLabels
      ? 'Punit Web Label'
      : 'Punit Tablet';
}
