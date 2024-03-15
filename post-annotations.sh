#!/bin/bash

cd "${0%/*}" || exit 1

err() { echo "$0 error: $*" >> /dev/stderr; exit 1; }
log() (set -x; "$@")
usage() { echo "Usage: $0 [-p project] [-l labels ] [-s slo ] [-a annotation]" >> /dev/stderr; exit 1; }
print_value_file() { printf "%s:\n\n" "${1}"; cat "${2}"; printf "\n"; }

get_slos() {
  local project=$1
  local labels=$2
  local slo=$3
  log ./bin/sloctl --no-config-file get slo -p "$project" ${labels:+-l "$labels"} ${slo:+"$slo"} | yq -r .[].metadata.name
}

generate_annotation_name() {
  readonly annotation_name_max_len=60
  local slo_name=$1
  timestamp=$(date +%s)
  max_chars=$((annotation_name_max_len - ${#timestamp}))
  annotation_name=$(printf "%.${max_chars}s-%s" "$slo_name" "$timestamp")
  echo "$annotation_name"
}

template() {
  local template_file=$1
  local output_file=$2
  local project=$3
  local slo_name=$4
  local annotation_description=$5
  annotation_time=$(date -Iseconds)
  annotation_name=$(generate_annotation_name "$slo_name")

  export project
  export slo_name
  export annotation_description
  export annotation_time
  export annotation_name

  cat "$template_file" >> "$output_file"
  yq ".[].metadata.name |= envsubst |
      .[].metadata.project |= envsubst |
      .[].spec.slo |= envsubst |
      .[].spec.description |= envsubst |
      .[].spec.startTime |= envsubst |
      .[].spec.endTime |= envsubst" -i "$output_file"
}

while getopts ":p:l:s:a:" o; do
    case "${o}" in
        p)
            [[ "${OPTARG}"  =~ ^[a-zA-Z0-9-]+$ ]]  \
            && project="${OPTARG}" \
            || err "Invalid project name: \"$OPTARG\". Must be alphanumeric with dashes allowed."
            ;;
        l)
            [[ "${OPTARG}"  =~ ^$|^[a-zA-Z0-9_-]+=([a-zA-Z0-9_-]+)(,{1}?[a-zA-Z0-9_-]+=([a-zA-Z0-9_-]+))*$ ]]  \
            && labels="${OPTARG}" \
            || err "Invalid labels: \"$OPTARG\". Must be comma-separated alphanumeric, with dashes and underscores allowed, in the format key=value,key2=value2. https://docs.nobl9.com/Features/Labels/#requirements-for-labels"
            ;;
        s)
            [[ "${OPTARG}"  =~ ^$|^[a-zA-Z0-9-]+$ ]]  \
            && slo="${OPTARG}" \
            || err "Invalid SLO name: \"$OPTARG\". Must be alphanumeric with dashes allowed."
            ;;
        a)
            annotation_description=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "${project}" ||  -z "${annotation_description}" ]]; then
    usage
fi

readonly batch_size=10
readonly manifest_file="annotations.yaml"

annotated_slos_count=1
slos=$(get_slos "$project" "$labels" "$slo")

for slo_name in $slos;
do
  printf "Annotating %s.%s\n" $project $slo_name

  template "annotation.yaml.template" $manifest_file "$project" "$slo_name" "$annotation_description"

  if [ $((annotated_slos_count % batch_size)) -eq 0 ]; then
    ./bin/sloctl apply --no-config-file -f $manifest_file
    rm $manifest_file
  fi

  annotated_slos_count=$((annotated_slos_count+1))
done

if [ $((annotated_slos_count % batch_size)) -ne 0 ]; then
  ./bin/sloctl apply --no-config-file -f $manifest_file
  rm -f $manifest_file
fi

printf "Annotated %s SLOs\n" $((annotated_slos_count-1))