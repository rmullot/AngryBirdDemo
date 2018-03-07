//
//  ABButtonNode.h
//  AngryBirdDemo
//
//  Created by Romain Mullot on 06/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum {
    active,
    selected,
    hidden
}ABButtonNodeState;

@interface ABButtonNode : SKSpriteNode

@property (nonatomic,getter= setState) ABButtonNodeState state;
@property (nonatomic, copy) void (^selectedHandler)(void);
@end
