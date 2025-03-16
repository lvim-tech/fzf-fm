#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/fn.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/actions.sh"

FZF_PREVIEW_COLUMNS=$(($(tput cols) / 2)) # half of the terminal width
FZF_PREVIEW_LINES=$(tput lines)           # full height
_KITTEN_ICAT_PLACE=${FZF_PREVIEW_COLUMNS:-64}x${FZF_PREVIEW_LINES}@${FZF_PREVIEW_COLUMNS:-64}x0

echo "$PWD" >"$LVIM_FM_WORKING_DIR/base-directory"

if [[ -f $LVIM_FM_WORKING_DIR/pwd ]]; then
    builtin cd "$(cat "$LVIM_FM_WORKING_DIR/pwd")" || return
fi

if [[ ! -f "$LVIM_FM_WORKING_DIR/action" ]]; then
    echo "menu" >"$LVIM_FM_WORKING_DIR/action"
fi

if [[ ! -f "$LVIM_FM_WORKING_DIR/mode" ]]; then
    echo "SELECT" >"$LVIM_FM_WORKING_DIR/mode"
fi

while :; do
    if [[ -f "$LVIM_FM_WORKING_DIR/quit" ]]; then
        rm "$LVIM_FM_WORKING_DIR/quit"
        break
    fi

    action=$(cat "$LVIM_FM_WORKING_DIR/action")
    mode=" [$(cat "$LVIM_FM_WORKING_DIR/mode")] "
    separator=("--separator=")
    header=("--header=")
    info=("--inline-info")
    no_border=("--no-border")
    border=("--border=none")
    pointer=("--pointer=$ICON_POINTER")
    marker=("--marker=$ICON_MARKER")
    multi=("-m")
    sort=("-s")
    tac=()
    delimiter=()
    long_info=""
    show_hidden_files=""
    preview_window_hidden=()
    preview_window=("--preview-window=right:50%:noborder")
    on_change="--bind=change:top"
    reload=()
    preview_window_for_search_in_files=()
    enter=("--bind=enter:accept+execute(echo {q} >/tmp/lvim-shell-query)")
    bind_base=(
        "--bind=$KEY_QUIT:clear-selection+execute-silent(
            touch $LVIM_FM_WORKING_DIR/quit
        )+abort"

        "--bind=$KEY_CLEAR_QUERY:clear-selection+clear-query"

        "--bind=$KEY_PREVIEW_DOWN:preview-down"

        "--bind=$KEY_PREVIEW_UP:preview-up"

        "--bind=$KEY_PREVIEW_HALF_PAGE_DOWN:preview-half-page-down"

        "--bind=$KEY_PREVIEW_HALF_PAGE_UP:preview-half-page-up"

        "--bind=$KEY_OPEN:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo {} > $LVIM_FM_WORKING_DIR/current_selection \
        )+top+accept"

        "--bind=$KEY_TOGGLE_PREVIEW:toggle-preview+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            [ ! -f $LVIM_FM_WORKING_DIR/hidden-preview ] \
            && touch $LVIM_FM_WORKING_DIR/hidden-preview \
            || rm $LVIM_FM_WORKING_DIR/hidden-preview \
        )"

        "--bind=$KEY_TOGGLE_HELP:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            [ ! -f $LVIM_FM_WORKING_DIR/show-help ] \
            && touch $LVIM_FM_WORKING_DIR/show-help \
            || rm $LVIM_FM_WORKING_DIR/show-help \
        )+accept"

        "--bind=$KEY_SAVE_CURRENT_PATH:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo $PWD > $LVIM_FM_WORKING_DIR/pwd \
        )+top+accept"

        "--bind=$KEY_DELETE_CURRENT_PATH:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            touch $LVIM_FM_WORKING_DIR/reload && \
            rm $LVIM_FM_WORKING_DIR/pwd \
        )+top+accept"

        "--bind=$KEY_MENU:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo menu > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_EXPLORER:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo explorer > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_SEARCH_DIRECTORIES_AND_FILES:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo search-directories-and-files > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_SEARCH_DIRECTORIES:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo search-directories > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_SEARCH_FILES:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo search-files > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_SEARCH_IN_FILES:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo search-in-files > $LVIM_FM_WORKING_DIR/action \
        )+top+accept"

        "--bind=$KEY_TOGGLE_HIDDEN_FILES:clear-selection+execute-silent(\
            touch $LVIM_FM_WORKING_DIR/prevent && \
            [ ! -f $LVIM_FM_WORKING_DIR/hidden-files ] \
            && touch $LVIM_FM_WORKING_DIR/hidden-files \
            || rm $LVIM_FM_WORKING_DIR/hidden-files \
        )+top+accept"

        "--bind=$KEY_LONG_PATH:clear-selection+execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            [ ! -f $LVIM_FM_WORKING_DIR/long-info ] \
            && touch $LVIM_FM_WORKING_DIR/long-info \
            || rm $LVIM_FM_WORKING_DIR/long-info \
        )+top+accept"
        # "--bind=$KEY_EXECUTE:execute( \
        #           ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'PASTE/COPY' ] \
        #           && echo 'EXECUTE/PASTE/COPY' >$LVIM_FM_WORKING_DIR/mode) \
        #           || ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'PASTE/CUT' ] \
        #           && echo 'EXECUTE/PASTE/CUT' >$LVIM_FM_WORKING_DIR/mode) \
        #       )+top+accept"
        #
        # "--bind=$KEY_COPY:execute( \
        #           ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'PASTE/COPY' ] \
        #           && (echo 'SELECT' >$LVIM_FM_WORKING_DIR/mode \
        #           && cat /dev/null > $LVIM_FM_WORKING_DIR/mode-items)) \
        #           || ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'SELECT' ] \
        #           && echo 'COPY' >$LVIM_FM_WORKING_DIR/mode) \
        #       )+top+accept"
        #
        # "--bind=$KEY_CUT:execute( \
        #           ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'PASTE/CUT' ] \
        #           && (echo 'SELECT' >$LVIM_FM_WORKING_DIR/mode \
        #           && cat /dev/null > $LVIM_FM_WORKING_DIR/mode-items)) \
        #           || ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'SELECT' ] \
        #           && echo 'CUT' >$LVIM_FM_WORKING_DIR/mode) \
        #       )+top+accept"
        #
        # "--bind=$KEY_DELETE:execute( \
        #           ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'SELECT' ] \
        #           && echo 'DELETE' >$LVIM_FM_WORKING_DIR/mode) \
        #       )+top+accept"
    )
    bind_app=()
    if [[ -f $LVIM_FM_WORKING_DIR/hidden-preview ]]; then
        preview_window_hidden=("--preview-window=:hidden")
    fi
    if [[ -f $LVIM_FM_WORKING_DIR/hidden-files ]]; then
        show_hidden_files="--all"
    fi
    if [[ -f $LVIM_FM_WORKING_DIR/long-info ]]; then
        long_info="--long"
    fi
    preview_engine=("--preview=
    FILE={..}
    # Check and remove extended data from eza output if present
    CLEAN_FILE=\$(echo \"\$FILE\" | sed -E 's/^[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +//')
    if [[ -n \$CLEAN_FILE ]]; then
        FILE=\$CLEAN_FILE
    fi
    FIRST_CHAR=\$(echo -n \"\$FILE\" | cut -c1)
    CODEPOINT=\$(printf \"%d\" \"'\$FIRST_CHAR'\")
    if (( CODEPOINT >= 57344 && CODEPOINT <= 63743 )); then
        FILE=\${FILE:2}
    fi
    echo \"Previewing file: \$FILE\" >&2
    echo \"Previewing file: \$FILE\" >> ~/logfile.log
    sleep 0.1
    [ -f \"\$FILE\" -o -d \"\$FILE\" ] &&
    {
        test -f \"\$FILE\" &&
        {
            MIME_TYPE=\$(file --mime-type -b \"\$FILE\")
            if [[ \$MIME_TYPE == image/* ]]; then
                kitty icat --clear --transfer-mode=memory --stdin=no --place=${_KITTEN_ICAT_PLACE} \"\$FILE\"
            else
                echo \"\$FILE\" | xargs -d '\n' bat --color=always --decorations=never
            fi
        } ||
        {
            eza \
                \$show_hidden_files \
                --group \
                --colour=always \
                --icons=always \
                --group-directories-first \
                --classify \
                --level 1 \
                --oneline \
                --no-quotes \
                \$long_info \
                \"\$FILE\" 2>/dev/null;
        }
    }"
    )
    if [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/COPY' ]]; then
        header=("--header=PASTE FILES IN $PWD")
        enter=()
        bind_app=(
            "--bind=enter:"
            "--bind=$KEY_EXECUTE:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/COPY' ] \
            && echo 'PASTE/COPY' >$LVIM_FM_WORKING_DIR/mode) \
        )+top+accept"
            "--bind=$KEY_COPY:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/COPY' ] \
            && (echo 'SELECT' >$LVIM_FM_WORKING_DIR/mode \
            && cat /dev/null > $LVIM_FM_WORKING_DIR/mode-items)) \
        )+top+accept"
            "--bind=$KEY_APPLY:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo 'PROCESS/COPY' >$LVIM_FM_WORKING_DIR/mode \
        )+top+accept"
        )
    elif [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/CUT' ]]; then
        header=("--header=PASTE FILES IN $PWD")
        enter=()
        bind_app=(
            "--bind=enter:"
            "--bind=$KEY_EXECUTE:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/CUT' ] \
            && echo 'PASTE/CUT' >$LVIM_FM_WORKING_DIR/mode) \
        )+top+accept"
            "--bind=$KEY_CUT:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/PASTE/CUT' ] \
            && (echo 'SELECT' >$LVIM_FM_WORKING_DIR/mode \
            && cat /dev/null > $LVIM_FM_WORKING_DIR/mode-items)) \
        )+top+accept"
            "--bind=$KEY_APPLY:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo 'PROCESS/CUT' >$LVIM_FM_WORKING_DIR/mode \
        )+top+accept"
        )
    elif [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/DELETE' ]]; then
        header=("--header=DELETE FILES")
        enter=()
        bind_app=(
            "--bind=enter:"
            "--bind=$KEY_DELETE:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            ([ $(cat "$LVIM_FM_WORKING_DIR"/mode) = 'EXECUTE/DELETE' ] \
            && (echo 'SELECT' >$LVIM_FM_WORKING_DIR/mode \
            && cat /dev/null > $LVIM_FM_WORKING_DIR/mode-items)) \
        )+top+accept"
            "--bind=$KEY_APPLY:execute-silent( \
            touch $LVIM_FM_WORKING_DIR/prevent && \
            echo 'PROCESS/DELETE' >$LVIM_FM_WORKING_DIR/mode \
        )+top+accept"
        )
    elif [[ $action = "menu" ]]; then
        multi=("+m")
        header=("--header=$ICON_MENU MENU")
        prompt=("--prompt=  Choice $ICON_PROMPT ")
        preview_window_hidden=("--preview-window=:hidden")
    elif [[ $action = "explorer" ]]; then
        header=("--header=$ICON_EXPLORER EXPLORER$mode$ICON_SEPARATOR $PWD")
        prompt=("--prompt=  Browse $ICON_PROMPT ")
    elif [[ $action = "search-directories-and-files" ]]; then
        header=("--header=$ICON_SEARCH_DIRECTORIES_AND_FILES SEARCH DIRECTORIES AND FILES$mode$ICON_SEPARATOR $PWD")
        prompt=("--prompt=  Search $ICON_PROMPT ")
    elif [[ $action = "search-directories" ]]; then
        header=("--header=$ICON_SEARCH_DIRECTORIES SEARCH DIRECTORIES$mode$ICON_SEPARATOR $PWD")
        prompt=("--prompt=  Search $ICON_PROMPT ")
    elif [[ $action = "search-files" ]]; then
        header=("--header=$ICON_SEARCH_FILES SEARCH FILES$mode$ICON_SEPARATOR $PWD")
        prompt=("--prompt=  Search $ICON_PROMPT ")
    elif [[ $action = "search-in-files" ]]; then
        header=("--header=$ICON_SEARCH_IN_FILES SEARCH IN FILES$mode$ICON_SEPARATOR $PWD")
        prompt=("--prompt=  Search $ICON_PROMPT ")
        if [[ -f $LVIM_FM_WORKING_DIR/hidden-files ]]; then
            reload=("--bind=change:reload:$SEARCH_IN_FILES_WITH_HIDDEN -n ${list_files:+-l} {q} || true")
        else
            reload=("--bind=change:reload:$SEARCH_IN_FILES_WITHOUT_HIDDEN -n ${list_files:+-l} {q} || true")
        fi
        preview_window_for_search_in_files=("--preview-window=~0,+{2}+1/2")
        delimiter=("--delimiter=:")
        preview_engine=("--preview=VAL={1} && \
        {
            file -biz \$PWD/\$VAL | grep ^text &>/dev/null && {
                bat --color=always --style=numbers -H {2} {1}
            }
        } \
        || \
        { \
            [ \$VAL != \$PWD ] && eza \
            $show_hidden_files \
            --group \
            --colour=always \
            --icons=always \
            --group-directories-first \
            --classify \
            --level 1 \
            --oneline \
            $long_info \
            \$VAL 2>/dev/null
        }"
        )
    fi
    if [[ -f $LVIM_FM_WORKING_DIR/show-help ]]; then
        preview_window_hidden=()
        preview_engine=("--preview=cat $LVIM_FM_WORKING_DIR/help")
    fi
    selected=$(
        get_list_for_fzf "$@" |
            IFS=$'\n' fzf \
                "$REVERSE" \
                --query="$1" \
                --history="$LVIM_FM_WORKING_DIR/history" \
                --nth="$(get_column_to_search)" \
                --highlight-line \
                --ansi \
                --color="$COLORS" \
                --preview-window=noborder \
                "${delimiter[@]}" \
                "${separator[@]}" \
                "${prompt[@]}" \
                "${header[@]}" \
                --header-first \
                "${info[@]}" \
                "${no_border[@]}" \
                "${border[@]}" \
                "${pointer[@]}" \
                "${marker[@]}" \
                "${multi[@]}" \
                "${sort[@]}" \
                "${tac[@]}" \
                "${preview_engine[@]}" \
                "${preview_window[@]}" \
                "${preview_window_for_search_in_files[@]}" \
                "${preview_window_hidden[@]}" \
                "${on_change[@]}" \
                "${reload[@]}" \
                "${bind_base[@]}" \
                "${bind_app[@]}" \
                "${enter[@]}"
    )
    if [[ -f "$LVIM_FM_WORKING_DIR/quit" ]]; then
        rm "$LVIM_FM_WORKING_DIR/quit"
        break
    elif [[ -f "$LVIM_FM_WORKING_DIR/current_selection" && -f "$LVIM_FM_WORKING_DIR/prevent" ]]; then
        rm "$LVIM_FM_WORKING_DIR/prevent"
        path=$(cat "$LVIM_FM_WORKING_DIR/current_selection")
        rm "$LVIM_FM_WORKING_DIR/current_selection"

        clean_file=$(echo "$path" | sed -E 's/^[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +//')
        if [[ -n "$clean_file" ]]; then
            path="$clean_file"
        fi

        first_char=$(echo -n "$path" | cut -c1)
        codepoint=$(printf "%d" "'$first_char'" 2>/dev/null)
        if ((codepoint >= 57344 && codepoint <= 63743)); then
            path="${path:2}"
        fi

        path=$(echo "$path" | sed -e 's/^ *//g' -e 's/ *$//g')

        # if [[ -d "$path" ]]; then
        if [[ -d "$path" && "$path" != "." && "$path" != ".." ]]; then
            yazi "$path" &>/dev/null
            # cd "$path" &>/dev/null || return
        elif [[ -f "$path" ]]; then
            # if [[ -f "$path" ]]; then
            mime_type=$(file --mime-type -b "$path")

            if [[ $mime_type == image/* ]]; then
                sxiv "$path" &>/dev/null
            elif [[ $mime_type == audio/* ]]; then
                mpd "$path" &>/dev/null
            elif [[ $mime_type == video/* ]]; then
                vlc "$path" &>/dev/null
            else
                $EDITOR "$path"
            fi
        else
            echo "$PWD" >"$LVIM_FM_WORKING_DIR/selected_directory"
            break
        fi
        # break
    elif [[ $action == "menu" ]]; then
        choice=$(
            echo "$selected" | cut -d" " -f2-
        )
        case "$choice" in
        "EXPLORER")
            echo "explorer" >"$LVIM_FM_WORKING_DIR/action"
            ;;
        "SEARCH DIRECTORIES AND FILES")
            echo "search-directories-and-files" >"$LVIM_FM_WORKING_DIR/action"
            ;;
        "SEARCH DIRECTORIES")
            echo "search-directories" >"$LVIM_FM_WORKING_DIR/action"
            ;;
        "SEARCH FILES")
            echo "search-files" >"$LVIM_FM_WORKING_DIR/action"
            ;;
        "SEARCH IN FILES")
            echo "search-in-files" >"$LVIM_FM_WORKING_DIR/action"
            ;;
        esac
    elif [[ $action == "search-in-files" ]]; then
        if [[ -f $LVIM_FM_WORKING_DIR/prevent ]]; then
            rm "$LVIM_FM_WORKING_DIR/prevent"
            if [[ -f $LVIM_FM_WORKING_DIR/reload ]]; then
                rm "$LVIM_FM_WORKING_DIR/reload"
                builtin cd "$(cat "$LVIM_FM_WORKING_DIR/base-directory")" || return
            fi
        else
            if [[ $selected == "$ICON_FOLDER .." ]]; then
                builtin cd .. || return
            fi
            post_action_search
        fi
    elif [[ $action == "search-directories-and-files" ]] || [[ $action == "search-directories" ]] || [[ $action == "search-files" ]]; then
        if [[ -f $LVIM_FM_WORKING_DIR/prevent ]]; then
            rm "$LVIM_FM_WORKING_DIR/prevent"
            if [[ -f $LVIM_FM_WORKING_DIR/reload ]]; then
                rm "$LVIM_FM_WORKING_DIR/reload"
                builtin cd "$(cat "$LVIM_FM_WORKING_DIR/base-directory")" || return
            fi
        else
            result=$(
                echo "$selected" |
                    rev |
                    cut -f1 -d ' ' |
                    rev |
                    sed \
                        -e 's/\[[0-9];[0-9][0-9]m//g' \
                        -e 's/\[[0-9];[0-9];[0-9][0-9]m//g' \
                        -e 's/\[0m//g' \
                        -e 's/^ *//g' \
                        -e 's/ *$//g'
            )
            post_action
        fi
    elif [[ $action == "explorer" ]]; then
        if [[ -f $LVIM_FM_WORKING_DIR/prevent ]]; then
            rm "$LVIM_FM_WORKING_DIR/prevent"
            if [[ -f $LVIM_FM_WORKING_DIR/reload ]]; then
                rm "$LVIM_FM_WORKING_DIR/reload"
                builtin cd "$(cat "$LVIM_FM_WORKING_DIR/base-directory")" || return
            fi
        else
            result=$(
                echo "$selected" |
                    rev |
                    cut -f1 -d ' ' |
                    rev |
                    sed \
                        -e 's/\[[0-9];[0-9][0-9]m//g' \
                        -e 's/\[[0-9];[0-9];[0-9][0-9]m//g' \
                        -e 's/\[0m//g' \
                        -e 's/^ *//g' \
                        -e 's/ *$//g'
            )
            post_action
        fi
    fi
done
