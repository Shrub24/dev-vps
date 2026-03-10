_repo_sync_complete() {
	local cur prev words cword
	_init_completion || return

	local cmd=${words[1]:-}
	local sub=${words[2]:-}

	if [[ $cword -eq 1 ]]; then
		COMPREPLY=($(compgen -W "init bootstrap add sync scan state" -- "$cur"))
		return
	fi

	case "$cmd" in
	add)
		if [[ $cword -eq 2 ]]; then
			COMPREPLY=($(compgen -W "$(repo-sync __complete-repo "$cur" 2>/dev/null)" -- "$cur"))
		else
			COMPREPLY=($(compgen -W "--push --ignore-path" -- "$cur"))
		fi
		;;
	init | bootstrap | sync | scan)
		COMPREPLY=($(compgen -W "--push" -- "$cur"))
		;;
	state)
		if [[ $cword -eq 2 ]]; then
			COMPREPLY=($(compgen -W "pull add commit push" -- "$cur"))
		elif [[ "$sub" == "add" ]]; then
			case "$prev" in
			--repo)
				COMPREPLY=($(compgen -W "$(repo-sync __complete-repo "$cur" 2>/dev/null)" -- "$cur"))
				;;
			*)
				COMPREPLY=($(compgen -W "--repo --push" -- "$cur"))
				;;
			esac
		elif [[ "$sub" == "commit" ]]; then
			case "$prev" in
			--repo)
				COMPREPLY=($(compgen -W "$(repo-sync __complete-repo "$cur" 2>/dev/null)" -- "$cur"))
				;;
			*)
				COMPREPLY=($(compgen -W "--repo --code-sha --push" -- "$cur"))
				;;
			esac
		fi
		;;
	esac
}

complete -F _repo_sync_complete repo-sync
