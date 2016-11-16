#!/bin/bash
declare -A versionCommands
declare -A validationCommands
declare -A checkersPresence
declare -A checkersType
declare -A outputFolders
path="./"

function checkOptions (){
  while getopts ":p:l:o:" option; do
    case $option in
      p)
        path=$OPTARG
        ;;
      l)
        parseCheckersInfo "$OPTARG"
        ;;
      o)
        parseOutputFolders "$OPTARG"
      ;;
    esac
  done
  path=$path"*"
}

function parseOutputFolders {
  IFS=';'
  read -ra registeredCheckers <<< "$1"
  for checkerString in "${registeredCheckers[@]}"; do
    checkersName=$(echo ${checkerString%':'*} | xargs)
    outputFolders[$checkersName]=$(echo ${checkerString#*':'} | xargs)
    eval "mkdir -p ${outputFolders[$checkersName]}"
  done
  IFS=$' \t\n'
}

function parseCheckersInfo {
  IFS=';'
  read -ra registeredCheckers <<< "$1"
  for checkerString in "${registeredCheckers[@]}"; do
    trimmedString=${checkerString//[[:blank:]]/}
    checkersName=${trimmedString%':'*}
    checkersPresence[$checkersName]=true
    checkersType[$checkersName]=${trimmedString#*':'}
  done
  IFS=$' \t\n'
}

function checkPresence (){
  for key in "${!versionCommands[@]}";  do
    if ! (test "${checkersPresence[$key]+set}";) then
      commandString="${versionCommands[$key]}"
      output=$(eval $commandString)
      versionNumber="-1"
      isVersionNumberDefined=false
      while read -r line; do
        if [ "$isVersionNumberDefined" = false ]; then
          versionNumber=$(echo "$line" | grep -o -E '[0-9.]+')
          isVersionNumberDefined=true
        fi
      done <<<"$output"
      if [ ${#versionNumber} -gt 0 ]; then
          checkersPresence[$key]=true
      fi
    fi
  done
}

function updateValidationCommands (){
  for key in "${!outputFolders[@]}"; do
    tempString="${validationCommands[$key]%"'"*}"
    if [[ "${outputFolders[$key]}" = /* ]]; then
      validationCommands[$key]="${tempString%"'"*}'${outputFolders[$key]}/'"
    else
      validationCommands[$key]="${tempString%"'"*}'$PWD/${outputFolders[$key]}/'"
    fi
  done
}

function associateAndValidate (){
  IFS=$(echo -en "\n\b")
  for file in $(find $path -type f); do
      typeString=$(mimetype --output-format %m "$file")
      isCheckerDefined=false
      for key in "${!checkersType[@]}";  do
          checkersTypeString=${checkersType[$key]}
          if [[ "$checkersTypeString" = *"$typeString"* ]] \
          && [ "${checkersPresence[$key]}" = true ]; then
            echo $file": "$key
            if [[ "$file" = /* ]]; then
               output=$(eval "${validationCommands[$key]}'$file.xml' $file")
            else
               output=$(eval "${validationCommands[$key]}'$file.xml' '$PWD'/'$file'")
            fi
            <<<$output
            isCheckerDefined=true
          fi
      done
      if [ "$isCheckerDefined" = false ]; then
        echo $file": checker unassigned"
      fi
  done
  IFS=$' \t\n'
}

function initMaps (){
  versionCommands["verapdf"]="verapdf --version"
  validationCommands["verapdf"]="verapdf  --format xml \
   --reportfolder 'reports_verapdf/'"
  checkersType["verapdf"]="application/pdf"

  versionCommands["mediaconch"]="mediaconch --version"
  validationCommands["mediaconch"]="mediaconch --Format=xml -fx\
   --LogFile='reports_mediaconch/'"
  checkersType["mediaconch"]="video/x-matroska,audio/x-matroska,video/webm,\
  audio/webm"

  versionCommands["dpf-manager"]="dpf-manager --version"
  validationCommands["dpf-manager"]="dpf-manager check -c\
   '$PWD/configs/default.dpf' -o '$PWD/reports_dpf_manager/'"
  checkersType["dpf-manager"]="image/tiff,image/tiff-fx"
}

function manageTempFolders (){
  eval "rm -rf reports_verapdf/"
  eval "rm -rf reports_dpf_manager/"
  eval "rm -rf reports_mediaconch"
  eval "mkdir -p reports_mediaconch"
}

manageTempFolders
checkOptions "$@"
initMaps
updateValidationCommands
checkPresence
associateAndValidate
