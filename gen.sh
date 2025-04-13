#!/bin/bash

# generate nav.dart
cd ./lib || exit 1
{
  OUTPUT_FILE="nav.dart"

  echo "import 'package:get/get.dart';" >$OUTPUT_FILE
  for dir in $(find ./page -type d -depth 1 -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
    echo "import 'package:repeat_flutter/page/$dir/$dir""_nav.dart';" >>$OUTPUT_FILE
  done
  echo "" >>$OUTPUT_FILE
  echo "enum Nav {" >>$OUTPUT_FILE

  for dir in $(find ./page -type d -depth 1 -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
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
  echo "  Future<T?>? push<T>({dynamic arguments}) {" >>$OUTPUT_FILE
  echo "    return Get.toNamed<T>(path, arguments: arguments);" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  void until() {" >>$OUTPUT_FILE
  echo "    Get.until((route) => Get.currentRoute == path);" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static back<T>({" >>$OUTPUT_FILE
  echo "    T? result," >>$OUTPUT_FILE
  echo "    bool closeOverlays = false," >>$OUTPUT_FILE
  echo "    bool canPop = true," >>$OUTPUT_FILE
  echo "    int? id," >>$OUTPUT_FILE
  echo "  }) {" >>$OUTPUT_FILE
  echo "    Get.back(result: result, closeOverlays: closeOverlays, canPop: canPop, id: id);" >>$OUTPUT_FILE
  echo "  }" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static final String initialRoute = gs.path;" >>$OUTPUT_FILE
  echo "" >>$OUTPUT_FILE
  echo "  static final List<GetPage> getPages = [" >>$OUTPUT_FILE

  for dir in $(find ./page -type d -depth 1 -not -path '*/\.*' -not -path '.' -not -path './page' | sort | sed 's/^\.\/page\///'); do
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

  if ! grep -q 'prepareDb(transactionDatabase);' ./lib/db/database.g.dart; then
    allLines=$(grep -nE 'transactionDatabase\.(\w+)' ./lib/db/database.g.dart)
    echo "$allLines" | tail -r | while read -r match_line; do
        line_number=$(echo "$match_line" | cut -d: -f1)
        sed -i '' "${line_number}i\\
        prepareDb(transactionDatabase);
" ./lib/db/database.g.dart
    done
  fi
fi
