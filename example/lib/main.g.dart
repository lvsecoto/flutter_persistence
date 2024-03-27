// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// PersistenceGenerator
// **************************************************************************

class _$Example {
  Future<LazyBox> box;

  _$Example(this.box);

  /// 设置[counter]
  Future<void> setCounter(int counter) async {
    await (await box).put('counter', counter);
  }

  /// 获取[counter]
  Future<int> getCounter() async {
    return await (await box).get('counter', defaultValue: Example.counter);
  }

  /// 观察[counter]
  Stream<int> observeCounter() => (_counter ??= () async* {
        yield (await getCounter());
        yield* (await box)
            .watch(key: 'counter')
            .map((event) => event.value as int);
      }()
              .shareReplay())
          .asBroadcastStream();

  Stream<int>? _counter;
}
