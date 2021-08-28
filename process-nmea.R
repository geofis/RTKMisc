#!/usr/bin/Rscript

# Jose Ramon Martinez Battlle (GH: geofis)

#### Packages ####
req_pkg <- c("tools","optparse","sf","dplyr")
install_load_pkg <- function(pkg){
  if(!dir.exists(Sys.getenv("R_LIBS_USER"))) dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)
  new_pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new_pkg))
    install.packages(new_pkg, lib = Sys.getenv("R_LIBS_USER"), dependencies = TRUE, repos = "https://cloud.r-project.org")
  sapply(pkg, function(x) suppressPackageStartupMessages(require(x, character.only = TRUE)))
}
invisible(install_load_pkg(req_pkg))


#### Make options ####
option_list = list(
  make_option(c("-p", "--path"), action="store", type='character',
              help="Search is recursive. Mandatory [default %default]"),
  make_option(c("-e", "--extension"), action="store", default=NULL, type='character',
              help="Extension to search for (no dot '.' required).
                -e and -f are mutually exclusive [default %default]"),
  make_option(c("-f", "--file_root_name"), action="store", default=NULL, type='character',
              help="Pattern to search for (no metacharacters allowed, e.g. '*').
                -e and -f are mutually exclusive [default %default]"),
  make_option(c("-s", "--solution_type"), action="store", default="fix", type='character',
              help="fix: only fix solutions are processed
                float: only float solutions are processed [default %default]"),
  make_option(c("-t", "--processing_type"), action="store", default = 'sum', type='character',
              help="sum: one point per NMEA file, with mean coordinates and statistics
                all: all points of each NMEA file saved in separate files as is
                [default %default]"),
  make_option(c("-m", "--merged"), action="store_true", default = 'FALSE',
              help="Generate a merged output (in the path) instead of single files?"),
  make_option(c("-k", "--kml"), action="store_true", default = 'FALSE',
              help="Generate KML files(s) instead of CSV?"),
  make_option(c("-g", "--gpkg"), action="store_true", default = 'FALSE',
              help="Generate Geopackage files(s) instead of CSV?"),
  make_option(c("-a", "--altitude_type"), action="store", default = 'alt_ell', type='character',
              help="Only for summaries processing type.
                alt_ell:ellipsoidal altitude
                alt_msl:mean-sea level altitude [default %default]"),
  make_option(c("-n", "--antenna_height"), action="store", default = 0.0, type='double',
              help="Value in m to be sustracted from altitude values [default %default]")
)
opt <- parse_args(OptionParser(
  option_list=option_list,
  description = "Creates CSV (default) files, or KML/GPKG files instead optionally, from NMEA messages.
  
  Example:
  ./process-nmea.R -p data -e ubx -s fix -t sum -m -k -a alt_msl -n 2.044
  
  This command will generate one single KML file in `data`,
  summarizing the mean position of RTK-fix coordinates (llh),
  as well as the standard deviation and standard error,
  of the points of the files ending with *.ubx extension
  containing NMEA messages within the directory. As specified
  in the command line, the Z-coordinate to use will be mean-sea
  level height (may use ellipsoidal altitude), and 2.044 metres
  (the antenna height) will be substracted from Z.",
  epilogue = "Jose Ramon Martinez Batlle (GH: geofis)\n"
  ))


#### Check arguments ####
# Check if path is NULL 
if(is.null(opt$path)) stop("A path must be defined")

# Check for metacharacters
if(!is.null(opt$file_root_name)) if(grepl('\\*', opt$file_root_name)) stop("No metacharacters (e.g. *) allowed in -f flag")

# Check if both -e and -f are NULL
if(is.null(opt$extension) & is.null(opt$file_root_name)) stop("Either extension (-e) or file root name (-f) must be defined")

# Check if both -e and -f are not NULL
if(!is.null(opt$extension) & !is.null(opt$file_root_name)) stop("Either extension (-e) or file root name (-f) must be defined")
pattern <- if(!is.null(opt$extension)) paste0('*\\.', opt$extension) else opt$file_root_name

#### Recode solution type ####
opt$solution_type <- switch(opt$solution_type, 'fix' = '4', 'float' = '5', 'both' = c('4', '5'), 'single' = '1')

#### Custom functions ####
# Convert DDMM.MMMMMMMMM to DD.DDDDDDDDD
to_dd <- function(nmea) {
  dd <- as.vector(sapply(nmea, function(x) {
    raw <- as.numeric(strsplit(gsub('([0-9]*)([0-9]{2})\\.([0-9]*)', '\\1,\\2,0.\\3', x), ',')[[1]])
    dd <- round(as.integer(raw[1]) + (raw[2] + raw[3])/60L, 9)
    return(dd)
  }))
  return(dd)
}

# Extract LLH from GNGGA sentences
read_llh_from_gngga <- function(x, sol_type = opt$solution_type, ant_hgt=opt$antenna_height) {
  nmea_mes <- readLines(x, skipNul=T, warn=F)
  gngga <- gsub('(.*)(\\$GNGGA.*\\*.{2}$)(.*)', '\\2', grep('GNGGA', nmea_mes, value=T, useBytes=T))
  gngga_df <- data.frame(do.call('rbind', lapply(gngga, function(x) t(data.frame(unlist(strsplit(x, split=','))[c(3:7, 10, 12)])))), stringsAsFactors = F)
  colnames(gngga_df) <- c('lat', 'lat_dir', 'lon', 'lon_dir', 'sol_type', 'alt_msl', 'geoid_hgt')
  rownames(gngga_df) <- NULL
  gngga_df <- gngga_df[gngga_df[,5] %in% sol_type, ]
  gngga_df[,c('lat', 'lon')] <- lapply(gngga_df[,c('lat', 'lon')], function(x) to_dd(x))
  gngga_df[,c('alt_msl', 'geoid_hgt')] <- lapply(gngga_df[, c('alt_msl', 'geoid_hgt')], function(x) as.numeric(x))
  gngga_df[, 'lat'] <- ifelse(gngga_df[, 'lat_dir']=='N', as.numeric(gngga_df[, 'lat'], 0-as.numeric(gngga_df[, 'lat'])))
  gngga_df[, 'lon'] <- ifelse(gngga_df[, 'lon_dir']=='W', 0-as.numeric(gngga_df[, 'lon'], as.numeric(gngga_df[, 'lon'])))
  gngga_df[, 'alt_ell'] <- gngga_df[, 'alt_msl'] + gngga_df[, 'geoid_hgt']
  gngga_df[, 'filename'] <- x
  gngga_df <- gngga_df[, c('filename', 'lat', 'lon', 'alt_ell', 'alt_msl', 'geoid_hgt')]
  gngga_df[,c('alt_ell', 'alt_msl')] <- gngga_df[,c('alt_ell', 'alt_msl')] - ant_hgt
  return(gngga_df)
}

# Generate sf object from df
calc_ave_std_se <- function(df_obj = df, lat = 'lat', lon = 'lon', z = opt$altitude_type,
                            target_crs_epsg = 32619, id_col = 'filename') {
  sf_obj <-  df_obj %>%
    st_as_sf(coords = c(lon, lat), crs = 4326, remove = FALSE) %>%
    st_transform(crs = target_crs_epsg) %>% 
    mutate(x = st_coordinates(geometry)[,1],
           y = st_coordinates(geometry)[,2],
           z = !!sym(z)) %>% 
    st_drop_geometry() %>% 
    group_by(!!sym(id_col)) %>%
    mutate(N = n(),
           std_x = sd(x),
           std_y = sd(y),
           std_z = sd(z),
           se_x = sd(x) / sqrt(N),
           se_y = sd(y) / sqrt(N),
           se_z = sd(z) / sqrt(N)) %>%
    group_by(!!sym(id_col), N, std_x, std_y, std_z, se_x, se_y, se_z) %>%
    summarise_at(vars(lat, lon, x, y, z), mean) %>% 
    mutate_at(vars(lat, lon), round, 9) %>% 
    mutate_at(vars(-one_of(id_col, lat, lon)), round, 4)
  return(sf_obj)
}

#### Processing ####
# Character vector of files
cat("Reading files in selected path")
l <- list.files(path = opt$path, pattern = pattern, recursive = T, full.names = T)

# Extract LLH from GNGGA sentences
cat("Extracting LLH from GGA sentences")
df <- lapply(l, function(x) tryCatch(read_llh_from_gngga(x), error=function(e) NULL))
df <- df[!sapply(df, is.null)] # In case NULL are produced (e.g. no valid points found)
if(length(df)==0) stop('No valid points were found')
df <- if(inherits(df, 'list')) df else list(df) # In case of 1-element list (e.g. only one single file contains valid point)

# Calculate summaries: mean, standard deviation and standard error
df_sum <- lapply(df, calc_ave_std_se)

# Write CSV and KML
cat("Writing output(s)")
if(opt$processing_type=='all') {
  if(opt$merged) {
    all_merged <- do.call('rbind', df)
    if(opt$kml) {
      all_merged %>% 
        st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
        st_write(dsn = paste0(opt$path, '/all-merged.kml'))
    } else if(opt$gpkg) {
      all_merged %>% 
        st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
        st_write(dsn = paste0(opt$path, '/all-merged.gpkg'))
    } else {
      write.csv(x = all_merged, file = paste0(opt$path, '/all-merged.csv', row.names = F))
    }
  } else {
    if(opt$kml) {
      invisible(lapply(df, function(x) x %>%
                         st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
                         st_write(dsn = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.kml'))
      ))
    } else if(opt$gpkg) {
      invisible(lapply(df, function(x) x %>%
                         st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
                         st_write(dsn = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.gpkg'))
      ))
    } else {
      invisible(lapply(df, function(x) write.csv(x = x, file = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.csv'), row.names = F)))
    }
  }
} else if(opt$processing_type=='sum') {
  if(opt$merged) {
    sum_merged <- do.call('rbind', df_sum)
    if(opt$kml) {
      sum_merged %>% 
        st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
        st_write(dsn = paste0(opt$path, '/summary-merged.kml'))
    } else if(opt$gpkg) {
      sum_merged %>% 
        st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
        st_write(dsn = paste0(opt$path, '/summary-merged.gpkg'))
    } else {
      write.csv(x = sum_merged, file = paste0(opt$path, '/summary-merged.csv', row.names = F))
    }
  } else {
    if(opt$kml) {
      invisible(lapply(df_sum, function(x) x %>%
                         st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
                         st_write(dsn = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.kml'))
      ))
    } else if(opt$gpkg) {
      invisible(lapply(df_sum, function(x) x %>%
                         st_as_sf(coords = c('lon', 'lat'), crs = 4326, remove = FALSE) %>% 
                         st_write(dsn = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.gpkg'))
      ))
    } else {
      invisible(lapply(df_sum, function(x) write.csv(x = x, file = paste0(file_path_sans_ext(unique(x$filename)), '-', opt$processing_type, '.csv'), row.names = F)))
    }
  }
} else {
  cat('\nInvalid processing type flag\n\n')
}
