import 'package:angular/angular.dart';
import 'package:cordova/cordova.dart';

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  directives: [coreDirectives]
)
class AppComponent implements OnInit {
  Cordova cordova = Cordova();
  String name = 'Angular';
  bool isDeviceReady = false;

  void ngOnInit() {
    cordova.isDeviceReady().then((bool isReady) => this.isDeviceReady = isReady); 
  }
}
