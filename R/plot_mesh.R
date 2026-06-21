lines <- readLines("../../Data/output_basemesh/mesh_interp_test.2dm")

nd <- lines[grepl("^ND", lines)]

nodes <- do.call(rbind, strsplit(nd, "\\s+"))
nodes <- nodes[, c(2,3,4,5)]
colnames(nodes) <- c("id","x","y","z")

nodes <- as.data.frame(nodes)
nodes$x <- as.numeric(nodes$x)
nodes$y <- as.numeric(nodes$y)
nodes$z <- as.numeric(nodes$z)

e3t <- lines[grepl("^E3T", lines)]

elems <- do.call(rbind, strsplit(e3t, "\\s+"))
elems <- elems[, c(2,3,4,5,7)]
colnames(elems) <- c("id","n1","n2","n3","n4")

elems <- as.data.frame(elems)
elems[] <- lapply(elems, as.numeric)


library(sf)

nodes$id <- as.integer(nodes$id)

make_triangle <- function(n1, n2, n3,n4) {
  pts <- rbind(
    nodes[nodes$id == n1, c("x","y")],
    nodes[nodes$id == n2, c("x","y")],
    nodes[nodes$id == n3, c("x","y")]
  )

  # ensure closure
  pts <- rbind(pts, pts[1, ])

  polygon <- sf::st_sf(sf::st_sfc(sf::st_polygon(list(as.matrix(pts))) , crs = 2056)) |>
    dplyr::mutate(
      hight = n4
    )

  polygon
}

triangles <- lapply(1:nrow(elems), function(i) {
  make_triangle(elems$n1[i], elems$n2[i], elems$n3[i], elems$n4[i])
})

mesh_sf <- dplyr::bind_rows(triangles)
nodes_sf <- sf::st_as_sf(nodes, coords = c("x", "y"))


sf::st_write(mesh_sf, "test.gpkg", delete_dsn = TRUE)
sf::st_write(nodes_sf, "test_nodes.gpkg", delete_dsn = TRUE)



nodes_bridge <- nodes |>
  dplyr::filter(
    id %in% c(519, 268, 1699, 437, 482)
  ) |>
  sf::st_as_sf(coords = c("x", "y"), crs = 2056)


