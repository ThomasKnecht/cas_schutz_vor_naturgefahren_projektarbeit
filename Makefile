
username ?= username
server ?= server
project_dir ?= project_dir
	

create_new_basemesh:
	mkdir -p ./meshes/$(mesh_name)/

sync_mesh_base_data:
	rsync -rlv --checksum \
		"./meshes/base_data/" \
		"$(username)@$(server):$(project_dir)/meshes/base_data/" 

sync_mesh_code:
	rsync -rlv --checksum \
		"./python/" \
		"$(username)@$(server):$(project_dir)/meshes/" \
	&& \
	rsync -rlv --checksum \
		"./bash/create_mesh.sh" \
		"$(username)@$(server):$(project_dir)/meshes/create_mesh.sh"

# hole_marker: einer von den drei Möglichkeiten eingeben: "messstationen", "with_bridges", "without_bridges", "with_read_bridge"
run_basemesh:
	make sync_mesh_base_data
	make sync_mesh_code
	ssh -o HostKeyAlgorithms=+ssh-rsa $(username)@$(server) \
		'bash -lc "cd $(project_dir)/meshes/ && \
		 chmod +x ./create_mesh.sh && \
		 ./create_mesh.sh $(mesh_name) $(hole_marker) $(maximum_area)"'

sync_output_basemesh:
	rsync -rlv --checksum \
		"$(username)@$(server):$(project_dir)/meshes/$(mesh_name)/" \
		"./meshes/$(mesh_name)/"

sync_uv_lock:
	rm ./src/python/uv.lock && \
    rsync -rlv --checksum \
		"$(username)@$(server):$(project_dir)/meshes/uv.lock" \
		"./python/uv.lock"


create_new_model:
	cp -r ./models/model_template ./models/$(model_name)
	mv ./models/$(model_name)/configuration/simulation.json ./models/$(model_name)/configuration/simulation_$(model_name).json
	cp ./models/config_templates/$(hole_marker)_$(time).json ./models/$(model_name)/configuration/model.json
	cp ./models/base_data/*$(time).txt ./models/$(model_name)/input_data/
	cp ./meshes/$(mesh_name)/output_basemesh/mesh_interp_test.2dm ./models/$(model_name)/input_data/
	rsync -rlv --checksum \
		"./models/$(model_name)/" \
		"$(username)@$(server):$(project_dir)/models/$(model_name)/" 

sync_model:
	rsync -rlv --checksum \
		"./models/$(model_name)/" \
		"$(username)@$(server):$(project_dir)/models/$(model_name)/" \
	&& \
    rsync -rlv --checksum \
		"./bash/model_workflow.sh" \
		"$(username)@$(server):$(project_dir)/models/model_workflow.sh"

run_model: 
	make sync_model model_name=$(model_name)
	ssh -o HostKeyAlgorithms=+ssh-rsa $(username)@$(server) "bash -lc 'cd $(project_dir)/models/$(model_name)/ \
		&& cp ../model_workflow.sh ./model_workflow.sh \
		&& tmux new-session -d -s $(model_name) \"./model_workflow.sh simulation_$(model_name).json 2>&1 | tee -a $(model_name).log\"'"

sync_model_result:
	rsync -rlv --checksum \
		"$(username)@$(server):$(project_dir)/models/$(model_name)/$(simulation_name)*" \
		"model_results/$(model_name)/"  


rasterize_model_result:
	gdal_rasterize -a max_depth -tr 0.5 0.5 \
		-a_nodata -9999.0 \
		-ot Float32 \
		-of GTiff \
		-a_srs EPSG:2056 \
		-tap \
		-co "COMPRESS=DEFLATE" \
		-co "PREDICTOR=3" \
		"model_results/$(model_name)/$(simulation_name).shp" \
		"model_results/$(model_name)/$(model_name).tif"
