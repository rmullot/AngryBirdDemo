//
//  GameScene.h
//  AngryBirdDemo
//
//  Created by Romain Mullot on 05/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <GameplayKit/GameplayKit.h>
#import "ABButtonNode.h"

@interface GameScene : SKScene<SKPhysicsContactDelegate>
/* Game object connections */
@property (nonatomic) SKSpriteNode *catapultArm;
@property (nonatomic) SKSpriteNode *catapult;
@property (nonatomic) SKSpriteNode *cantileverNode;
@property (nonatomic) SKSpriteNode *touchNode;

/* Level loader holder */
@property (nonatomic) SKNode *levelHolder;

/* Tracking helpers */
@property (nonatomic,getter= setTrackerNode) SKNode *trackerNode;
@property (nonatomic) CGPoint lastTrackerPosition;
@property (nonatomic) NSTimeInterval lastTimeInterval;

/* Physics helpers */
@property (nonatomic) SKPhysicsJointSpring *touchJoint;
@property (nonatomic) SKPhysicsJointPin *penguinJoint;

/* UI Connections */
@property (nonatomic) ABButtonNode *buttonRestart;

@end
