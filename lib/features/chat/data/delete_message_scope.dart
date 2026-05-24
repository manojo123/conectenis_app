enum DeleteMessageScope {
  forMe('for_me'),
  forEveryone('for_everyone');

  const DeleteMessageScope(this.value);
  final String value;
}
