#!/usr/bin/env bash

function print_fzf_menu {
	echo "$ICON_EXPLORER" EXPLORER
	echo "$ICON_SEARCH_DIRECTORIES_AND_FILES" SEARCH DIRECTORIES AND FILES
	echo "$ICON_SEARCH_DIRECTORIES" SEARCH DIRECTORIES
	echo "$ICON_SEARCH_FILES" SEARCH FILES
	echo "$ICON_SEARCH_IN_FILES" SEARCH IN FILES
}

function print_pre_process {
	cat "$LVIM_FM_WORKING_DIR"/mode-items
}

function print_fzf_header {
	echo "$ICON_FOLDER ."
	[[ $PWD = "/" ]] && echo "/" || echo "$ICON_FOLDER .."
}

function explorer {
	$EXPLORER $long_info $show_hidden_files
}

function search_directories_and_files {
	if [[ -f "$LVIM_FM_WORKING_DIR/hidden-files" ]]; then
		$SEARCH_DIRECTORIES_AND_FILES_WITH_HIDDEN
	else
		$SEARCH_DIRECTORIES_AND_FILES_WITHOUT_HIDDEN
	fi
}

function search_directories {
	if [[ -f "$LVIM_FM_WORKING_DIR/hidden-files" ]]; then
		$SEARCH_DIRECTORIES_WITH_HIDDEN
	else
		$SEARCH_DIRECTORIES_WITHOUT_HIDDEN
	fi
}

function search_files {
	if [[ -f "$LVIM_FM_WORKING_DIR/hidden-files" ]]; then
		$SEARCH_FILES_WITH_HIDDEN
	else
		$SEARCH_FILES_WITHOUT_HIDDEN
	fi
}

function search_in_files {
	if [[ -f $LVIM_FM_WORKING_DIR/hidden-files ]]; then
		$SEARCH_IN_FILES_WITH_HIDDEN -n ${list_files:+-l} "$1"
	else
		$SEARCH_IN_FILES_WITHOUT_HIDDEN -n ${list_files:+-l} "$1"
	fi
}

function post_action {
	directories=()
	files=()

	local all_files=()
	while IFS= read -r file; do
		all_files+=("$file")
	done < <(find "$PWD" -maxdepth 1 -mindepth 1 -printf "%f\n")

	if [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "COPY" ]] ||
		[[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "CUT" ]] ||
		[[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "DELETE" ]]; then

		for file in "${all_files[@]}"; do
			if echo "$selected" | grep -q "$file"; then
				if [[ -d "$file" ]] &&
					[[ "$file" != "." ]] &&
					[[ "$file" != ".." ]]; then
					echo "$PWD/$file" >>"$LVIM_FM_WORKING_DIR"/mode-items
				elif [[ -f "$file" ]]; then
					echo "$PWD/$file" >>"$LVIM_FM_WORKING_DIR"/mode-items
				fi
			fi
		done

		if [[ -s "$LVIM_FM_WORKING_DIR"/mode-items ]]; then
			if [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "DELETE" ]]; then
				echo "EXECUTE/DELETE" >"$LVIM_FM_WORKING_DIR"/mode
			else
				echo "PASTE/$(cat "$LVIM_FM_WORKING_DIR"/mode)" >"$LVIM_FM_WORKING_DIR"/mode
			fi
		else
			echo "SELECT" >"$LVIM_FM_WORKING_DIR"/mode
		fi
	else
		if [[ $selected == *".."* ]]; then
			directories=("..")
		# elif [[ $clean_selected == *"."* ]] && [[ $clean_selected != *".."* ]]; then
		#     return
		else
			found_dir=false
			for file in "${all_files[@]}"; do
				if echo "$selected" | grep -q "$file"; then
					if [[ -d "$file" ]]; then
						directories=("$file")
						found_dir=true
						break
					elif [[ -f "$file" ]] && [[ $found_dir == false ]]; then
						files+=("$file")
					fi
				fi
			done
		fi

		current_mode=$(cat "$LVIM_FM_WORKING_DIR"/mode)
		if [[ ${#directories[@]} -gt 0 ]]; then
			builtin cd "${directories[-1]}" || return
		fi
	fi
}

function post_action_search {
	files=()

	for result in $selected; do
		files+=("$result")
	done

	mapfile -t files < <(echo "${files[@]}" | awk 'BEGIN{RS=" ";} !a[$1]++ {print $1}')

	if [[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "COPY" ]] ||
		[[ $(cat "$LVIM_FM_WORKING_DIR"/mode) == "CUT" ]]; then
		if [[ ${#files[@]} != 0 ]]; then
			for i in "${files[@]}"; do
				echo "$PWD/$i" >>"$LVIM_FM_WORKING_DIR"/mode-items
			done
			echo 'PASTE' >"$LVIM_FM_WORKING_DIR"/mode
		fi
	fi
}

function get_list_for_fzf {
	# if [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'PROCESS/COPY' ]]; then
	#     process_copy "$1"
	# elif [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'PROCESS/CUT' ]]; then
	#     process_cut "$1"
	# elif [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'PROCESS/DELETE' ]]; then
	#     process_delete "$1"
	# elif [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'EXECUTE/PASTE/COPY' ]]; then
	#     print_pre_process "$1"
	# elif [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'EXECUTE/PASTE/CUT' ]]; then
	#     print_pre_process "$1"
	# elif [[ $(cat "$LVIM_FM_WORKING_DIR/mode") = 'EXECUTE/DELETE' ]]; then
	#     print_pre_process "$1"
	# elif [[ $action = "menu" ]]; then
	if [[ $action = "menu" ]]; then
		print_fzf_menu "$1"
	elif [[ $action = "explorer" ]]; then
		print_fzf_header "$1"
		explorer "$1"
	elif [[ $action = "search-directories-and-files" ]]; then
		print_fzf_header "$1"
		search_directories_and_files "$1"
	elif [[ $action = "search-directories" ]]; then
		print_fzf_header "$1"
		search_directories "$1"
	elif [[ $action = "search-files" ]]; then
		print_fzf_header "$1"
		search_files "$1"
	elif [[ $action = "search-in-files" ]]; then
		search_in_files "$1"
	fi
}

function get_column_to_search {
	if [[ $action = "explorer" ]] && [[ -f $LVIM_FM_WORKING_DIR/long-info ]]; then
		nth='8..-1'
	elif [[ $action = "explorer" ]] && [[ ! -f $LVIM_FM_WORKING_DIR/long-info ]]; then
		nth='2..-1'
	else
		nth=".."
	fi
	echo -n $nth
}
