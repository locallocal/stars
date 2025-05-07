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
      _audioPlayer.playerStateStream.listen(
        (state) {
          debugPrint(
            '播放器状态变化: ${state.processingState}, 播放中: ${state.playing}',
          );

          // 处理所有可能的状态
          switch (state.processingState) {
            case ProcessingState.completed:
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                  _position = _duration;
                });
              }
              break;
            case ProcessingState.ready:
              debugPrint('播放器已准备好');
              break;
            case ProcessingState.buffering:
              debugPrint('播放器正在缓冲');
              break;
            case ProcessingState.loading:
              debugPrint('播放器正在加载');
              break;
            case ProcessingState.idle:
              debugPrint('播放器空闲中');
              break;
          }
        },
        onError: (error) {
          debugPrint('播放器状态监听错误: $error');
        },
      );

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
    // 检查是否在结束位置附近
    bool isNearEnd =
        (_duration.inMilliseconds - _position.inMilliseconds) < 500;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    // 如果在结束位置附近且要开始播放，则重置到开始位置
    if (isNearEnd) {
      debugPrint('播放位置接近结束，重置到开始位置');
      _position = Duration.zero;
      await _audioPlayer.seek(Duration.zero);
    }

    // 开始播放
    setState(() {
      _isPlaying = true;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 播放/暂停按钮
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                color:
                    _isPlaying
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                onPressed: () async {
                  _togglePlay();
                },
              ),
            ),
            SizedBox(width: 8.0),
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
    );
  }
}
