import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:widget_image_extractor/boundary_image_resolver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? _bytes;
  final _globalKey = GlobalKey();

  void _incrementCounter() async {
    final bytes = await controller.capture();
    setState(() {
      _bytes = bytes;
    });
  }

  final controller = ImageBoundaryController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageBoundaryResolver(
          child: Container(
            color: Colors.blue,
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Container(
                  color: Colors.white,
                  child: ImageBoundary(
                    key: _globalKey,
                    controller: controller,
                    child: const Text(
                      'You "aisuhdasiudh aiojsdaosid aiosjda',
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.topLeft,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          color: Colors.blue,
                          child: _bytes != null
                              ? Image.memory(
                                  _bytes!,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
