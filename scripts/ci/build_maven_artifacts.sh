#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Build all artifacts and put into an artifacts/ folder
# parameters:
# 1. version tag, e.g. v0.20.1-incubating
# 2. output dir

set -e
set -o pipefail

if [ "$#" -ne 2 ]; then
    echo "ERROR: Wrong number of arguments. Usage '$0 VERSION_TAG OUTPUT_DIR'"
    exit 1
fi
VERSION_TAG=$1
OUTPUT_DIR=$2

# Clear out the pex cache
rm -rf /var/lib/jenkins/.pex/build/*

# Build
echo "Starting Heron Maven Jars Process"
bash scripts/release/status.sh

echo "Make jar components"
$HOME/bin/bazel build heron/api/src/java:all
$HOME/bin/bazel build heron/spi/src/java:all
$HOME/bin/bazel build heron/simulator/src/java:all
$HOME/bin/bazel build storm-compatibility/src/java:all

echo "Found Version Tag $VERSION_TAG"
mkdir -p artifacts/$VERSION_TAG
rm -rf artifacts/$VERSION_TAG/*

echo "Run Maven template for poms ... "
BASE_DIR=`pwd`
cd ./release/

git clean -f -x .
sh ./maven/maven-pom-version.sh $VERSION_TAG

cd $BASE_DIR

echo "Build directories for jars ... "
mkdir $OUTPUT_DIR/$VERSION_TAG/heron-api
mkdir $OUTPUT_DIR/$VERSION_TAG/heron-spi
mkdir $OUTPUT_DIR/$VERSION_TAG/heron-simulator
mkdir $OUTPUT_DIR/$VERSION_TAG/heron-storm

echo "Copy heron-api artifacts ... "
cp ./release/heron-api-$VERSION_TAG.pom $OUTPUT_DIR/$VERSION_TAG/heron-api/
cp ./bazel-bin/heron/api/src/java/api-shaded.jar $OUTPUT_DIR/$VERSION_TAG/heron-api/heron-api-$VERSION_TAG.jar
cp ./bazel-bin/heron/api/src/java/heron-api-javadoc.zip $OUTPUT_DIR/$VERSION_TAG/heron-api/heron-api-$VERSION_TAG-javadoc.jar
cp ./bazel-bin/heron/api/src/java/libapi-java-low-level-functional-src.jar $OUTPUT_DIR/$VERSION_TAG/heron-api/heron-api-$VERSION_TAG-sources.jar

echo "Copy heron-spi artifacts ... "
cp ./release/heron-spi-$VERSION_TAG.pom ./$OUTPUT_DIR/$VERSION_TAG/heron-spi/
cp ./bazel-bin/heron/spi/src/java/spi-unshaded_deploy.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-spi/heron-spi-$VERSION_TAG.jar
cp ./bazel-bin/heron/spi/src/java/heron-spi-javadoc.zip ./$OUTPUT_DIR/$VERSION_TAG/heron-spi/heron-spi-$VERSION_TAG-javadoc.jar
cp ./bazel-bin/heron/spi/src/java/libheron-spi-src.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-spi/heron-spi-$VERSION_TAG-sources.jar

echo "Copy heron-simulator artifacts ... "
cp ./release/heron-simulator-$VERSION_TAG.pom ./$OUTPUT_DIR/$VERSION_TAG/heron-simulator/
cp ./bazel-bin/heron/simulator/src/java/simulator-shaded.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-simulator/heron-simulator-$VERSION_TAG.jar
cp ./bazel-bin/heron/simulator/src/java/heron-simulator-javadoc.zip ./$OUTPUT_DIR/$VERSION_TAG/heron-spi/heron-simulator-$VERSION_TAG-javadoc.jar
cp ./bazel-bin/heron/simulator/src/java/libsimulator-java-src.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-simulator/heron-simulator-$VERSION_TAG-sources.jar

echo "Copy heron-storm artifacts ... "
cp ./release/heron-storm-$VERSION_TAG.pom ./$OUTPUT_DIR/$VERSION_TAG/heron-storm/
cp ./bazel-bin/storm-compatibility/src/java/heron-storm.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-storm/heron-storm-$VERSION_TAG.jar
cp ./bazel-bin/storm-compatibility/src/java/heron-storm-javadoc.zip ./$OUTPUT_DIR/$VERSION_TAG/heron-storm/heron-storm-$VERSION_TAG-javadoc.jar
cp ./bazel-bin/storm-compatibility/src/java/libstorm-compatibility-java-src.jar ./$OUTPUT_DIR/$VERSION_TAG/heron-storm/heron-storm-$VERSION_TAG-sources.jar


echo "Compress all artifacts into a bundle file ..."
tar -czf "${VERSION_TAG}_artifacts.tar.gz" $OUTPUT_DIR
mv "${VERSION_TAG}_artifacts.tar.gz" $OUTPUT_DIR