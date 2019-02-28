import Flutter
import UIKit
import FBSDKLoginKit
import FBSDKShareKit

public class SwiftFlutterFacebookApiPlugin: NSObject, FlutterPlugin {
    let loginManager: FBSDKLoginManager
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_facebook_api", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterFacebookApiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public override init() {
        loginManager = FBSDKLoginManager()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "loginWithReadPermissions" || call.method == "loginWithPublishPermissions" {
            var lBehavior: FBSDKLoginBehavior = .native
            var permissions: [String] = []
            if let aru = call.arguments as? [String: AnyObject] {
                if let behav = aru["behavior"] as? String {
                    lBehavior = self.loginBehavior(of: behav)
                }
                if let per = aru["permissions"] as? [String] {
                    permissions = per
                }
            }
            if call.method == "loginWithPublishPermissions" {
                self.loginWithPublishPermissions(behavior: lBehavior,
                                                 permissions: permissions,
                                                 result: result)
            } else {
                self.loginWithReadPermissions(behavior: lBehavior,
                                              permissions: permissions,
                                              result: result)
            }
        } else if call.method == "logOut" {
            logOut(result: result)
        } else if call.method == "getCurrentAccessToken" {
            getCurrentAccessToken(result: result)
        } else if call.method == "share" {
            if let arguments = call.arguments as? [String: Any] {
                var shareImage: UIImage?
                if let imgData = (arguments["image"] as? FlutterStandardTypedData)?.data {
                    shareImage = UIImage(data: imgData)
                }
                let shareText = arguments["caption"] as? String ?? ""
                shareFacebook(withImage: shareImage, caption: shareText, result: result)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func loginWithReadPermissions(behavior: FBSDKLoginBehavior, permissions: [Any], result: @escaping FlutterResult) {
        loginManager.loginBehavior = behavior
        loginManager.logIn(withReadPermissions: permissions, from: nil) { (loginResult, error) in
            self.handleLoginResult(loginResult: loginResult!, error: error, result: result)
        }
    }
    
    private func loginWithPublishPermissions(behavior: FBSDKLoginBehavior, permissions: [Any], result: @escaping FlutterResult) {
        loginManager.loginBehavior = behavior
        loginManager.logIn(withPublishPermissions: permissions, from: nil) { (loginResult, error) in
            self.handleLoginResult(loginResult: loginResult!, error: error, result: result)
        }
    }
    
    private func handleLoginResult(loginResult: FBSDKLoginManagerLoginResult, error: Error?, result: FlutterResult) {
        if error != nil {
            let resultDic = [
                "status": "error",
                "errorMessage": error!.localizedDescription
            ]
            result(resultDic)
        } else {
            if loginResult.isCancelled {
                let resultDic = [
                    "status": "cancelledByUser",
                ]
                result(resultDic)
            } else {
                let mappedToken = ""
                let resultDic = [
                    "status": "loggedIn",
                    "errorMessage": mappedToken
                ]
                result(resultDic)
            }
        }
    }
    
    func logOut(result: FlutterResult) {
        loginManager.logOut()
        result(nil)
    }
    
    func getCurrentAccessToken(result: FlutterResult) {
        let currentToken = FBSDKAccessToken.current()
        result(accessTokenToMap(accessToken: currentToken))
    }
    
    private func loginBehavior(of behavior: String) -> FBSDKLoginBehavior {
        if behavior == "webOnly" {
            return .browser
        } else if behavior == "webViewOnly" {
            return .web
        } else if behavior == "nativeOnly" {
            return .native
        }
        return .native
    }
    
    private func accessTokenToMap(accessToken: FBSDKAccessToken?) -> [String: AnyObject]? {
        if (accessToken == nil) {
            return nil
        }
        return [
            "token": accessToken!.tokenString as AnyObject,
            "userId": accessToken!.userID as AnyObject,
            "expires": accessToken!.expirationDate.timeIntervalSince1970 * 1000.0 as AnyObject,
            "permissions": [] as AnyObject,
            "declinedPermissions": [] as AnyObject
        ]
    }

    // Share block
    private func shareFacebook(withImage image: UIImage?, caption: String, result: @escaping FlutterResult) {        
        DispatchQueue.main.async {
            func isFBInstalled() -> Bool {
                var components = URLComponents()
                components.scheme = "fbauth2"
                components.path = "/"
                return UIApplication.shared.canOpenURL(components.url!)
            }
            if isFBInstalled() {
                let shareDialog = FBSDKShareDialog()
                let fbPhoto = FBSDKSharePhoto(image: image, userGenerated: true)
                let content = FBSDKSharePhotoContent()
                content.photos = [fbPhoto as Any]
                shareDialog.shareContent = content
                
                if let flutterAppDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
                    shareDialog.fromViewController = flutterAppDelegate.window.rootViewController
                    shareDialog.mode = .automatic
                    shareDialog.show()
                    result("Success")
                }
            } else {
                result("Cannot find facebook app")
            }
        }
    }
}
