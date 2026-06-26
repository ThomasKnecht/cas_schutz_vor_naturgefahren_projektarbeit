# Projektarbeit CAS "Schutz vor Naturgefahren"

This repository contains the model runs for the hydrodynamical modelling with BASEMENT as part of the CAS-thesis "Hydrodynamische Modellierung der Überschwemmung im Raum Siders–Chippis mittels BASEMENT"

It contains scripts that help with the creation of the mesh as well as all configuration files for the model runs.

The Makefile defines steps to easily run certain parts of the modelling process.


# Setup

The modelling process is set up so that the creation of the mesh and the modelling is run on a remote linux-server.

On the linux-server the following software needs to be available:
    
    - BASEMENT 4.2 (https://basement.ethz.ch/download/software-download/download-v4.html)
    - python
    - uv (https://docs.astral.sh/uv/getting-started/installation/)
    - basemesh (https://pypi.org/project/BASEmesh/)

On the client the following global variables need to be defined:

```
export server="server-dns"

export username="username-on-the-server"

export project_dir="path-to-project-on-server"

```
These variables are needed for the `rsync` call, to push locally modified files to the server.
The call hat the following structure: 

`rsync -rlv --checksum "path-on-client" "$(username)@$(server):$(project_dir)/end-dir" `

# Modelling Steps

The modelling steps are mostly defined as code in the Makefile.
There are some steps that need to be made manually when creating a new model.

## Step-by-Step

__Mesh-Createion__

```
- Make sure that the DTM, the prerimeter-file and the stringdefs-file are in the the `meshes/base_data/` directory

- run: `make create_new_basemesh mesh_name=the_new_name`; 
This creates a new directory in the meshes-directory

- run: `make run_basemesh mesh_name=the_new_name hole_marker=which_hole_marker maximum_area=ara`; 
This call syncs first the base_data as well as the needed code to the server.
Then it creates the basemesh. There are the following options for the `hole_marker`: "messstationen", "with_bridges", "without_bridges", "with_read_bridge". The area is set as integer.

- run: `make sync_output_basemesh mesh_name=the_new_name`;
This syncs the created basemesh back to the client into the created mesh-directory.

- look at the created mesh in QGIS.

```


__Creat and run Model__

- run: `make reate_new_model model_name=your_model_name hole_marker=which_hole_marker time=run_time mesh_name=mesh_to_use`;
This call sets up a new model structure on the client. It copies the needed mesh file into the `input_data`-directory as well as a preset config file from `config_templates` to `configuration` in the new model-directory. Futhermore it syncs the model setup to the server.

- Adjust the model.json if needed. Furthermore, the Zufluss and HQ-Relation files can/need to be adjusted.

- run: `make run_model model_name=your_model_name`;
This first syncs the model-directory to the server and then starts a tmux backround session in which the model is created.

- run: `make sync_model_result model_name=your_model_name simulation_name=simulation_name`;
This syncs the results to your client. The `simulation_name` is the name josen in the model.json under: "simulation_name".

- run: `make rasterize_model_result model_name=your_model_name simulation_name=simulation_name`;
This rasterizes the shapefile for easier post processing and raster calculations.

- look at the result mesh in QGIS. A style-file `QGIS_style.qml` is present in the model_results directory