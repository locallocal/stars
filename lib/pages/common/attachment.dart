import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// 从相机获取图片
Future<File?> getImageFromCamera() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // 设置图片质量，减小文件大小
      maxWidth: 1200, // 限制最大宽度
      maxHeight: 1200, // 限制最大高度
    );
    if (photo == null) {
      return null; // 用户取消了拍照
    }

    // 将XFile转换为File
    return File(photo.path);
  } catch (e) {
    debugPrint('拍照出错: $e');
    return null;
  }
}

// 从相册获取图片
Future<File?> getImageFromGallery() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // 设置图片质量，减小文件大小
      maxWidth: 1200, // 限制最大宽度
      maxHeight: 1200, // 限制最大高度
    );
    if (image == null) {
      return null; // 用户取消了选择
    }

    // 将XFile转换为File
    return File(image.path);
  } catch (e) {
    debugPrint('选择图片出错: $e');
    return null;
  }
}

// 选择文件
Future<File?> pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      // - FileType.image：仅图片文件
      // - FileType.media：媒体文件（图片和视频）
      // - FileType.audio：音频文件
      // - FileType.video：视频文件
      // - FileType.custom：自定义文件类型（需要指定 allowedExtensions 参数）
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return null; // 用户取消了选择
    }

    // 获取文件路径并转换为File对象
    String? filePath = result.files.single.path;
    if (filePath == null) {
      return null;
    }
    return File(filePath);
  } catch (e) {
    debugPrint('选择文件出错: $e');
    return null;
  }
}
