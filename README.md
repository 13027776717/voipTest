Push notifications tutorial
====================

On mobile devices (Android & iOS), you probably want your app to be reachable even if it's not in the foreground. 

To do that you need it to be able to receive push notifications from your SIP proxy, and in this tutorial, using [Apple Push Notification Service](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html), you'll learn how to simply send the device push information to your server.

Apple will also require you to use their CallKit API when you receive a push notification, you must always notify CallKit when you receive a VOIP Push or your app will be terminated. If you use the "Core.pushEnabled=true" settings, as is done in this app, most of this work is done in the sdk and you only require to notify an incoming call when your Core Delegate notifies you of a new call.

Compared to the previous tutorials, some changes have been required in `CallKitTutorial.xcodeproj` in order to enable `Push Notifications` and `BackGround Modes (Voice Over IP)` in the capabilities of your project.
