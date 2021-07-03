//
//  AppDelegate.m
//  BLEDemo
//
//  Created by Bri on 2021/4/21.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
