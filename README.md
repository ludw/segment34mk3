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
- Goal completion marker
- Pressure trend
- Monthly run/bike distance
- Notifications as icon
- Line font for bottom fields
- clock font without segments
- separate 24h mode for alt tz
- Next sun event in bottom field

## Change log
v0.5
- Fixed issue with High / Low temp via OWM
- Fixed issue with seconds clipping in always active mode with large font

v0.4
- Font style options for bottom fields
- More options for bottom field layout
- Adjustment in pink color theme
- Yellow on Blue color theme replaced with Orange on
- AM/PM on by default for 12h time
- Option for histogram size
- New clock overlay option: scanlines in AOD