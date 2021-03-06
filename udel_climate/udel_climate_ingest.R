

library(sp)
library(raster)


args <- commandArgs(trailingOnly = TRUE)

dataset <- args[1]
# dataset <- 'precip_2014'
# dataset <- 'air_temp_2014'

base_dir <- '/sciclone/aiddata10/REU/geo'
raw_dir <- sprintf('%s/raw/udel_climate/%s', base_dir, dataset)
data_dir <- sprintf('%s/data/rasters/udel_climate/%s',
                    base_dir, dataset)

# base_dir <- '/home/userz/Desktop'
# raw_dir <- sprintf('%s/udel_test/%s', base_dir, dataset)
# data_dir <- sprintf('%s/udel_test/udel_%s',
#                     base_dir, dataset)


if (!file.exists(raw_dir)) {
  msg <- sprintf("directory not found (%s)", raw_dir)
  stop(msg)
}

flist <- list.files(raw_dir)

if (length(flist) == 0) {
  msg <- sprintf("no files found (%s)", raw_dir)
  stop(msg)
}


default_methods <- c('monthly', 'mean', 'min', 'max', 'var', 'sd')

if (length(args) > 1) {
  raw_methods <- unlist(strsplit(args[2], ','))
  invalid_methods <- setdiff(raw_methods, default_methods)
  if (length(invalid_methods) > 0) {
    msg <- sprintf("invalid methods given (%s)",
                   paste(invalid_methods, collapse=', '))
    stop(msg)
  }
} else {
  raw_methods <- default_methods
}

build_monthly <- 'monthly' %in% raw_methods

methods <- raw_methods[raw_methods != 'monthly']



for (fname in flist) {
  cat(sprintf('\nprocessing %s...\n', fname))
  year <- unlist(strsplit(fname, '[.]'))[2]
  fpath <- sprintf('%s/%s', raw_dir, fname)
  data <- read.table(fpath)
  months <- sprintf('%02d', c(1:12))
  names(data) <- c("lon", "lat", months)

  coordinates(data) = ~lon+lat
  proj4string(data) = CRS("+init=epsg:4326")


  # monthly
  if (build_monthly) {
    cat('\tbuilding monthly...\n')
    dir.create(sprintf('%s/monthly/%s', data_dir, year), recursive=TRUE)
    for (m in months) {
      data_trim <- data[, m]
      gridded(data_trim) = TRUE
      r <- raster(data_trim)

      out_name <- sprintf('%s_%s.tif', gsub("[.]", "_", fname), m)
      out_path <- sprintf('%s/monthly/%s/%s', data_dir, year, out_name)
      writeRaster(r, file=out_path, overwrite=TRUE)
    }
  }


  # yearly
  for (j in methods) {
    cat(sprintf('\tbuilding yearly %s...\n', j))
    dir.create(sprintf('%s/yearly/%s', data_dir, j), recursive=TRUE)

    data[[j]] <- apply(data@data[,as.character(c(1:12))], 1, j)
    data_trim <- data[, j]
    gridded(data_trim) = TRUE
    r <- raster(data_trim)

    out_name <- sprintf('%s_%s.tif', gsub("[.]", "_", fname), j)
    out_path <- sprintf('%s/yearly/%s/%s', data_dir, j, out_name)
    writeRaster(r, file=out_path, overwrite=TRUE)
  }


}

warnings()

