import 'package:floor/floor.dart';

/// Floor no soporta `DateTime` de forma nativa. Este converter persiste las
/// fechas como epoch en milisegundos (`int`) y las reconstruye al leer.
class DateTimeConverter extends TypeConverter<DateTime?, int?> {
  @override
  DateTime? decode(int? databaseValue) {
    if (databaseValue == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int? encode(DateTime? value) {
    return value?.millisecondsSinceEpoch;
  }
}
