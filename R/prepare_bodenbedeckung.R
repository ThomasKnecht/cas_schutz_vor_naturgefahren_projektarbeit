
perimeter <- sf::st_read("../../Data/new_perimeter.gpkg")


points <- sf::st_point_on_surface(perimeter) |>
  dplyr::mutate(
    Maximum_area = ifelse(Region == 1, 10, NA)
  ) |>
  dplyr::select(
    Region,
    Maximum_area,
    Hole_marker,
    geom
  )


edges <- perimeter |>
  sf::st_cast("MULTILINESTRING") |>
  sf::st_cast("LINESTRING") |>
  tibble::rowid_to_column() |>
  dplyr::select(rowid, geom)


stringdefs <- sf::st_read("../../Data/stringdefs.gpkg")


sf::st_write(points, "../../Data/input_basemesh/points.gpkg", delete_dsn = TRUE)
sf::st_write(edges, "../../Data/input_basemesh/edges.gpkg", "edges", delete_dsn = TRUE)
sf::st_write(stringdefs, "../../Data/input_basemesh/stringdefs.gpkg", delete_dsn = TRUE)



