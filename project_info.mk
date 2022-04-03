

PROJECT_DOCKER_BASE_DIR_APPS = docker_base:my_app
PROJECT_DOCKER_BASE_DIRS = $(PROJECT_BASE_PATH)/docker_base
FN__PROJECT_APP_DIRS     = \
	$(foreach \
		docker_base_path,$\
		$(1),$\
		$(if \
			$(filter \
				$(PROJECT_BASE_PATH)/docker_base,\
				$(docker_base_path)\
			),$\
			$(PROJECT_BASE_PATH)/docker_base/my_app,$\
			$\
		)$\
	)
