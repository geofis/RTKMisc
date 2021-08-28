# RTKMisc

Jose Ramon Martinez Batlle (GH: geofis)

The R script `process-nmea.R` creates CSV (default) or KML file(s) from NMEA messages. For now, it is intended to run from the Shell terminal.

## Requisites

- R (>=3.3.0)

- Packages `tools`, `optparse`, `sf`, `dplyr`. The script checks for the dependencies, so no packages installation is needed before running the script.

## Help

```
$ /.process-nmea.R -h

Usage: ./process-nmea.R [options]
Creates CSV (default) files, or KML/GPKG files instead optionally, from NMEA messages.

Options:
	-p PATH, --path=PATH
		Path to search recursively. Mandatory [default NULL]

	-e EXTENSION, --extension=EXTENSION
		File extension to search [default ubx]

	-s SOLUTION_TYPE, --solution_type=SOLUTION_TYPE
		Solution type (fix,float) [default fix]

	-t PROCESSING_TYPE, --processing_type=PROCESSING_TYPE
		Processing type. sum:single point,all:all points [default sum]

	-m, --merged
		Generate a merged output (in the path) instead of single files? [default FALSE]

	-k, --kml
		Generate KML files(s) instead of CSV? [default FALSE]

	-g, --gpkg
		Generate Geopackage files(s) instead of CSV? [default FALSE]

	-a ALTITUDE_TYPE, --altitude_type=ALTITUDE_TYPE
		Altitude type for summaries. alt_ell:ellipsoidal altitude,alt_msl:mean-sea level altitude [default alt_ell]

	-n ANTENNA_HEIGHT, --antenna_height=ANTENNA_HEIGHT
		Antenna height (meters). This value will be sustracted from altitude values [default 0]

	-h, --help
		Show this help message and exit

Jose Ramon Martinez Batlle (GH: geofis)
```

## Example

```
./process-nmea.R -p MY/PATH -e ubx -s fix -t sum -m -k -a alt_msl -n 2.044
```

For each file ending with *.ubx extension containing NMEA messages within `PATH/TO/NMEA/FILES`, the command generates one single KML file in `PATH/TO/NMEA/FILES`, that will have the mean position of RTK-fix coordinates (llh) as well as the standard deviation and standard error. As specified in the command line, the Z-coordinate to use will be mean-sea level height (may use ellipsoidal altitude), and 2.044 metres (the antenna height) will be substracted from Z.

Hint: add the script to the $PATH, or set an alias, to call it from anywhere in your PC.