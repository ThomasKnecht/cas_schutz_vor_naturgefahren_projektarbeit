download_and_crop_swissalti <- function(url) {
  download_name <- basename(url)
  dir_name <- "temp_dir/"

  download_path <- paste0(dir_name, download_name)

  if (!dir.exists(dir_name)) {
    dir.create(dir_name, showWarnings = FALSE)
  }

  download.file(url, download_path)


  raster_data <- terra::rast(download_path)


  return(raster_data)
}
