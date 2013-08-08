//
//  OWMHistoryViewController.m
//  OpenWeatherMapAPI
//
//  Created by Andrew F. Dreher on 8/8/13.
//  Copyright (c) 2013 Adrian Bak. All rights reserved.
//

#import "OWMHistoryViewController.h"
#import "OWMWeatherAPI.h"

@interface OWMHistoryViewController () {
  OWMWeatherAPI *_weatherAPI;
  NSArray *_forecast;
  NSDateFormatter *_dateFormatter;
  
  int downloadCount;
  
}
@end

@implementation OWMHistoryViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  downloadCount = 0;
  
  NSString *dateComponents = @"H:m yyMMMMd";
  NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale systemLocale] ];
  _dateFormatter = [[NSDateFormatter alloc] init];
  [_dateFormatter setDateFormat:dateFormat];
  
  _forecast = @[];
  
  _weatherAPI = [[OWMWeatherAPI alloc] initWithAPIKey:@"1111111111"]; // Replace the key with your own
  
  // We want localized strings according to the preferred system language
  [_weatherAPI setLanguageUsingPreferredLanguage];
  
  // We want the temperatures in Celsius, you can also get them in Fahrenheit.
  [_weatherAPI setTemperatureFormat:kOWMTempCelsius];
  
  [self.activityIndicator startAnimating];
  
  
  NSDate *yesterday = [NSDate dateWithTimeInterval:-86400 sinceDate:[NSDate date]];
  [_weatherAPI historicalWeatherByCityName:@"Odense"
                                 startDate:yesterday
                                   endDate:nil
                                periodicity:kOWMPeriodTick
                                     count:nil
                              withCallback:^(NSError *error, NSDictionary *result) {
    downloadCount++;
    if (downloadCount > 1) [self.activityIndicator stopAnimating];
    
    if (error) {
      // Handle the error
      return;
    }
            
    NSString *cityName = @"Unavailable";
    NSString *weather = @"N/A";
    NSString *temp = @"N/A";
    NSString *timestamp = @"N/A";
                                
    NSArray *list = result[@"list"];
    if (list && list.count > 0) {
      result = [list firstObject];
      
      NSDictionary *city = result[@"city"];
      if (city) {
        cityName = [NSString stringWithFormat:@"%@, %@", city[@"name"], city[@"country"]];
        weather = [result[@"weather"] firstObject][@"description"];
        temp = [NSString stringWithFormat:@"%.1f℃", [result[@"main"][@"temp"] floatValue]];
        timestamp = [_dateFormatter stringFromDate:result[@"dt"]];
      }
    }
    [self.activityIndicator stopAnimating];
    
    self.cityName.text = cityName;
    self.weather.text = weather;
    self.yesterdaysTemp.text = temp;
    self.yesterdaysTimestamp.text = timestamp;
  }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
