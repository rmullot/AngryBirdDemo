//
//  ABButtonNode.m
//  AngryBirdDemo
//
//  Created by Romain Mullot on 06/03/2018.
//  Copyright © 2018 Romain Mullot. All rights reserved.
//

#import "ABButtonNode.h"


@implementation ABButtonNode


- (void) setState:(ABButtonNodeState)state {
    _state = state;
    switch(state) {
    case active:
        /* Enable touch */
        self.userInteractionEnabled  = true;
        
        /* Visible */
        self.alpha = 1;
        break;
    case selected:
        /* Semi transparent */
        self.alpha = 0.7;
        break;
    case hidden:
        /* Disable touch */
        self.userInteractionEnabled = false;
        
        /* Hide */
        self.alpha = 0;
        break;
    };
    
}
    
    /* Setup a dummy action closure */



    - (id)initWithCoder:(NSCoder *)aDecoder {
        
        if(self = [super initWithCoder:aDecoder]) {
            /* Enable touch on button node */
            self.userInteractionEnabled  = true;
            self.selectedHandler = ^void(void){ NSLog(@"No button action set"); };
        }
        
        return self;
    }

    
    // MARK: - Touch handling
    - (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
        _state = selected;
    }
    
    - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//        selectedHandler();
        _state = active;
    }
@end
