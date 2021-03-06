//
//  ShuttleTracDataStore.m
//  ShuttleTrac
//
//  Created by Brady Law on 4/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShuttleTracDataStore.h"

@interface ShuttleTracDataStore ( )

-(void)requestStopsFromWeb;
-(void)requestRoutesFromWeb;

@property (retain, readwrite) BookmarkedStopsDataStore *bookmarkedStopsDataStore;
@property (retain, readwrite) BusMapDataStore *busMapDataStore;

@end

#define PARSING_STOPS	0
#define PARSING_ROUTES	1

@implementation ShuttleTracDataStore

@synthesize bookmarkedStopsDataStore, busMapDataStore, updateNeeded;

-(id)init {
	if (self = [super init]) {
		busStops = [[NSMutableDictionary alloc] init];
		busRoutes = [[NSMutableDictionary alloc] init];
				
		// NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		[self refreshStopAndRouteData];
		
		// Initiate data stores
		self.bookmarkedStopsDataStore	= [[[BookmarkedStopsDataStore alloc] initWithDataStore:self] autorelease];
		self.busMapDataStore			= [[[BusMapDataStore alloc] initWithDataStore:self] autorelease];
		
		updateNeeded = NO;
	}
	return self;
}
- (id)initWithCoder:(NSCoder *)coder {
	updateNeeded = [coder decodeBoolForKey:@"updateNeeded"];
	
	if (updateNeeded)
		return [self init];

	if (self = [super init]) {
		busStops = [[coder decodeObjectForKey:@"busStops"] retain];
		busRoutes = [[coder decodeObjectForKey:@"busRoutes"] retain];
		sortedRoutes = [[coder decodeObjectForKey:@"sortedRoutes"] retain];
		
		bookmarkedStopsDataStore = [[coder decodeObjectForKey:@"bookmarkedStopsDataStore"] retain];
		busMapDataStore = [[coder decodeObjectForKey:@"busMapDataStore"] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:bookmarkedStopsDataStore forKey: @"bookmarkedStopsDataStore"];
	[coder encodeObject:busMapDataStore forKey: @"busMapDataStore"];
	[coder encodeObject:sortedRoutes forKey:@"sortedRoutes"];
	
	[coder encodeObject:busRoutes forKey: @"busRoutes"];
	[coder encodeObject:busStops forKey: @"busStops"];
	
	[coder encodeBool:updateNeeded forKey:@"updateNeeded"];
}

-(void)refreshStopAndRouteData {
	[self requestStopsFromWeb];
	[self requestRoutesFromWeb];
}

-(void)requestStopsFromWeb{
	parsingMode = PARSING_STOPS;
	
	NSURL *url = [NSURL URLWithString:@"http://shuttle.umd.edu/RTT/Public/Utility/File.aspx?ContentType=SQLXML&Name=Platform.xml"];

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)requestRoutesFromWeb{
	parsingMode = PARSING_ROUTES;
	
	NSURL *url = [NSURL URLWithString:@"http://shuttle.umd.edu/RTT/Public/Utility/File.aspx?ContentType=SQLXML&Name=RoutePattern.xml"];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(NSArray *)sortedRoutes {
	if (sortedRoutes == nil) {
		sortedRoutes = [[[busRoutes allValues] sortedArrayUsingSelector:@selector(routeNameCompare:)] retain];
	}
	return sortedRoutes;
}

-(NSMutableDictionary *)allBusStops {	
	return busStops;
}

-(NSMutableDictionary *)allBusRoutes {
	return busRoutes;
}

#pragma mark XML Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
	if ([elementName isEqual: @"Platform"]) {
		NSInteger busNumber = [[attributeDict objectForKey:@"PlatformNo"] integerValue];
		if(parsingMode == PARSING_STOPS){
			if(!currBusStop){
				NSString *name = [[attributeDict objectForKey:@"Name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				NSInteger tagNumber = [[attributeDict objectForKey:@"PlatformTag"] integerValue];

				currBusStop = [[BusStop alloc] init];
				[currBusStop setName:name];
				[currBusStop setStopNumber:busNumber];
				[currBusStop setTagNumber:tagNumber];
			}
		}
		if(parsingMode == PARSING_ROUTES){
			BusStop *b = [busStops objectForKey:[NSNumber numberWithInteger: busNumber]];
			if(b)
				[currRouteBusStops addObject: b];
		}
	}
	else if([elementName isEqual:@"Position"]){
		if(currBusStop){
			CLLocationCoordinate2D loc;
			loc.latitude = [[attributeDict objectForKey:@"Lat"] doubleValue];
			loc.longitude = [[attributeDict objectForKey:@"Long"] doubleValue];
			[currBusStop setCoordinate:loc];
		}
	}
	
	//Get Routes
	else if([elementName isEqual:@"Route"]){
		if(!currBusRoute){
			NSInteger routeNum = [[attributeDict objectForKey:@"RouteNo"] integerValue];
			NSString *routeName = [[attributeDict objectForKey:@"Name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			currRouteBusStops = [[NSMutableArray alloc] init]; // create array to store bus stops reached on route
			
			currBusRoute = [[BusRoute alloc] initRouteWithID:routeNum name:routeName stops:nil];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	
	if([elementName isEqual:@"Platform"]){
		if(currBusStop){
			[busStops setObject:currBusStop forKey:[NSNumber numberWithInteger:currBusStop.stopNumber]];
			
			// We're done with the current bus stop
			[currBusStop release];
			currBusStop = nil;
		}			
	}
	else if([elementName isEqual:@"Route"]){
		[currBusRoute setStops:currRouteBusStops];
		[busRoutes setObject:currBusRoute forKey:[NSNumber numberWithInteger:currBusRoute.routeID]];
		
		// We're done with this
		[currRouteBusStops release];
		currRouteBusStops = nil;
		
		[currBusRoute release];
		currBusRoute = nil;
		
		[currBusStop release];
		currBusStop = nil;
	}
}


-(void)dealloc {
	// 2 Main Data Stores
	//[bookmarkedStopsDataStore release];
	//[busMapDataStore release];
	
	[busStops release];
	[busRoutes release];
		
	[super dealloc];
}

@end
