function resource
    set -l config_path $XDG_CONFIG_HOME/fish
    for file in (ls $config_path)
        islink $config_path/$file
        if test $status -eq 0
            source $config_path/$file
            echo $file
        end
    end

    set -l function_path $XDG_CONFIG_HOME/fish/functions
    for file in (ls $function_path)
        islink $function_path/$file
        if test $status -eq 0
            source $function_path/$file
            echo $file
        end
    end
end
