import geopandas as gpd
import numpy as np
from pathlib import Path
import sys

# Setup
# "messstationen", "with_bridges", "without_bridges"
mesh_name = sys.argv[1]
with_holemarker = sys.argv[2]
maximum_area = int(sys.argv[3])


########################################################################################

perimeter = gpd.read_file("base_data/new_perimeter.gpkg")
stringdefs = gpd.read_file("base_data/stringdefs.gpkg")

points = perimeter.copy()
points["geometry"] = points.representative_point()
# points["Maximum_area"] = np.where(points["Region"] == 1, 10, np.nan)
points["Maximum_area"] = maximum_area
points = points[["Region", "Maximum_area", "Hole_marker", "geometry"]]

if with_holemarker == "with_bridges":
    points["Hole_marker"] = np.where(points["Region"].isin([2, 3]), 1, np.nan)
elif with_holemarker == "messstationen":
    points["Hole_marker"] = np.where(points["Region"].isin([2, 4]), 1, np.nan)
elif with_holemarker == "without_bridges":
    points["Hole_marker"] = np.nan

edges = perimeter.copy()
edges["geometry"] = edges["geometry"].apply(
    lambda geom: geom.boundary if geom.geom_type in ("Polygon", "MultiPolygon") else geom
)
edges = edges.explode(index_parts=False).reset_index(drop=True)
edges = edges.reset_index().rename(columns={"index": "rowid"})
edges["rowid"] = edges["rowid"] + 1
edges = edges[["rowid", "geometry"]]



out_dir = Path(f"{mesh_name}/input_basemesh")
out_dir.mkdir(parents=True, exist_ok=True)

points.to_file(out_dir / "points.gpkg", driver="GPKG")
edges.to_file(out_dir / "edges.gpkg", layer="edges", driver="GPKG")
stringdefs.to_file(out_dir / "stringdefs.gpkg", driver="GPKG")
