class WebviewArgs {
  final String initialUrl;
  final String pageTitle;
  final bool selfCertificate;

  WebviewArgs({
    required this.initialUrl,
    required this.pageTitle,
    this.selfCertificate = true,
  });
}
