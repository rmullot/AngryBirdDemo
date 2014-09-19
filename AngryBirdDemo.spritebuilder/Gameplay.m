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
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    CCNode *_currentProjectile;
    CCPhysicsJoint *_penguinCatapultJoint;
    
}
@end

@implementation Gameplay

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
    CCNode *level = [CCBReader load:@"Levels/Level1"];
    [_levelNode addChild:level];
    _physicsNode.debugDraw = TRUE;
    //No collision possible with those invisible elements
    //There usefull only for the joints node
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
}

-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    //If we touch the catapult arm
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        //We save the initial position of the finger in changing the position of the mouse joint
        _mouseJointNode.position = touchLocation;
        
        //We create a joint between our finger and catapult
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        //Now We create a projectile
        _currentProjectile = [CCBReader load:@"Projectile"];
        CGPoint projectilePosition = [_catapultArm convertToWorldSpace:ccp(34,138)];
        _currentProjectile.position = [_physicsNode convertToNodeSpace:projectilePosition];
        // add it to the physics world
        [_physicsNode addChild:_currentProjectile];
        _currentProjectile.physicsBody.allowsRotation = FALSE;
        
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentProjectile.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentProjectile.anchorPointInPoints];
    }
}

#pragma mark - Touch events
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches end, meaning the user releases their finger, release the catapult
    [self launchProjectile];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches are cancelled, meaning the user drags their finger off the screen or onto something else, release the catapult
    [self launchProjectile];
}

- (void)launchProjectile {
    if (_mouseJoint != nil)
    {
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        //We authorize the rotation when the projectile fly
        _currentProjectile.physicsBody.allowsRotation = TRUE;
    
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentProjectile worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
    }
    
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}
@end
