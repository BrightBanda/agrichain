/// Paths of the AgriChain backend, relative to [AppConfig.apiBaseUrl].
class ApiEndpoints {
  const ApiEndpoints._();

  // Authentication
  static const String registerFarmer = '/auth/register/farmer';
  static const String registerOrganization = '/auth/register/organization';
  static const String login = '/auth/login';
  static const String users = '/auth/users';

  // Products
  static const String products = '/products';

  // Harvests
  static const String harvests = '/harvests';

  // Lending
  static const String loanProducts = '/loan-products';
  static const String myLoans = '/loans/mine';
  static const String applyForLoan = '/loans/apply';
  static const String loanApplications = '/loans/applications';
  static String loanDecision(String loanId) => '/loans/$loanId/decision';
  static String loanRepayments(String loanId) => '/loans/$loanId/repayments';

  // Credit engine
  static const String lendingScore = '/lending-score';
  static const String lendingScoreHistory = '/lending-score/history';

  // Blockchain ledger
  static const String chain = '/blockchain/chain';
  static const String chainStats = '/blockchain/chain/stats';
  static const String chainVerify = '/blockchain/verify';
  static const String verifyRecord = '/blockchain/verify-record';
  static String blockAt(int index) => '/blockchain/blocks/$index';
  static String recordBlocks(String entityType, String entityId) =>
      '/blockchain/records/$entityType/$entityId';

  // Demonstration only — the backend refuses these unless DEBUG is on.
  static String demoTamperBlock(int index) =>
      '/blockchain/demo/tamper-block/$index';
  static const String demoTamperRecord = '/blockchain/demo/tamper-record';
}
