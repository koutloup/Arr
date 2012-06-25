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

#import "ArrGeoTools.h"


@implementation ArrGeoTools

+ (float)degFromCoordinate:(CLLocationCoordinate2D)originCoordinate toCoordinate:(CLLocationCoordinate2D)destinationCoordinate {
    return [self radToDeg:[self radianFromCoordinate:originCoordinate toCoordinate:destinationCoordinate]];
}

+ (float)radianFromCoordinate:(CLLocationCoordinate2D)originCoordinate toCoordinate:(CLLocationCoordinate2D)destinationCoordinate {
	float diffLongitude = destinationCoordinate.longitude - originCoordinate.longitude;
	float diffLatitude = destinationCoordinate.latitude - originCoordinate.latitude;
    float possibleRadian = (M_PI * .5f) - atan(diffLatitude / diffLongitude);
    if (diffLongitude > 0) 
        return possibleRadian;
	else if (diffLongitude < 0) 
        return possibleRadian + M_PI;
	else if (diffLatitude < 0) 
        return M_PI;
	
	return 0.0f;
}

+ (CLLocationDistance)distanceBetweenCoordinate:(CLLocationCoordinate2D)originCoordinate andCoordinate:(CLLocationCoordinate2D)destinationCoordinate {    
    CLLocation *originLocation = [[CLLocation alloc] initWithLatitude:originCoordinate.latitude longitude:originCoordinate.longitude];
    CLLocation *destinationLocation = [[CLLocation alloc] initWithLatitude:destinationCoordinate.latitude longitude:destinationCoordinate.longitude];
    CLLocationDistance distance = [originLocation distanceFromLocation:destinationLocation];
    [originLocation release];
    [destinationLocation release];
    
    return distance;
}

+ (float)radToDeg:(float)rad {
    return rad * (180 / M_PI);
}

+ (float)degToRad:(float)deg {
    return deg * (M_PI / 180);
}

@end
