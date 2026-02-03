import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat arrivalDate = DateFormat('dd/MM/yyyy');
  static final NumberFormat money = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$ ',
    decimalDigits: 0,
  );
  static final NumberFormat kg = NumberFormat('0.00');
}
