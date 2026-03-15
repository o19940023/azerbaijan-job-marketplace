import 'dart:io';

void main() {
  final path = 'lib/features/jobs/presentation/pages/job_detail_screen.dart';
  final file = File(path);
  
  if (!file.existsSync()) {
    print('File not found');
    exit(1);
  }

  var text = file.readAsStringSync();

  final startStr = 'class _SeekerActionButtons extends StatefulWidget {';
  final endStr = '  Widget _buildEmployerViewActions(BuildContext context) {';
  
  final startIdx = text.indexOf(startStr);
  final endIdx = text.indexOf(endStr);
  
  if (startIdx == -1 || endIdx == -1) {
    print('Could not find the class boundaries');
    exit(1);
  }
  
  // Extract seeker class
  final seekerClassCode = text.substring(startIdx, endIdx);
  
  // Find the mis-placed brace before it
  final searchSubstr = '}\n\nclass _SeekerActionButtons';
  final braceIdx = text.indexOf(searchSubstr, startIdx - 50);
  
  int braceToRemoveIdx = -1;
  if (braceIdx != -1) {
    braceToRemoveIdx = braceIdx;
  } else {
    braceToRemoveIdx = text.lastIndexOf('}', startIdx);
  }
  
  // Create string without the class and the brace
  final textBeforeBrace = text.substring(0, braceToRemoveIdx);
  final textAfterBraceBeforeClass = text.substring(braceToRemoveIdx + 1, startIdx);
  final textAfterClass = text.substring(endIdx);
  
  final textWithoutClass = textBeforeBrace + textAfterBraceBeforeClass + textAfterClass;
  
  // Now find where to put it
  final quickInfoStr = 'class _QuickInfo extends StatelessWidget {';
  final quickInfoIdx = textWithoutClass.indexOf(quickInfoStr);
  
  if (quickInfoIdx == -1) {
    print('Could not find class _QuickInfo');
    exit(1);
  }
  
  final finalText = textWithoutClass.substring(0, quickInfoIdx) + seekerClassCode + '\n' + textWithoutClass.substring(quickInfoIdx);
  
  file.writeAsStringSync(finalText);
  print('Fixed job_detail_screen.dart');
}
