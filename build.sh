#!/bin/bash
PROJECT_DIR=`pwd`
PROJECT_NAME='FRAudioPlayerSDK'
CONFIGURATION="Release"
BUILD_DIR="${PROJECT_DIR}/build_result"
BUILD_ROOT="${PROJECT_DIR}/build_result"
UNIVERSAL_OUTPUTFOLDER="${PROJECT_DIR}/framework"
WORKSPACE_NAME=${PROJECT_NAME}.xcodeproj
# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
mkdir -p "${BUILD_DIR}"
rm -rf "${BUILD_DIR}/*"
rm -rf "${UNIVERSAL_OUTPUTFOLDER}/*"
mkdir -p ${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework


# Step 1. Build Device and Simulator versions
xcodebuild -project "${WORKSPACE_NAME}" -scheme "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphoneos ONLY_ACTIVE_ARCH=NO   BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -project "${WORKSPACE_NAME}" -scheme "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO EXCLUDED_ARCHS="arm64"  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create  "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}" -output "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}"