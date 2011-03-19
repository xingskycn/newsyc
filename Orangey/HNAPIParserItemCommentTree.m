//
//  HNAPIParserItemCommentTree.m
//  Orangey
//
//  Created by Grant Paul on 3/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HNAPIParserItemCommentTree.h"
#import "XMLDocument.h"

@implementation HNAPIParserItemCommentTree

- (id)parseString:(NSString *)string options:(NSDictionary *)options {
    XMLDocument *document = [[XMLDocument alloc] initWithHTMLData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *lasts = [NSMutableArray array];
    
    NSArray *comments = [document elementsMatchingPath:@"//table//tr[position()>1]//td//table//tr//table//tr"];
    
    for (int i = 0; i < [comments count]; i++) {
        XMLElement *comment = [comments objectAtIndex:i];
        
        NSNumber *depth = nil;
        NSNumber *points = [NSNumber numberWithInt:0];
        NSString *body = nil;
        NSString *user = nil;
        NSNumber *identifier = nil;
        NSString *date = nil;
        NSMutableArray *children = nil;
        
        for (XMLElement *element in [comment children]) {
            if ([[element attributeWithName:@"class"] isEqual:@"default"]) {
                for (XMLElement *element2 in [element children]) {
                    if ([[element2 tagName] isEqual:@"div"]) {
                        for (XMLElement *element3 in [element2 children]) {
                            if ([[element3 attributeWithName:@"class"] isEqual:@"comhead"]) {
                                NSString *content = [element3 content];
                                
                                // XXX: is there any better way of doing this?
                                int start = [content rangeOfString:@"</a> "].location;
                                if (start != NSNotFound) content = [content substringFromIndex:start + [@"</a> " length]];
                                int end = [content rangeOfString:@" ago"].location;
                                if (end != NSNotFound) date = [content substringToIndex:end];
                                
                                for (XMLElement *element4 in [element3 children]) {
                                    NSString *content = [element4 content];
                                    NSString *tag = [element4 tagName];
                                    
                                    if ([tag isEqual:@"a"]) {
                                        NSString *href = [element4 attributeWithName:@"href"];
                                        
                                        if ([href hasPrefix:@"user?id="]) {
                                            user = content;
                                        } else if ([href hasPrefix:@"item?id="]) {
                                            identifier = [NSNumber numberWithInt:[[href substringFromIndex:[@"item?id=" length]] intValue]];
                                        }
                                    } else if ([tag isEqual:@"span"]) {
                                        int end = [content rangeOfString:@" "].location;
                                        if (end != NSNotFound) points = [NSNumber numberWithInt:[[content substringToIndex:end] intValue]];
                                    }
                                }
                            }
                        }
                    } else if ([[element2 attributeWithName:@"class"] isEqual:@"comment"]) {
                        // XXX: strip out _reply_ link at the bottom.
                        body = [element2 content];
                    }
                }
            } else {
                for (XMLElement *element2 in [element children]) {
                    if ([[element2 tagName] isEqual:@"img"] && [[element2 attributeWithName:@"src"] isEqual:@"http://ycombinator.com/images/s.gif"]) {
                        // Yes, really: HN uses a 1x1 gif to indent comments. It's like 1999 all over again. :(
                        int width = [[element2 attributeWithName:@"width"] intValue];
                        depth = [NSNumber numberWithInt:width / 40];
                    }
                }
            }
        }
        
        if (depth != nil) children = [NSMutableArray array];
        
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:user forKey:@"user"];
        [item setObject:body forKey:@"body"];
        [item setObject:identifier forKey:@"identifier"];
        [item setObject:date forKey:@"ago"];
        [item setObject:points forKey:@"points"];
        if (children != nil) [item setObject:children forKey:@"children"];

        if ([lasts count] >= [depth intValue]) [lasts removeObjectsInRange:NSMakeRange([depth intValue], [lasts count] - [depth intValue])];
        [lasts addObject:item];
        
        if ([depth intValue] == 0) {
            [result addObject:item];
        } else {
            NSMutableArray *children = [[lasts objectAtIndex:[depth intValue] - 1] objectForKey:@"children"];
            [children addObject:item];
        }
    }
        
    [document release];
    
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:result forKey:@"children"];
    return item;
}

@end
