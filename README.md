# Segment34 Mk3
A watchface for Garmin watches with a 34 Segment display

![Screenshot of the watchface](screenshot.png "Screenshot")

The watchface features the following:

- Time displayed with a 34 segment display
- Phase of the moon with graphic display
- Heartrate or Respiration rate
- Weather (conditions, temperature and windspeed)
- Sunrise/Sunset
- Date
- Notification count
- Configurable: Active minutes / Distance / Floors / Time to Recovery / VO2 Max
- Configurable: Steps / Calories / Distance
- Battery days remaining (or percentage on some watches)
- Always on mode
- Settings in the Garmin app


## Frequently Asked Questions
https://github.com/ludw/segment34mk3/blob/main/FAQ.md

## IQ Store Listing
https://apps.garmin.com/apps/aa85d03d-ab89-4e06-b8c6-71a014198593

## Buy me a coffee (if you want to)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M51A1RGV)

## Contributing (code)
This is more of a hobby project than an actively maintained project, I have limited time to review and respond to issues so response time can be long.

If you want to contribute code to this repository, please start by opening an issue and explaining what you have in mind and why. If I think it sounds like a good idea I can add you to contributors and let you open a PR. 

As memory is very limited on a watchface (especially on older devices) new features must meet a high bar:
- Useful for a large number of users
- Implemented in a performant and memory efficient manner
- Not in the way for existing users, if it changes how it looks it should probably be optional
- Fits in well with the aesthetics of the watch face

For refactorings and optimizations keep in mind that:
- I value my own understanding of the codebase, refactorings reduce this understanding and must outweigh the loss in other benefits
- Optimizations must include profiler results and memory useage
- Both optimizations and refactorings require significant testing across all supported devices

 ## Things people have asked for (may or may not be implemented)



## Change log
v0.9
- Active minutes histogram show both vigorous and moderate minutes
- Fixed issue with labels for monthly run distance
- Fixed issue with weather data cache causing some fields to be blank after an hour without connection
- Notifications icon with or without notification count

v0.8
- More adjustments to 7 segment font
- Separate 24h/12h setting for alt timezone
- Steps/Distance/active minutes in histogram
- Monthly run distance (both rolling 28 days and actual month)
- Side bar width setting: Narrow (default) or Wide (double width)
- Limit Bar Height setting: caps bars to fit within the round screen, with an indicator line at maximum height
- Counter value that reset every midnight and can be increased/decreased with longpress actions
- Stress in histogram should now show unmeasurable periods as gaps

v0.7
- Fix for font errors

v0.6
- Steps in small fields behaves a bit better
- Outline for 17 segment (rounded) fixed
- 7 Segment font slightly adjusted
- 17 Segment font slightly adusted

v0.5
- Fixed issue with High / Low temp via OWM
- Fixed issue with seconds clipping in always active mode with large font
- Fixed issue with battery bar going outside outline
- More options for bottom 5 field, incl next sun event
- Dawn / Dusk as option (calculated)
- Seconds field can be configured to show something else
- Shortened weather conditions as an alternative

v0.4
- Font style options for bottom fields
- More options for bottom field layout
- Adjustment in pink color theme
- Yellow on Blue color theme replaced with Orange on
- AM/PM on by default for 12h time
- Option for histogram size
- New clock overlay option: scanlines in AOD