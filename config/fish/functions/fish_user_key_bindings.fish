function fish_user_key_bindings
    bind \cd accept-autosuggestion
    bind \cs emoji-fish
end

if test -d $HOME/.fzf
    fzf_key_bindings
end
