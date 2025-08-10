import 'package:flutter/material.dart';
import 'dart:io';

class ChatAvatarSection extends StatelessWidget {
  final Widget? chatAvatar;
  final File? selectedImage;
  final VoidCallback onPickImage;

  const ChatAvatarSection({
    super.key,
    this.chatAvatar,
    this.selectedImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Аватар чату',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF58FF7F).withOpacity(0.3),
                  width: 2,
                ),
                color: chatAvatar == null && selectedImage == null
                    ? const Color(0xFF58FF7F).withOpacity(0.1)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: selectedImage != null
                    ? Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      )
                    : chatAvatar != null
                        ? chatAvatar!
                        : Icon(
                            Icons.group,
                            color: const Color(0xFF58FF7F).withOpacity(0.7),
                            size: 28,
                          ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: onPickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58FF7F).withOpacity(0.2),
                      foregroundColor: const Color(0xFF58FF7F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF58FF7F).withOpacity(0.3),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      selectedImage != null ? 'Змінити аватар' : 'Додати аватар',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG або GIF до 5MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEEEEEE),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            color: Color(0xFFEEEEEE),
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0x1AFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF58FF7F),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            counterStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatInfoSection extends StatelessWidget {
  final String time;
  final String typeChat;

  const ChatInfoSection({
    super.key,
    required this.time,
    required this.typeChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дата створення: $time',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'Тип чату: $typeChat',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String? avatar;
  final double size;
  final bool isOwner;

  const UserAvatar({
    super.key,
    this.avatar,
    required this.size,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size / 2;
    final iconSize = size * 0.5;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isOwner 
              ? const Color(0xFF58FF7F).withOpacity(0.5)
              : const Color(0xFF58FF7F).withOpacity(0.3),
          width: isOwner ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - (isOwner ? 2 : 1)),
        child: avatar != null && avatar!.isNotEmpty
            ? Image.network(
                avatar!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF58FF7F).withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFF58FF7F).withOpacity(0.7),
                      size: iconSize,
                    ),
                  );
                },
              )
            : Container(
                color: const Color(0xFF58FF7F).withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF58FF7F).withOpacity(0.7),
                  size: iconSize,
                ),
              ),
      ),
    );
  }
}