function fish_user_key_bindings
    bind \cd accept-autosuggestion
end

# ペースト末尾の改行で2行目ができないようにする
# (fish 4 の貼り付けは __fish_paste を通るので、元の関数を退避して包む)
if functions -q __fish_paste; and not functions -q __fish_paste_orig
    functions --copy __fish_paste __fish_paste_orig
    function __fish_paste
        __fish_paste_orig (string replace -r '[\r\n]+$' '' -- $argv[1] | string collect)
    end
end
