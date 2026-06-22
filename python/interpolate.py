"""
BASEmesh v2 - Elevation Interpolation
======================================
Interpolates elevation onto an existing flat 2DM mesh from a GeoTIFF raster.


Usage:
    uv run interpolate.py

Requirements:
    pip install basemesh rasterio
"""

import rasterio
from rasterio.transform import rowcol
import basemesh
from basemesh.abc import ElevationSource
import sys

mesh_path = sys.argv[1]

# ---------------------------------------------------------------------------
# Inputs — adjust as needed
# ---------------------------------------------------------------------------
input_mesh_path   = f"{mesh_path}/output_basemesh/mesh_test.2dm"
raster_path = "base_data/merged_dem_hardcut_gebplus10m_plus30cm.tif"
output_path = f"{mesh_path}/output_basemesh/mesh_interp_test.2dm"

# ---------------------------------------------------------------------------
# 1. Load existing mesh
# ---------------------------------------------------------------------------
mesh = basemesh.Mesh.open(input_mesh_path)
print(f"Loaded mesh: {mesh}")

# ---------------------------------------------------------------------------
# 2. Define raster elevation source
# ---------------------------------------------------------------------------
class GeoTiffElevationSource(ElevationSource):
    """Wraps a GeoTIFF raster for use as a BASEmesh ElevationSource."""

    def __init__(self, path: str, band: int = 1) -> None:
        self._src = rasterio.open(path)
        self._data = self._src.read(band)
        self._nodata = self._src.nodata

    def elevation_at(self, point):
        row, col = rowcol(self._src.transform, point[0], point[1])
        if not (0 <= row < self._data.shape[0] and 0 <= col < self._data.shape[1]):
            raise ValueError(f"Point {point} is outside raster extent")
        value = self._data[row, col]
        if self._nodata is not None and value == self._nodata:
            raise ValueError(f"Point {point} is at a nodata cell")
        return float(value)

    def close(self):
        self._src.close()

# ---------------------------------------------------------------------------
# 3. Interpolate and save
# ---------------------------------------------------------------------------
elevation_source = GeoTiffElevationSource(raster_path)

print(f"Interpolating elevation from {raster_path} ...")
# interpolate nodes
basemesh.interpolate_mesh(mesh, elevation_source)

# interpolate elements
elevations = basemesh.calculate_element_elevation(mesh, elevation_source)

 # Update element materials
for element in mesh.elements:
    bed_elev = elevations[element.id]
    # NOTE: QGIS always interprets the first material as the MATID
    # and the second as element bed elevation. If no MATID is
    # given, 0 is inserted to keep the dataset names in QGIS
    # consistent and avoid confusion for plugin users.
    matid = element.materials[0] if element.materials else 0
    element.materials = matid, bed_elev, *element.materials[1:]


elevation_source.close()
print("Elevation interpolated.")

mesh.save(output_path)
print(f"Mesh saved to: {output_path}")
