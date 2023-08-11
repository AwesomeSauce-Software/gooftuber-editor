#!/bin/bash
# An update script for https://github.com/AwesomeSauce-Software/gooftuber-editor
# If run, it will
# 1. Pull the latest changes from the master branch
# 2. Run flutter pub get
# 3. Run flutter build web --release --dart2js-optimization O2
# 4. Copy the build/web folder to the /var/www/edit.awesomesauce.software/ folder

# 1. Pull the latest changes from the master branch
rm -rf gooftuber-editor
git clone https://github.com/AwesomeSauce-Software/gooftuber-editor
cd gooftuber-editor

# 2. Run flutter pub get
export PATH="$PATH:/home/deploy/development/flutter/bin"
flutter pub get

# 3. Run flutter build web --release --dart2js-optimization O2 and check for errors
flutter build web --release --dart2js-optimization O2
if [ $? -ne 0 ]; then
    echo "flutter build web --release --dart2js-optimization O2 failed"
    exit 1
fi

# 4. Copy the build/web folder to the /var/www/edit.awesomesauce.software/ folder
rm -rf /var/www/edit.awesomesauce.software/*
cp -r build/web/* /var/www/edit.awesomesauce.software/