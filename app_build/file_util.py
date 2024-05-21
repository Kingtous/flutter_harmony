# Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/python
import shutil
import os


def copyFile(sourceFile, targetFile):
    if os.path.exists(targetFile):
        os.remove(targetFile)
    shutil.copy(sourceFile, targetFile)
    print("拷贝从{}到{}结束。".format(sourceFile, targetFile))


def copyFiles(sourceFiles, targetFiles):
    if os.path.exists(targetFiles):
        shutil.rmtree(targetFiles)
    shutil.copytree(sourceFiles, targetFiles)
    print("拷贝从{}到{}结束。".format(sourceFiles, targetFiles))