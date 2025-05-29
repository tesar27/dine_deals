#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Install dependencies and run code generation.
flutter doctor
flutter pub get
flutter packages pub run build_runner build
flutter build ios --config-only