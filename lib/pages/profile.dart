import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/services/profile_service.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/model/model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  // 获取用户名
  String get _name => _profile?.name ?? "用户名";
  // 获取头像路径
  String get _avatar => _profile?.avatar ?? "";
  // 获取字体大小
  double get _fontSize => _profile?.fontSize ?? 16.0;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
  }

  Future<void> _loadProfileInfo() async {
    setState(() {
      _isLoading = true;
    });

    final loadedProfile = await ProfileService.getProfile();

    setState(() {
      _profile = loadedProfile;
      _themeMode = intToThemeMode(loadedProfile.themeMode);
      _isLoading = false;
    });
  }

  // 保存设置
  Future<void> _saveProfile() async {
    if (_profile == null) return;

    final profile = Profile(
      name: _name,
      avatar: _avatar,
      fontSize: _fontSize,
      themeMode: themeModeToInt(_themeMode),
      createTimestamp: _profile!.createTimestamp,
      modifyTimestamp: DateTime.now(),
    );
    await ProfileService.updateProfile(profile);
    _profile = profile; // 更新本地缓存
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: true,
          title: const Text('我的'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 头像区域
          Padding(
            padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _showAvatarOptions();
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage:
                          _avatar.isNotEmpty ? FileImage(File(_avatar)) : null,
                      child:
                          _avatar.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // 名称区域
          ListTile(
            leading: const Icon(Icons.person),
            title: Text("名称", style: TextStyle(fontSize: _fontSize)),
            subtitle: Text(_name, style: TextStyle(fontSize: _fontSize - 2)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showEditNameDialog();
            },
          ),

          const Divider(),

          // 主题切换
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text("主题设置", style: TextStyle(fontSize: _fontSize)),
            subtitle: Text(
              _themeMode == ThemeMode.system
                  ? "跟随系统"
                  : _themeMode == ThemeMode.light
                  ? "浅色模式"
                  : "深色模式",
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showThemeOptions();
            },
          ),

          // 字号调节
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text("文字大小", style: TextStyle(fontSize: _fontSize)),
            subtitle: Text(
              "调整应用内文字大小",
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            onTap: () {
              _showFontSizeDialog();
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _profile = Profile(
                    name: _name,
                    avatar: _avatar,
                    fontSize: value,
                    themeMode: themeModeToInt(_themeMode),
                    createTimestamp: _profile!.createTimestamp,
                    modifyTimestamp: DateTime.now(),
                  );
                });
                _saveProfile(); // 保存设置
              },
            ),
          ),

          const Divider(),

          // 关于
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text("关于", style: TextStyle(fontSize: _fontSize)),
            subtitle: Text(
              "版本 1.0.0",
              style: TextStyle(fontSize: _fontSize - 2),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 显示关于信息
              showAboutDialog(
                context: context,
                applicationName: "AI聊天助手",
                applicationVersion: "1.0.0",
                applicationIcon: const FlutterLogo(size: 40),
                children: [const Text("一个简单的AI聊天应用")],
              );
            },
          ),
        ],
      ),
    );
  }

  // 显示头像选项
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text("拍照"),
                  onTap: () {
                    Navigator.pop(context);
                    // 这里添加拍照逻辑
                    _showSnackBar("拍照功能暂未实现");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("从相册选择"),
                  onTap: () {
                    Navigator.pop(context);
                    // 这里添加从相册选择逻辑
                    _showSnackBar("相册选择功能暂未实现");
                  },
                ),
                // 在修改 _avatarPath 后添加:
                if (_avatar.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      "删除头像",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _profile = Profile(
                          name: _name,
                          avatar: '',
                          fontSize: _fontSize,
                          themeMode: themeModeToInt(_themeMode),
                          createTimestamp: _profile!.createTimestamp,
                          modifyTimestamp: DateTime.now(),
                        );
                      });
                      _saveProfile(); // 保存设置
                      _showSnackBar("头像已删除");
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // 显示编辑名称对话框
  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("修改名称"),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "名称",
                hintText: "请输入新名称",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _profile = Profile(
                      name:
                          controller.text.trim().isEmpty
                              ? "用户名"
                              : controller.text.trim(),
                      avatar: _avatar,
                      fontSize: _fontSize,
                      themeMode: themeModeToInt(_themeMode),
                      createTimestamp: _profile!.createTimestamp,
                      modifyTimestamp: DateTime.now(),
                    );
                  });
                  _saveProfile(); // 保存设置
                  Navigator.pop(context);
                  _showSnackBar("名称已更新");
                },
                child: const Text("保存"),
              ),
            ],
          ),
    );
  }

  // 显示主题选项
  void _showThemeOptions() {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text("选择主题"),
            children: [
              RadioListTile<ThemeMode>(
                title: const Text("跟随系统"),
                value: ThemeMode.system,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() {
                    _themeMode = value!;
                  });
                  _saveProfile(); // 保存设置

                  // 通知应用程序更新主题
                  ProfileService.notifyThemeChanged(_themeMode);
                  Navigator.pop(context);
                  _showSnackBar("已设置为跟随系统主题");
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("浅色模式"),
                value: ThemeMode.light,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() {
                    _themeMode = value!;
                  });
                  _saveProfile(); // 保存设置

                  ProfileService.notifyThemeChanged(_themeMode);
                  Navigator.pop(context);
                  _showSnackBar("已设置为浅色模式");
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("深色模式"),
                value: ThemeMode.dark,
                groupValue: _themeMode,
                onChanged: (value) {
                  setState(() {
                    _themeMode = value!;
                  });
                  _saveProfile(); // 保存设置

                  ProfileService.notifyThemeChanged(_themeMode);
                  Navigator.pop(context);
                  _showSnackBar("已设置为深色模式");
                },
              ),
            ],
          ),
    );
  }

  // 显示字体大小对话框
  void _showFontSizeDialog() {
    double tempFontSize = _fontSize;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("调整文字大小"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("预览文字效果", style: TextStyle(fontSize: tempFontSize)),
                      const SizedBox(height: 20),
                      Slider(
                        value: tempFontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 6,
                        label: tempFontSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            tempFontSize = value;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("取消"),
                    ),
                    TextButton(
                      onPressed: () {
                        this.setState(() {
                          _profile = Profile(
                            name: _name,
                            avatar: _avatar,
                            fontSize: tempFontSize,
                            themeMode: themeModeToInt(_themeMode),
                            createTimestamp: _profile!.createTimestamp,
                            modifyTimestamp: DateTime.now(),
                          );
                        });
                        _saveProfile(); // 保存设置
                        Navigator.pop(context);
                        _showSnackBar("文字大小已更新");
                      },
                      child: const Text("保存"),
                    ),
                  ],
                ),
          ),
    );
  }

  // 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
