# 自动生成持久化代码

标记这个类要自动生成持久化代码

在类定义静态常量，就会以这个常量的名字作为键名存储数据，其默认值为这个常量的值

基于Hive

```dart
import 'package:rxdart/rxdart.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

part 'persistence.g.dart';

@persistenceAnnotation
class Persistence extends _$Persistence {
  static const value1 = 1;

  /// 会生成
  /// Future<int> getValue1()
  /// Future<void> setValue1(int value1)
  /// Stream<int> observeValue1()
}
```

支持基本类型，也支持enum，对象，支持空

enum会转成字符串存储，对象会调用toJson()(需要有这个方法，并且import 'dart:convert')
