#import "AppDelegate.h"     // Header

#import "TMWStore.h"        // TMW (Model)
#import "TMWStoryboardIDs.h"// TMW (ViewControllers/Segues)
#import "TMWActions.h"      // TMW (ViewControllers/Protocol)
#import "TMWRootViewControllerSwapSegue.h"
#import <Relayr/Relayr.h>   // Relayr.framework

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:TMWStoryboard bundle:nil];
    
    TMWStore* store = [TMWStore sharedInstance];
    UIViewController <TMWActions>* controller;
    if (store.relayrApp && store.relayrUser)
    {
        controller = [storyboard instantiateViewControllerWithIdentifier:TMWStoryboardIDs_ControllerMain];
        [controller loadIoTsWithCompletion:nil];
    }
    else { _window.rootViewController = [storyboard instantiateInitialViewController]; }
    _window.rootViewController = controller;
    [_window makeKeyAndVisible];
    
    // Setup the notifications.
    UIUserNotificationType const notificationTypes = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    
    // Retrieve the notification (if any) that launched the application.
    NSDictionary* notif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notif.count) { [((id <TMWActions>)_window.rootViewController) notificationDidArrived:notif]; }
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application { }
- (void)applicationDidBecomeActive:(UIApplication*)application { }
- (void)applicationWillResignActive:(UIApplication*)application { }
- (void)applicationWillTerminate:(UIApplication*)application { }
- (void)applicationDidEnterBackground:(UIApplication*)application
{
    TMWStore* store = [TMWStore sharedInstance];
    
    RelayrApp* app = [TMWStore sharedInstance].relayrApp;
    RelayrUser* user = app.loggedUsers.firstObject;
    if (!app || !user) { [store removeFromFileSystem]; return; }
    
    [store persistInFileSystem];
}

- (void)application:(UIApplication*)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings { }
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [((id <TMWActions>)_window.rootViewController) deviceTokenChangedFromData:[TMWStore sharedInstance].deviceToken toData:deviceToken];
}
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [((id <TMWActions>)_window.rootViewController) deviceTokenChangedFromData:[TMWStore sharedInstance].deviceToken toData:nil];
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    [((id <TMWActions>)_window.rootViewController) notificationDidArrived:userInfo];
}

@end
