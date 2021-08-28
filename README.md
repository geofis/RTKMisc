# RTKMisc

Jose Ramon Martinez Batlle (GH: geofis)

The R script `process-nmea.R` creates CSV (default) or KML file(s) from NMEA messages. For now, it is intended to run from the Shell terminal.

## Requisites

- R (>=3.3.0)

- Packages `tools`, `optparse`, `sf`, `dplyr`. The script checks for the dependencies, so no packages installation is needed before running the script.

## Help

```
$ ./process-nmea.R -h

Usage: /home/jose/Documentos/git/RTKMisc/process-nmea.R [options]
Creates CSV (default) files, or KML/GPKG files instead optionally, from NMEA messages.
  
Options:
	-p PATH, --path=PATH
		Search is recursive. Mandatory [default NULL]

	-e EXTENSION, --extension=EXTENSION
		Extension to search for (no dot '.' required).
                -e and -f are mutually exclusive [default NULL]

	-f FILE_ROOT_NAME, --file_root_name=FILE_ROOT_NAME
		Pattern to search for (no metacharacters allowed, e.g. '*').
                -e and -f are mutually exclusive [default NULL]

	-s SOLUTION_TYPE, --solution_type=SOLUTION_TYPE
		fix: only fix solutions are processed
                float: only float solutions are processed [default fix]

	-t PROCESSING_TYPE, --processing_type=PROCESSING_TYPE
		sum: one point per NMEA file, with mean coordinates and statistics
                all: all points of each NMEA file saved in separate files as is
                [default sum]

	-m, --merged
		Generate a merged output (in the path) instead of single files?

	-k, --kml
		Generate KML files(s) instead of CSV?

	-g, --gpkg
		Generate Geopackage files(s) instead of CSV?

	-a ALTITUDE_TYPE, --altitude_type=ALTITUDE_TYPE
		Only for summaries processing type.
                alt_ell:ellipsoidal altitude
                alt_msl:mean-sea level altitude [default alt_ell]

	-n ANTENNA_HEIGHT, --antenna_height=ANTENNA_HEIGHT
		Value in m to be sustracted from altitude values [default 0]

	-h, --help
		Show this help message and exit

Jose Ramon Martinez Batlle (GH: geofis)
```

## Example

```
./process-nmea.R -p data -e ubx -s fix -t sum -m -k -a alt_msl -n 2.044
```

  This command will generate one single KML file in `data`,
  summarizing the mean position of RTK-fix coordinates (llh),
  as well as the standard deviation and standard error,
  of the points of the files ending with *.ubx extension
  containing NMEA messages within the directory. As specified
  in the command line, the Z-coordinate to use will be mean-sea
  level height (may use ellipsoidal altitude), and 2.044 metres
  (the antenna height) will be substracted from Z.


Hint: add the script to the `$PATH`--or set an alias--to call it from anywhere in your PC.