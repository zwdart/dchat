import 'package:flutter/widgets.dart';

class GroupDraftModel extends ChangeNotifier {
  final TextEditingController name;
  final Set<String> selected;

  GroupDraftModel({
    String initialName = '',
    Set<String> initialMembers = const {},
  })  : name = TextEditingController(text: initialName),
        selected = {...initialMembers};

  bool isSelected(String id) => selected.contains(id);

  void toggle(String id) {
    if (!selected.add(id)) selected.remove(id);
    notifyListeners();
  }

  String get trimmedName => name.text.trim();

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
