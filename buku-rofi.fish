#!/usr/bin/env fish
# @SPREEKDOS/buku-rofi/buku-rofi.fish:v1.0.0
# TODO: use AI to generate tags when adding bookmark
# TODO: auto complete tags to make them consistent
# TODO: order the indices using --order requires buku v5.0
# TODO: add search engine tabs?
# NOTPLANNED: use --normal-window but without the position getting ruined by smart placement
# TODO: generate title using edit
# Display usage and help information.
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
    echo "  • Search Tags"
    echo "  • Clipboard support"
    echo "  • Debug logging (enable with -d/--debug)"
    echo ""
    echo "Dependencies:"
    echo "  • fish"
    echo "  • buku"
    echo "  • rofi"
    echo "  • notify-send"
    echo "  • awk"
    echo ""
    echo "Portability:"
    echo "  • Tested on Fish 3.x and 2.7.x. Some features may not work on older Fish versions."
    echo ""
    echo "For bug reports or feature requests, please open an issue on GitHub."
    exit 0
end

# Handle command-line arguments and flags.
function handle_arguments --description "Parse and act on CLI flags."
    argparse --name "$script_name" d/debug h/help e/export i/import -- $argv
    if set -q _flag_d
        set -g fish_trace 1
    end
    if set -q _flag_h
        display_help
    end
    if set -q _flag_e
        buku_export
    end
    if set -q _flag_i
        buku_import
    end
end

# Check that required external commands are available.
function check_command --description "Ensure all required external commands are present."
    set missing_cmds
    for cmd in $argv
        if not command -s $cmd >/dev/null
            set missing_cmds $missing_cmds $cmd
        end
    end
    if set -q missing_cmds[1]
        echo "$script_name: The following required commands are missing: $missing_cmds"
        # Try to suggest install commands based on OS
        if test -f /etc/os-release
            set os_id (grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
            switch $os_id
                case ubuntu debian linuxmint
                    echo "To install, run: sudo apt install $missing_cmds"
                case arch artix
                    echo "To install, run: sudo pacman -S $missing_cmds"
                case fedora rhel centosy
                    echo "To install, run: sudo dnf install $missing_cmds"
                case opensuse
                    echo "To install, run: sudo zypper install $missing_cmds"
                case '*'
                    echo "Please install the required commands using your package manager."
            end
        else
            echo "Please install the required commands using your system's package manager."
        end
        exit 1
    end
    # Fish version check for portability
    set min_version 2.7.0
    set current_version (fish --version | string match -r '\d+\.\d+\.\d+')
    set versions $min_version\n$current_version
    set sorted (printf "%s\n" $versions | sort -V | head -n1)

    if test "$sorted" != "$min_version"
        echo "Your Fish version ($current_version) is older than required ($min_version)."
        exit 1
    end
end

# Initialize script-level settings and variables.
function init_script --description "Initialize script name and UI variables."
    cd (status dirname)
    set -g script_name (status basename)
    set -g simple_theme 'configuration { kb-custom-1 : "" ;
    kb-custom-2 : "" ;
    kb-custom-3 : "" ;
    kb-custom-4 : "" ;
    kb-custom-5 : "" ;
    kb-custom-6 : "" ;
    }
    mainbox { children : [Inputbar, listview] ;}
    Inputbar {children : [prompt, textbox-prompt-sep, entry]; }'
    set -g matching_buku normal
end

# Export bookmarks to a file using buku.
function buku_export --description "Export bookmarks to a file."
    if not set -q export_file
        set export_file "$HOME/buku-rofi_export.md"
    end
    buku -e $export_file
    echo "$script_name: Bookmarks exported to $export_file"
end

# Import bookmarks from a file using buku.
function buku_import --description "Import bookmarks from a file."
    if not set -q import_file
        set import_file "$HOME/buku-rofi_export.md"
    end
    if test -f $import_file
        echo n\ny | command buku --nostdin --np --nc -i $import_file
        echo "$script_name: Bookmarks imported from $import_file"
        exit 0 # needs to restart to work correctly
    else
        echo "$script_name: $import_file not found."
    end
end

# Wrapper for buku CLI.
function buku --description "Call buku CLI with common flags."
    command buku --nostdin --nc --np --tacit $argv
end

# Wrapper for rofi CLI.
function rofi --description "Call rofi with default options and theme."
    command rofi -dmenu -replace -no-custom -i -no-click-to-exit -theme "buku-rofi.rasi" -format d\ns\nf $argv
end

# Wrapper for notify-send CLI.
function notify_send --description "Send a desktop notification."
    command notify-send --app-name=$script_name --urgency=low --expire-time=2500 $argv
end

# Open a rofi dialog with given entries and theme.
function rofi_dialog --description "Show a rofi dialog with entries and theme."
    set -l prompt $argv[1]
    set -l entries $argv[2]
    set -l theme_str $argv[3]
    echo -e $entries | rofi -p $prompt -theme-str "$simple_theme" -theme-str $theme_str $argv[4..]
end

# Display a confirmation dialog in rofi.
function confirm_rofi --description "Confirm an action with the user."
    set confirm_rofi_answer (rofi_dialog "$script_name | $argv[1]" "Yes\nCancel" "
        Inputbar {children : [prompt]; }")
    switch $confirm_rofi_answer[2]
        case Yes
            return 0
        case Cancel
            return 1
    end
end

# Display an error dialog in rofi, and handle retry/return.
function error_rofi --description "Show error dialog with Retry/Return options."
    set error_rofi_answer (rofi_dialog "$script_name | $argv[1]" "Retry\nReturn" "        Inputbar {children : [prompt]; }")
    switch $error_rofi_answer[2]
        case Retry
            $argv[2]
        case Return
            main
        case ''
            exit 1
    end
end

# Open a bookmark in the default browser via buku.
function open_buku --description "Open the selected bookmark."
    buku --open $rofi_output[1]
end

# Add a bookmark via buku, with optional tags and title.
function add_buku --description "Add a new bookmark with buku."
    if test -n "$argv"
        set bookmark_url (string replace ' ' '' (string match --regex '^.*?\s+' "$argv"))
        set bookmark_tags (string match --regex '\s+?.*,+?\s\w+' "$argv")
        set bookmark_title (string replace '^\s+' '' (string replace "$bookmark_url"(string replace '^\s+' '' $bookmark_tags) '' "$argv"))
    else
        set save_or_add_tags_prompt (string trim (rofi_dialog "$script_name | Enter URL of the new bookmark" "Add tags\0permanent\x1ftrue\nSave\0permanent\x1ftrue" "entry { placeholder : 'URL' ; }"))
        set bookmark_url "$save_or_add_tags_prompt[3]"
        if test -z "$bookmark_url"
            error_rofi "URL field is empty" add_buku
        end
        switch $save_or_add_tags_prompt[2]
            case 'Add tags'
                set save_or_add_title_prompt (rofi_dialog "$script_name | Enter tags for the new bookmark" "Add title\0permanent\x1ftrue\nSave\0permanent\x1ftrue" "entry { placeholder : 'tag1, tag2, tag3, ...' ; }")
                set bookmark_tags "$save_or_add_title_prompt[3]"
                if test -z "$bookmark_tags"
                    error_rofi "Tags field is empty" add_buku
                end
                switch $save_or_add_title_prompt[2]
                    case 'Add title'
                        set bookmark_title (rofi_dialog "$script_name | Enter title of the new bookmark" "Save\0permanent\x1ftrue" "entry { placeholder : 'Title' ; }")
                        if test -z "$bookmark_title"
                            error_rofi "Title field is empty" add_buku
                        end
                end
        end
    end

    set bookmark_url (string replace --regex https?:// '' $bookmark_url)
    set bookmark_url (string trim --right --chars='/' $bookmark_url)
    set bookmark_url (string replace --regex www. '' $bookmark_url)
    if test -n "$bookmark_url" -a -z "$bookmark_tags" -a -z "$bookmark_title"
        buku --add $bookmark_url
        or error_rofi "buku exited with error $status"
        and notify_send "$script_name: Added bookmark to buku" "Bookmark details
URL : $bookmark_url"
    else if test -n "$bookmark_url" -a -n "$bookmark_tags" -a -z "$bookmark_title"
        buku --add $bookmark_url --tag $bookmark_tags
        or error_rofi "buku exited with error $status"
        and notify_send "$script_name: Added bookmark to buku" "Bookmark details
URL : $bookmark_url
Tags : $bookmark_tags"
    else if test -n "$bookmark_url" -a -n "$bookmark_tags" -a -n "$bookmark_title"
        buku --add $bookmark_url --tag $bookmark_tags --title $bookmark_title
        or error_rofi "buku exited with error $status"
        and notify_send "$script_name: Added bookmark to buku" "Bookmark details
URL : $bookmark_url
Tags : $bookmark_tags
Title : $bookmark_title"
    end
end

# Delete a bookmark using buku, with confirmation dialog.
function delete_buku --description "Delete the selected bookmark."
    if confirm_rofi "Are you sure you want to delete : $rofi_output[2]"
        echo y | command buku --nostdin --np --nc --delete "$rofi_output[1]" # quotation is neccessary to avoid deleting all bookmarks
    end
end

# Edit an existing bookmark via buku and rofi.
function edit_buku --description "Edit the selected bookmark."
    set old_bookmark $(buku --format 20 --print $rofi_output[1] | string split \t )
    set old_bookmark_url "$old_bookmark[1]"
    set old_bookmark_tags "$old_bookmark[2]"
    set old_bookmark_title $(buku --format 30 --print $rofi_output[1])
    if test -n $old_bookmark_title
        set old_bookmark_title "( $old_bookmark_title )"
    end

    set edited_bookmark (rofi_dialog "$script_name | Edit the bookmark" "Save\0permanent\x1ftrue\nCancel\0permanent\x1ftrue" "entry { placeholder : 'New bookmark' ; }" -filter "$old_bookmark_url $old_bookmark_tags $old_bookmark_title")
    switch $edited_bookmark[2]
        case Cancel ''
            main
    end
    set new_bookmark_url (string split -f 1 ' ' $edited_bookmark[3])
    set new_bookmark_tags (string split -f 2 ' ' $edited_bookmark[3])
    if string match '(' $new_bookmark_tags
        set -e new_bookmark_tags
    end
    set new_bookmark_title (string match -r "\(.*\)"  $edited_bookmark[3] | string replace '( ' '' | string replace ' )' '')
    if test -z $new_bookmark_title
        set -e new_bookmark_title
    end

    if test -n "$new_bookmark_url"
    buku --update $rofi_output[1] --url $new_bookmark_url --tag $new_bookmark_tags --title $new_bookmark_title
        or error_rofi "buku exited with error $status"
        and notify_send "$script_name: Edited bookmark in buku" "Bookmark new details
index: $rofi_output[1]
URL : $new_bookmark_url
Tags : $new_bookmark_tags
Title : $new_bookmark_title"
    else
        error_rofi "Input is mulformed"
    end
end

# Toggle hiding the result list in rofi UI.
function hide_results --description "Toggle the result list display in UI."
    if set -q hide_results
        set -e hide_results
    else
        set -g hide_results "mainbox { children : [box-hint, Inputbar, box-hint2] ;}
            box-hint2 { children : [textbox-hint-listview] ;
                orientation :  horizontal ;
                border : 1 0 0 0; }
            textbox-hint-listview { content : \"<span font_scale='subscript' > Result list is hidden use Alt+Q to unhide it      </span>\" ;
                horizontal-align : 1 ;
                markup : true ;
                color : Red ;}
            listview {enabled : false ;}"
    end
end

# Select matching strategy for rofi search.
function matching_buku --description "Select a bookmark search matching strategy."
    set -g matching_buku (rofi_dialog "$script_name | Choose matching type" "normal\nregex\nglob\nfuzzy\nprefix" "$simple_theme
        Inputbar {children : [prompt]; }
        listview { layout :  horizontal ; spacing : 15 ;}")
    set -g matching_buku[1] $matching_buku[2]
    set -ge matching_buku[2..]
    echo $matching_buku
end

# For auto-filtering tags in search.
function auto_filter --description "Auto-filter tags in search."
    set saved_tags (cat saved-tags)
    set -g auto_filter (rofi_dialog "$script_name | Auto filter" (test -n "$saved_tags" ; and echo $saved_tags"\n")"Save tags from search query\0permanent\x1ftrue" "entry { placeholder : 'Tag' ; }
    listview { layout :  horizontal ; spacing : 15 ;} ")
    switch $auto_filter[2]
        case "Save tags to the list"
            if not contains "$auto_filter[3]" (cat saved-tags)
                echo $auto_filter[3] >>saved-tags
            end
            set -g auto_filter[2] $auto_filter[3]
    end
    if test -n "$auto_filter[2]"
        set -ge previous_filter
        set -g filter $auto_filter[3]
    end
end

# Copy the bookmark URL to the clipboard.
function copy_url --description "Copy the bookmark URL to clipboard."
    set bookmark_url (echo $rofi_output[2] | string trim | string split -f 4 --no-empty ' ')
    echo $bookmark_url | fish_clipboard_copy
end

# Search for tags using buku and rofi.
function search_tags --description "Search for tags and copy to clipboard."
    set -g search_tags "$(buku --stag | awk '{print $2}')"
    set -g search_tags $(rofi_dialog "$script_name | Search tags" "$search_tags" "entry { placeholder : 'Tag' ; }
        listview { layout :  horizontal ; spacing : 15 ;} ")

    if test -n "$search_tags[2]"
        set -ge previous_filter
        set -g filter $search_tags[2]
    end
end

# Main loop and UI of the bookmark manager.
function main --description "Main UI loop for the bookmark manager."
    while true
        if test -z "$auto_filter" -a -z "$search_tags"
            set -g previous_filter $rofi_output[3]
            set -g filter $previous_filter
        end
        set bookmarks (buku --format 2  --print | awk -F ' ' '{print " [ " $1 " ]      " $2 "      " $3 "      " }'  | paste - $(buku --format 30  --print | string replace -ra "^\b" "\( " | string replace -ra "\b\$" " \)" | psub))

        set -g rofi_output (echo -e (test -n "$bookmarks" ; and echo $bookmarks"\n")"Add search query as bookmark\0permanent\x1ftrue" | rofi -p "$script_name" -matching "$matching_buku" -filter "$filter" -theme-str "
        $hide_results
        textbox-matching {content : \"$matching_buku\" ;  }")
        switch $status
            case 0
                switch $rofi_output[2]
                    case "Add search query as bookmark"
                        add_buku "$rofi_output[3]"
                    case '*'
                        open_buku
                        and return 0
                end
            case 1
                exit 0
            case 65
                exit 1
            case 10
                matching_buku
            case 11
                add_buku
            case 12
                delete_buku
            case 13
                edit_buku
            case 14
                hide_results
            case 15
                auto_filter
                main
            case 16
                copy_url
            case 17
                search_tags
        end
        if set -q auto_filter -o -q search_tags
            set -ge auto_filter
            set -ge search_tags
        end
    end
end

# --- Script entrypoint ---
init_script $argv
handle_arguments $argv
check_command buku rofi notify-send awk
main $argv

if set -q _flag_d
    set -e fish_trace
end
