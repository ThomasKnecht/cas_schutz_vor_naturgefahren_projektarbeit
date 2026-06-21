"""
BASEmesh v2 - Quality Mesh Generation
======================================
Generates a 2DM mesh for BASEMENT from:
  - Data/edges.gpkg   : break lines (boundary + internal constraints)
  - Data/points.gpkg  : region marker points with attributes:
                          Region        -> attribute (Material ID)
                          Hole_marker   -> whether to use HoleMarker instead
                          Maximum_area  -> max element area in this region

Requirements:
    pip install basemesh geopandas
"""

import pandas as pd
import geopandas as gpd
import basemesh
from basemesh import triangle
from typing import Dict, List
from basemesh.types import (LineString2D, Point2D)
import sys

mesh_path = sys.argv[1]

# ---------------------------------------------------------------------------
# 1. Load input layers
# ---------------------------------------------------------------------------
edges_gdf = gpd.read_file(f"{mesh_path}/input_basemesh/edges.gpkg")
points_gdf = gpd.read_file(f"{mesh_path}/input_basemesh/points.gpkg")
stringdefs = gpd.read_file(f"{mesh_path}/input_basemesh/stringdefs.gpkg")

print(f"Loaded {len(edges_gdf)} edge features")
print(f"Loaded {len(points_gdf)} region point features")

# ---------------------------------------------------------------------------
# 2. Build Node and Segment objects from edges.gpkg
#    - SNAP rounds coordinates to collapse near-coincident nodes
#    - seg_set deduplicates reversed/shared boundary segments
# ---------------------------------------------------------------------------
SNAP = 3  # decimal places — adjust if your CRS unit is not metres

node_map = {}  # (x, y) -> triangle.Node
seg_set  = set()  # frozenset of endpoint coords, to skip duplicates
segments = []
node_id  = 0
seg_id   = 0

for geom in edges_gdf.geometry:
    if geom.geom_type == "LineString":
        lines = [geom]
    elif geom.geom_type == "MultiLineString":
        lines = list(geom.geoms)
    else:
        continue
    for line in lines:
        coords = list(line.coords)
        for i in range(len(coords) - 1):
            x0, y0 = round(coords[i][0],     SNAP), round(coords[i][1],     SNAP)
            x1, y1 = round(coords[i + 1][0], SNAP), round(coords[i + 1][1], SNAP)
            if (x0, y0) == (x1, y1):
                continue  # zero-length segment after snapping
            seg_key = frozenset([(x0, y0), (x1, y1)])
            if seg_key in seg_set:
                continue  # duplicate/reversed segment
            seg_set.add(seg_key)
            for x, y in [(x0, y0), (x1, y1)]:
                if (x, y) not in node_map:
                    node_map[(x, y)] = triangle.Node(id_=node_id, pos_x=x, pos_y=y)
                    node_id += 1
            segments.append(
                triangle.Segment(
                    id_=seg_id,
                    start=node_map[(x0, y0)].id,
                    end=node_map[(x1, y1)].id,
                )
            )
            seg_id += 1

nodes = list(node_map.values())
print(f"Built {len(segments)} segments, {len(nodes)} unique nodes from edges")

# ---------------------------------------------------------------------------
# 3. Build RegionMarker / HoleMarker objects from points.gpkg
# ---------------------------------------------------------------------------
regions = []
holes   = []

for _, row in points_gdf.iterrows():
    x        = row.geometry.x
    y        = row.geometry.y
    is_hole  = bool(row["Hole_marker"])   if not pd.isna(row["Hole_marker"])  else False
    max_area = float(row["Maximum_area"]) if not pd.isna(row["Maximum_area"]) else -1.0
    region   = int(row["Region"])         if not pd.isna(row["Region"])       else None
    if is_hole:
        holes.append(triangle.HoleMarker(pos_x=x, pos_y=y))
    else:
        regions.append(
            triangle.RegionMarker(
                pos_x=x,
                pos_y=y,
                max_area=max_area,
                attribute=region,
            )
        )

print(f"Built {len(regions)} region markers, {len(holes)} hole markers")

# ---------------------------------------------------------------------------
# 4. Run quality meshing
# ---------------------------------------------------------------------------
mesh = basemesh.quality_mesh(
    nodes=nodes,
    segments=segments,
    holes=holes,
    regions=regions,
    min_angle=30,
    # max_area=1000.0,
)

print(f"Mesh generated: {mesh}")

# ---------------------------------------------------------------------------
# 5. Add stringdefs
# ---------------------------------------------------------------------------



string_def_lines: Dict[str, LineString2D] = {}

for idx, row in stringdefs.iterrows():
    if row.geometry.geom_type == "LineString":
        lines = [row.geometry]
    elif row.geometry.geom_type == "MultiLineString":
        lines = list(row.geometry.geoms)
    else:
        continue

    SNAP = 3 
    print(row)
    attr_index = row["id"]
    name = row["typ"]
    line_string: List[Point2D] = []
    for line in lines:
        coords = list(line.coords)
        for i in range(len(coords) - 1):
            line_string.append((round(coords[i][0], SNAP), round(coords[i][1], SNAP)))
        string_def_lines[name] = tuple(line_string)


string_defs = basemesh.resolve_string_defs(string_def_lines, mesh, precision= 0.001)

string_defs = basemesh.split_string_defs(string_defs, 20000)

for name, nodes in string_defs.items():
    mesh.add_node_string(name, [mesh.get_node_by_id(i) for i in nodes])

# ---------------------------------------------------------------------------
# 6. Export to 2DM (required format for BASEMENT 3.x)
# ---------------------------------------------------------------------------
output_path = f"{mesh_path}/output_basemesh/mesh_test.2dm"
mesh.save(output_path)

print(f"Mesh saved to: {output_path}")
print("Done. Next step: interpolate elevation onto the mesh using BASEmesh.")



