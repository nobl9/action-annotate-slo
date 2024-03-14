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

while getopts ":p:l:s:a:" o; do
    case "${o}" in
        p)
            project=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            ;;
        l)
            labels=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            ;;
        s)
            slo=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            ;;
        a)
            annotation=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "${project}" ||  -z "${annotation}" ]]; then
    usage
fi

readonly ANNOTATION_NAME_MAX_LEN=60
readonly ANNOTATIONS_BATCH_SIZE=10

annotation_time=$(date -Iseconds)

batch_size=1
slos=$(get_slos "$project" "$labels" "$slo")
for slo_name in $slos;
do
  printf "Annotating %s.%s\n" $project $slo_name

  timestamp=$(date +%s)
  max_chars=$((ANNOTATION_NAME_MAX_LEN - ${#timestamp}))
  annotation_name=$(printf "%.${max_chars}s-%s" "$slo_name" "$timestamp")

  cat annotation.yaml.template >> annotations.yaml
  sed -i"" -e "s/\$ANNOTATION_NAME/$annotation_name/g" \
    -e "s/\$ANNOTATION_DESCRIPTION/$annotation/g" \
    -e "s/\$PROJECT/$project/g" \
    -e "s/\$SLO_NAME/$slo_name/g" \
    -e "s/\$ANNOTATION_TIME/$annotation_time/g" \
    -e "s/\$ANNOTATION_TIME/$annotation_time/g" \
    annotations.yaml

  if [ $((batch_size % ANNOTATIONS_BATCH_SIZE)) -eq 0 ]; then
    ./bin/sloctl apply --no-config-file -f annotations.yaml
    rm annotations.yaml
  fi

  batch_size=$((batch_size+1))
done

if [ $((batch_size % ANNOTATIONS_BATCH_SIZE)) -ne 0 ]; then
  ./bin/sloctl apply --no-config-file -f annotations.yaml
  rm -f annotations.yaml
fi
