RESOLVE_DIR := .internal
BUILD_DIR := build
TOOLS_DIR := tools

DMENGINE_WINDOWS_PATH := $(BUILD_DIR)/x86_64-win32/dmengine
DMENGINE_MACOS_PATH := $(BUILD_DIR)/x86_64-osx/dmengine
DMENGINE_LINUX_PATH := $(BUILD_DIR)/x86_64-linux/dmengine

BOB_PATH := $(TOOLS_DIR)/bob.jar
BOB_VERSION := 1.3.5

.PHONY: clean
clean:
	rm -rf "$(RESOLVE_DIR)"
	rm -rf "$(BUILD_DIR)"
	rm -rf manifest.*

.PHONY: test
test:
	$(MAKE) resolve
	$(MAKE) test-linux

.PHONY: test-windows
test-windows: $(BOB_PATH)
	java -jar "$(BOB_PATH)" \
		--variant headless \
		--platform x86_64-win32 \
		build
	$(MAKE) "$(DMENGINE_WINDOWS_PATH)"
	"$(DMENGINE_WINDOWS_PATH)" --config="bootstrap.main_collection=/test/test.collectionc"

.PHONY: test-macos
test-macos: $(BOB_PATH)
	java -jar "$(BOB_PATH)" \
		--variant headless \
		--platform x86_64-darwin \
		build
	$(MAKE) "$(DMENGINE_MACOS_PATH)"
	"$(DMENGINE_MACOS_PATH)" --config="bootstrap.main_collection=/test/test.collectionc"

.PHONY: test-linux
test-linux: $(BOB_PATH)
	java -jar "$(BOB_PATH)" \
		--variant headless \
		--platform x86_64-linux \
		build
	$(MAKE) "$(DMENGINE_LINUX_PATH)"
	"$(DMENGINE_LINUX_PATH)" --config="bootstrap.main_collection=/test/test.collectionc"

resolve: $(RESOLVE_DIR)

$(RESOLVE_DIR): $(BOB_PATH)
	java -jar "$(BOB_PATH)" resolve

$(BOB_PATH):
	curl -L -o /tmp/bob.jar "https://github.com/defold/defold/releases/download/$(BOB_VERSION)/bob.jar"
	mkdir -p `dirname "$(BOB_PATH)"`
	mv /tmp/bob.jar "$(BOB_PATH)"
	java -jar "$(BOB_PATH)" --version

$(DMENGINE_WINDOWS_PATH): $(BOB_PATH)
	cd $(TOOLS_DIR) ; jar -xf "../$<" "libexec/x86_64-win32/dmengine_headless.exe"
	mkdir -p `dirname "$@"`
	mv $(TOOLS_DIR)/libexec/x86_64-win32/dmengine_headless.exe "$@"

$(DMENGINE_MACOS_PATH): $(BOB_PATH)
	cd $(TOOLS_DIR) ; jar -xf "../$<" "libexec/x86_64-darwin/dmengine_headless"
	mkdir -p `dirname "$@"`
	mv $(TOOLS_DIR)/libexec/x86_64-darwin/dmengine_headless "$@"
	chmod +x "$@"

$(DMENGINE_LINUX_PATH): $(BOB_PATH)
	cd $(TOOLS_DIR) ; jar -xf "../$<" "libexec/x86_64-linux/dmengine_headless"
	mkdir -p `dirname "$@"`
	mv $(TOOLS_DIR)/libexec/x86_64-linux/dmengine_headless "$@"
	chmod +x "$@"

