#!/bin/bash

atomic_sort_unique() {
    local file="$1"
    local lock_dir="${file}.lock"
    local max_wait=50
    local i=0

    while ! mkdir "$lock_dir" 2>/dev/null; do
        if [[ -d "$lock_dir" ]] && find "$lock_dir" -maxdepth 0 -mmin +1 -print -quit 2>/dev/null | grep -q .; then
            rm -rf "$lock_dir" 2>/dev/null
            continue
        fi
        i=$((i + 1))
        if [[ $i -ge $max_wait ]]; then
            echo "Warning: Could not acquire lock for $file after ${max_wait} attempts" >&2
            return 1
        fi
        sleep 0.1
    done

    local return_code=0
    local tmp_file="${file}.tmp"

    if [[ -f "$file" ]]; then
        if ! sort -u "$file" > "$tmp_file"; then
            return_code=$?
            rm -f "$tmp_file" 2>/dev/null || true
        elif ! mv "$tmp_file" "$file"; then
            return_code=$?
            rm -f "$tmp_file" 2>/dev/null || true
        fi
    fi

    rm -rf "$lock_dir" 2>/dev/null || true
    return $return_code
}

repo_cache_key() {
    local repo="${1:-.}"
    local normalized="$repo"

    if [[ "$normalized" == "." ]]; then
        normalized="root"
    fi

    local safe_name
    safe_name="$(printf "%s" "$normalized" | tr "/" "_" | tr -c '[:alnum:]_.-' "_")"

    local checksum
    checksum="$(printf "%s" "$repo" | cksum | awk '{print $1}')"

    printf "%s-%s\n" "$safe_name" "$checksum"
}

safe_rm_cache() {
    local dir="$1"
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

    [[ -z "$dir" ]] && return 1
    [[ "$dir" != *"tsc-cache"* ]] && return 1
    [[ ! -d "$dir" ]] && return 0

    local resolved
    resolved="$(cd "$dir" && pwd)" || return 1
    local expected_prefix
    expected_prefix="$(cd "$project_dir/.claude/tsc-cache" 2>/dev/null && pwd)" || return 1

    if [[ "$resolved" != "$expected_prefix"* ]]; then
        echo "Warning: Refusing to delete $dir (not under $expected_prefix)" >&2
        return 1
    fi

    rm -rf "$resolved"
}

is_project_dir() {
    local dir="$1"
    [ -f "$dir/tsconfig.json" ] || [ -f "$dir/tsconfig.app.json" ] || [ -f "$dir/tsconfig.build.json" ] ||
    [ -f "$dir/package.json" ] ||
    [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ] ||
    [ -f "$dir/go.mod" ] ||
    [ -f "$dir/Cargo.toml" ] ||
    [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ] ||
    [ -f "$dir/Gemfile" ] ||
    [ -f "$dir/Makefile" ] || [ -d "$dir/.git" ]
}

get_repo_for_file() {
    local file_path="$1"
    local project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
    local relative_path="${file_path#$project_dir/}"
    local dir_path
    dir_path="$(dirname "$relative_path")"

    while [[ "$dir_path" != "." && -n "$dir_path" ]]; do
        local full_path="$project_dir/$dir_path"
        if [ -d "$full_path" ] && is_project_dir "$full_path"; then
            echo "$dir_path"
            return 0
        fi
        dir_path="$(dirname "$dir_path")"
    done

    if is_project_dir "$project_dir"; then
        echo "."
        return 0
    fi

    echo ""
    return 1
}

get_tsc_command() {
    local repo_path="$1"

    if [ -f "$repo_path/tsconfig.app.json" ]; then
        echo "npx tsc --project tsconfig.app.json --noEmit"
    elif [ -f "$repo_path/tsconfig.build.json" ]; then
        echo "npx tsc --project tsconfig.build.json --noEmit"
    elif [ -f "$repo_path/tsconfig.json" ]; then
        if grep -q '"references"' "$repo_path/tsconfig.json" 2>/dev/null; then
            if [ -f "$repo_path/tsconfig.src.json" ]; then
                echo "npx tsc --project tsconfig.src.json --noEmit"
            else
                echo "npx tsc --build --noEmit"
            fi
        else
            echo "npx tsc --noEmit"
        fi
    else
        echo ""
    fi
}

validate_and_run_tsc() {
    local tsc_cmd="$1"
    if [[ -z "$tsc_cmd" ]]; then
        echo "Skipping TSC command: empty command" >&2
        return 2
    fi

    local re_tsc_command='^(cd[[:space:]].+[[:space:]]&&[[:space:]])?(npx[[:space:]]tsc|node_modules/\.bin/tsc|\./node_modules/\.bin/tsc|tsc)[[:space:]]'
    if [[ ! "$tsc_cmd" =~ $re_tsc_command ]]; then
        echo "Skipping unsafe TSC command: $tsc_cmd" >&2
        return 2
    fi

    local cd_target=""
    local re_cd_quoted='^cd[[:space:]]"([^"]+)"[[:space:]]&&'
    local re_cd_bare='^cd[[:space:]]([^[:space:]]+)[[:space:]]&&'
    if [[ "$tsc_cmd" =~ $re_cd_quoted ]]; then
        cd_target="${BASH_REMATCH[1]}"
    elif [[ "$tsc_cmd" =~ $re_cd_bare ]]; then
        cd_target="${BASH_REMATCH[1]}"
    fi
    if [[ -n "$cd_target" && ! -d "$cd_target" ]]; then
        echo "Skipping TSC command: directory does not exist: $cd_target" >&2
        return 2
    fi

    local sanitized=$(echo "$tsc_cmd" | sed -E 's/^cd "[^"]*" && //; s/^cd [^ ]* && //')
    local re_tsc_safe='^(npx[[:space:]]tsc|node_modules/\.bin/tsc|./node_modules/\.bin/tsc|tsc)([[:space:]]+([[:alnum:]_./:@%+=,-]+|"[^"]+"))*[[:space:]]*$'
    if [[ "$sanitized" =~ [\;\&\|\<\>\`\$\(\)] ]] || [[ ! "$sanitized" =~ $re_tsc_safe ]]; then
        echo "Skipping suspicious TSC command: $tsc_cmd" >&2
        return 2
    fi

    /bin/bash -c "$tsc_cmd" 2>&1
}
