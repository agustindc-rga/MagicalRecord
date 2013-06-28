BUILD_CONFIGURATION = Release

default:
	xcodebuild -target "libMagicalRecord-iOS" -configuration $(BUILD_CONFIGURATION) -sdk iphoneos
	xcodebuild -target "libMagicalRecord-iOS" -configuration $(BUILD_CONFIGURATION) -sdk iphonesimulator
	#BUILD_DIR="build" BUILD_STYLE="$(BUILD_CONFIGURATION)" sh Scripts/CombineLibs.sh
	sh Scripts/iOSFramework.sh $(BUILD_CONFIGURATION)

# If you need to clean a specific target/configuration: $(COMMAND) -target $(TARGET) -configuration DebugOrRelease -sdk $(SDK) clean
clean:
	-rm -rf build/*

test:
	GHUNIT_CLI=1 xcodebuild -target Tests -configuration Debug -sdk iphonesimulator build
