#!/usr/bin/env bash

# if bash version is less than 4.0, exit
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "Bash version must be 4.0 or higher"
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_directory> [--ignore <ignore_list>] [--single-file]"
    exit 1
fi

input_directory=$1
output_directory="${input_directory%/}-llm-dataset"
ignore_list=()
single_file=false

shift # Move past the input_directory argument

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --ignore)
            shift
            ignore_list=($@)
            break
            ;;
        --single-file)
            single_file=true
            ;;
        *)
            break
            ;;
    esac
    shift
done

# Declare associative array for file type associations
declare -A associations_dict=(
    ["c"]="C"
    ["cpp"]="cpp"
    ["cs"]="csharp"
    ["css"]="css"
    ["java"]="java"
    ["js"]="javascript"
    ["json"]="json"
    ["py"]="python"
    ["ts"]="typescript"
    ["html"]="html"
    ["xml"]="xml"
    ["sh"]="bash"
    ["ps1"]="powershell"
    ["tf"]="tf"
    ["tfstate"]="tf"
    ["tfvars"]="tf"
    ["yaml"]="yaml"
    ["yml"]="yaml"
)

# Function to convert file and add codeblock
convert_file() {
    local file=$1
    local base_name=$(basename "$file")
    local extension="${base_name##*.}"
    local language=${associations_dict["$extension"]}

    if [ -n "$language" ]; then
        if [ "$single_file" = true ]; then
            echo "Converting $file to single file..."
            echo -e "### File: $base_name\n\`\`\`$language" >> "$output_directory/converted.md"
            cat "$file" >> "$output_directory/converted.md"
            echo -e "\n\`\`\`\n" >> "$output_directory/converted.md"
        else
            local output_file="$output_directory/${base_name%.*}-converted.md"
            echo "Converting $file to $output_file..."
            echo -e "### File: $base_name\n\`\`\`$language" > "$output_file"
            cat "$file" >> "$output_file"
            echo -e "\n\`\`\`\n" >> "$output_file"
        fi
    else
        echo "Ignoring $file as no association found."
    fi
}

# Create output directory
mkdir -p "$output_directory"

# Initialize a single-file output if --single-file is set
if [ "$single_file" = true ]; then
    echo "### Combined Output" > "$output_directory/combined-output.md"
fi

# Iterate through files and directories
find "$input_directory" -type f -not -name ".*" | while read -r file; do
    relative_path="${file#$input_directory/}"

    # Check if file should be ignored
    if [[ " ${ignore_list[@]} " =~ " $relative_path " ]]; then
        echo "Ignoring $file"
    else
        convert_file "$file"
        # Append to the combined output file if --single-file is set
        if [ "$single_file" = true ]; then
            cat "$file" >> "$output_directory/combined-output.md"
            echo -e "\n\`\`\`\n" >> "$output_directory/combined-output.md"
        fi
    fi
done

echo "Conversion complete. Converted files stored in $output_directory"
