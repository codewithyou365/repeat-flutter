class WebviewArgs {
  final String initialUrl;
  final String pageTitle;
  final bool selfCertificate;
  final bool showTopBar;
  final bool showNavigationBar;

  WebviewArgs({
    required this.initialUrl,
    required this.pageTitle,
    this.selfCertificate = true,
    this.showTopBar = true,
    this.showNavigationBar = true,
  });
}
