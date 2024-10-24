#!/usr/bin/env bash

function set_version {
    local file_path="$1"
    local pattern_start="$2"
    local pattern_end="$3"
    local pattern_expression="$4"

    local sed_script_file_path="set_version.sed"

    # set up clean up of sed script file on exit
    trap "rm -f $sed_script_file_path" EXIT

    # create sed script file
    cat <<EOF > "$sed_script_file_path"
/${pattern_start}/,/${pattern_end}/{
    $pattern_expression
}
EOF
    if [[ $? -ne 0 ]]; then
        echo "Error: failed to create sed script file" >&2
        return 1
    fi

    # replace version in place
    sed -i -E -f "$sed_script_file_path" "$file_path"
    if [[ $? -ne 0 ]]; then
        echo "Error: failed to replace version in file '$file_path'" >&2
        return 1
    fi

    return 0
}

# check arguments
if [[ $# -ne 1 ]]; then
    echo "Error: invalid number of arguments" >&2
    echo "Usage: $0 <VERSION>"
    exit 1
fi

version="$1"
script_directory_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_directory_path=$(readlink -f "$script_directory_path")
xml_file_paths=(
    "$project_directory_path"/modules/openapi-generator-cli/pom.xml
    "$project_directory_path"/modules/openapi-generator-gradle-plugin/pom.xml
    "$project_directory_path"/modules/openapi-generator-core/pom.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/pom.xml
    "$project_directory_path"/modules/openapi-generator-online/pom.xml
    "$project_directory_path"/modules/openapi-generator/pom.xml
    "$project_directory_path"/modules/openapi-generator-gradle-plugin/gradle.properties
    "$project_directory_path"/modules/openapi-generator-gradle-plugin/samples/local-spec/gradle.properties
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/multi-module/java-client/pom.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/java-client.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/non-java-invalid-spec.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/non-java.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/kotlin.xml
    "$project_directory_path"/modules/openapi-generator-maven-plugin/examples/spring.xml
    "$project_directory_path"/pom.xml
)
property_file_paths=(
    "$project_directory_path"/modules/openapi-generator-gradle-plugin/gradle.properties
    "$project_directory_path"/modules/openapi-generator-gradle-plugin/samples/local-spec/gradle.properties
)

# set version in XML files
for file_path in ${xml_file_paths[@]}; do
    set_version \
        "$file_path" \
        "<!-- RELEASE_VERSION -->" \
        "<!-- \/RELEASE_VERSION -->" \
        "s/(<version>\s*)\S+(\s*<\/version>)/\1$version\2/g"
    if [[ $? -ne 0 ]]; then
        echo "Error: failed to set version in file '$file_path'" >&2
        exit 1
    fi
done

# set version in property files
for file_path in ${property_file_paths[@]}; do
    set_version \
        "$file_path" \
        "# RELEASE_VERSION" \
        "# \/RELEASE_VERSION" \
        "s/(openApiGeneratorVersion\s*=\s*)\S+$/\1$version/g"
    if [[ $? -ne 0 ]]; then
        echo "Error: failed to set version in file '$file_path'" >&2
        exit 1
    fi
done
