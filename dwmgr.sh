#!/usr/bin/env sh

# Config parameters
PATCHES_PATH="patches"

## DMENU
PERSONAL_DMENU_REPO="my-dmenu"
DMENU_GIT="https://git.suckless.org/dmenu"
DMENU_URL="tools.suckless.org/dmenu"
DMENU_PATCH_PATH="${DMENU_URL}/${PATCHES_PATH}"
DMENU_PATCHES_URL="https://${DMENU_PATCH_PATH}/"
DMENU_VERSION="5.0"
DMENU_DEPS="../dmenu-deps.csv"

## DWM
PERSONAL_DWM_REPO="my-dwm"
DWM_GIT="https://git.suckless.org/dwm"
DWM_URL="dwm.suckless.org"
DWM_PATCH_PATH="${DWM_URL}/${PATCHES_PATH}"
DWM_PATCHES_URL="https://${DWM_PATCH_PATH}/"
DWM_VERSION="6.2"
DWM_DEPS="../dwm-deps.csv"

clone_repo() { 
    repo="$1"
    git_url="$2"
    version="$3"

    [ -d "$repo" ] || {
        git clone "$git_url" "$repo"
        (cd "$repo" && git checkout "$version")
    }
}

download_patches() {
    patch_dir="$1"
    domain="$2"
    patches_url="$3"

    [ -d "$patch_dir" ] || {
        wget -q --recursive ‐-mirror --no-parent "${patches_url}"
    }
}

apply_patch() {
    patch_file="$1"
    echo "---> apply patch: $patch_file" 
    patch -s -t -p1 -F 3 < "$patch_file" || {
        echo "Could not apply patch $patch_file"     
        echo "returning"
        exit 1
    }
}

setup() { 
    git_repo="$1"
    repo_name="$2"
    patch_path="$3"
    version="$4"
    deps="$5"
    patch_dir="$6"
    domain="$7"
    patches_url="$8"

    clone_repo "$repo_name" "$git_repo" "$version"
    download_patches "$patch_dir" "$domain" "$patches_url"

    set -e pipefail

    cd "$repo_name"

    patchno=0
    while read -r row; do
        mainpatch="$(echo "$row" | cut -d ',' -f 1)"

        dependencies="$(echo "$row" | cut -d ',' -f 2-)"
        feature_name="$(basename "$(dirname "$mainpatch")")"
        branch_name=$(basename "${mainpatch%.*}")

        echo "looking at feature: $feature_name"
        echo "patch: $mainpatch"
        echo "branch: $branch_name"

        existing_branch=$(git branch -l "$branch_name" | tr -d ' ')

        [ "$existing_branch" = "$branch_name" ] && {
            echo "branch $existing_branch already present - skipping" 
            continue
        }

        echo "apply patch $mainpatch on branch $branch_name"
        git checkout -b "$branch_name"

        [ -n "$dependencies" ] && {
            echo "$dependencies" | tr ',' '\n' | while read -r dep; do
                apply_patch "../$patch_path/$dep"
            done
        }

        apply_patch "../$patch_path/$mainpatch"
        make config.h
        make || {
            echo "could not run build"
            exit 1
        }

        make clean
        git add -A                
        git commit -m "applied patch"
        git clean -d -f
        git checkout "$version"
        patchno=$((patchno+1))

    done < "$deps"

    echo "applied $patchno patches"

    return 0
}

reset() {
    personal_repo="$1"
    version="$2"
    ( 
    cd "$personal_repo"
    git reset --hard && git checkout master && git branch | grep -v master | while read -r b; do 
        git branch -D "$b"; git clean -d -f; 
    done 
    git checkout "$version"
    )
}

print_help() {
    cat <<EOF
    ./dwmgr.sh
       -h : print help
       -d : absolute path to custom dependency file (default deps.csv)
       -s [dwm|dmenu]: set up a private repository. Patches are automatically fetched
            and applied. every patch is applied on its own branch
       -r [dwm|dmenu]: reset private repostirory (CAUTION: this will delete all branches 
            and reset the copy of your private repository)
EOF
}

while getopts "hs:r" opt; do
    case ${opt} in
        h)
            print_help
            exit 0
            ;;
        s)
            #setup 
            case "${OPTARG}" in 
                "dwm")
                    echo "setting up dwm"
                    setup "$DWM_GIT" \
                        "$PERSONAL_DWM_REPO" \
                        "$DWM_PATCH_PATH" \
                        "$DWM_VERSION" \
                        "$DWM_DEPS" \
                        "$DWM_PATCH_PATH" \
                        "$DWM_URL" \
                        "$DWM_PATCHES_URL"
                    ;;
                "dmenu")
                    echo "setting up dmenu"
                    setup "$DMENU_GIT" \
                        "$PERSONAL_DMENU_REPO" \
                        "$DMENU_PATCH_PATH" \
                        "$DMENU_VERSION" \
                        "$DMENU_DEPS" \
                        "$DMENU_PATCH_PATH" \
                        "$DMENU_URL" \
                        "$DMENU_PATCHES_URL"
                    ;;
            esac
            exit 0
            ;;
        r)
            reset "$PERSONAL_DMENU_REPO" "$DMENU_VERSION"
            exit 0
            ;;
        \?) 
            print_help
            exit 0
            ;;
    esac
done

print_help

exit 1
