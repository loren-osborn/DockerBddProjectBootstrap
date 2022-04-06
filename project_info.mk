

PROJECT_DOCKER_COMPOSITION_NAMES             = MY_COMPOSITION
PROJECT__MY_COMPOSITION__BASE_DIR            = my_composition
PROJECT__MY_COMPOSITION__DOCKER_COMPOSE_FILE = \
	$(call \
		FN__APPEND_TO_FILEPATH,$\
		$(PROJECT__MY_COMPOSITION__BASE_DIR),$\
		docker-compose.yml$\
	)
PROJECT__MY_COMPOSITION__CONTAINER_LABELS                       = APP_SERVER DB_SERVER
PROJECT__MY_COMPOSITION__APP_SERVER__NAME                       = my_app
PROJECT__MY_COMPOSITION__DB_SERVER__NAME                        = db
PROJECT__MY_COMPOSITION__APP_SERVER__TEST_SUITES                = MY_TEST_SUITE
PROJECT__MY_COMPOSITION__APP_SERVER__MY_TEST_SUITE__PROJECT_DIR = \
	$(call \
		FN__APPEND_TO_FILEPATH,$\
		$(PROJECT__MY_COMPOSITION__BASE_DIR),$\
		my_app$\
	)
PROJECT__MY_COMPOSITION__APP_SERVER__MY_TEST_SUITE__CONTAINER_DIR  = /my_app
PROJECT__MY_COMPOSITION__APP_SERVER__MY_TEST_SUITE__LAUNCH_COMMAND = ./vendor/bin/phpunit
