//
//  OWMWeatherAPI.m
//  OpenWeatherMapAPI
//
//  Created by Adrian Bak on 20/6/13.
//  Copyright (c) 2013 Adrian Bak. All rights reserved.
//

#import "AFJSONRequestOperation.h"
#import "OWMWeatherAPI.h"


NSString * const BASE_URL = @"http://api.openweathermap.org/data/";


@interface OWMWeatherAPI () {
  NSString *_baseURL;
  NSString *_apiKey;
  NSString *_apiVersion;
  NSOperationQueue *_weatherQueue;
  
  NSString *_language;
  
  OWMTemperature _temperatureFormat;
}
@property (nonatomic, strong) NSString *apiKey;

@end


@implementation OWMWeatherAPI
@synthesize apiKey = _apiKey;
@synthesize apiVersion = _apiVersion;
@synthesize language = _language;
@synthesize temperatureFormat = _temperatureFormat;


- (instancetype)initWithAPIKey:(NSString *)apiKey {
  self = [super init];
  if (self) {
    self.apiKey = apiKey;
    self.apiVersion = @"2.5";
    
    _weatherQueue = [[NSOperationQueue alloc] init];
    _weatherQueue.name = @"OMWWeatherQueue";
    
    self.temperatureFormat = kOWMTempCelsius;
  }
  return self;
}


#pragma mark - private parts

/**
 * Convert the OWMPeriod enum to an NSString.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (NSString *)periodToString:(OWMPeriod)period {
  if(period == kOWMPeriodHourly) {
    return @"hour";
  } else if(period == kOWMPeriodDaily) {
    return @"daily";
  } else {
    return @"tick";
  }
}

/**
 * Convert the city name into a query for the API.  Since the city name could have spaces, etc. we
 * need to escape the string to create a proper URL.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (NSString *)queryForCityName:(NSString *)name {
  NSAssert(name != nil, @"city name must not be nil");
  NSAssert(name.length > 0, @"Invalid city name");
  
  NSString *escapedName = [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return [NSString stringWithFormat:@"q=%@", escapedName];
}

/**
 * Convert the city id into a query for the API.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (NSString *)queryForCityId:(NSString *)cityId {
  NSAssert(cityId != nil, @"city id must not be nil");

  return [NSString stringWithFormat:@"id=%@", cityId];
}

/**
 * Convert the coordinates into a query for the API.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (NSString *)queryForCoordinate:(CLLocationCoordinate2D)coordinate {
  return [NSString stringWithFormat:@"lat=%f&lon=%f", coordinate.latitude, coordinate.longitude];
}

/**
 * Utility method to convert the temperature from Kelvin to degrees Celsius.
 *
 * @updated 2013-08-08
 */
+ (NSNumber *)tempToCelsius:(NSNumber *)tempKelvin {
  if (tempKelvin) {
    return @(tempKelvin.floatValue - 273.15);
  }
  return nil;
}

/**
 * Utility method to convert the temperature from Kelvin to degrees Fahrenheit.
 *
 * @updated 2013-08-08
 */
+ (NSNumber *)tempToFahrenheit:(NSNumber *)tempKelvin {
  if (tempKelvin) {
    return @((tempKelvin.floatValue * 9.0/5.0) - 459.67);
  }
  return nil;
}

/**
 * Utility method to convert the temperature from Kelvin (returned by OpenWeather) to the preferred
 * format.
 */
- (NSNumber *)convertTemp:(NSNumber *)temp {
  if (self.temperatureFormat == kOWMTempCelsius) {
    return [OWMWeatherAPI tempToCelsius:temp];
  } else if (self.temperatureFormat == kOWMTempFahrenheit) {
    return [OWMWeatherAPI tempToFahrenheit:temp];
  } else {
    return temp;
  }
}

/** 
 * Convert the date from UNIX time to an NSDate.
 */
- (NSDate *)convertToDate:(NSNumber *)num {
  return [NSDate dateWithTimeIntervalSince1970:num.intValue];
}

/**
 * Recursively change temperatures in result data
 **/
- (NSDictionary *)convertResult:(NSDictionary *)res {
  
  NSMutableDictionary *dic = [res mutableCopy];
  
  NSMutableDictionary *main = [[dic objectForKey:@"main"] mutableCopy];
  if (main) {
    main[@"temp"] = [self convertTemp:main[@"temp"]];
    main[@"temp_min"] = [self convertTemp:main[@"temp_min"]];
    main[@"temp_max"] = [self convertTemp:main[@"temp_max"]];
    
    dic[@"main"] = [main copy];
  }
  
  NSMutableDictionary *temp = [[dic objectForKey:@"temp"] mutableCopy];
  if (temp) {
    temp[@"day"] = [self convertTemp:temp[@"day"]];
    temp[@"eve"] = [self convertTemp:temp[@"eve"]];
    temp[@"max"] = [self convertTemp:temp[@"max"]];
    temp[@"min"] = [self convertTemp:temp[@"min"]];
    temp[@"morn"] = [self convertTemp:temp[@"morn"]];
    temp[@"night"] = [self convertTemp:temp[@"night"]];
    
    dic[@"temp"] = [temp copy];
  }
  
  NSMutableDictionary *sys = [[dic objectForKey:@"sys"] mutableCopy];
  if (sys) {
    sys[@"sunrise"] = [self convertToDate: sys[@"sunrise"]];
    sys[@"sunset"] = [self convertToDate: sys[@"sunset"]];
    
    dic[@"sys"] = [sys copy];
  }
  
  
  NSMutableArray *list = [[dic objectForKey:@"list"] mutableCopy];
  if (list) {
    for (int i = 0; i < list.count; i++) {
      [list replaceObjectAtIndex:i withObject:[self convertResult: list[i]]];
    }
    
    dic[@"list"] = [list copy];
  }
  
  dic[@"dt"] = [self convertToDate:dic[@"dt"]];
  
  return [dic copy];
}

/**
 * Calls the web api, and converts the result. Then it calls the callback on the caller-queue
 **/
- (void)callMethod:(NSString *)method withCallback:(OWMCallback)callback {
  NSAssert(method != nil, @"method cannot be nil");
  NSAssert(method.length > 0, @"Invalid method length.");
  
  NSOperationQueue *callerQueue = [NSOperationQueue currentQueue];
  
  // build the lang parameter
  NSString *languageString;
  if (self.language && self.language.length > 0) {
    languageString = [NSString stringWithFormat:@"&lang=%@", self.language];
  } else {
    languageString = @"";
  }
  
  NSString *urlString = [NSString stringWithFormat:@"%@%@%@&APPID=%@%@",
                                  BASE_URL, self.apiVersion, method, self.apiKey, languageString];
  
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  
  AFJSONRequestOperation *operation =
      [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                      success:^(NSURLRequest *request,
                                                                NSHTTPURLResponse *response,
                                                                id JSON) {
    
    // callback on the caller queue
    NSDictionary *res = [self convertResult:JSON];
    [callerQueue addOperationWithBlock:^{
      callback(nil, res);
    }];
    
    
  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    
    // callback on the caller queue
    [callerQueue addOperationWithBlock:^{
      callback(error, nil);
    }];
    
  }];
  [_weatherQueue addOperation:operation];
}

#pragma mark - public api

/**
 * Set the request language using the device's preferred language, if it available.
 *
 * @updated 2013-08-08
 */
- (void)setLanguageUsingPreferredLanguage {
  NSString *lang = [[NSLocale preferredLanguages] firstObject];
  
  // look up, lang and convert it to the format that openweathermap.org accepts.
  NSDictionary * const langCodes = @{
                                     @"en-GB"   : @"en",
                                     @"es"      : @"sp",
                                     @"pt-PT"   : @"pt",
                                     @"sv"      : @"se",
                                     @"uk"      : @"ua",
                                     @"zh-Hans" : @"zh_cn",
                                     @"zh-Hant" : @"zh_tw",
                                     };

  NSString *l = [langCodes objectForKey:lang];
  if (l) {
    lang = l;
  }
  self.language = lang;
}


#pragma mark current weather

/** 
 * Common code for creating a current weather request.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)currentWeatherForQuery:(NSString *)query withCallback:(OWMCallback)callback {
  NSAssert(query != nil, @"query cannot be nil");

  NSString *method = [NSString stringWithFormat:@"/weather?%@", query];
  [self callMethod:method withCallback:callback];
}

/**
 * Request the current weather using the city name.
 *
 * @updated 2013-08-08
 */
- (void)currentWeatherByCityName:(NSString *)name withCallback:(OWMCallback)callback {
  [self currentWeatherForQuery:[self queryForCityName:name] withCallback:callback];
}

/**
 * Request the current weather using latitude and longitude.
 *
 * @updated 2013-08-08
 */
- (void)currentWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                       withCallback:(OWMCallback)callback {
  [self currentWeatherForQuery:[self queryForCoordinate:coordinate] withCallback:callback];
}

/**
 * Request the current weather using the city ID.
 *
 * @updated 2013-08-08
 */
- (void)currentWeatherByCityId:(NSString *)cityId withCallback:(OWMCallback)callback {
  [self currentWeatherForQuery:[self queryForCityId:cityId] withCallback:callback];
}


#pragma mark forecast

/**
 * Common code for creating a forecast request.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)forecastWeatherForQuery:(NSString *)query withCallback:(OWMCallback)callback {
  NSAssert(query != nil, @"query cannot be nil");

  NSString *method = [NSString stringWithFormat:@"/forecast?%@", query];
  [self callMethod:method withCallback:callback];
}

/**
 * Request the forecast using the city name.
 *
 * @updated 2013-08-08
 */
- (void)forecastWeatherByCityName:(NSString *)name withCallback:(OWMCallback)callback {
  [self forecastWeatherForQuery:[self queryForCityName:name] withCallback:callback];
}

/**
 * Request the forecast using latitude and longitude.
 *
 * @updated 2013-08-08
 */
- (void)forecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                       withCallback:(OWMCallback)callback {
  [self forecastWeatherForQuery:[self queryForCoordinate:coordinate] withCallback:callback];
}

/**
 * Request the forecast using the city ID.
 *
 * @updated 2013-08-08
 */
- (void)forecastWeatherByCityId:(NSString *)cityId withCallback:(OWMCallback)callback {
  [self forecastWeatherForQuery:[self queryForCityId:cityId] withCallback:callback];
}


#pragma mark forecast - n days

/**
 * Common code for creating a daily forecast request.
 * 
 * @param count Number of days to request.  This is optional and may be set to nil.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)dailyForecastWeatherForQuery:(NSString *)query
                           withCount:(NSNumber *)count
                         andCallback:(OWMCallback)callback {
  NSAssert(query != nil, @"query cannot be nil");

  NSString *method = [NSString stringWithFormat:@"/forecast/daily?%@", query];
  if (count && count.integerValue > 0) {
    method = [NSString stringWithFormat:@"%@&cnt=%d", method, count.integerValue];
  }
  [self callMethod:method withCallback:callback];
}

/**
 * Request the daily forecast using the city name.
 *
 * @updated 2013-08-08
 */
- (void)dailyForecastWeatherByCityName:(NSString *)name
                             withCount:(NSNumber *)count
                           andCallback:(OWMCallback)callback {
  [self dailyForecastWeatherForQuery:[self queryForCityName:name]
                           withCount:count
                         andCallback:callback];
}

/**
 * Request the daily forecast using latitude and longitude.
 *
 * @updated 2013-08-08
 */
- (void)dailyForecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                               withCount:(NSNumber *)count
                             andCallback:(OWMCallback)callback {
  [self dailyForecastWeatherForQuery:[self queryForCoordinate:coordinate]
                           withCount:count
                         andCallback:callback];
}

/**
 * Request the daily forecast using the city ID.
 *
 * @updated 2013-08-08
 */
- (void)dailyForecastWeatherByCityId:(NSString *)cityId
                           withCount:(NSNumber *)count
                         andCallback:(OWMCallback)callback {
  [self dailyForecastWeatherForQuery:[self queryForCityId:cityId]
                           withCount:count
                         andCallback:callback];
}

#pragma mark - history

/**
 * Common code for creating a historical weather request.  Note that OpenWeatherMap historical
 * queries typically only exist from 1 October 2012 onward.
 *
 * @param startDate The date from which to request observations.  This is required.
 * @param endDate The ending time for observations. This is optional and may be nil.
 * @param periodicity The type of period requested.
 * @param count Number of instances to request.  This is optional and may be set to nil.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)historicalWeatherWithQuery:(NSString *)query
                         startDate:(NSDate *)start
                           endDate:(NSDate *)end
                       periodicity:(OWMPeriod)period
                             count:(NSNumber *)count
                      withCallback:(OWMCallback)callback {
  NSAssert(query != nil, @"query cannot be nil");
  NSAssert(start, @"start date cannot be nil");
  
  NSString *method = [NSString stringWithFormat:@"/history/city?%@&type=%@&start=%d",
                      query,
                      [self periodToString:period],
                      (NSInteger)[start timeIntervalSince1970]];
  if (end) {
    method = [NSString stringWithFormat:@"%@&end=%d",
                                        method, (NSInteger)[start timeIntervalSince1970]];
  }
  if (count && count.integerValue > 0) {
    method = [NSString stringWithFormat:@"%@&cnt=%d", method, count.integerValue];
  }
  [self callMethod:method withCallback:callback];
}

/**
 * Request historical weather using the city name.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)historicalWeatherByCityName:(NSString *)name
                          startDate:(NSDate *)start
                            endDate:(NSDate *)end
                        periodicity:(OWMPeriod)period
                              count:(NSNumber *)count
                       withCallback:(OWMCallback)callback {
  [self historicalWeatherWithQuery:[self queryForCityName:name]
                         startDate:start
                           endDate:end
                       periodicity:period
                             count:count
                      withCallback:callback];
}

/**
 * Request historical weather using the city ID.
 *
 * @author Andrew F. Dreher
 * @date 2013-08-08
 */
- (void)historicalWeatherByByCityId:(NSString *)cityId
                          startDate:(NSDate *)start
                            endDate:(NSDate *)end
                        periodicity:(OWMPeriod)period
                              count:(NSNumber *)count
                       withCallback:(OWMCallback)callback {
  [self historicalWeatherWithQuery:[self queryForCityId:cityId]
                         startDate:start
                           endDate:end
                       periodicity:period
                             count:count
                      withCallback:callback];
}

@end
