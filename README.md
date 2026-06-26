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
 
- Make sure that the DTM, the prerimeter-file and the stringdefs-file are in the the `meshes/base_data/` directory

- run: `make create_new_basemesh mesh_name=the_new_name`; 
This creates a new directory in the meshes-directory

- run: `make run_basemesh mesh_name=the_new_name hole_marker=which_hole_marker maximum_area=ara`; 
This call syncs first the base_data as well as the needed code to the server.
Then it creates the basemesh. There are the following options for the `hole_marker`: "messstationen", "with_bridges", "without_bridges", "with_read_bridge". The area is set as integer.

- run: `make sync_output_basemesh mesh_name=the_new_name`;
This syncs the created basemesh back to the client into the created mesh-directory.

- look at the created mesh in QGIS.

