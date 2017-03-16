//
//  MJKeywordTool.h
//  Common
//
//  Created by 黄磊 on 16/7/22.
//
//

#import <Foundation/Foundation.h>

typedef void (^KeywordSuggestBlock)(NSString *theKeyword, NSArray *suggestList);


@interface MJKeywordTool : NSObject

+ (instancetype)sharedInstance;

- (void)suggestKeywordFor:(NSString *)aKeyword completion:(KeywordSuggestBlock)completion;

@end
