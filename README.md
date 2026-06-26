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

