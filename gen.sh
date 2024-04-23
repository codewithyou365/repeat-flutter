#!/bin/bash

# generate nav.dart
cd ./lib || exit 1
{
  OUTPUT_FILE="nav.dart"

  echo "import 'package:get/get.dart';" >$OUTPUT_FILE
  for dir in $(find ./page -type d -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
    echo "import 'package:repeat_flutter/page/$dir/$dir""_nav.dart';" >>$OUTPUT_FILE
  done
  echo "" >>$OUTPUT_FILE
  echo "enum Nav {" >>$OUTPUT_FILE

  for dir in $(find ./page -type d -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
    camelCaseDir=$(echo "$dir" | perl -pe 's/_([a-z])/uc($1)/ge')
    path=$(echo "$dir" | sed "s/_/\//g")
    echo "  $camelCaseDir(\"/$path\")," >>$OUTPUT_FILE
  done

  echo "  ;" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  final String path;" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  const Nav(this.path);" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  Future? push({dynamic arguments}) {" >>$OUTPUT_FILE
  echo "    return Get.toNamed(path, arguments: arguments);" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  Future? pop() {" >>$OUTPUT_FILE
  echo "    return Get.offNamed(path);" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static back() {" >>$OUTPUT_FILE
  echo "    Get.back();" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static final String initialRoute = main.path;" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static final List<GetPage> getPages = [" >>$OUTPUT_FILE

  for dir in $(find ./page -type d -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
    camelCaseDir=$(echo "$dir" | perl -pe 's/_([a-z])/uc($1)/ge')
    echo "    $camelCaseDir""Nav($camelCaseDir.path)," >>$OUTPUT_FILE
  done

  echo "  ];" >>$OUTPUT_FILE
  echo "}" >>$OUTPUT_FILE
}
cd - || exit 1

# generate database.g.dart
read -p "generate database.g.dart (y: start)" -r start
if [ "$start" == "y" ]; then
  flutter packages pub run build_runner build
  while grep -q 'CREATE TABLE IF NOT EXISTS ``' ./lib/db/database.g.dart; do
    lineNumber=$(grep -n 'CREATE TABLE IF NOT EXISTS ``' ./lib/db/database.g.dart | cut -d: -f1 | head -n 1)
    sed -i '' "$((lineNumber - 1)),${lineNumber}d" ./lib/db/database.g.dart
  done

fi
