//
//  IPAdress.h
//  dlna
//
//  Created by jackyshan on 2017/3/25.
//  Copyright © 2017年 jackyshan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPAdress : NSObject

+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSDictionary *)getIPAddresses;

@end
