function __week_num_to_str
    switch $argv
        case 0
            echo 'Sun'
        case 1
            echo 'Mon'
        case 2
            echo 'Tue'
        case 3
            echo 'Wed'
        case 4
            echo 'Thu'
        case 5
            echo 'Fri'
        case 6
            echo 'Sat'
    end
end

function __month_num_to_str
    switch $argv
        case 01
            echo 'Jan'
        case 02
            echo 'Feb'
        case 03
            echo 'Mar'
        case 04
            echo 'Apr'
        case 05
            echo 'May'
        case 06
            echo 'Jun'
        case 07
            echo 'Jul'
        case 08
            echo 'Aug'
        case 09
            echo 'Sep'
        case 10
            echo 'Oct'
        case 11
            echo 'Nov'
        case 12
            echo 'Dec'
    end
end

function before-date-git-style
    if test (count $argv) -ne 1
        false
        return
    end
    set -l week (__week_num_to_str (date --date "-$argv day" +"%w"))
    set -l month (__month_num_to_str (date --date "-$argv day" +"%m"))
    set -l day (string trim (date --date "-$argv day" +"%e"))
    set -l time_year_zone (date --date "-$argv day" +"%T %Y %z")

    echo $week $month $day $time_year_zone
end
