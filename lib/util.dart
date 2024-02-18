formatDateTime(DateTime dt) {
  return dt.toString().substring(0, 19);
}

capitalize(String str) {
  return '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}';
}
