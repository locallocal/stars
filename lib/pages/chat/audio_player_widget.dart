import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioFilePath;

  const AudioPlayerWidget({super.key, required this.audioFilePath});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      // 检查文件是否存在
      final file = File(widget.audioFilePath);
      if (!await file.exists()) {
        debugPrint('音频文件不存在: ${file.path}');
        return;
      }
      // 加载音频文件
      await _audioPlayer.setFilePath(widget.audioFilePath);

      // 获取音频总时长
      _duration = _audioPlayer.duration ?? Duration.zero;
      if (mounted) {
        setState(() {});
      }

      // 监听播放状态变化
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            // _position = Duration.zero;
            _position = _duration;
          });
          // _audioPlayer.seek(Duration.zero);
        }
      });

      // 监听播放位置变化
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });
    } catch (e) {
      debugPrint('音频播放器初始化失败: $e');
    }
  }

  Future<void> _togglePlay() async {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    setState(() {
      if (_position == _duration) {
        _position = Duration.zero;
        _audioPlayer.seek(Duration.zero);
      }
    });
    await _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 播放/暂停按钮
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  _togglePlay();
                },
              ),
              // 显示当前播放时间
              Text(_formatDuration(_position)),
              const Text(' / '),
              Text(_formatDuration(_duration)),
            ],
          ),

          // 进度条
          Slider(
            activeColor: Theme.of(context).colorScheme.primary,
            value: _position.inSeconds.toDouble(),
            min: 0,
            max:
                _duration.inSeconds.toDouble() > 0
                    ? _duration.inSeconds.toDouble()
                    : 1.0,
            onChanged: (value) {
              final position = Duration(seconds: value.toInt());
              _audioPlayer.seek(position);
              setState(() {
                _position = position;
              });
            },
          ),
        ],
      ),
    );
  }
}
