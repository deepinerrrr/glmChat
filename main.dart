// main.dart

import 'package:flutter/material.dart';
import 'package:glmchat/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:glmchat/models/chat_message.dart';
import 'package:flutter/services.dart'; // 用于复制功能
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        title: 'Flutter ChatBot',
        theme: ThemeData(
          primarySwatch: Colors.purple, // 修改主题色为浅紫色
        ),
        home: ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Color.fromARGB(255, 155, 111, 252),
        title: Text('GLM-4'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 155, 111, 252),
                ),
                child: ListTile(
                  title: Text(
                    '历史记录',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  subtitle: Text(
                    'Chat History',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                )),
            //创建一个蓝色的圆角矩形
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: InkWell(
                onTap: () {
                  //跳转到网页链接
                  //final Uri _url = Uri.parse('https://flutter.dev');
                  launchUrl(Uri.parse('https://space.bilibili.com/1834448890'));
                },
                child: Container(
                    height: 60,
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 219, 206, 248),
                      borderRadius: BorderRadius.circular(65),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                                'https://s3.bmp.ovh/imgs/2024/08/10/8ff9dcf18c05316b.png'),
                          ),
                          //https://i1.hdslb.com/bfs/face/9824feed6a2fa59534662ab28a39b387e4c90275.jpg
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 10, 5),
                          child: Text(
                            'bilibili:@浪来_',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        )
                      ],
                    )),
              ),
            ),

            // 动态生成聊天记录列表
            // 动态生成聊天记录列表
            for (int i = 0; i < chatProvider.chatHistories.length; i++)
              //创建一个圆角矩形
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  // color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ListTile(
                  title: Text(
                    chatProvider.chatHistories[i].title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(chatProvider.chatHistories[i].timestamp),
                  onTap: () {
                    chatProvider.loadChatHistory(i);
                    Navigator.pop(context); // 关闭侧边栏
                  },
                ),
              )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                return GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('内容已复制')),
                    );
                  },
                  child: ChatMessageWidget(message: message),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                      //设置边框
                      border: Border.all(color: Colors.grey),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18)),
                  child: IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      chatProvider.clearMessages(); // 清空消息
                      _scrollToBottom();
                    },
                  ),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: TextField(
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        await chatProvider.sendMessage(value);
                        _controller.clear();
                        setState(() {
                          _isTyping = false;
                        });
                        _scrollToBottom();
                      }
                    },
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ),
                ),
                SizedBox(width: 12.0),
                Container(
                  decoration: BoxDecoration(
                      color: _isTyping
                          ? Color.fromARGB(255, 222, 208, 253)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18)),
                  child: IconButton(
                    icon: Icon(Icons.send),
                    color: _isTyping
                        ? Color.fromARGB(255, 40, 26, 236)
                        : Colors.grey,
                    onPressed: () async {
                      if (_controller.text.isNotEmpty) {
                        await chatProvider.sendMessage(_controller.text);
                        _controller.clear();
                        setState(() {
                          _isTyping = false;
                        });
                        _scrollToBottom();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Color.fromARGB(255, 180, 150, 247)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.0), // 美化聊天气泡
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.message.contains('```')) ...[
                        Text(
                          message.message.split('```')[0],
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              borderRadius: BorderRadius.circular(25)),
                          width: double.infinity,
                          padding: const EdgeInsets.all(28.0),
                          child: SelectableText(
                            message.message.split('```')[1].split('```')[0],
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          message.message.split('```').length > 2
                              ? message.message.split('```')[2]
                              : '',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ] else ...[
                        Text(
                          message.message,
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (message.isUser) ...[
                SizedBox(width: 8.0),
                InkWell(
                  onTap: () {
                    //弹窗
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('打赏'),
                          content: Image.network(
                              'https://s3.bmp.ovh/imgs/2024/08/10/ebf4a1353e1798c0.jpg'),
                          actions: [
                            TextButton(
                              child: Text('关注B站'),
                              onPressed: () {
                                //删除消息
                                launchUrl(Uri.parse(
                                    'https://space.bilibili.com/1834448890'));
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://i1.hdslb.com/bfs/face/9824feed6a2fa59534662ab28a39b387e4c90275.jpg'),
                    radius: 20.0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
