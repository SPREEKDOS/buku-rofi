#!/usr/bin/env fish
# @SPREEKDOS/buku-rofi/buku-rofi.fish:v1.0.0
#TODO add tags searching
#TODO remember last prompt before switching between functions?
#set fish_trace 1

set -g script_name $(status basename)

if not which -s buku >/dev/null
    echo "$script_name: cant find buku, to install it use: sudo apt install buku"
    exit 1
end
if not which -s rofi >/dev/null
    echo "$script_name: cant find rofi, to install it use: sudo apt install rofi"
    exit 1
end
if not which -s notify-send >/dev/null
    echo "$script_name: cant find notify-send, to install it use: sudo apt install notify-send"
    exit 1
end
if not which -s awk >/dev/null
    echo "$script_name: cant find awk, to install it use: sudo apt install awk"
    exit 1
end

function buku
    command buku --nc --np $argv #--tacit 
end
function rofi
    command rofi -dmenu -replace -no-custom -i -no-click-to-exit -theme "buku-rofi.rasi" $argv
end
function notify-send
    command notify-send --app-name=$script_name --urgency=low --expire-time=2500 $argv
end
function confirm-rofi
    set confirm_rofi_answer $(echo Yes\nCancel | rofi -theme-str "mainbox { children : [textbox-confirm, listview] ;}
    textbox-confirm {content : \"$script_name | $argv \"; }
    listview { layout :  horizontal ;
        spacing : 15 ;}")

    switch $confirm_rofi_answer
        case Yes
            return 0
        case Cancel
            return 1
    end
end
function error-rofi
    set -l error_rofi_answer $(echo Retry\nReturn | rofi -theme-str "mainbox { 
    children : [ textbox-error, listview ] ;}
        textbox-error { content : \"$script_name | $argv[1] : \" ;}
        listview { layout :  horizontal ;
        spacing : 15 ;}")

    switch $error_rofi_answer
        case Retry
            $argv[2]
        case Return
            main
    end
    exit 1
end
function search-buku
    buku --open $rofi_output[1]
end
function add-buku
    if not test -z "$argv"
        set bookmark_url $(string replace ' ' '' $(string match --regex '^.*?\s+' "$argv" ))
        set bookmark_tags $(string match --regex '\s+?.*,+?\s\w+' "$argv")
        set bookmark_title $(string replace '^\s+' '' $(string replace "$bookmark_url$(string replace '^\s+' '' $bookmark_tags)" '' "$argv" ) )
        if test -z "$bookmark_title"
            buku --add $bookmark_url --tag $bookmark_tags
        else
            buku --add $bookmark_url --tag $bookmark_tags --title $bookmark_title
        end
        or error-rofi "buku exited with error $status"
        notify-send "$script_name: Added bookmark to buku" "Bookmark details
URL : $bookmark_url
Tags : $bookmark_tags
$(test -z "$bookmark_title"; and echo Title : $bookmark_title)"
        return 0
    end

    set bookmark_url $(string replace ' ' '' $(command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Enter URL of the new bookmark" -format f -theme-str "mainbox { children : [Inputbar] ;}
entry { placeholder : 'URL' ; }"))
    if test -z "$bookmark_url"
        main
    end
    set bookmark_url "$(string replace --regex https?:// '' $bookmark_url)"
    set second_prompt $(echo -e "Save\0permanent\x1ftrue\nAdd title\0permanent\x1ftrue" | command rofi -dmenu -format s\nf -replace -i -no-click-to-exit -theme buku-rofi.rasi -p "$script_name | Enter tags of the new bookmark" -theme-str "mainbox { children : [Inputbar, listview] ;} entry { placeholder : 'tag1, tag2, tag3, ...' ; }
listview { layout :  horizontal ;
        spacing : 15 ;}")
    set bookmark_tags "$second_prompt[2]"
    if test -z "$bookmark_tags"
        error-rofi "Tags field is empty" add-buku
    end
    switch $second_prompt[1]
        case 'Add title'
            set bookmark_title $(command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Enter title of the new bookmark" -format f -theme-str "mainbox { children : [Inputbar] ;}
        entry { placeholder : 'Title' ; }")
    end
    if test -z "$bookmark_title"
        buku --add $bookmark_url --tag $bookmark_tags
    else
        buku --add $bookmark_url --tag $bookmark_tags --title $bookmark_title
    end
    or error-rofi "buku exited with error $status"

    #    notify-send "$script_name: Added bookmark to buku" "Bookmark details
    #URL : $bookmark_url
    #tags : $bookmark_tags
    #$(test -z "$bookmark_title"; and echo Title : $bookmark_title)"

end

function delete-buku
    if confirm-rofi "Ary you sure you want to delete : $rofi_output[2]"
        echo y | command buku --nostdin --np --nc --delete $rofi_output[1]
    end
end
function edit-buku
    set edited_bookmark $(echo Save\nCancel | command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Edit the bookmark" -format s\nf -filter "$rofi_output[2]" -theme-str "mainbox { children : [Inputbar] ;}
entry { placeholder : 'New bookmark' ; }")
    switch edited_bookmark
        case Cancel
            main
        case ''
            main
    end
    set bookmark_url $(string replace ' ' '' $(string match --regex '^.*?\s+' "$edited_bookmark" ))
    set bookmark_tags $(string match --regex '\s+?.*,+?\s\w+' "$edited_bookmark")
    set bookmark_title $(string replace '^\s+' '' $(string replace "$bookmark_url$(string replace '^\s+' '' $bookmark_tags)" '' "$edited_bookmark" ) )
    if test -z "$bookmark_title"
        buku --update $bookmark_url --tag $bookmark_tags
    else
        buku --update $bookmark_url --tag $bookmark_tags --title $bookmark_title
    end
    or error-rofi "buku exited with error $status"
    notify-send "$script_name: Edited bookmark in buku" "Bookmark new details
URL : $bookmark_url
Tags : $bookmark_tags
$(test -z "$bookmark_title"; and echo Title : $bookmark_title)"
end
function hide_results
    if set -q hide_results
        set -e hide_results
    else
        set -g hide_results
    end
end
function matching-buku
    set -g matching_buku $(echo normal\nregex\nglob\nfuzzy\nprefix | rofi -p "Choose matching type" -theme-str "mainbox { children : [Inputbar, listview] ;}
Inputbar {children : [prompt, textbox-prompt-sep]; }
listview { layout : horizontal ;
spacing : 15 ;}")

end
function main
    argparse --name $script_name h/help -- $argv
    while true
        if not set -q matching_buku
            set -g matching_buku normal
        end
        if not set -q hide_results
            set -g rofi_output $(echo -e "$(buku --format 4 --print | awk -F ' ' '{print "[ " $1 " ]   " $2 "   " $NF }' )\nAdd search quary as bookmark\0permanent\x1ftrue" | rofi -p "$script_name" -format d\ns\nf -matching "$matching_buku" -theme-str "textbox-matching { content : \"$matching_buku\" ;  }")
        else
            set -g rofi_output $(echo -e "$(buku --format 4 --print | awk -F ' ' '{print "[ " $1 " ]   " $2 "   " $NF }' )\nAdd search quary as bookmark\0permanent\x1ftrue" | rofi -format d\ns\nf -matching "$matching_buku" -theme-str "mainbox { children : [box-hint, Inputbar, box-hint2] ; }
            box-hint2 { children : [textbox-hint-listview] ;
                orientation :  horizontal ;
                border : 1 0 0 0; }
            textbox-hint-listview { content : \"<span font_scale='subscript' > Result list is hidden use Alt+Q to unhide it      </span>\" ;
    horizontal-align : 1 ;
    markup : true ;}
            listview {enabled : false ;}
            textbox-matching {content : \"$matching_buku\" ;  }")
        end
        switch $status
            case 0
                switch $rofi_output[2]
                    case "Add search quary as bookmark"
                        add-buku "$rofi_output[3]"
                    case '*'
                        search-buku
                        and return 0
                end
            case 1
                exit 1
            case 10
                matching-buku
            case 11
                add-buku
            case 12
                delete-buku
            case 13
                edit-buku
            case 14
                hide_results
        end
    end
end

main $argv
#set -e fish_trace
