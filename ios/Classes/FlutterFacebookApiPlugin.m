#import "FlutterFacebookApiPlugin.h"
#import <flutter_facebook_api/flutter_facebook_api-Swift.h>

@implementation FlutterFacebookApiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterFacebookApiPlugin registerWithRegistrar:registrar];
}
@end
