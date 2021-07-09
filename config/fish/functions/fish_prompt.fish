# Defined interactively
function fish_prompt --description 'Write out the prompt'
    set -l last_status $status

    # # User
    # set_color $fish_color_user
    # echo -n $USER
    # set_color normal

    # echo -n '@'

    # # Host
    # set_color $fish_color_host
    # echo -n (prompt_hostname)
    # set_color normal

    # echo -n ':'

    echo -e ''
    # PWD
    set_color $fish_color_cwd
    echo -n (prompt_pwd)
    set_color normal
    echo -n ' '

    if set -q VIRTUAL_ENV
        set_color $fish_color_escape
        echo -n \((basename $VIRTUAL_ENV)\)
        set_color normal
    end

    __terlar_git_prompt
    if test $SSH_CLIENT
        set_color $fish_color_quote
        echo -n  " "(hostname)
        set_color normal
    end
    echo

    if not test $last_status -eq 0
        set_color $fish_color_error
    end

    echo -n '➤ '
    set_color normal
end
