
#import "Utility.h"

@implementation Utility

static NSString *databasePath;

+(NSString *) getDatabasePath
{
    
    //NSString *databasePath;
    //if (!databasePath) {
        databasePath = [(AppDelegate *)[[UIApplication sharedApplication] delegate] databasePath];
    //}
    
    return databasePath; 
}

/*---------------------------------------------------------------------------
 * method pops alert message to screen
 *---------------------------------------------------------------------------*/
+(void)alertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

/*---------------------------------------------------------------------------
 * method encodes and returns a string formatted to pass in a url
 *---------------------------------------------------------------------------*/
+(NSString *) urlEncodeData:(NSString *)str {
    NSString *encodedString = (__bridge NSString *)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)str,
                                            NULL,
                                            CFSTR("!*'();:@&=+$,/?%#[]"),
                                            kCFStringEncodingUTF8);
    return encodedString;
}

+(NSString *) urlDecodeData:(NSString *)str {
    return (__bridge NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef) str, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
}

+(NSMutableArray *)repackDictionaryForSetSQLiteTable:(NSDictionary *)dic keyList:(NSArray *)keyList {
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
    id value;
    for (id key in keyList) {
        value = [dic objectForKey:key];
        if (value) {
            [retDic setObject:value forKey:key];
        }
        else {
            
        }
        
    }
    [arr addObject:retDic];
    
    return arr;
}


@end
