#!/bin/bash
path=$1
if ! [[ -n "$path" ]]; then
  path="./"
fi
path=$path"*"

declare -A versionCommands
declare -A checkersPresence
declare -A checkersType

versionCommands["verapdf"]="verapdf --version"
checkersType["verapdf"]="application/pdf"

for key in "${!versionCommands[@]}";  do
  commandString="${versionCommands[$key]}"
  output=$(eval $commandString)
  versionNumber="-1"
  isVersionNumberDefined=false
  while read -r line; do
    if [ "$isVersionNumberDefined" = false ]; then
      versionNumber=${line#*' '}
      isVersionNumberDefined=true
    fi
  done <<<"$output"
  if [ ${#versionNumber}-gt0 ]; then
    if [[ $versionNumber =~ ^[0-9.]+$ ]]; then
      checkersPresence[$key]=true
    fi
  fi
done

for file in $(find $path -type f); do
    typeString=$(mimetype --output-format %m "$file")
    isCheckerDefined=false
    for key in "${!checkersType[@]}";  do
        checkersTypeString=${checkersType[$key]}
        if [[ "$checkersTypeString" = *"$typeString"* ]] && [ "${checkersPresence[$key]}" = true ]; then
          echo $file": "$key
          isCheckerDefined=true
        fi
    done
    if [ "$isCheckerDefined" = false ]; then
      echo $file": checker unassigned"
    fi
done
