import 'package:flutter/material.dart';
import 'package:hypebard/stores/AIChatStore.dart';
import 'package:hypebard/utils/Chatgpt.dart';
import 'package:hypebard/utils/platform.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';
import 'package:speech_xf/speech_xf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';



GlobalKey<_QuestionInputState> globalQuestionInputKey = GlobalKey();

class QuestionInput extends StatefulWidget {
  final Map chat;
  final bool autofocus;
  final bool enabled;
  final Function? scrollToBottom;
  final Function? onGeneratingStatusChange;

  const QuestionInput({
    Key? key,
    required this.chat,
    required this.autofocus,
    required this.enabled,
    this.scrollToBottom,
    this.onGeneratingStatusChange,
  }) : super(key: key);

  @override
  _QuestionInputState createState() => _QuestionInputState();
}

class _QuestionInputState extends State<QuestionInput> {
  final FocusNode focusNode = FocusNode();
  TextEditingController questionController = TextEditingController();
  bool _isGenerating = false;
  String myQuestion = '';

  final stt.SpeechToText _speechToText = stt.SpeechToText(); // Add this line
  bool _isListening = false;
  String _transcription = '';

  Map<String, dynamic> xfSettingResult = {
    'language': 'zh_cn',
    'vadBos': '5000',
    'vadEos': '1800',
    'ptt': '1',
  };


  @override
  void initState() {
    super.initState();
    if (PlatformTool.isAndroid()) {
      /// using xf speech recognition when the platform is Android
      /// 讯飞语音识别初始化
      _initXfSpeechSDK();
    } else {
      /// using google speech recognition when the platform is not Android
      _initializeSpeechToText();
    }
  }

  /// 讯飞语音识别初始化
  void _initXfSpeechSDK() async {
    await SpeechXf.init(dotenv.env['XUNFEI_APP_ID'] ?? '');
  }

  /// 讯飞语音识别结束
  void stopXfSpeechListening() async {
    await SpeechXf.stopListening();
  }

  /// 讯飞语音识别开始
  void startXfSpeechListening() async {
    /// 语音识别结果监听
    onXfSpeechResultListener();
    /// 音量变化监听
    onXfSpeechVolumeChanged();
    await SpeechXf.startListening(
      isDynamicCorrection: false,
      language: xfSettingResult['language'],
      vadBos: xfSettingResult['vadBos'],
      vadEos: xfSettingResult['vadEos'],
      ptt: xfSettingResult['ptt'],
    );
  }

  void _initializeSpeechToText() async {
    bool available = await _speechToText.initialize();
    if (available) {
      _speechToText.errorListener = (error) {
        print('Speech recognition error: $error');
        setState(() {
          _isListening = false;
        });
      };
    } else {
      print('The user has denied the use of speech recognition.');
    }
  }

  void _startListening() async {
    if (!_isListening) {
        if(PlatformTool.isAndroid()) {
          setState(() {
            _isListening = true;
            _transcription = '';
          });
          startXfSpeechListening();
        } else {
          bool available = await _speechToText.initialize();
          if (available) {
            setState(() {
              _isListening = true;
              _transcription = '';
            });
            _speechToText.listen(
              onResult: (result) {
                setState(() {
                  _transcription = result.recognizedWords;
                  questionController.text = _transcription;
                });
                if (result.finalResult) {
                  _stopListening();
                  onQuestionChange(_transcription);
                  onSubmit();
                }
              },
            );
          }
        }
    }
  }

  void onXfSpeechResultListener() {
    /// 语音识别结果监听
    SpeechXf.onSpeechResultListener(
      onSuccess: (result, isLast) {
        if (mounted) {
          setState(() {
            _transcription = _transcription + result;
          });
        }
        if (isLast) {
          print('Speech recognition finished.');
          _stopListening();
          onQuestionChange(_transcription);
          onSubmit();
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
      },
    );
  }

  /// 音量变化监听
  void onXfSpeechVolumeChanged() {
    SpeechXf.onVolumeChanged(
      volume: (v) {},
      bytes: (bytes) {},
    );
  }

  void _stopListening() {
    if (_isListening) {
      if(PlatformTool.isAndroid()){
        stopXfSpeechListening();
      } else {
        _speechToText.stop();
      }
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    if (PlatformTool.isAndroid()) {
      SpeechXf.iatDestroy();
    }
    questionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    precacheImage(
      const AssetImage('images/submit_active_icon.png'),
      context,
    );
    super.didChangeDependencies();
  }

  void _updateGeneratingStatus(bool value) {
    _isGenerating = value;

    if (widget.onGeneratingStatusChange != null) {
      widget.onGeneratingStatusChange!(value);
    }

    setState(() {});
  }

  void reGenerate(int messageIndex) async {
    _updateGeneratingStatus(true);
    final store = Provider.of<AIChatStore>(context, listen: false);
    Map chat = widget.chat;
    List messages = [];
    Map ai = chat['ai'];

    /// If it is a continuous conversation, check whether it is related
    if (ai['isContinuous']) {
      messages = [
        chat['systemMessage'],
        ...chat['messages'].take(messageIndex),
      ];
    } else {
      messages = [
        chat['systemMessage'],
        chat['messages'][messageIndex],
      ];
    }

    /// This is the state in formation
    await store.replaceMessage(chat['id'], messageIndex, {
      'role': 'generating',
      'content': '',
    });
    try {
      final response = await ChatGPT.sendMessage(messages);
      final firstCompletionChoice = response.choices.first;
      await store.replaceMessage(chat['id'], messageIndex, {
        'role': 'assistant',
        'content': firstCompletionChoice.message.content,
      });

      _updateGeneratingStatus(false);
    } catch (error) {
      print(error);
      _updateGeneratingStatus(false);
      await store.replaceMessage(chat['id'], messageIndex, {
        'role': 'error',
        'content': error.toString(),
      });
    }

    print(messages);
  }

  void onSubmit() async {
    final store = Provider.of<AIChatStore>(context, listen: false);
    if (myQuestion == '') {
      return;
    }
    if (_isGenerating) {
      print('---_isGenerating---');
      return;
    }
    final text = myQuestion;

    _updateGeneratingStatus(true);

    setState(() {
      questionController.clear();
      myQuestion = '';
    });

    Map message = {
      'role': 'user',
      'content': text,
    };

    bool isFirstMessage = widget.chat['messages'].length == 0;
    debugPrint('--- $isFirstMessage---');
    Map chat = await store.pushMessage(widget.chat, message);

    List messages = [
      chat['systemMessage'],
      message,
    ];
    Map ai = chat['ai'];

    /// If it is a continuous conversation, check whether it is related
    if (!isFirstMessage && ai['isContinuous']) {
      messages = [
        chat['systemMessage'],
        ...chat['messages'],
      ];
    }

    /// This is the state in formation
    Map generatingChat = await store.pushMessage(widget.chat, {
      'role': 'generating',
      'content': '',
    });
    int messageIndex = generatingChat['messages'].length - 1;
    if (widget.scrollToBottom != null) {
      widget.scrollToBottom!();
    }
    try {
      final response = await ChatGPT.sendMessage(messages);
      final firstCompletionChoice = response.choices.first;
      await store.replaceMessage(chat['id'], messageIndex, {
        'role': 'assistant',
        'content': firstCompletionChoice.message.content?.first.text,
      });
      _updateGeneratingStatus(false);
    } catch (error) {
      print(error);
      _updateGeneratingStatus(false);
      await store.replaceMessage(chat['id'], messageIndex, {
        'role': 'error',
        'content': error.toString(),
      });
      if (widget.scrollToBottom != null) {
        widget.scrollToBottom!();
      }
    }
  }

  void onQuestionChange(String value) {
    setState(() {
      myQuestion = value;
      if (_isListening) {
        questionController.text = _transcription;
        print('questionController.text:${questionController.text}');
        onSubmit(); // Update the text field with the transcription
      }
    });
  }

  Image _getMicrophoneImage() {
    String imagePath =
        _isListening ? 'microphone_active_icon.png' : 'microphone_icon.png';
    return Image.asset(
      'images/$imagePath',
      width: 40,
      height: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 0,
            color: Colors.transparent,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(500),
                borderRadius: BorderRadius.circular(50.0),
                border: Border.all(
                    color: const Color.fromRGBO(70, 20, 75, 0.9254901960784314),
                    width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.5),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                    blurStyle: BlurStyle.outer,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      enabled: widget.enabled,
                      controller: questionController,
                      minLines: 1,
                      maxLines: 2,
                      cursorRadius: Radius.zero,
                      decoration: const InputDecoration.collapsed(
                          hintText: "有问题尽管问我..."),
                      autofocus: widget.autofocus,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        height: 24 / 18,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      onChanged: onQuestionChange,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.words,
                      enableInteractiveSelection: true,
                      onSubmitted: (String value) {
                        onSubmit();
                      },
                      onTap: () {
                        if (widget.scrollToBottom != null) {
                          widget.scrollToBottom!();
                        }
                      },
                    ),
                  ),
                  widget.enabled
                      ? renderSubmitBtnWidget()
                      : IgnorePointer(
                          child: renderSubmitBtnWidget(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderSubmitBtnWidget() {
    bool isActive =
        _transcription.isNotEmpty || !_isGenerating && !_isListening;
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_isListening) {
              _stopListening();
            } else {
              _startListening();
            }
            Vibration.vibrate(
                duration: 50); // Vibration effect of 50 milliseconds
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: _getMicrophoneImage(),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onSubmit();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'images/${isActive ? 'submit_active_icon.png' : 'submit_icon.png'}',
              width: 40,
              height: 30,
            ),
          ),
        ),
      ],
    );
  }
}
