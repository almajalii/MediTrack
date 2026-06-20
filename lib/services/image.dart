import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalImageService {
  final ImagePicker _picker = ImagePicker();

  /// Show bottom sheet to choose between camera and gallery
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A3A6B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSourceRow(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                subtitle: 'Take a new photo',
                color: const Color(0xFF00B9E4),
                isDark: isDark,
                onTap: () async {
                  final file = await pickImage(ImageSource.camera);
                  if (sheetContext.mounted) Navigator.pop(sheetContext, file);
                },
              ),
              Divider(height: 1, indent: 56, color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEF0F5)),
              _buildSourceRow(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                subtitle: 'Choose from library',
                color: const Color(0xFF7C3AED),
                isDark: isDark,
                onTap: () async {
                  final file = await pickImage(ImageSource.gallery);
                  if (sheetContext.mounted) Navigator.pop(sheetContext, file);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, null),
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A3A6B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Verify file exists
        if (await imageFile.exists()) {
          return imageFile;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Save image to local app storage
  Future<String?> saveImageLocally({
    required File imageFile,
    required String userId,
    required String medicineName,
  }) async {
    try {
      // Verify source file exists
      if (!await imageFile.exists()) {
        return null;
      }

      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // Create a subdirectory for medicine images
      final String userDirPath = '${appDocDir.path}/medicine_images/$userId';
      final Directory medicineImagesDir = Directory(userDirPath);

      // Create directory if it doesn't exist
      if (!await medicineImagesDir.exists()) {
        await medicineImagesDir.create(recursive: true);
      } else {}

      // Create unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String sanitizedName = medicineName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final String extension = path.extension(imageFile.path);
      final String fileName = '${sanitizedName}_$timestamp$extension';
      final String savePath = '${medicineImagesDir.path}/$fileName';

      // Copy image to new location
      final File savedImage = await imageFile.copy(savePath);

      // Verify the saved file exists
      if (await savedImage.exists()) {
        await savedImage.length();
        return savedImage.path;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Load image from local storage
  Future<File?> loadImageLocally(String imagePath) async {
    try {
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        return imageFile;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Delete image from local storage
  Future<bool> deleteImageLocally(String imagePath) async {
    try {
      final File imageFile = File(imagePath);

      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920, maxHeight: 1920);

      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((xFile) => File(xFile.path)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
