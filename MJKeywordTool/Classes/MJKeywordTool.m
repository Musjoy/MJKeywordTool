//
//  MJKeywordTool.m
//  Common
//
//  Created by 黄磊 on 16/7/22.
//
//

#import "MJKeywordTool.h"
#ifdef MODULE_FILE_SOURCE
#import "FileSource.h"
#endif

#import HEADER_WEB_SERVICE


#ifndef FILE_NAME_SUGGEST_API
#define FILE_NAME_SUGGEST_API   @"suggest_api"
#endif

#define DEFAULT_SUGGEST_URL @"https://suggestqueries.google.com/complete/search?output=firefox&hl={lg}&q={q}"

static MJKeywordTool *s_keywordTool = nil;

@interface MJKeywordTool ()

@property (nonatomic, strong) NSCache *cacheSuggests;
@property (nonatomic, strong) NSString *serverUrl;
@property (nonatomic, strong) NSString *curLanguage;

@end

@implementation MJKeywordTool

+ (instancetype)sharedInstance
{
    static dispatch_once_t once_patch;
    dispatch_once(&once_patch, ^() {
        s_keywordTool = [[self alloc] init];
    });
    return s_keywordTool;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSDictionary *dicAPI = getFileData(FILE_NAME_SUGGEST_API);
        if (dicAPI) {
            _serverUrl = dicAPI[@"server_url"];
        }
        if (_serverUrl.length == 0) {
            _serverUrl = DEFAULT_SUGGEST_URL;
        }
        _cacheSuggests = [[NSCache alloc] init];
        
#ifdef MODULE_FILE_SOURCE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadAPI)
                                                     name:[kNoticPlistUpdate stringByAppendingString:FILE_NAME_SUGGEST_API]
                                                   object:nil];
#endif
    }
    return self;
}

- (NSString *)curLanguage
{
    if (_curLanguage == nil) {
        NSArray *languages = [NSLocale preferredLanguages];
        _curLanguage = [languages objectAtIndex:0];
    }
    return _curLanguage;
}


- (void)reloadAPI
{
    NSDictionary *dicAPI = getFileData(FILE_NAME_SUGGEST_API);
    if (dicAPI) {
        _serverUrl = dicAPI[@"server_url"];
    }
    if (_serverUrl.length == 0) {
        _serverUrl = DEFAULT_SUGGEST_URL;
    }
}


- (void)suggestKeywordFor:(NSString *)aKeyword completion:(KeywordSuggestBlock)completion
{
    // 参数盘点
    if (aKeyword.length == 0) {
        return;
    }
    if (completion == NULL) {
        return;
    }
    
    // 读取缓存
    NSArray *arrSuggest = [_cacheSuggests objectForKey:aKeyword];
    if (arrSuggest) {
        completion(aKeyword, arrSuggest);
        return;
    }
    
    // 从网络获取建议列表
    [self fetchSuggestFor:aKeyword completion:^(NSString *theKeyword, NSArray *suggestList) {
        if (suggestList) {
            [_cacheSuggests setObject:suggestList forKey:theKeyword];
            completion(theKeyword, suggestList);
        }
    }];
    
    
}


- (void)fetchSuggestFor:(NSString *)aKeyword completion:(KeywordSuggestBlock)completion
{
    // 拼接请求url
    aKeyword = [aKeyword stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *serverUrl = [_serverUrl stringByReplacingOccurrencesOfString:@"{q}" withString:aKeyword];
    if ([serverUrl rangeOfString:@"{lg}"].length > 0) {
        serverUrl = [serverUrl stringByReplacingOccurrencesOfString:@"{lg}" withString:self.curLanguage];
    }
    
    getServerUrl(serverUrl, ^(NSURLResponse *response, id data, NSError *error) {
        if (!error) {
            if ([data isKindOfClass:[NSArray class]]) {
                NSArray *arr = data;
                if (arr.count >= 2) {
                    completion(arr[0], arr[1]);
                }
            }
        }
    });
    
}



@end
