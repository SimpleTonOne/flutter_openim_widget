import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_openim_widget/flutter_openim_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_voice_record_bar.dart';
import 'chat_voice_record_view.dart';

typedef SpeakViewChildBuilder = Widget Function(
    ChatVoiceRecordBar recordBar, UILocalizations localizations);

class ChatVoiceRecordLayout extends StatefulWidget {
  const ChatVoiceRecordLayout({
    Key? key,
    this.localizations = const UILocalizations(),
    required this.builder,
    this.onCompleted,
  }) : super(key: key);

  final UILocalizations localizations;
  final SpeakViewChildBuilder builder;
  final Function(int sec, String path)? onCompleted;

  @override
  _ChatVoiceRecordLayoutState createState() => _ChatVoiceRecordLayoutState();
}

class _ChatVoiceRecordLayoutState extends State<ChatVoiceRecordLayout> {
  var _selectedCancelArea = false;
  var _selectedSoundToWordArea = false;
  var _selectedPressArea = true;
  var _showVoiceRecordView = false;
  var _showSpeechRecognizing = false;
  var _showRecognizeFailed = false;
  Timer? _timer;
  late VoiceRecord _record;
  String? _path;
  int _sec = 0;

  @override
  void initState() {
    super.initState();
  }

  void callback(int sec, String path) {
    print('----path:$path------sec:$sec');
    _sec = sec;
    _path = path;
  }

  @override
  void dispose() {
    if (null != _timer) {
      _timer?.cancel();
      _timer = null;
    }
    super.dispose();
  }

  ChatVoiceRecordBar _createSpeakBar() => ChatVoiceRecordBar(
        localizations: widget.localizations,
        onLongPressMoveUpdate: (details) {
          Offset global = details.globalPosition;
          setState(() {
            _selectedPressArea = global.dy >= 683.h;
            _selectedCancelArea = /*global.dy >= 563.h &&*/
                global.dy < 683.h && global.dx < 172.w;
            _selectedSoundToWordArea = global.dy < 683.h && global.dx >= 172.w;
          });
        },
        onLongPressEnd: (details) async {
          await _record.stop();
          print('---------停止记录--------------');
          setState(() {
            if (_selectedPressArea) {
              _callback();
            }
            if (_selectedSoundToWordArea) {
              if (null != _timer) {
                _timer?.cancel();
                _timer = null;
              }
              _timer = new Timer(Duration(seconds: 1), () {
                setState(() {
                  _showRecognizeFailed = true;
                  _showSpeechRecognizing = false;
                });
              });
              _showSpeechRecognizing = true;
              _showVoiceRecordView = true;
              _selectedPressArea = false;
              _selectedCancelArea = false;
              _selectedSoundToWordArea = false;
              print('--------------------1');
            } else {
              _showVoiceRecordView = false;
              _selectedPressArea = false;
              _selectedCancelArea = false;
              _selectedSoundToWordArea = false;
              print('--------------------2');
            }
          });
        },
        onLongPressStart: (details) {
          setState(() {
            print('---------开始记录--------------');
            _record = VoiceRecord(callback);
            _record.start();
            _selectedPressArea = true;
            _showVoiceRecordView = true;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(_createSpeakBar(), widget.localizations),
        IgnorePointer(
          ignoring: !_showRecognizeFailed,
          child: Visibility(
            visible: _showVoiceRecordView,
            child: ChatRecordVoiceView(
              localizations: widget.localizations,
              selectedCancelArea: _selectedCancelArea,
              selectedSoundToWordArea: _selectedSoundToWordArea,
              selectedPressArea: _selectedPressArea,
              showSpeechRecognizing: _showSpeechRecognizing,
              showRecognizeFailed: _showRecognizeFailed,
              onCancel: () {
                setState(() {
                  _selectedCancelArea = false;
                  _selectedSoundToWordArea = false;
                  _selectedPressArea = true;
                  _showVoiceRecordView = false;
                  _showSpeechRecognizing = false;
                  _showRecognizeFailed = false;
                });
              },
              onConfirm: () {
                setState(() {
                  _callback();
                  _selectedCancelArea = false;
                  _selectedSoundToWordArea = false;
                  _selectedPressArea = true;
                  _showVoiceRecordView = false;
                  _showSpeechRecognizing = false;
                  _showRecognizeFailed = false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _callback() {
    print('------------发送------------');
    if (_sec > 0 && null != _path) {
      widget.onCompleted?.call(_sec, _path!);
    }
  }
}
