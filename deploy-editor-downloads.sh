#!/bin/bash
# An update script for https://github.com/AwesomeSauce-Software/gooftuber-editor
# If run, it will
# 1. Pull the latest changes from the master branch
# 2. Run flutter pub get
# 3. Run flutter build linux --release
# 4. ZIP the build and move it to /var/www/edit.awesomesauce.software/linux.zip

# 1. Pull the latest changes from the master branch
rm -rf gooftuber-editor
git clone https://github.com/AwesomeSauce-Software/gooftuber-editor
cd gooftuber-editor

# 2. Run flutter pub get
export PATH="$PATH:/home/deploy/development/flutter/bin"
flutter pub get

# 3. Run flutter build linux --release --dart2js-optimization O2 and check for errors
flutter build linux --release
if [ $? -ne 0 ]; then
    echo "flutter build failed"
    exit 1
fi

# 4. ZIP the build and move it to /var/www/edit.awesomesauce.software/linux.zip
rm -rf /var/www/edit.awesomesauce.software/linux.zip
zip -r /var/www/edit.awesomesauce.software/linux.zip build/linux/x64/release/bundle/*