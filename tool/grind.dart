import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:grinder/grinder.dart';
import 'package:http/http.dart';
import 'package:colorize/colorize.dart';

String localIp = getMachineIp();
String port = '4200';

String host = 'http://${localIp}:${port}';
String cordovaFilesPath = '${Directory.current.path}/cordova/platforms/android/platform_www';
String cordovaFilesDestination = '${Directory.current.path}/web';


String getMachineIp() {
  String commandProcess = Platform.isWindows ? 'ipconfig' : 'ifconfig';
  ProcessResult result = Process.runSync(commandProcess, []);

  Iterable<Match> matches = new RegExp(r"\s+IPv4 Address.*: ([\d\.]+)").allMatches(result.stdout);

  // take last because when you have installed virtualbox, it goes at the begining
  return matches.last.group(1).toString();
}

void checkHostAlive(Completer hostIsAlive) {
  new Timer(Duration(seconds: 1), () {
    http
      .get(host)
      .then((Response response) => hostIsAlive.complete(true))
      .catchError((error) => checkHostAlive(hostIsAlive));
  });
}

void removeCordovaJsFromIndexHtml() {
  File indexHtml = new File('${cordovaFilesDestination}/index.html');
  String content = indexHtml.readAsStringSync();
  String newIndexHtmlContent = content.replaceAll('<script defer src="cordova.js"></script>', '');
  indexHtml.writeAsStringSync(newIndexHtmlContent);
}

void addCordovaJsToIndexHtml() {
  File indexHtml = new File('${cordovaFilesDestination}/index.html');
  String content = indexHtml.readAsStringSync();
  String newIndexHtmlContent = content.replaceAll('</head>', '<script defer src="cordova.js"></script></head>');
  indexHtml.writeAsStringSync(newIndexHtmlContent);
}



main(args) => grind(args);

@Task('set content src of cordova index to working with external ip')
set_cordova_config_xml_to_remote_url() {
  File cordovaConfigXml = new File('${Directory.current.path}/cordova/config.xml');
  String content = cordovaConfigXml.readAsStringSync();
  String newContent = content.replaceAllMapped(new RegExp("(<content src=\")(.+)(\" \/>)"), (Match m) => "${m[1]}${host}${m[3]}");
  cordovaConfigXml.writeAsStringSync(newContent);
}

@Task('reset content src of cordova index')
reset_cordova_config_xml() {
  File cordovaConfigXml = new File('${Directory.current.path}/cordova/config.xml');
  String content = cordovaConfigXml.readAsStringSync();
  String newContent = content.replaceAllMapped(new RegExp("(<content src=\")(.+)(\" \/>)"), (Match m) => "${m[1]}index.html${m[3]}");
  cordovaConfigXml.writeAsStringSync(newContent);
}

@Task('create cordova links')
create_cordova_links() {
  Map<String, String> directoryLinks = {
    '${cordovaFilesDestination}/plugins': '${cordovaFilesPath}/plugins',
    '${cordovaFilesDestination}/cordova-js-src': '${cordovaFilesPath}/cordova-js-src',
  };

  directoryLinks.forEach((String key, String value) {
    Link link = Link(key);
    link.createSync(value);
  });

  File cordovaJs = new File('${cordovaFilesPath}/cordova.js');
  cordovaJs.copySync('${cordovaFilesDestination}/cordova.js');

  File cordovaPluginsJs = new File('${cordovaFilesPath}/cordova_plugins.js');
  cordovaPluginsJs.copySync('${cordovaFilesDestination}/cordova_plugins.js');
}

@Task('Cleaning up')
@Depends(reset_cordova_config_xml)
clean() {
  List<File> filesToDelete = [
    new File('${Directory.current.path}/web/cordova.js'),
    new File('${Directory.current.path}/web/cordova_plugins.js')
  ];

  List<Directory> dirsToDelete = [
    new Directory('${Directory.current.path}/web/plugins'),
    new Directory('${Directory.current.path}/web/cordova-js-src'),
  ];

  filesToDelete
      .forEach((File file) => (file.existsSync()) ? file.deleteSync() : null);

  dirsToDelete.forEach((Directory dir) =>
      (dir.existsSync()) ? dir.deleteSync(recursive: true) : null);

  removeCordovaJsFromIndexHtml();
}

@Task()
run_sass() {
  Process.start('sass', ['--watch', '${Directory.current.path}/scss/main.scss:${Directory.current.path}/web/styles.css'], runInShell: true)
    .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((String data){
        Colorize colorizedString = new Colorize(data);
        colorizedString.lightMagenta();
        print(colorizedString);
      });
    });
}

@Task()
@Depends(clean, create_cordova_links, set_cordova_config_xml_to_remote_url, run_sass)
run_android() {
  addCordovaJsToIndexHtml();
  Process.start('webdev', ['serve', 'web:4200', '--hostname=${localIp}'], runInShell: true)
    .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((String data){
        Colorize colorizedString = new Colorize(data);
        colorizedString.lightGreen();
        print(colorizedString);
      });
    });

  Completer<bool> hostIsAlive = new Completer();
  checkHostAlive(hostIsAlive);
  hostIsAlive.future.then((bool isAlive) {
    print('host is alive, start building cordova android app');
    Process.start('cordova', ['run', 'android'], runInShell: true, workingDirectory: Directory.current.path + '/cordova')
      .then((Process process) {
        process.stdout.transform(utf8.decoder).listen((String data){
          Colorize colorizedString = new Colorize(data);
          colorizedString.lightCyan();
          print(colorizedString);
        });
    });
  });
}

/// if you build once before, you can use this task to just run server with cordova available
@Task()
@Depends(clean, create_cordova_links, set_cordova_config_xml_to_remote_url, run_sass)
run_android_wo_build() {
  addCordovaJsToIndexHtml();
  Process.start('webdev', ['serve', 'web:4200', '--hostname=${localIp}'], runInShell: true)
    .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((String data){
        Colorize colorizedString = new Colorize(data);
        colorizedString.lightGreen();
        print(colorizedString);
      });
    });
}

@Task()
@Depends(clean, run_sass)
serve_web() {
  Process.start('webdev', ['serve', 'web:4200'], runInShell: true)
    .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((String data){
        Colorize colorizedString = new Colorize(data);
        colorizedString.lightGreen();
        print(colorizedString);
      });
  });
}

@Task()
@Depends(clean, run_sass)
serve_web_external() {
  Process.start('webdev', ['serve', 'web:4200', '--hostname=${localIp}'], runInShell: true)
    .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((String data){
        Colorize colorizedString = new Colorize(data);
        colorizedString.lightGreen();
        print(colorizedString);
      });
  }); 
}