import 'dart:io' as io;
import 'dart:isolate';
import 'package:diff_image/diff_image.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'So Sánh Ảnh'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> imgBytes1;
  List<int> imgBytes2;
  Isolate isolate;
  TextEditingController controller;
  final ImagePicker imagePicker = ImagePicker();
  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialogSelectImage1(context: context);
                      },
                      child: imgBytes1 == null
                          ? Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.width * 0.5,
                              alignment: Alignment.center,
                              color: Colors.grey,
                              child: Text("Chọn ảnh 1"),
                            )
                          : Image.memory(imgBytes1, fit: BoxFit.fill),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        showDialogSelectImage2(context: context);
                      },
                      child: imgBytes2 == null
                          ? Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: MediaQuery.of(context).size.width * 0.5,
                              color: Colors.grey,
                              alignment: Alignment.center,
                              child: Text("Chọn ảnh 2"),
                            )
                          : Image.memory(imgBytes2, fit: BoxFit.fill),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.compare),
                onPressed: () {
                  compaireImage();
                },
                label: Text("So sánh"),
              ),
              SizedBox(
                height: 20,
              ),
              Text("Kết quả: ${controller.text}")
            ],
          ),
        ),
      ),
    );
  }

  void showDialogSelectImage1({BuildContext context}) {
    Alert(
      context: context,
      title: "Chọn ảnh",
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Chọn từ thư viện"),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Chụp hình"),
            ),
          )
        ],
      ),
    ).show().then((value) {
      print("$value");
      if (value != null) {
        if (value) {
          selectImageFromCamera1();
        } else {
          selectImageFromLibrary1();
        }
      }
    });
  }

  void showDialogSelectImage2({BuildContext context}) {
    Alert(
      context: context,
      title: "Chọn ảnh",
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Chọn từ thư viện"),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Flexible(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Chụp hình"),
            ),
          )
        ],
      ),
    ).show().then((value) {
      print("$value");
      if (value != null) {
        if (value) {
          selectImageFromCamera2();
        } else {
          selectImageFromLibrary2();
        }
      }
    });
  }

  Future<void> selectImageFromCamera1() async {
    final pickedFile = await imagePicker.getImage(
        source: ImageSource.camera, maxWidth: 250, maxHeight: 500);
    if (pickedFile != null) {
      io.File _image = io.File(pickedFile.path);
      _asyncInit1(_image);
    }
  }

  Future<void> selectImageFromLibrary1() async {
    final pickedFile = await imagePicker.getImage(
        source: ImageSource.gallery, maxWidth: 250, maxHeight: 500);
    if (pickedFile != null) {
      io.File _image = io.File(pickedFile.path);
      _asyncInit1(_image);
    }
  }

  Future<void> selectImageFromCamera2() async {
    final pickedFile = await imagePicker.getImage(
        source: ImageSource.camera, maxWidth: 250, maxHeight: 500);
    if (pickedFile != null) {
      io.File _image = io.File(pickedFile.path);
      _asyncInit2(_image);
    }
  }

  Future<void> selectImageFromLibrary2() async {
    final pickedFile = await imagePicker.getImage(
        source: ImageSource.gallery, maxWidth: 250, maxHeight: 500);
    if (pickedFile != null) {
      io.File _image = io.File(pickedFile.path);
      _asyncInit2(_image);
    }
  }

  static _isolateEntry(dynamic d) async {
    final ReceivePort receivePort = ReceivePort();
    d.send(receivePort.sendPort);

    final config = await receivePort.first;

    print(config);

    final file = io.File(config['path']);
    final bytes = await file.readAsBytes();

    img.Image image = img.decodeImage(bytes);
    img.Image thumbnail = img.copyResize(
      image,
      width: 250,
      height: 500,
    );

    d.send(img.encodeNamedImage(thumbnail, basename(config['path'])));
  }

  _asyncInit1(io.File file) async {
    final ReceivePort receivePort = ReceivePort();
    isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);

    receivePort.listen((dynamic data) {
      if (data is SendPort) {
        if (mounted) {
          data.send({
            'path': file.path,
            'size': Size(250, 500),
          });
        }
      } else {
        if (mounted) {
          setState(() {
            imgBytes1 = data;
          });
        }
      }
    });
  }

  _asyncInit2(io.File file) async {
    final ReceivePort receivePort = ReceivePort();
    isolate = await Isolate.spawn(_isolateEntry, receivePort.sendPort);
    receivePort.listen((dynamic data) {
      if (data is SendPort) {
        if (mounted) {
          data.send({
            'path': file.path,
            'size': Size(252, 500),
          });
        }
      } else {
        if (mounted) {
          setState(() {
            imgBytes2 = data;
          });
        }
      }
    });
  }

  void compaireImage() {
    try {
      img.Image imge1 = img.decodeImage(imgBytes1);
      img.Image imge2 = img.decodeImage(imgBytes2);
      var diff = DiffImage.compareFromMemory(
        imge1,
        imge2,
      );
      controller.text = "Giống nhau ${100 - diff.diffValue}%";
    } catch (e) {
      controller.text = "$e";
      print(e);
    }
  }
}
