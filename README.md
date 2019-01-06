# Cordova - Angular Dart

## Overview
If you would like to build app with cordova, like ionic-angular, but wanna learn or just use angular dart, you can use this starter.

## Issues

- Currently working only for android, its matter of create new grinder task to work with ios.

## Setup
- clone this repo and inside your directory use command "pub get"
- go to cordova directory and install dependencies by running "npm install"
- in cordova directory add android platform

## Usage - commands

### web
- you can use just "webdev serve" command and develop you app without cordova plugins, like you would do in ionic serve command
- grind run_sass - it make sass watcher for scss file scss/main.scss and compile it to web/styles.css
- grind serve_web - this command use webdev serve command on port 4200
- grind serve_web_external - webdev serve on external ip (machine ip ex: 192.168.148.1)
### device

- grind clean - clean all stuff needed to work with cordova, you may need this if you switch from development android to webdev serve
- grind run_android - run your angular app with cordova on android, working just like ionic run android --livereload. So you can make changes in your code, refresh the browser and here you go. 
- grind run_android_wo_build - when you deploy your apk to device once before, using command grind run_android, and now you wanna resume your work. Just run this command, open your app on device and you can resume your work without building apk from scratch.
