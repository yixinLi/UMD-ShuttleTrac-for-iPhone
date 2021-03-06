//
//  BusRoute.h
//  ShuttleTrac
//
//  Created by Brady Law on 4/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BusRoute : NSObject  <NSCoding> {
	// Name of the route
	NSString *routeName;
	
	// ID of the route
	NSInteger routeID;
	
	// Bus stops this route hits
	NSArray *stops;
}

+(BusRoute *)busRouteWithID:(NSInteger)rID name:(NSString *)rName stops:(NSArray *)rStops;

-(id)initRouteWithID:(NSInteger)rID name:(NSString *)rName stops:(NSArray *)rStops;

-(NSComparisonResult)routeNameCompare:(BusRoute *)otherRoute;
-(NSComparisonResult)routeIdCompare:(BusRoute *)otherRoute;

@property (retain, readonly) NSString *routeName;
@property (assign, readonly) NSInteger routeID;
@property (retain, readwrite) NSArray *stops;

@end
