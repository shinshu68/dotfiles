function resource
    set -l config_path $XDG_CONFIG_HOME/fish
    for file in (ls $config_path)
        if islink $config_path/$file
            source $config_path/$file
            echo $file
        end
    end

    set -l function_path $XDG_CONFIG_HOME/fish/functions
    for file in (ls $function_path)
        if islink $function_path/$file
            source $function_path/$file
            echo $file
        end
    end
end
