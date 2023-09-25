useColor="true" # Set to false if you find your environment just doesn't handle colors well

# Returns a color code for the given foreground/background colors
# This code is echoed to the terminal before outputting text in
# order to generate a colored output.
#
# string foreground color name. Optional if no background provided.
#        Defaults to "Default" which uses the system default
# string background color name.  Optional. Defaults to $color_background
#        which is set based on the current terminal background
# returns a string
function Color () {

    local foreground=$1
    local background=$2

    if [ "$foreground" == "" ];  then foreground="Default"; fi
    if [ "$background" == "" ]; then background="$color_background"; fi

    local colorString='\033['

    # Foreground Colours
    case "$foreground" in
        "Default")      colorString='\033[0;39m';;
        "Black" )       colorString='\033[0;30m';;
        "DarkRed" )     colorString='\033[0;31m';;
        "DarkGreen" )   colorString='\033[0;32m';;
        "DarkYellow" )  colorString='\033[0;33m';;
        "DarkBlue" )    colorString='\033[0;34m';;
        "DarkMagenta" ) colorString='\033[0;35m';;
        "DarkCyan" )    colorString='\033[0;36m';;
        "Gray" )        colorString='\033[0;37m';;
        "DarkGray" )    colorString='\033[1;90m';;
        "Red" )         colorString='\033[1;91m';;
        "Green" )       colorString='\033[1;92m';;
        "Yellow" )      colorString='\033[1;93m';;
        "Blue" )        colorString='\033[1;94m';;
        "Magenta" )     colorString='\033[1;95m';;
        "Cyan" )        colorString='\033[1;96m';;
        "White" )       colorString='\033[1;97m';;
        *)              colorString='\033[0;39m';;
    esac

    # Background Colours
    case "$background" in
        "Default" )     colorString="${colorString}\033[49m";;
        "Black" )       colorString="${colorString}\033[40m";;
        "DarkRed" )     colorString="${colorString}\033[41m";;
        "DarkGreen" )   colorString="${colorString}\033[42m";;
        "DarkYellow" )  colorString="${colorString}\033[43m";;
        "DarkBlue" )    colorString="${colorString}\033[44m";;
        "DarkMagenta" ) colorString="${colorString}\033[45m";;
        "DarkCyan" )    colorString="${colorString}\033[46m";;
        "Gray" )        colorString="${colorString}\033[47m";;
        "DarkGray" )    colorString="${colorString}\033[100m";;
        "Red" )         colorString="${colorString}\033[101m";;
        "Green" )       colorString="${colorString}\033[102m";;
        "Yellow" )      colorString="${colorString}\033[103m";;
        "Blue" )        colorString="${colorString}\033[104m";;
        "Magenta" )     colorString="${colorString}\033[105m";;
        "Cyan" )        colorString="${colorString}\033[106m";;
        "White" )       colorString="${colorString}\033[107m";;
        *)              colorString="${colorString}\033[49m";;
    esac

    echo "${colorString}"
}


# Outputs a line, including linefeed, to the terminal using the given foreground / background
# colors 
#
# string The text to output. Optional if no foreground provided. Default is just a line feed.
# string Foreground color name. Optional if no background provided. Defaults to "Default" which
#        uses the system default
# string Background color name.  Optional. Defaults to $color_background which is set based on the
#        current terminal background
function WriteLine () {

    local resetColor='\033[0m'

    local str=$1
    local forecolor=$2
    local backcolor=$3

    if [ "$str" == "" ]; then
        printf "\n"
        return;
    fi

    # Note the use of the format placeholder %s. This allows us to pass "--" as strings without error
    if [ "$useColor" == "true" ]; then
        local colorString=$(Color ${forecolor} ${backcolor})
        printf "${colorString}%s${resetColor}\n" "${str}"
    else
        printf "%s\n" "${str}"
    fi
}

# Outputs a line without a linefeed to the terminal using the given foreground / background colors 
#
# string The text to output. Optional if no foreground provided. Default is just a line feed.
# string Foreground color name. Optional if no background provided. Defaults to "Default" which
#        uses the system default
# string Background color name.  Optional. Defaults to $color_background which is set based on the
#        current terminal background
function Write () {
    local resetColor="\033[0m"

    local forecolor=$1
    local backcolor=$2
    local str=$3

    if [ "$str" == "" ];  then
        return;
    fi

    # Note the use of the format placeholder %s. This allows us to pass "--" as strings without error
    if [ "$useColor" == "true" ]; then
        local colorString=$(Color ${forecolor} ${backcolor})
        printf "${colorString}%s${resetColor}" "${str}"
    else
        printf "%s" "$str"
    fi
}
