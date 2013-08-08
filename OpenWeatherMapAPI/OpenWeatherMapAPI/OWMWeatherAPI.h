//
//  OWMWeatherAPI.h
//  OpenWeatherMapAPI
//
//  Created by Adrian Bak on 20/6/13.
//  Copyright (c) 2013 Adrian Bak. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>


//
//  TYPES
//

typedef NS_ENUM(NSInteger, OWMTemperature) {
  kOWMTempKelvin,
  kOWMTempCelsius,
  kOWMTempFahrenheit
};

typedef NS_ENUM(NSInteger, OWMPeriod) {
  kOWMPeriodTick,
  kOWMPeriodHourly,
  kOWMPeriodDaily,
};

typedef void(^OWMCallback)(NSError* error, NSDictionary *result);


//
//  CLASS
//

@interface OWMWeatherAPI : NSObject

- (instancetype)initWithAPIKey:(NSString *)apiKey;

@property (nonatomic, readonly) NSString *apiKey;
@property (nonatomic, strong) NSString *apiVersion;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, assign) OWMTemperature temperatureFormat;

- (void)setLanguageUsingPreferredLanguage;


#pragma mark - current weather

- (void)currentWeatherByCityName:(NSString *)name withCallback:(OWMCallback)callback;


- (void)currentWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                      withCallback:(OWMCallback)callback;

- (void)currentWeatherByCityId:(NSString *)cityId withCallback:(OWMCallback)callback;


#pragma mark - forecast

- (void)forecastWeatherByCityName:(NSString *)name withCallback:(OWMCallback)callback;

- (void)forecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                       withCallback:(OWMCallback)callback;

- (void)forecastWeatherByCityId:(NSString *)cityId withCallback:(OWMCallback)callback;


#pragma mark forecast - n days

- (void)dailyForecastWeatherByCityName:(NSString *)name
                             withCount:(NSNumber *)count
                           andCallback:(OWMCallback)callback;

- (void)dailyForecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                               withCount:(NSNumber *)count
                             andCallback:(OWMCallback)callback;

- (void)dailyForecastWeatherByCityId:(NSString *)cityId
                           withCount:(NSNumber *)count
                         andCallback:(OWMCallback)callback;


#pragma mark - history

/**
 * For historical weather, the endDate and count may be set to nil.
 */
- (void)historicalWeatherByCityName:(NSString *)name
                          startDate:(NSDate *)start
                            endDate:(NSDate *)end
                        periodicity:(OWMPeriod)period
                              count:(NSNumber *)count
                       withCallback:(OWMCallback)callback;

- (void)historicalWeatherByByCityId:(NSString *)cityId
                          startDate:(NSDate *)start
                            endDate:(NSDate *)end
                        periodicity:(OWMPeriod)period
                              count:(NSNumber *)count
                       withCallback:(OWMCallback)callback;

@end
