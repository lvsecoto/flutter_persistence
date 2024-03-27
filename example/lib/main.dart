import 'package:persistence_annotation/persistence_annotation.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

part 'main.g.dart';

void main() async {
  Hive.init(null, backendPreference: HiveStorageBackendPreference.memory);
  print(await Example(Hive.openLazyBox('example')).getCounter());
  await Example(Hive.openLazyBox('example')).setCounter(100);
  print(await Example(Hive.openLazyBox('example')).getCounter());
}

@persistenceAnnotation
class Example extends _$Example {
  static const int counter = 0;

  Example(super.box);
}
