import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:persistence_annotation/persistence_annotation.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

/// 生成利用Hive坐本地存储的类
class PersistenceGenerator
    extends GeneratorForAnnotation<PersistenceAnnotation> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is ClassElement) {
      // 处理带有[PersistenceAnnotation]的类
      final clazz = element;

      // 里面有static const的字段，转换为存放在Hive的数据
      final fields = element.fields.where((it) {
        var ignore = false;
        final annotation = typeChecker.firstAnnotationOf(it);
        if (annotation != null) {
          ignore = ConstantReader(annotation).read('ignore').boolValue;
        }
        // 只处理static 的字段处理，忽略的字段也不处理
        return it.isPublic && !ignore;
      });

      // 是否是用LazyBox加载的，还是在应用启动就立即加载
      final isLazy = annotation.read('lazy').boolValue;

      /// static 的字段的值作为默认值，stream，Future
      String generatePersistenceForField(
        ClassElement clazz,
        FieldElement field,
      ) {
        // static const 的字段的值作为默认值

        final isEnum = (field.type.element as ClassElement).isDartCoreEnum;
        final isClass =
            !isEnum && (!(field.type.element?.library?.isDartCore ?? false));

        final isIterable =
            field.type.isDartCoreSet || field.type.isDartCoreList;

        // 类型
        final fieldType = field.type.getDisplayString(
          withNullability:
              field.type.nullabilitySuffix == NullabilitySuffix.question,
        );

        final fieldClassName =
            field.type.getDisplayString(withNullability: false);

        final fieldName = field.name;

        String future(String type) {
          if (isLazy) {
            return 'Future<$type>';
          } else {
            return type;
          }
        }

        final async = isLazy ? 'async' : '';
        final _await = isLazy ? 'await' : '';

        final doc =
            field.documentationComment?.replaceAll(RegExp('^/// '), '').trim();

        return """
          /// 设置${doc ?? ''}[$fieldName]
          ${future("void")} set${fieldName.pascalCase}($fieldType $fieldName) $async {
            ${field.type.nullabilitySuffix == NullabilitySuffix.question ? """
              // 如果设置字段为空，则清除这个值
               if ($fieldName == null) {
                 $_await ($_await box).delete('${fieldName.snakeCase}');
                 return;
               }
            """ : ""}
            ${isEnum ? "$_await ($_await box).put('${fieldName.snakeCase}', EnumToString.convertToString($fieldName));" : isClass ? "$_await ($_await box).put('${fieldName.snakeCase}', jsonEncode($fieldName.toJson()));" : isIterable ? "$_await ($_await box).put('${fieldName.snakeCase}', jsonEncode($fieldName));" : "$_await ($_await box).put('${fieldName.snakeCase}', $fieldName);"}
          }
          
          /// 获取${doc ?? ''}[$fieldName]
          ${future("$fieldType")} get${fieldName.pascalCase}() $async {
            ${isEnum ? "return _decode${fieldName.pascalCase}($_await ($_await box).get('${fieldName.snakeCase}', defaultValue: ''));" : isClass ? "return _decode${fieldName.pascalCase}($_await ($_await box).get('${fieldName.snakeCase}', defaultValue: '{}'));" : isIterable ? "return _decode${fieldName.pascalCase}($_await ($_await box).get('${fieldName.snakeCase}', defaultValue: '')) as ${field.type};" : "return $_await ($_await box).get('${fieldName.snakeCase}', defaultValue: ${clazz.name}.$fieldName);"}
          }

          /// 观察${doc ?? ''}[$fieldName]
          Stream<$fieldType> observe${fieldName.pascalCase}() => (_${fieldName.camelCase} ??= () async* {
            yield ($_await get${fieldName.pascalCase}());
            yield* ($_await box).watch(key: '${fieldName.snakeCase}').map((event) => 
              ${(isEnum || isClass || isIterable) ? "_decode${fieldName.pascalCase}(event.value ?? '')" : "event.value as $fieldType"}
            );
          }().shareReplay()).asBroadcastStream();

          Stream<$fieldType>? _${fieldName.camelCase};
          
          ${(isEnum || isClass) ? """
          /// $fieldClassName是enum或Class，需要序列化
          $fieldType _decode${fieldName.pascalCase}(String? val) {
            ${isEnum ? "return EnumToString.fromString($fieldType.values, val.toString()) "
                    "?? ${clazz.name}.$fieldName;" : "try {"
                    "return $fieldClassName.fromJson(jsonDecode(val.toString()));"
                    "} catch (e) {"
                    "return ${clazz.name}.$fieldName;"
                    "}"}
           }
          """ : ""}
          
          ${(isIterable) ? """
          /// $fieldClassName是List，需要序列化
          $fieldType _decode${fieldName.pascalCase}(String val) {
            try {
              return (jsonDecode(val) as List<dynamic>?)?.map((it) => ${RegExp('<(.+)>').firstMatch(fieldType)!.group(1)}.fromJson(it)).toList()${field.type.nullabilitySuffix == NullabilitySuffix.question ? '' : ' ?? ${clazz.name}.$fieldName'};
            } catch (e) {
              return ${clazz.name}.$fieldName;
            }
          }
          """ : ""}
        """;
      }

      return '''
      class _\$${clazz.name} {
        ${isLazy ? "Future<LazyBox> box;" : "Box box;"}
        
        _\$${clazz.name}(this.box);
        
        ${fields.map((field) => generatePersistenceForField(clazz, field)).join("\n")}
      }
      ''';
    }
  }
}
