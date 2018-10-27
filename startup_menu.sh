#!/bin/bash
#
# start_menu.sh
# quick startup menu for doing compsci coursework stuff
#
# Copyright (c) 2018 ywei04 <Yichen Wei>
#
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

BACKTITLE="Welcom to startup guide"
COLORIZE=1


IFS='
'

i=0
s=65    # decimal ASCII "A"
continue=0

do_finish() {
    echo the folder you are last at is $PWD
    #unset i s continue result IFS RET files file
    exit 0
}

enter_folder() {
    #echo $1
    cd $1
}

compile_and_run() {
    echo clang++ -Wall -Wextra -std=c++11 $1
    if [[ COLORIZE==0 ]] ; then
        error_message=$(clang++ -Wall -Wextra -fcolor-diagnostics -std=c++11 $1 3>&1 1>&2 2>&3)
    else
        error_message=$(clang++ -Wall -Wextra -std=c++11 $1 3>&1 1>&2 2>&3)
    fi
    COMPILE_RET=$?
    echo "$error_message"
    echo "$error_message" | grep -q "warning"
    GREP_RET=$?
    if [[ "$RET" == 1 ]] ; then
        echo "Compile failed. Please Check the error messages!"
        read -p "Press enter to continue to the startup guide... "
    elif [[ "$GREP_RET" == 0 ]] ; then
        echo "Compiler warning observed. Please Check the error messages!"
        read -p "Do you still want to run the program? (y/N) " RUN_PROGRAM
        if [[ "$RUN_PROGRAM" = "y" ]] || [[ "$RUN_PROGRAM" = "Y" ]] ; then
            echo "----------Running the program...----------"
            ./a.out
            echo Process exited with status $?
            echo "------------------------------------------"
        fi
        read -p "Press enter to continue to the startup guide... "
    else
        echo "----------Running the program...----------"
        ./a.out
        echo Process exited with status $?
        echo "------------------------------------------"
        read -p "Press enter to continue to the startup guide... "
    fi
}

open_file() {
    file=$1
    result=$(whiptail --backtitle "$BACKTITLE" \
        --title "$PWD/$file" \
        --menu "Please select the thing you want to with $file:" 15 80 6 \
        --ok-button Select \
        --cancel-button Cancel \
        "0" " View the content of the file" \
        "1" " Open it up in your favorite editor" \
        "2" " Compile it and test it!" \
        "3" " Directly exec it! (not safe!)" \
        3>&1 1>&2 2>&3)
    if [[ $? == 0 ]] ; then
        case "$result" in
            0) less $file ;;
            1) $PREFERRED_EDITOR $file ;;
            2) compile_and_run $1 ;;
            3) 
                echo "----------Running the program...----------"
                ./$file
                echo Process exited with status $?
                echo "------------------------------------------"
                read -p "Press enter to continue to the startup guide... "
        esac || whiptail --msgbox "There was an error running option" 20 60 1
    fi
    unset result RET file
}

init_editor_preference() {
    result=$(whiptail --backtitle "$BACKTITLE" \
            --title "Select Options" \
            --ok-button Select \
            --cancel-button Cancel \
            --menu "Please select your favorite editor:" 15 80 6 \
            "0" " nano" \
            "1" " vim" \
            "2" " emacs" \
            3>&1 1>&2 2>&3)
    if [[ $? -eq 0 ]] ; then
        case "$result" in
            0)
                echo "PREFERRED_EDITOR=nano" > "$HOME/.guide_editor_preference" 
                PREFERRED_EDITOR=nano
                ;;
            1)
                echo "PREFERRED_EDITOR=vim" > "$HOME/.guide_editor_preference" 
                PREFERRED_EDITOR=vim
                ;;
            2)
                echo "PREFERRED_EDITOR=emacs" > "$HOME/.guide_editor_preference" 
                PREFERRED_EDITOR=emacs
                ;;
        esac
    fi
}

init_board() {
    if [ ! -f "$HOME/.guide_editor_preference" ] ; then
        init_editor_preference
    else
        source $HOME/.guide_editor_preference
    fi
    result=$(whiptail --backtitle "$BACKTITLE" \
        --title "Select Options" \
        --ok-button Select \
        --cancel-button Quit \
        --menu "Please select the thing you want to do:" 15 80 6 \
        "1" " Open up a folder" \
        "2" " Quit the guide and use the terminal directly" \
        "3" " Edit your editor perference" \
        3>&1 1>&2 2>&3)
    
    if [[ $? != 0 ]] ; then
        do_finish
    fi 

    case "$result" in
        1) ;;
        2) do_finish ;;
        3) 
            init_editor_preference
            init_board
            ;;
    esac || whiptail --msgbox "There was an error running option" 20 60 1
}


read -p "Press enter to continue to the startup guide... "

init_board

while (( "$continue" == 0 )) ; do
    i=0
    s=65
    if [[ "$PWD" != "$HOME" ]] ; then
        files[i]="A"
        files[i+1]=".."
        ((i+=2))
        ((s++))
    else
        files[i]="A"
        files[i+1]="Back to Main Menu"
        ((i+=2))
        ((s++))
    fi
    for f in `ls `;
    do
        extension="${f##*.}"
        if [[ $PWD == $HOME ]] ; then
            if [[ $f == comp* ]] ; then
                files[i]=$(echo -en "\0$(( $s / 64 * 100 + $s % 64 / 8 * 10 + $s % 8 ))")
                files[i+1]="$f"    # save file name
                ((i+=2))
                ((s++))
            fi
        else
            # convert to octal then ASCII character for selection tag
            files[i]=$(echo -en "\0$(( $s / 64 * 100 + $s % 64 / 8 * 10 + $s % 8 ))")
            files[i+1]="$f"    # save file name
            ((i+=2))
            ((s++))
        fi
    done
    
    result=$(whiptail --backtitle "$BACKTITLE" \
        --title "Simple File Browser" \
        --menu "Current folder: $PWD" 24 80 16 \
        --ok-button Select \
        --cancel-button Quit \
        "${files[@]}" \
        3>&1 1>&2 2>&3)
    if [[ $? != 0 ]] ; then
        do_finish
    fi

    if [[ "$result" == "A" ]] && [[ "$PWD" != "$HOME" ]] ; then
        enter_folder ".."
    elif [[ "$result" == "A" ]] ; then
        init_board
    else
        # echo "The result is:" $result
        ((index = 2 * ( $( printf "%d" "'$result" ) - 65 ) + 1 ))
        if [[ -d "${files[index]}" ]]; then
            enter_folder "${files[index]}"
        elif [[ -f "${files[index]}" ]]; then
            open_file "${files[index]}"
        else
            echo "file not valid"
            whiptail --msgbox "File not valid" 20 60 1
        fi
    fi
    unset files
done
unset i s continue result IFS

