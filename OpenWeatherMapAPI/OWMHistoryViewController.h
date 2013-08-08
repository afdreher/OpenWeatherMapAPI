//
//  OWMHistoryViewController.h
//  OpenWeatherMapAPI
//
//  Created by Andrew F. Dreher on 8/8/13.
//  Copyright (c) 2013 Adrian Bak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OWMHistoryViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *cityName;
@property (weak, nonatomic) IBOutlet UILabel *yesterdaysTemp;
@property (weak, nonatomic) IBOutlet UILabel *yesterdaysTimestamp;
@property (weak, nonatomic) IBOutlet UILabel *weather;

@end
