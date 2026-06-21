#!/bin/bash

mkdir -p $1/input_basemesh/
mkdir -p $1/output_basemesh/

#test
uv lock
uv sync
uv run python prepare_edges_and_nodes.py $1 $2 $3
uv run python meshing.py $1
uv run python interpolate.py $1
