class CacheBaseModel<T> {
  final bool status;

  final T file;

  CacheBaseModel({
    required this.status,
    required this.file,
  });
}
