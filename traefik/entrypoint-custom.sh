#!/usr/bin/env sh
set -e

echo "Running custom entrypoint"

CA_CERTS_CONFIG_LOCATION=${CA_CERTS_CONFIG_LOCATION:-/config/ca-certs}
TEMPLATE_FILES_LOCATION=${TEMPLATE_FILES_LOCATION:-/config/templates}
TRAEFIK_CONFIG_LOCATION=${TRAEFIK_CONFIG_LOCATION:-/config/traefik}

# Check if required directories exist at the start
if [ ! -d "$CA_CERTS_CONFIG_LOCATION" ]; then
    echo "CA certs directory does not exist: $CA_CERTS_CONFIG_LOCATION" >&2
    exit 1
fi

if [ ! -d "$TEMPLATE_FILES_LOCATION" ]; then
    echo "Template files directory does not exist: $TEMPLATE_FILES_LOCATION" >&2
    exit 1
fi

mkdir -p $TRAEFIK_CONFIG_LOCATION

# Generates config according to template
generateConfig() {
    local template_file=$1

    if [ ! -f "$template_file" ]; then
        echo "Template file does not exist: $template_file" >&2
        return 1
    fi

    local cert_files=$(find "$CA_CERTS_CONFIG_LOCATION" -type f \( -name "*.pem" -o -name "*.crt" \))
    # Convert cert_files into a valid YAML list without trailing characters
    local cert_files_yaml_list="[]"
    if [ -z "$cert_files" ]; then
        echo "No certificate files found in $CA_CERTS_CONFIG_LOCATION" >&2
    else
        cert_files_yaml_list="[ $(echo "$cert_files" | awk '{printf "\"%s\", ", $0}' | sed 's/, $//') ]"
    fi

    local template_content=$(cat "$template_file")
    local replaced_content=${template_content//\$\{cert_files_yaml_list\}/$cert_files_yaml_list}
    echo "$replaced_content"
}

# Process all template files
template_files=$(find "$TEMPLATE_FILES_LOCATION" -type f -name "*.template" )

for template_file in $template_files; do
    echo "Processing template file: $template_file"
    generated_file_name=$(basename "$template_file" | sed 's/\.template$//')
    generated_file_path="$TRAEFIK_CONFIG_LOCATION/$generated_file_name"

    generated_config=$(generateConfig $template_file)

    echo "$generated_config" > $generated_file_path
    echo "Saved as $generated_file_path:"
    cat $generated_file_path
done

# Execute the original entrypoint
exec /entrypoint.sh "$@"
