enum LegalDocumentType {
  privacyPolicy('privacy_policy'),
  userAgreement('user_agreement');

  const LegalDocumentType(this.assetName);

  final String assetName;
}
