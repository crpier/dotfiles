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

set -q __terlar_git_prompt_cache_ttl_seconds; or set -g __terlar_git_prompt_cache_ttl_seconds 2
set -q __terlar_git_prompt_lock_ttl_minutes; or set -g __terlar_git_prompt_lock_ttl_minutes 5

function __terlar_git_prompt --description 'Write out the git prompt'
    # If git isn't installed, there's nothing we can do.
    # Return 1 so the calling prompt can deal with it.
    if not command -sq git
        return 1
    end

    # Keep the prompt itself cheap: only discover the repo synchronously.
    # The expensive `git status` work happens in a background worker.
    set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
        return
    end

    set -l cache_base "$XDG_CACHE_HOME"
    if test -z "$cache_base"
        set cache_base "$HOME/.cache"
    end

    set -l cache_dir "$cache_base/fish/terlar_git_prompt"
    command mkdir -p "$cache_dir" 2>/dev/null; or return

    set -l cache_key
    if command -sq sha1sum
        set cache_key (printf '%s' "$repo_root" | command sha1sum | string split -f1 ' ')
    end
    if test -z "$cache_key"
        set cache_key (string escape --style=url -- "$repo_root")
    end

    set -l cache_file "$cache_dir/$cache_key.prompt"
    set -l stamp_file "$cache_dir/$cache_key.started"
    set -l lock_dir "$cache_dir/$cache_key.lock"

    if test -f "$cache_file"
        __terlar_git_prompt_render (command cat "$cache_file")
    end

    __terlar_git_prompt_start_worker "$repo_root" "$cache_file" "$stamp_file" "$lock_dir" "$fish_pid"
end

function __terlar_git_prompt_start_worker --argument-names repo_root cache_file stamp_file lock_dir parent_fish_pid
    set -l now (command date +%s)
    set -l last_started 0

    if test -f "$stamp_file"
        read -l last_started < "$stamp_file"
    end

    if string match -qr '^\d+$' -- "$last_started"
        if test (math "$now - $last_started") -lt $__terlar_git_prompt_cache_ttl_seconds
            return
        end
    end

    if test -d "$lock_dir"
        set -l stale_lock (command find "$lock_dir" -maxdepth 0 -mmin +$__terlar_git_prompt_lock_ttl_minutes -print 2>/dev/null)
        if test -n "$stale_lock"
            command rm -rf "$lock_dir"
        else
            return
        end
    end

    command mkdir "$lock_dir" 2>/dev/null; or return
    printf '%s\n' "$now" > "$stamp_file"

    set -l source_file (status filename)

    fish -c '
        source "$argv[1]"; or begin
            command rm -rf "$argv[4]"
            exit 1
        end
        cd "$argv[2]"; or begin
            command rm -rf "$argv[4]"
            exit 1
        end

        set -l tmp_file "$argv[3].$fish_pid.tmp"
        __terlar_git_prompt_collect > "$tmp_file"
        command mv "$tmp_file" "$argv[3]"
        command date +%s > "$argv[6]"
        command rm -rf "$argv[4]"
        command kill -s SIGUSR1 "$argv[5]" 2>/dev/null
    ' -- "$source_file" "$repo_root" "$cache_file" "$lock_dir" "$parent_fish_pid" "$stamp_file" >/dev/null 2>&1 &
    disown $last_pid
end

function __terlar_git_prompt_collect --description 'Collect git prompt data for the async cache'
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

        # HACK: To allow matching a literal `??` both with and without `?` globs.
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

function __terlar_git_prompt_render --argument-names prompt_data --description 'Render cached git prompt data'
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

function __terlar_git_prompt_repaint --on-signal SIGUSR1 --description 'Repaint after async git prompt refreshes'
    commandline -f repaint 2>/dev/null
end
