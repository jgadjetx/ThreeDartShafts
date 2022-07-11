import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart_jsm/three_dart_jsm.dart' as THREE_JSM;

class Home extends StatefulWidget {

  Home({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<Home> {
  late FlutterGlPlugin three3dRender;
  THREE.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;

  double dpr = 1.0;
  bool verbose = true;
  bool disposed = false;

  late THREE.WebGLRenderTarget renderTarget;

  dynamic? sourceTexture;


  final GlobalKey<THREE_JSM.DomLikeListenableState> _globalKey = GlobalKey<THREE_JSM.DomLikeListenableState>();

  late THREE_JSM.MapControls controls;

  static const double radius = 5;
  static const  double diameter = radius * 2;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height - 60;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P45 SHAFTS V2 Mobile"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return Container(child: _build(context));
        },
      ),
      floatingActionButton: TextButton(
        child: const Text(
          "RESET",
          style: TextStyle(
            color: Color(0xFFE89C00)
          ),
        ),
        onPressed: () {         
          camera.position.set(1,50, 20);
          camera.lookAt(camera.position);
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Stack(
            children: [
              THREE_JSM.DomLikeListenable(
                  key: _globalKey,
                  builder: (BuildContext context) {
                    return Container(
                        width: width,
                        height: height,
                        color: Colors.black,
                        child: Builder(builder: (BuildContext context) {
                         
                          return three3dRender.isInitialized ? Texture(textureId: three3dRender.textureId!) : Container();
                          
                        }));
                  }),
            ],
          ),
        ),
      ],
    );
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;
    final _gl = three3dRender.gl;

    controls.update();

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    _gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = THREE.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = THREE.WebGLRenderTargetOptions({
        "minFilter": THREE.LinearFilter,
        "magFilter": THREE.LinearFilter,
        "format": THREE.RGBAFormat
      });
      renderTarget = THREE.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  loadFont() async {
    var loader = THREE_JSM.TYPRLoader(null);
    var fontJson = await loader.loadAsync("assets/pingfang.ttf");

    print("loadFont successs ............ ");

    return THREE.TYPRFont(fontJson);
  }

  initPage()async {

    //scene
    scene = THREE.Scene();
    scene.background = THREE.Color(0x282728);
    
    //camera
    camera = THREE.PerspectiveCamera(20, width / height, 0.1, 1000);
    camera.position.set(1,50, 30);
    camera.lookAt(scene.position);

    // controls
    controls = THREE_JSM.MapControls(camera, _globalKey);

    //lights
    var ambientLight = THREE.AmbientLight(0xffffff, 0.6);
    var directionalLight = THREE.DirectionalLight(0xffffff, 0.6);
    directionalLight.position.set(10, 20, 0);
    scene.addAll([ambientLight, directionalLight]);

    //world
    var font = await loadFont();
    
    var elementOne = THREE.Mesh(
      THREE.CylinderGeometry(1,1,1,60),
      THREE.MeshLambertMaterial({'color': 0x989799,"transparent": true,"opacity": 0.9,})
    );

    elementOne.position.set(2.3,0.5);
    elementOne.scale.x = 0.2;
    elementOne.scale.y = 1;
    elementOne.scale.z = 0.2;
    
    scene.add(elementOne);

    var shaftOutter = THREE.Mesh(
      THREE.CircleGeometry(radius: radius,segments: 100),
      THREE.MeshBasicMaterial({'color': 0x989799,"side": THREE.DoubleSide,})
    );

    var shaftBase = THREE.Mesh(
      THREE.CircleGeometry(radius: radius - 0.1,segments: 100),
      THREE.MeshBasicMaterial({'color': 0x515151,"side": THREE.DoubleSide,})
    );
    
    shaftOutter.rotation.set(1.2, 0, 0);
    shaftBase.rotation.set(1.2, 0, 0);

    //add to scene
    scene.addAll([shaftBase,shaftOutter]);
    renderCompassElement("N",font);
    renderCompassElement("E",font);
    renderCompassElement("S",font);
    renderCompassElement("w",font);

    animate();
  }

  renderCompassElement(symbol,font){

    const diameterPercentage = 2.5 * (diameter / 100);
    const positionReletiveToDiameter = diameter/ 2 + diameterPercentage;
    var textGeo = THREE.Mesh(
      THREE.TextGeometry(
        symbol,
        {
          "font":font,
          "size":diameterPercentage,
          "height":0.01
        }
      ),
      THREE.MeshPhongMaterial({'color': 0xe89c00})
    );

    textGeo.rotation.x = -1.55;
    
    switch (symbol) {
      case 'N':
        textGeo.position.z = -positionReletiveToDiameter;
        break;
      case 'E':
        textGeo.position.x = positionReletiveToDiameter;
        break;
      case 'S':
        textGeo.position.z = positionReletiveToDiameter + diameterPercentage;
        break;
      default:
        textGeo.position.x = - positionReletiveToDiameter - diameterPercentage;
    }

    scene.add(textGeo);
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }
    
    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");

    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
