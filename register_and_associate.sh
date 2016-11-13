#!/bin/bash
declare -A versionCommands
declare -A checkersPresence
declare -A checkersType

path="./"

function checkOptions (){
  while getopts ":p:l:" option; do
    case $option in
      p)
        path=$OPTARG
        ;;
      l)
        parseCheckersInfo "$OPTARG"
        ;;
    esac
  done
  path=$path"*"
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

function associateFilesWithCheckers (){
  IFS=$(echo -en "\n\b")
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
  IFS=$' \t\n'
}

function initMaps (){
  versionCommands["verapdf"]="verapdf --version"
  checkersType["verapdf"]="application/pdf"
  versionCommands["mediaconch"]="mediaconch --version"
  checkersType["mediaconch"]="video/x-matroska,audio/x-matroska,video/webm,\
  audio/webm,audio/L16,audio/L8,audio/L20,audio/L24"
}

checkOptions "$@"
initMaps
checkPresence
associateFilesWithCheckers
