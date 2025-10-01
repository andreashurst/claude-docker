# Bash completion for claude-flow
_claude_flow() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--version --stop --clean --root --help"

    case "${prev}" in
        claude-flow)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
}

complete -F _claude_flow claude-flow
