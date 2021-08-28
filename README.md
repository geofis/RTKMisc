# RTKMisc

Jose Ramon Martinez Batlle (GH: geofis)

The script `process-nmea.R` creates CSV (default) or KML file(s) from NMEA messages. For now, it is intended to run from the Shell terminal.

## Example

```
process-nmea.R -p MY/PATH -s fix -t sum -m -k -a alt_msl -n 2.044
```

This code generates one single KML file of RTK-fix mean coordinates (llh), as well as statistics for each file containing NMEA messages within `MY/PATH`. The Z-coordinate will be mean-sea level height, and 2.044 metres (the antenna height) will be substracted from Z.

Hint: add the script to the $PATH, or set an alias, to call it from anywhere in your PC.
  