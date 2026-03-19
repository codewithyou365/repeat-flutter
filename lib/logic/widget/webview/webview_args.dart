class WebviewArgs {
  final String initialUrl;
  final String pageTitle;
  double height = 0;
  double width = 0;
  final bool selfCertificate;

  WebviewArgs({
    required this.initialUrl,
    required this.pageTitle,
    this.selfCertificate = true,
  });
}
