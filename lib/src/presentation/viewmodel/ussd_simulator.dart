import '../../core/utils/formatters.dart';
import '../../data/models/harvest.dart';
import '../../data/models/product.dart';
import '../../data/models/user.dart';
import 'farmer_dashboard_view_model.dart';

/// Which screen the USSD session is showing.
enum UssdScreen { root, score, loan, harvest, prices, registration, ended }

/// A simulated USSD session (FR-25).
///
/// Real USSD needs a telco short code and an aggregator gateway; AgriChain has
/// neither. What this reproduces faithfully is the *interaction model* a farmer
/// on a basic phone would get: a numbered menu, one digit at a time, a plain
/// text response, and no images or scrolling. The figures are the same live
/// data the app screens use, so the two can never disagree.
///
/// Deliberately free of Flutter imports so the whole menu tree is unit-testable.
class UssdSimulator {
  /// Roughly the width of a feature-phone USSD dialog.
  static const int lineWidth = 26;

  // Mutable so a session can keep its place in the menu while the data behind
  // it arrives or refreshes. The screen is the session's state; the data is not.
  User? user;
  FarmerDashboard? dashboard;
  List<Product> products;

  UssdScreen _screen = UssdScreen.root;
  String? _error;

  UssdSimulator({this.user, this.dashboard, this.products = const []});

  /// Points the session at newer data without disturbing the current screen.
  void updateData({
    User? user,
    FarmerDashboard? dashboard,
    List<Product>? products,
  }) {
    this.user = user;
    this.dashboard = dashboard;
    if (products != null) this.products = products;
  }

  UssdScreen get screen => _screen;
  bool get isEnded => _screen == UssdScreen.ended;

  /// True while the session still accepts input.
  bool get acceptsInput => !isEnded;

  /// Handles one reply. Anything that is not an offered option is rejected with
  /// a message rather than silently ignored, which is how real USSD behaves.
  void reply(String input) {
    if (isEnded) return;

    final choice = input.trim();
    _error = null;

    if (choice.isEmpty) {
      _error = 'Enter a number.';
      return;
    }

    if (_screen == UssdScreen.root) {
      switch (choice) {
        case '1':
          _screen = UssdScreen.score;
        case '2':
          _screen = UssdScreen.loan;
        case '3':
          _screen = UssdScreen.harvest;
        case '4':
          _screen = UssdScreen.prices;
        case '5':
          _screen = UssdScreen.registration;
        case '0':
          _screen = UssdScreen.ended;
        default:
          _error = 'Invalid choice. Try again.';
      }
      return;
    }

    // Every leaf screen offers only Back or Exit.
    switch (choice) {
      case '0':
        _screen = UssdScreen.root;
      case '00':
        _screen = UssdScreen.ended;
      default:
        _error = 'Invalid choice. Try again.';
    }
  }

  void restart() {
    _screen = UssdScreen.root;
    _error = null;
  }

  /// The text a feature phone would display.
  String get display {
    final body = switch (_screen) {
      UssdScreen.root => _rootMenu,
      UssdScreen.score => _scoreScreen,
      UssdScreen.loan => _loanScreen,
      UssdScreen.harvest => _harvestScreen,
      UssdScreen.prices => _pricesScreen,
      UssdScreen.registration => _registrationScreen,
      UssdScreen.ended => _endedScreen,
    };

    if (_error == null) return body;
    return '$_error\n\n$body';
  }

  // -------------------------------------------------------------------------
  // Screens
  // -------------------------------------------------------------------------

  String get _rootMenu {
    final name = user?.farmerProfile?.shortName ?? 'Farmer';
    return '''
AgriChain Malawi
Moni, $name

1. My Money Score
2. My Loan Balance
3. My Last Harvest
4. Market Prices
5. Registration Status
0. Exit''';
  }

  String get _scoreScreen {
    final score = dashboard?.score;
    if (score == null) return _unavailable('MY MONEY SCORE');

    return '''
MY MONEY SCORE

Score: ${score.score} pts
Level: ${score.tier.label}

You can borrow up to
${formatMwk(score.borrowCapacity)}

$_backHint''';
  }

  String get _loanScreen {
    final loan = dashboard?.activeLoan;
    if (loan == null) {
      return '''
MY LOAN BALANCE

You have no active loan.
Dial again after your
loan is approved.

$_backHint''';
    }

    final due = loan.dueDate;
    final dueLine = due == null
        ? 'Due date: not set'
        : loan.isOverdue
              ? 'OVERDUE since ${formatFullDate(due)}'
              : 'Due: ${formatFullDate(due)}';

    return '''
MY LOAN BALANCE

Owing: ${formatMwk(loan.outstandingBalance)}
Paid: ${formatMwk(loan.amountRepaid)}
$dueLine

$_backHint''';
  }

  String get _harvestScreen {
    final harvests = dashboard?.recentWork ?? const <Harvest>[];
    if (harvests.isEmpty) {
      return '''
MY LAST HARVEST

No harvest recorded yet.
Ask your cooperative to
record and verify one.

$_backHint''';
    }

    final latest = harvests.first;
    return '''
MY LAST HARVEST

${latest.cropName}
${formatQuantity(latest.quantity)} ${latest.unitType.label}
Season ${latest.season}
Status: ${latest.status.label}

$_backHint''';
  }

  String get _pricesScreen {
    if (products.isEmpty) return _unavailable('MARKET PRICES');

    // Three entries keeps the response inside one USSD page.
    final lines = products
        .take(3)
        .map(
          (product) =>
              '${product.productName}\n  ${formatMwk(product.pricePerUnit)}'
              ' /${product.unitType.label}',
        )
        .join('\n');

    return '''
MARKET PRICES

$lines

$_backHint''';
  }

  String get _registrationScreen {
    final verified = user?.isVerified ?? false;
    final body = verified
        ? 'APPROVED\nYou can apply for loans\nfrom connected banks.'
        : 'PENDING APPROVAL\nAwaiting review by a\nloan institution.';

    return '''
REGISTRATION STATUS

$body

$_backHint''';
  }

  String get _endedScreen => '''
Session ended.

Thank you for using
AgriChain Malawi.''';

  String _unavailable(String title) => '''
$title

Service unavailable.
Please try again later.

$_backHint''';

  static const String _backHint = '0. Back\n00. Exit';
}
