#!/bin/bash
echo "Start building github pages"

cd "$(dirname "$0")" || exit

./build_with_replace_includes.sh

cd ../..

export PLANTUML_INCLUDE_PATH="$(pwd)/puml"

plantuml -tsvg -o ../images/diagrams ./puml/ -x "**/puml-theme-*.puml"
plantuml -tsvg -o ../build/images/diagrams ./puml/ -x "**/puml-theme-*.puml"

for filename in $(find ./docs -name '*.adoc'); do
    newFileName=$(basename $filename | sed 's/adoc/html/')
    asciidoctor $filename -o build/concept/$newFileName -a allow-uri-read
done

npx @redocly/cli lint docs_sources/push_gateway_openapi.yaml
npx @redocly/cli lint docs_sources/fd_openapi.yaml

npx @redocly/cli build-docs docs_sources/push_gateway_openapi.yaml -o build/push_gateway_openapi.html
npx @redocly/cli build-docs docs_sources/fd_openapi.yaml -o build/fd_openapi.html

cp images/gematik_logo.png build/images/gematik_logo.png
cp ./docs_sources/index.html ./build/index.html
cp images/*.drawio.svg build/images/
cp push-poc-ios/push_poc.mp4 build/push_poc.mp4
