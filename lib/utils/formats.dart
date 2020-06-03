import 'package:intl/intl.dart';

final DateFormat isoDateFormat = DateFormat('yyyy-MM-dd');

NumberFormat currencyFormat = NumberFormat.currency(symbol: '', locale: 'en_IN', decimalDigits: 0);

final  _formatRecent = DateFormat('MMMEd');
final  _formatNormal = DateFormat('MMMd');
final  _formatPast = DateFormat('yMMMd');

extension UsefulDateFormats on DateTime {
  String formatForServer() {
    final iso8861 = toIso8601String();
    return (isUtc) ? iso8861 : (iso8861 + "Z");
  }
  
  String formatRelativeToNow() {
    final now = DateTime.now();
    final format = (now.difference(this).inDays < 7) ? _formatRecent : (now.year != this.year) ? _formatPast : _formatNormal;
    return format.format(this);
  }
}