/*
 Copyright (C) 2011 Petros Koutloubasis. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DemoVC.h"
#import "ArrLocation.h"

@implementation DemoVC

@synthesize arrOverlay;

- (void)dealloc {
    [arrOverlay release];
    
    [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([ArrOverlayVC isSupported]) {
        self.arrOverlay = [[[ArrOverlayVC alloc] init] autorelease];
        self.arrOverlay.delegate = self;
    
        NSLog(@"UIImagePickerControllerSourceTypeCamera is avaible");
        [self.arrOverlay setupImgPicker];
        [self presentModalViewController:self.arrOverlay.imagePickerController animated:NO];
        
        //example locations
        ArrLocation *arrLoc = [[ArrLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(16.775833,-3.009444) title:@"Timbuktu"];
        [self.arrOverlay addLocation:arrLoc];
        [arrLoc release];
    } else {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 440, 27)];
        [label setTextAlignment:UITextAlignmentCenter];
        [label setText:@"your device is not supported"];
        [self.view addSubview:label];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - ArrOverlayVCDelegate
- (void)didFinish {
    [self dismissModalViewControllerAnimated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
