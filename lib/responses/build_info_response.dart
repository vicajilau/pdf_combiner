class BuildInfoResponse {
  String? buildDate,
      buildDateWithTime,
      versionNumber,
      packageName,
      appName,
      buildNumber;

  BuildInfoResponse(
      {this.buildDate,
      this.buildDateWithTime,
      this.versionNumber,
      this.packageName,
      this.appName,
      this.buildNumber});
}
