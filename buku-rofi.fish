#!/usr/bin/env fish
# @SPREEKDOS/buku-rofi/buku-rofi.fish:v1.0.0
#TODO add tags searching
#TODO remember last prompt before switching between functions?
#TODO Copy URLs or titles to clipboard
#TODO use ai to generate tags when adding bookmark
#TODO strip trailing slash

# Function to display help
function display_help
    echo "Usage: $script_name [options]"
    echo "Options:"
    echo "  -d, --debug   Enable debug mode"
    echo "  -h, --help    Display this help message"
    echo "  -e, --export  Export bookmarks to a file"
    echo "  -i, --import  Import bookmarks from a file"
    echo ""
    echo "Features:"
    echo "  • Interactive bookmark search and open"
    echo "  • Add, edit, delete bookmarks"
    echo "  • Tag-based filtering (TODO)"
    echo "  • Clipboard support (TODO)"
    echo "  • Debug logging (enable with -d/--debug)"
    echo ""
    echo "Dependencies:"
    echo "  • buku"
    echo "  • rofi"
    echo "  • notify-send"
    echo "  • awk"
    exit 0
end

# Function to handle arguments
function handle_arguments
    argparse --name "$script_name" d/debug h/help e/export i/import -- $argv
    if set -q _flag_d
        set -g fish_trace 1
    end
    if set -q _flag_h
        display_help
    end
    if set -q _flag_e
        buku-export
    end
    if set -q _flag_i
        buku-import
    end
end

# Function to check if a command exists
function check_command
    for cmd in $argv
        if not command -s $cmd >/dev/null
            echo "$script_name: Command '$cmd' not found. To install it, use: sudo apt install $cmd"
            exit 1
        end
    end
end

# Function to initialize script settings
function init_script
    set -g script_name (status basename)
    set -g disable_defined_custom_keybind 'configuration { kb-custom-1 : "" ;
    kb-custom-2 : "" ; 
    kb-custom-3 : "" ; 
    kb-custom-4 : "" ; 
    kb-custom-5 : "" ; 
    kb-custom-6 : "" ;
    }'
    set -g matching_buku normal
    set -g auto_filter ""
end

# Function to export bookmarks to a file
function buku-export
    buku -e $export_file
    echo "$script_name: Bookmarks exported to $export_file"
end

# Function to import bookmarks from a file
function buku-import
    if test -f $import_file
        buku -i $import_file
        error_rofi "Bookmarks imported from $import_file"
    else
        error-rofi "$import_file not found."
    end
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
function rofi-dialog
    set -l entries $argv[1]
    set -l theme $argv[2]
    echo $entries | rofi -theme-str $theme 
end

# Function to dsiplay confirm dialog in rofi
function confirm-rofi
    set confirm_rofi_answer (rofi-dialog "Yes\nCancel" "$disable_defined_custom_keybind
    mainbox { children : [textbox-confirm, listview] ;}
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

# Function to dsiplay error dialog in rofi
function error-rofi
    set error_rofi_answer (rofi-dialog "Retry\nReturn" "$disable_defined_custom_keybind
    mainbox { 
    children : [ textbox-error, listview ] ;}
        textbox-error { content : \"$script_name | $argv[1] : \" ;}
        listview { layout :  horizontal ;
        spacing : 15 ;}")
    switch $error_rofi_answer
        case Retry
            $argv[2]
        case Return
            main
        case ''
            exit 1
    end
end

# Function to open a bookmark in the defualt browser
function open-buku
    buku --open $rofi_output[1]
end
# Function to add a bookmark
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

    set bookmark_url $(string replace ' ' '' $(command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Enter URL of the new bookmark" -format f -theme-str "$disable_defined_custom_keybind
    mainbox { children : [Inputbar] ;}
    entry { placeholder : 'URL' ; }"))
    if test -z "$bookmark_url"
        main
    end
    set bookmark_url "$(string replace --regex https?:// '' $bookmark_url)"
    set bookmark_url (string trim --right --chars='/' $bookmark_url)
    set second_prompt $(echo -e "Save\0permanent\x1ftrue\nAdd title\0permanent\x1ftrue" | command rofi -dmenu -format s\nf -replace -i -no-click-to-exit -theme buku-rofi.rasi -p "$script_name | Enter tags of the new bookmark" -theme-str "$disable_defined_custom_keybind
    mainbox { children : [Inputbar, listview] ;} entry { placeholder : 'tag1, tag2, tag3, ...' ; }
    listview { layout :  horizontal ;
        spacing : 15 ;}")
    set bookmark_tags "$second_prompt[2]"
    if test -z "$bookmark_tags"
        error-rofi "Tags field is empty" add-buku
    end
    switch $second_prompt[1]
        case 'Add title'
            set bookmark_title $(command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Enter title of the new bookmark" -format f -theme-str "$disable_defined_custom_keybind
            mainbox { children : [Inputbar] ;}
        entry { placeholder : 'Title' ; }")
    end
    if test -z "$bookmark_title"
        buku --add $bookmark_url --tag $bookmark_tags
    else
        buku --add $bookmark_url --tag $bookmark_tags --title $bookmark_title
    end
    or error-rofi "buku exited with error $status"
    and notify-send "$script_name: Added bookmark to buku" "Bookmark details
    URL : $bookmark_url
    tags : $bookmark_tags
    $(test -z "$bookmark_title"; and echo Title : $bookmark_title)"

end

# Function to delete a bookmark
function delete-buku
    if confirm-rofi "Ary you sure you want to delete : $rofi_output[2]"
        echo y | command buku --nostdin --np --nc --delete $rofi_output[1]
    end
end

# Function to edit an existing bookmark
function edit-buku
    set edited_bookmark $(echo -e "Save\0permanent\x1ftrue\nCancel\0permanent\x1ftrue" | command rofi -dmenu -replace -i -no-click-to-exit -theme "buku-rofi.rasi" -p "$script_name | Edit the bookmark" -format s\nf -filter "$rofi_output[2]" -theme-str "$disable_defined_custom_keybind
    mainbox { children : [Inputbar,listview] ;}
    entry { placeholder : 'New bookmark' ; }
    listview { layout : horizontal ;
    spacing : 15 ;}")
    switch $edited_bookmark[1]
        case Cancel ''
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
    and notify-send "$script_name: Edited bookmark in buku" "Bookmark new details
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
    set -g matching_buku $(echo normal\nregex\nglob\nfuzzy\nprefix | rofi -p "$script_name | Choose matching type" -theme-str "$disable_defined_custom_keybind
    mainbox { children : [Inputbar, listview] ;}
    Inputbar {children : [prompt, textbox-prompt-sep]; }
    listview { layout : horizontal ;
    spacing : 15 ;}")

end
function auto-filter
    set saved_tags "$(cat saved-tags)"
    set -g auto_filter $(echo -e "$(if test -n "$saved_tags" ; echo "$saved_tags\n" ; end)Save tags from search query\0permanent\x1ftrue" | rofi -p "$script_name | Auto-filter" -format s\nf -theme-str "$disable_defined_custom_keybind
        mainbox { children : [Inputbar, listview] ;}
        Inputbar { children : [prompt, textbox-prompt-sep, entry]; }")
    switch $auto_filter[1]
        case "Save tags to the list"
            if not contains "$auto_filter[2]" $(cat saved-tags)
                echo $auto_filter[2] >> saved-tags
            end
            set -g auto_filter[1] $auto_filter[2]
            set -ge auto_filter[2..]
    end
end

# Function to main loop
function main
    argparse --name $script_name h/help -- $argv
    while true
        if not set -q matching_buku
            set -g matching_buku normal
        end
        set bookmarks $(buku --format 4 --print | awk -F ' ' '{print "[ " $1 " ]   " $2 "   " $NF }')
        if not set -q hide_results
            set -g rofi_output $(echo -e "$(if test -n "$bookmarks" ; echo $bookmarks"\n" ; end )Add search query as bookmark\0permanent\x1ftrue" | rofi -p "$script_name" -format d\ns\nf -matching "$matching_buku" -filter "$auto_filter" -theme-str "textbox-matching { content : \"$matching_buku\" ;  }" )
        else
            set -g rofi_output $(echo -e "$(if test -n "$bookmarks" ; echo $bookmarks"\n" ; end)Add search query as bookmark\0permanent\x1ftrue" | rofi -format d\ns\nf -matching "$matching_buku" -filter "$auto_filter" -theme-str "$disable_defined_custom_keybind
            mainbox { children : [box-hint, Inputbar, box-hint2] ;}
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
                        open-buku
                        and return 0
                end
            case 1
                exit 0
            case 65
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
            case 15
                auto-filter
                main
        end
        if set -q auto_filter
            set -ge auto_filter
        end
    end
end
check_command buku rofi notify-send awk 
init_script $argv
handle_arguments $argv
main $argv

if set -q _flag_d
    set -e fish_trace
end
