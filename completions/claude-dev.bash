# Bash completion for claude-dev
_claude_dev() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--version --stop --clean --root --help"

    case "${prev}" in
        claude-dev)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
}

complete -F _claude_dev claude-dev
