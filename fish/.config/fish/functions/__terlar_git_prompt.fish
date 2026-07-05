set -g fish_color_git_clean green
set -g fish_color_git_staged yellow
set -g fish_color_git_dirty red

set -g fish_color_git_added green
set -g fish_color_git_modified blue
set -g fish_color_git_renamed magenta
set -g fish_color_git_copied magenta
set -g fish_color_git_deleted red
set -g fish_color_git_untracked yellow
set -g fish_color_git_unmerged red

set -g fish_prompt_git_status_added '✚'
set -g fish_prompt_git_status_modified '*'
set -g fish_prompt_git_status_renamed '➜'
set -g fish_prompt_git_status_copied '⇒'
set -g fish_prompt_git_status_deleted '✖'
set -g fish_prompt_git_status_untracked '?'
set -g fish_prompt_git_status_unmerged !

set -g fish_prompt_git_status_order added modified renamed copied deleted untracked unmerged

function __terlar_git_prompt --description 'Write out the git prompt'
    if not command -sq git
        return 1
    end

    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return

    __terlar_git_prompt_render (__terlar_git_prompt_collect)
end

function __terlar_git_prompt_collect --description 'Collect git prompt data'
    set -l branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if test -z "$branch"
        return
    end

    set -l index (command git status --porcelain 2>/dev/null | command cut -c 1-2 | command sort -u)

    if test -z "$index"
        printf '%s\t%s\t%s\n' "$branch" clean ''
        return
    end

    set -l gs
    set -l state dirty

    for i in $index
        if string match -rq '^[AMRCD]' -- "$i"
            set state staged
        end

        set -l dq '??'
        switch $i
            case 'A '
                set -a gs added
            case 'M ' ' M'
                set -a gs modified
            case 'R '
                set -a gs renamed
            case 'C '
                set -a gs copied
            case 'D ' ' D'
                set -a gs deleted
            case "$dq"
                set -a gs untracked
            case 'U*' '*U' DD AA
                set -a gs unmerged
        end
    end

    set -l status_names (string join ' ' $gs)
    printf '%s\t%s\t%s\n' "$branch" "$state" "$status_names"
end

function __terlar_git_prompt_render --argument-names prompt_data --description 'Render git prompt data'
    if test -z "$prompt_data"
        return
    end

    set -l fields (string split \t -- "$prompt_data")
    set -l branch "$fields[1]"
    set -l state "$fields[2]"
    set -l gs (string split ' ' -- "$fields[3]")

    if test -z "$branch"
        return
    end

    echo -n ' '

    if test "$state" = clean
        set_color $fish_color_git_clean
        printf '%s' "$branch✓"
        set_color normal
        return
    end

    if test "$state" = staged
        set_color $fish_color_git_staged
    else
        set_color $fish_color_git_dirty
    end

    printf '%s' "$branch⚡"

    for i in $fish_prompt_git_status_order
        if contains -- $i $gs
            set -l color_name fish_color_git_$i
            set -l status_name fish_prompt_git_status_$i

            set_color $$color_name
            echo -n $$status_name
        end
    end

    set_color normal
end
