//
//  Gameplay.m
//  AngryBirdDemo
//
//  Created by Romain MULLOT on 15/08/2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"

@interface Gameplay()
{
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
}
@end

@implementation Gameplay

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    CCNode *level = [CCBReader load:@"Levels/Level1"];
    [_levelNode addChild:level];
    _physicsNode.debugDraw = TRUE;
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    [self launchProjectile];
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

- (void)launchProjectile {
    
    CCNode* projectile = [CCBReader load:@"Projectile"];
    projectile.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    [_physicsNode addChild:projectile];
    
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [projectile.physicsBody applyForce:force];
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:projectile worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}
@end
