//
//  ABReferenceNode.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 06/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import "ABReferenceNode.h"

@implementation ABReferenceNode
-(void)didLoadReferenceNode:(SKNode *)node{
    /* Set reference to avatar node */
    _avatar = (SKSpriteNode *) [self childNodeWithName:@"//avatar"];
}
@end
 