//
//  BusTimeLookupController.h
//  ShuttleTrac
//
//  Created by Brady Law on 3/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BusStop.h"
#import "BusTimesTableViewController.h"

@interface BusTimeLookupController : UIViewController {
	IBOutlet UITextField *busStopNumber;
	IBOutlet UITableView *busStopTableView;
	BusStop *busStop;
	
	BusTimesTableViewController *arrivalTimesTableController;
}

-(IBAction)lookupBusStop:(UIButton *)submitButton;

@end
