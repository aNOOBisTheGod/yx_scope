import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../models/dep.dart';
import '../priority.dart';
import '../yx_scope_lint_rule.dart';

class FinalDep extends YXScopeLintRule {
  static const _code = LintCode(
    name: 'final_dep',
    problemMessage: 'A dep field must be `late final`',
    correctionMessage: 'Make your dep field `final`',
    errorSeverity: ErrorSeverity.WARNING,
  );

  const FinalDep() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    yxScopeRegistry(context).addScopeDeclarations((module) {
      void checkFinal(BaseScopeDeclaration module) {
        for (final dep in module.deps.values) {
          final field = dep.field;

          if (!field.fields.isFinal) {
            reporter.atToken(
              dep.nameToken,
              _code,
              data: field.fields,
            );
          }
        }

        for (final module in module.modules.values) {
          checkFinal(module);
        }
      }

      checkFinal(module);
    });
  }

  @override
  List<Fix> getFixes() => [FinalDepFix()];
}

class FinalDepFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    final changeBuilder = reporter.createChangeBuilder(
      message: analysisError.correctionMessage!,
      priority: FixPriority.finalDep.value,
    );

    final fields = analysisError.data as VariableDeclarationList;

    changeBuilder.addDartFileEdit((builder) {
      final keyword = fields.keyword;
      if (keyword != null) {
        builder.addSimpleReplacement(
          keyword.sourceRange,
          'final',
        );
      } else {
        builder.addSimpleInsertion(fields.lateKeyword!.end, ' final');
      }

      final type = fields.type;
      if (type != null) {
        builder.addDeletion(type.sourceRange);
      }

      builder.format(fields.sourceRange);
    });
  }
}
