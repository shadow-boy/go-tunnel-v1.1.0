#!/bin/bash -eux
#
# Copyright 2019 The Outline Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

readonly BUILD_DIR=build/macos
readonly TUN2SOCKS_FRAMEWORK=Tun2socks.framework

rm -rf $BUILD_DIR
make clean && make macos
# Add Info.plist
cp apple/Info.plist $BUILD_DIR/$TUN2SOCKS_FRAMEWORK/Versions/A/Resources/
