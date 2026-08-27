import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static String short(DateTime date, String locale) =>
      DateFormat.yMMMd(locale).format(date);
}
