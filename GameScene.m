//
//  GameScene.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 05/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import "GameScene.h"
#import <SceneKit/SceneKit.h>
#import "ABReferenceNode.h"
@implementation GameScene 

- (void) setTrackerNode:(SKNode*)trackerNode {
    if(trackerNode != nil){
        /* Set tracker */
        _lastTrackerPosition = trackerNode.position;
    }
    
}

- (void)sceneDidLoad {
    // Setup your scene here
    _lastTrackerPosition = CGPointMake(0,0);
    _lastTimeInterval = 0;
    
}

-(void) didMoveToView:(SKView *)view{
    /* Set reference to catapultArm SKSpriteNode */
    _catapultArm = (SKSpriteNode *)[self childNodeWithName:@"catapultArm"];
    _catapult = (SKSpriteNode *)[self childNodeWithName:@"catapult"];
    _cantileverNode = (SKSpriteNode *)[self childNodeWithName:@"cantileverNode"];
    _touchNode = (SKSpriteNode *)[self childNodeWithName:@"touchNode"];
    
    /* Set reference to levelHolder SKNode */
    _levelHolder = [self childNodeWithName:@"levelHolder"];
    
    /* Set reference to buttonRestart SKSpriteNode */
    _buttonRestart = (ABButtonNode *)[self childNodeWithName:@"//buttonRestart"];
    
    /* Setup button selection handler */
    _buttonRestart.selectedHandler = ^void(void){
        if(self.view != nil){
            
            // Load the SKScene from 'GameScene.sks'
            SKScene *scene = [SKScene nodeWithFileNamed: @"GameScene"];
            if(scene != nil){
                
                // Set the scale mode to scale to fit the window
                scene.scaleMode = SKSceneScaleModeAspectFit;
                
                // Present the scene
                [view presentScene:scene];
            }
            
            // Debug helpers
            view.showsFPS = true;
            view.showsPhysics = true;
            view.showsDrawCount = true;
        }
    };
    
    /* Load Level 1 */
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource: @"Level1" ofType: @"sks"];
    SKReferenceNode *level = [SKReferenceNode referenceNodeWithURL:[NSURL fileURLWithPath:resourcePath]];
    [_levelHolder addChild:level];
    
    /* Initialize catapult arm physics body of type alpha */
    SKPhysicsBody *catapultArmBody = [SKPhysicsBody bodyWithTexture:_catapultArm.texture size: _catapultArm.size];
    
    /* Mass needs to be heavy enough to hit the penguin with sufficient force */
    catapultArmBody.mass = 0.5;
    
    /* No need for gravity otherwise the arm will fall over */
    catapultArmBody.affectedByGravity = false;
    
    /* Improves physics collision handling of fast moving objects */
    catapultArmBody.usesPreciseCollisionDetection = true;
    
    /* Assign the physics body to the catapult arm */
    _catapultArm.physicsBody = catapultArmBody;
    
    /* Pin joint catapult and catapult arm */
    SKPhysicsJointPin *catapultPinJoint = [SKPhysicsJointPin jointWithBodyA:_catapult.physicsBody bodyB:_catapultArm.physicsBody anchor:CGPointMake(-91 ,-55)];
    [self.physicsWorld addJoint:catapultPinJoint];
    
    /* Spring joint catapult arm and cantilever node */
    SKPhysicsJointSpring *catapultSpringJoint = [SKPhysicsJointSpring jointWithBodyA:_catapultArm.physicsBody bodyB:_cantileverNode.physicsBody anchorA: CGPointMake(_catapultArm.position.x+15,_catapultArm.position.y+30) anchorB:_cantileverNode.position];
    [self.physicsWorld addJoint:catapultSpringJoint];
    
    /* Make this joint a bit more springy */
    catapultSpringJoint.frequency = 1.5;
    
    /* Set physics contact delegate */
    self.physicsWorld.contactDelegate = self;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    /* There will only be one touch as multi touch is not enabled by default */
    for(UITouch *touch in touches){
        
        /* Grab scene position of touch */
        CGPoint location = [touch locationInNode: self];
        
        /* Get node reference if we're touching a node */
        SKNode * touchedNode = [self nodeAtPoint:location];
        
        /* Is it the catapult arm? */
        if ([touchedNode.name  isEqual: @"catapultArm"]){
            
            /* Reset touch node position */
            _touchNode.position = location;
            
            /* Spring joint touch node and catapult arm */
            _touchJoint = [SKPhysicsJointSpring jointWithBodyA:_touchNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:location anchorB:location];
            [self.physicsWorld addJoint:_touchJoint];
            
            /* Add a new penguin to the scene */
            ABReferenceNode *penguin = [ABReferenceNode nodeWithFileNamed:@"Penguin"];
            [self addChild:penguin];
            
            /* Position penguin in the catapult bucket area */
            penguin.avatar.position =  CGPointMake(_catapultArm.position.x +32, _catapultArm.position.y + 50);
            
            /* Improves physics collision handling of fast moving objects */
            penguin.avatar.physicsBody.usesPreciseCollisionDetection = true;
            
            /* Setup pin joint between penguin and catapult arm */
            _penguinJoint = [SKPhysicsJointPin jointWithBodyA:_catapultArm.physicsBody bodyB:penguin.avatar.physicsBody anchor:penguin.avatar.position];
            [self.physicsWorld addJoint:_penguinJoint];
            
            /* Set tracker to follow penguin */
            _trackerNode = penguin.avatar;
        }
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    /* Called when a touch moved */
    
    /* There will only be one touch as multi touch is not enabled by default */
    for(UITouch *touch in touches){
        
        /* Grab scene position of touch and update touchNode position */
        CGPoint location = [touch locationInNode: self];
        _touchNode.position = location;
        
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch ended */
    
    /* Let it fly!, remove joints used in catapult launch */
    if (_touchJoint != nil) {
        [self.physicsWorld removeJoint:_touchJoint];
    }
    if (_penguinJoint != nil) {
        [self.physicsWorld removeJoint:_penguinJoint];
    }
}


-(void)update:(CFTimeInterval)currentTime {
    /* Check there is a node to track and camera is present */
    if(_trackerNode != nil && self.camera != nil){
        
        /* Calculate horizontal distance to move */
        CGFloat moveDistance = _trackerNode.position.x - _lastTrackerPosition.x;
        
        /* Duration is time between updates */
        CGFloat moveDuration = currentTime - _lastTimeInterval;
        
        /* Create a move action for the camera */
        if(self.camera.position.x + moveDistance >= 0 && self.camera.position.x + moveDistance <= 392){
            SKAction *moveCamera = [SKAction moveByX:moveDistance y:0 duration:moveDuration];
            [self.camera runAction:moveCamera];
        }
        
        /* Store last tracker position */
        _lastTrackerPosition = _trackerNode.position;
        
        /* Has penguin come to a near stand still */
        CGFloat idleVelocity = 0.15;
        
        /* Is the penguin currently joined to the catapult */
        int nodeJoints = (int)_trackerNode.physicsBody.joints.count;
        CGFloat length = sqrt(_trackerNode.physicsBody.velocity.dx*_trackerNode.physicsBody.velocity.dx + _trackerNode.physicsBody.velocity.dy*_trackerNode.physicsBody.velocity.dy);
        if(length < idleVelocity && nodeJoints == 0) {
                
                /* Reset tracker node */
                self.trackerNode = nil;
                
                /* Move camera back to start position */
                SKAction *resetCamera = [SKAction moveToX:0 duration:1.0];
                [self.camera runAction:resetCamera];
                
                /* Reset catapult arm */
                _catapultArm.physicsBody.velocity = CGVectorMake(0,0);
                _catapultArm.physicsBody.angularVelocity = 0.0;
                _catapultArm.zRotation = 0;
                _catapultArm.position = CGPointMake(-81,31);
                
                /* Remove penguin */
            SKAction * removeNode = [SKAction removeFromParent];
            [_trackerNode runAction:removeNode];
            }
    }
    
    /* Store current update step time */
    _lastTimeInterval = currentTime;

}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    /* Physics contact delegate implementation */
    
    /* Get references to the bodies involved in the collision */
    SKPhysicsBody *contactA = contact.bodyA;
    SKPhysicsBody *contactB = contact.bodyB;
    
    /* Get references to the physics body parent SKSpriteNode */
    SKSpriteNode *nodeA = (SKSpriteNode*)contactA.node;
    SKSpriteNode *nodeB = (SKSpriteNode*)contactB.node;
    
    /* Was a donut involved? */
    if(contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2){
        
        /* Was it more than a gentle nudge? */
        if(contact.collisionImpulse > 2.0){
            
            /* Kill Donut(s) */
            if(contactA.categoryBitMask == 2){
               [self dieDonut:nodeA];
            }
            if(contactB.categoryBitMask == 2){
                 [self dieDonut:nodeB];
            }
        }
    }
}
-(void)dieDonut:(SKNode*)node{
    /* Donut death*/
    
    /* Load our particle effect */
    SKEmitterNode *particles = [SKEmitterNode nodeWithFileNamed: @"DonutExplosion"];
    
    /* Convert node location (currently inside LevelHolder, to scene space) */
    particles.position = [self convertPoint:node.position fromNode:node];
    
    /* Restrict total particles to reduce runtime of particle */
    particles.numParticlesToEmit = 25;
    
    /* Add particles to scene */
    [self addChild:particles];
    
    /* Play SFX */
    SKAction *donutSFX = [SKAction playSoundFileNamed:@"sfx_donut" waitForCompletion: false];
    [self runAction:donutSFX];
    
    /* Create our donut removal action */
    SKAction *donutDeath = [SKAction removeFromParent];
    [node runAction:donutDeath];
}
@end
