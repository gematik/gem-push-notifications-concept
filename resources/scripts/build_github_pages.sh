#!/bin/bash
echo "Start building github pages"

# Branch to publish in addition to main build output. Example: BUILD_BRANCH=1.1 ./build_github_pages.sh
BUILD_BRANCH="${BUILD_BRANCH:-main}"

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

# Migration from old tag folders to branch folders.
if [ -d "build/1.0.1" ] && [ ! -d "build/1.0" ]; then
    mv "build/1.0.1" "build/1.0"
fi
rm -rf "build/1.0.0" "build/1.0.0-RC2"

# Publish branch output while always keeping main docs in build/ up to date.
if [ "$BUILD_BRANCH" != "main" ]; then
    mkdir -p "build/$BUILD_BRANCH"
    cp -R build/concept "build/$BUILD_BRANCH/"
    cp -R build/images "build/$BUILD_BRANCH/"
    cp build/fd_openapi.html "build/$BUILD_BRANCH/fd_openapi.html"
    cp build/push_gateway_openapi.html "build/$BUILD_BRANCH/push_gateway_openapi.html"
    cp build/index.html "build/$BUILD_BRANCH/index.html"
    cp build/push_poc.mp4 "build/$BUILD_BRANCH/push_poc.mp4"
fi

build_versions_menu() {
    current="$1"
    shift

    if [ "$current" = "main" ]; then
        main_href="index.html"
    else
        main_href="../index.html"
    fi

    main_class="version-option"
    if [ "$current" = "main" ]; then
        main_class="version-option current"
    fi

    menu_items="                    <a href=\"$main_href\" class=\"$main_class\">main</a>"

    for version in "$@"; do
        if [ "$version" = "main" ] || [ "$version" = "$current" ]; then
            continue
        fi

        if [ "$current" = "main" ]; then
            href="$version/index.html"
        else
            href="../$version/index.html"
        fi

        menu_items="$menu_items\n                    <a href=\"$href\" class=\"version-option\">$version</a>"
    done

    for version in "$@"; do
        if [ "$version" != "main" ] && [ "$version" = "$current" ]; then
            href="../$version/index.html"
            menu_items="$menu_items\n                    <a href=\"$href\" class=\"version-option current\">$version</a>"
        fi
    done

    printf '%s\n' "            <div id=\"version-selector\">"
    printf '%s\n' "                <span id=\"version-button\">$current ▼</span>"
    printf '%s\n' "                <div id=\"version-popover\">"
    printf '%b\n' "$menu_items"
    printf '%s\n' "                </div>"
    printf '%s\n' "            </div>"
}

replace_menu_block() {
    html_file="$1"
    current="$2"
    shift 2

    replacement_file="$(mktemp)"
    build_versions_menu "$current" "$@" >"$replacement_file"

    # If there is no selector yet, replace the static <div>main</div> placeholder first.
    if ! grep -q '<div id="version-selector">' "$html_file"; then
        awk -v repl="$replacement_file" '
            {
                if ($0 ~ /<div>main<\/div>/) {
                    while ((getline line < repl) > 0) {
                        print line;
                    }
                    close(repl);
                    next;
                }
                print;
            }
        ' "$html_file" >"$html_file.tmp" && mv "$html_file.tmp" "$html_file"
    fi

    awk -v repl="$replacement_file" '
        {
            if (in_block == 0 && $0 ~ /<div id="version-selector">/) {
                in_block = 1;
                depth = 1;
                while ((getline line < repl) > 0) {
                    print line;
                }
                close(repl);
                next;
            }

            if (in_block == 1) {
                open_count = gsub(/<div/, "<div", $0);
                close_count = gsub(/<\/div>/, "</div>", $0);
                depth += open_count - close_count;

                if (depth <= 0) {
                    in_block = 0;
                }
                next;
            }

            print;
        }
    ' "$html_file" >"$html_file.tmp" && mv "$html_file.tmp" "$html_file"

    rm -f "$replacement_file"
}

versions=("main")
for index_file in build/*/index.html; do
    [ -f "$index_file" ] || continue
    version_name="$(basename "$(dirname "$index_file")")"
    if [[ "$version_name" =~ ^[0-9]+\.[0-9]+$ ]]; then
        versions+=("$version_name")
    fi
done

if [[ "$BUILD_BRANCH" =~ ^[0-9]+\.[0-9]+$ ]]; then
    already_present=false
    for version in "${versions[@]}"; do
        if [ "$version" = "$BUILD_BRANCH" ]; then
            already_present=true
            break
        fi
    done

    if [ "$already_present" = false ]; then
        versions+=("$BUILD_BRANCH")
    fi
fi

replace_menu_block "build/index.html" "main" "${versions[@]}"

for index_file in build/*/index.html; do
    [ -f "$index_file" ] || continue
    version_name="$(basename "$(dirname "$index_file")")"
    if [[ "$version_name" =~ ^[0-9]+\.[0-9]+$ ]]; then
        replace_menu_block "$index_file" "$version_name" "${versions[@]}"
    fi
done
