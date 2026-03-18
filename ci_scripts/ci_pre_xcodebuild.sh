#!/bin/sh

# 安装 CocoaPods（以防云端版本有问题）
gem install cocoapods

# 进入项目目录
cd $CI_PRIMARY_REPOSITORY_PATH

# 执行 pod install
pod install