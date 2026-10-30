import 'dart:io';

/// Fails CI when the pure, platform-free core logic is under-covered.
///
/// Widgets and platform services are intentionally excluded: they are covered
/// by widget tests, but the guarantee we want to enforce in every PR is that
/// the decision-making code (missions, geofences, conflicts, privacy, AI
/// parsing) stays above the agreed threshold.
const List<String> coreFiles = [
  'lib/domain/usecases/mission_evaluator.dart',
  'lib/domain/usecases/geofence_planner.dart',
  'lib/domain/usecases/conflict_resolver.dart',
  'lib/domain/usecases/titipan_visibility.dart',
  'lib/domain/entities/natural_draft.dart',
  'lib/domain/usecases/heuristic_natural_parser.dart',
];

Future<void> main(List<String> args) async {
  final threshold = args.isEmpty ? 80.0 : double.parse(args.first);
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run: flutter test --coverage',
    );
    exitCode = 2;
    return;
  }

  final coverage = _parseLcov(lcov.readAsLinesSync());
  var covered = 0;
  var total = 0;
  var failed = false;

  for (final path in coreFiles) {
    final key = _normalise(path);
    final entry = coverage[key];
    if (entry == null) {
      stderr.writeln('missing coverage for $path');
      failed = true;
      continue;
    }
    covered += entry.hit;
    total += entry.found;
    final percent = entry.percent;
    final marker = percent >= threshold ? 'PASS' : 'FAIL';
    stdout.writeln(
      '$marker ${percent.toStringAsFixed(1).padLeft(5)}%  '
      '${entry.hit.toString().padLeft(4)}/${entry.found.toString().padLeft(4)}  $path',
    );
    if (percent < threshold) failed = true;
  }

  final aggregate = total == 0 ? 0.0 : covered / total * 100;
  stdout.writeln(
    '\ncore coverage: ${aggregate.toStringAsFixed(1)}% '
    '($covered/$total lines), threshold ${threshold.toStringAsFixed(1)}%',
  );
  if (aggregate < threshold) failed = true;
  if (failed) exitCode = 1;
}

Map<String, _Coverage> _parseLcov(List<String> lines) {
  final result = <String, _Coverage>{};
  String? current;
  var found = 0;
  var hit = 0;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      current = _normalise(line.substring(3));
      found = 0;
      hit = 0;
    } else if (line.startsWith('LF:')) {
      found = int.tryParse(line.substring(3)) ?? 0;
    } else if (line.startsWith('LH:')) {
      hit = int.tryParse(line.substring(3)) ?? 0;
    } else if (line == 'end_of_record' && current != null) {
      result[current] = _Coverage(found, hit);
      current = null;
    }
  }
  return result;
}

String _normalise(String path) => path.replaceAll('\\', '/');

class _Coverage {
  const _Coverage(this.found, this.hit);

  final int found;
  final int hit;

  double get percent => found == 0 ? 100 : hit / found * 100;
}
