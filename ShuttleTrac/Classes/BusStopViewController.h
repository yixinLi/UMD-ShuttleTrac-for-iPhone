//
//  BusStopView.h
//  ShuttleTrac
//
//  Created by Brady Law on 4/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ShuttleTracDataStore.h"
#import "BusStopArrivals.h"

@interface BusStopViewController : UIViewController <UITableViewDataSource, BusStopArrivalsDelegate> {
	IBOutlet UITableView *tableView;
	
	ShuttleTracDataStore *dataStore;
	BusStopArrivals *arrivals;
}

@property (assign, readwrite) ShuttleTracDataStore *dataStore;
@property (assign, readwrite) BusStopArrivals *arrivals;

@end