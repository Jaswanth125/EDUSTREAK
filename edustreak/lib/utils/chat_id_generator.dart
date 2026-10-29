String buildChatId(String uidA, String uidB) {
  final ids = [uidA, uidB]..sort();
  return ids.join('_');
}

