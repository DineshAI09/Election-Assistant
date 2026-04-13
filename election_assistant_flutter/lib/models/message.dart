enum MessageSender { user, bot }

class ChatMessage {
  final String? text;
  final String? image;
  final MessageSender sender;

  const ChatMessage({
    this.text,
    this.image,
    required this.sender,
  });
}
