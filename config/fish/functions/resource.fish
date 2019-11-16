function resource
    if test (count $argv) -ne 1
        false
        return
    end

    set -l config_path $XDG_CONFIG_HOME/fish
    set -l function_path $XDG_CONFIG_HOME/fish/functions

    if test $argv = 'all'
        for file in (ls $config_path)
            if islink $config_path/$file
                source $config_path/$file
                echo $file
            end
        end

        for file in (ls $function_path)
            if test $file = 'resource.fish'
                continue
            end

            if islink $function_path/$file
                source $function_path/$file
                echo $file
            end
        end
    else
        set -l file (find $XDG_CONFIG_HOME/fish | grep '\.fish$' | grep -F "$argv")
        source $file
    end
end
