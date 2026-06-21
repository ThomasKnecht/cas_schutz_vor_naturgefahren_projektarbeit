tiles <- c(
  "2606-1125",
  "2606-1126",
  "2607-1125",
  "2607-1126",
  "2608-1125",
  "2608-1126"
)

download_urls <- paste0(
  "https://data.geo.admin.ch/ch.swisstopo.swissalti3d/swissalti3d_2024_",
  tiles,
  "/swissalti3d_2024_",
  tiles,
  "_0.5_2056_5728.tif"
)


croped_tiles <- purrr::map(download_urls, download_and_crop_swissalti)

r <- terra::mosaic(terra::sprc(croped_tiles))

terra::writeRaster(r, "Data/swissalti3d_croped/siders_perimeter_all.tiff")
