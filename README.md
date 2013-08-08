<center>![OpenWeatherMapAPI](https://raw.github.com/adba/OpenWeatherMapAPI/master/hero.png)</center>

# Open Weather Map iOS API #

This projects allows you to quickly and easily fetch data
from [openweathermap.org](http://openweathermap.org/ "OpenWeatherMap.org").

## API Changes ##

### Version 0.0.5a ###

The methods for getting the daily forecast have changed names. So instead of: `dailyForecastWeatherByCityName:withCount:withCallback:`
they are now called: `dailyForecastWeatherByCityName:withCount:andCallback:`

Many of the previous getter/setter methods are now defined as property methods.

The method `setLangWithPreferedLanguage`, which sets the language parameter according to the preferred language on the phone, is now called `setLanguageUsingPreferredLanguage`.

For the methods that accept a count argument, the value is now an NSNumber, to allow for optional `nil` values, since counts are not specifically required by the OpenWeatherMap API.

Methods for querying historical weather data have been added.

## Usage ##

### Installation ###

Since this is a forked release, I'm not going to make an alternative Pod file.  You should download the code directly if you wish to use this version.

1. Download the code

2. Include the header `#import "OWMWeatherAPI.h"`.
3. Setup the api:
    
    ```Objective-c
    // Setup weather api
    OWMWeatherAPI *weatherAPI = [[OWMWeatherAPI alloc] initWithAPIKey:@"YOUR-API-KEY"];
    ```

4. Select the default temperature format (defaults to Celsius)

    ```Objective-c
    [weatherAPI setTemperatureFormat:kOWMTempCelsius];
    ```

### Getting data ###

The api is at this time just simple wrapper for the http-api. So to get the current weather for
the city [`Odense`](http://en.wikipedia.org/wiki/Odense "Odense") you can call it like this:

```Objective-c
[weatherAPI currentWeatherByCityName:@"Odense" withCallback:^(NSError *error, NSDictionary *result) {
    if (error) {
        // handle the error
        return;
    }

    // The data is ready

    NSString *cityName = result[@"name"];
    NSNumber *currentTemp = result[@"main"][@"temp"];

}]
```

The result data is a `NSDictionary` that looks like 
this ([json](http://api.openweathermap.org/data/2.5/weather?q=Odense "JSON data")):

```JavaScript
    {
        coord: {
            lon: 10.38831,
            lat: 55.395939
        },
        sys: {
            country: "DK",
            sunrise: 1371695759, // this is an NSDate
            sunset: 1371758660   // this is also converted to a NSDate
        },
        weather: [
            {
                id: 800,
                main: "Clear",
                description: "Sky is Clear",
                icon: "01d"
            }
        ],
        base: "global stations",
        main: {
            temp: 295.006,      // this is the the temperature format you´ve selected
            temp_min: 295.006,  //                 --"--
            temp_max: 295.006,  //                 --"--
            pressure: 1020.58,
            sea_level: 1023.73,
            grnd_level: 1020.58,
            humidity: 80
        },
        wind: {
            speed: 6.47,
            deg: 40.0018
        },
        clouds: {
            all: 0
        },
        dt: 1371756382,
        id: 2615876,
        name: "Odense",
        cod: 200
    }
```

See an example in the `OWMViewController.m` file.

## Methods ##
The following methods are availabe at this time:

### current weather ###

current weather by city name:
```Objective-c
    - (void)currentWeatherByCityName:(NSString *)name
                        withCallback:(OWMCallback)callback;
```

current weather by coordinate:
```Objective-c
    - (void)currentWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                          withCallback:(OWMCallback)callback;
```

current weather by city id:
```Objective-c
    - (void)currentWeatherByCityId:(NSString *)cityId
                      withCallback:(OWMCallback)callback;
```

### forecasts (3 hour intervals) ###

forecast by city name:
```Objective-c
    - (void)forecastWeatherByCityName:(NSString *) name
                         withCallback:(OWMCallback)callback;
```

forecast by coordinate:
```Objective-c
    - (void)forecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                           withCallback:(OWMCallback)callback;
```

forecast by city id:
```Objective-c
    - (void)forecastWeatherByCityId:(NSString *)cityId
                       withCallback:(OWMCallback)callback;
```

### daily forecasts ###

daily forecast by city name:
```Objective-c
    -(void) dailyForecastWeatherByCityName:(NSString *)name
                                 withCount:(NSNumber *)count
                               andCallback:(OWMCallback)callback;
```

daily forecast by coordinates:
```Objective-c
    - (void)dailyForecastWeatherByCoordinate:(CLLocationCoordinate2D)coordinate
                                   withCount:(NSNumber *)count
                                 andCallback:(OWMCallback)callback;

```

daily forecast by city id:
```Objective-c
   - (void)dailyForecastWeatherByCityId:(NSString *)cityId
                              withCount:(NSNumber *)count
                           andCallback:(OWMCallback)callback;
```

###  historical weather ###

historical weather by city name:
```Objective-c
   - (void)historicalWeatherByCityName:(NSString *)name
                             startDate:(NSDate *)start
                               endDate:(NSDate *)end
                           periodicity:(OWMPeriod)period
                                 count:(NSNumber *)count
                          withCallback:(OWMCallback)callback;
```

historical weather by city id:
```Objective-c
   - (void)historicalWeatherByByCityId:(NSString *)cityId
                             startDate:(NSDate *)start
                               endDate:(NSDate *)end
                           periodicity:(OWMPeriod)period
                                 count:(NSNumber *)count
                          withCallback:(OWMCallback)callback;
```

NOTE: Historical data may be missing.  In spot testing, API usually returns data from about 1 October 2012 onward.  Also note that the count often will not match the returned data, so use some caution with these methods.