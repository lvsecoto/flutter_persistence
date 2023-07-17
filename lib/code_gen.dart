import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'persistence/persistence.dart';

Builder codeGenPersistenceBuilder(BuilderOptions options) => SharedPartBuilder(
  [PersistenceGenerator()],
  'code_gen_persistence',
  allowSyntaxErrors: true
);