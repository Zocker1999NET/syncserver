SYSTEMPYTHON = `which python2 python | head -n 1`
VIRTUALENV = virtualenv --python=$(SYSTEMPYTHON)
ENV = ./local
TOOLS := $(addprefix $(ENV)/bin/,flake8 nosetests)

# Hackety-hack around OSX system python bustage.
# The need for this should go away with a future osx/xcode update.
ARCHFLAGS = -Wno-error=unused-command-line-argument-hard-error-in-future
INSTALL = ARCHFLAGS=$(ARCHFLAGS) $(ENV)/bin/pip install

.PHONY: all
all: build

.PHONY: build
build: | $(ENV)
$(ENV): requirements.txt
	$(VIRTUALENV) --no-site-packages $(ENV)
	$(INSTALL) -r requirements.txt
	$(ENV)/bin/python ./setup.py develop
	touch $(ENV)

.PHONY: test
test: | $(TOOLS)
	$(ENV)/bin/flake8 ./syncserver
	$(ENV)/bin/nosetests -s syncstorage.tests
	# Tokenserver tests currently broken due to incorrect file paths
	# $(ENV)/bin/nosetests -s tokenserver.tests
	
	# Test against a running server
	$(ENV)/bin/pserve syncserver/tests.ini 2> /dev/null & SERVER_PID=$$!; \
	sleep 2; \
	$(ENV)/bin/python -m syncstorage.tests.functional.test_storage \
		--use-token-server http://localhost:5000/token/1.0/sync/1.5; \
	kill $$SERVER_PID

$(TOOLS): | $(ENV)
	$(INSTALL) nose flake8

.PHONY: serve
serve: | $(ENV)
	$(ENV)/bin/pserve ./syncserver.ini

.PHONY: clean
clean:
	rm -rf $(ENV)
