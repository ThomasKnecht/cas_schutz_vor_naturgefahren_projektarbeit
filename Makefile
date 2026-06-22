
username ?= username
server ?= server
	

create_new_basemesh:
	mkdir -p ./meshes/$(mesh_name)/

sync_mesh_base_data:
	rsync -rlv --checksum "./meshes/base_data/" "$(username)@$(server):/mnt/data2/cas/basement/meshes/base_data/" 

sync_mesh_code:
	rsync -rlv --checksum "./python/" "$(username)@$(server):/mnt/data2/cas/basement/meshes/" && \
	rsync -rlv --checksum "./bash/create_mesh.sh" "$(username)@$(server):/mnt/data2/cas/basement/meshes/create_mesh.sh"

# hole_marker: einer von den drei Möglichkeiten eingeben: "messstationen", "with_bridges", "without_bridges"
run_basemesh:
	ssh -o HostKeyAlgorithms=+ssh-rsa $(username)@$(server) 'bash -lc "cd /mnt/data2/cas/basement/meshes/ && chmod +x ./create_mesh.sh && ./create_mesh.sh $(mesh_name) $(hole_marker) $(maximum_area)"'

sync_output_basemesh:
	rsync -rlv --checksum "$(username)@$(server):/mnt/data2/cas/basement/meshes/$(mesh_name)/" "./meshes/$(mesh_name)/"

sync_uv_lock:
	rm ./src/python/uv.lock && \
    rsync -rlv --checksum "$(username)@$(server):/mnt/data2/cas/basement/meshes/uv.lock" "./python/uv.lock"


sync_model:
	rsync -rlv --checksum "./models/$(model_name)/" "$(username)@$(server):/mnt/data2/cas/basement/models/$(model_name)/" && \
    rsync -rlv --checksum "./bash/model_workflow.sh" "$(username)@$(server):/mnt/data2/cas/basement/models/model_workflow.sh"


run_model: 
	make sync_model model_name=$(model_name)
	ssh -o HostKeyAlgorithms=+ssh-rsa $(username)@$(server) "bash -lc 'cd /mnt/data2/cas/basement/models/$(model_name)/ \
		&& cp ../model_workflow.sh ./model_workflow.sh \
		&& tmux new-session -d -s $(model_name) \"./model_workflow.sh simulation_$(model_name).json 2>&1 | tee -a $(model_name).log\"'"


create_new_model:
	cp -r ./models/model_template ./models/$(model_name)
	cp ./models/config_templates/$(hole_marker)_$(time).json ./models/$(model_name)/configuration/model.json
	cp ./models/base_data/*$(time).txt ./models/$(model_name)/input_data/
	cp ./meshes/$(mesh_name)/output_basemesh/mesh_interp_test.2dm ./models/$(model_name)/input_data/
	rsync -rlv --checksum "./models/$(model_name)/" "$(username)@$(server):/mnt/data2/cas/basement/models/$(model_name)/" 



sync_model_result:
	rsync -rlv --checksum "$(username)@$(server):/mnt/data2/cas/basement/models/$(model_name)/Siders*"  "../Resultate/$(model_name)/"  


rasterize_model_result:
	gdal_rasterize -a max_depth -tr 0.5 0.5 -a_nodata -9999.0 -ot Float32 -of GTiff -a_srs EPSG:2056 -tap -co "COMPRESS=DEFLATE" -co "PREDICTOR=3" "../Resultate/$(model_name)/Siders_els_track.shp" "../Resultate/$(model_name)/$(model_name).tif"
