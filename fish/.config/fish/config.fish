if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
    pokemon-colorscripts -r --no-title
end

zoxide init fish | source
starship init fish | source

alias cd="z"
alias ..="cd .."

alias l="eza --icons"
alias ls="eza --icons --long"
alias la="eza --icons --long --all"

set -x OPENROUTER_API_KEY (pass show open-router/api-key)
