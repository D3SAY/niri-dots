fish_add_path -g ~/.local/bin ~/.spicetify

if status is-interactive
    starship init fish | source

    alias ls lsd
    alias z "cd .."

    alias please sudo
    alias пожалуйста sudo
    alias portage pacman
end
