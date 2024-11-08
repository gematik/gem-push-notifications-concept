#!/bin/bash
echo "Start building github pages"

cd "$(dirname "$0")" || exit

./build_with_replace_includes.sh

cd ../..

plantuml -v -o ../images/diagrams ./puml/
plantuml -v -o ../build/images/diagrams ./puml/
asciidoctor ./docs/concept.adoc -r asciidoctor-diagram -o build/concept/index.html -a allow-uri-read

npx @redocly/cli build-docs docs_sources/push_gateway_openapi.yaml -o build/push_gateway_openapi.html
npx @redocly/cli build-docs docs_sources/fd_openapi.yaml -o build/fd_openapi.html

cp images/gematik_logo.png build/images/gematik_logo.png
cp ./docs_sources/index.html ./build/index.html
