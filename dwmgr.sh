#!/usr/bin/env sh

# Config parameters
PERSONAL_DWM_REPO="my-dwm"
PATCHES_PATH="patches"
DWM_URL="dwm.suckless.org"
PATCH_PATH="${DWM_URL}/${PATCHES_PATH}"
PATCHES_URL="https://${PATCH_PATH}/"
DWM_VERSION="6.2"
DEPS="../deps.csv"

clone_repo() { 
    [ -d "$PERSONAL_DWM_REPO" ] || {
        git clone https://git.suckless.org/dwm "$PERSONAL_DWM_REPO"
        (cd "$PERSONAL_DWM_REPO" && git checkout "$DWM_VERSION")
    }
}

download_patches() {
    [ -d "$PATCH_PATH" ] || {
        wget -q --recursive ‐-mirror \
            --domains "${DWM_URL}" --no-parent "${PATCHES_URL}"
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
    clone_repo
    download_patches

    set -e pipefail

    cd "$PERSONAL_DWM_REPO"

    patchno=0
    while read -r row; do
        MAINPATCH="$(echo "$row" | cut -d ',' -f 1)"

        DEPENDENCIES="$(echo "$row" | cut -d ',' -f 2-)"
        FEATURE_NAME="$(basename "$(dirname "$MAINPATCH")")"
        BRANCH_NAME=$(basename "${MAINPATCH%.*}")

        echo "looking at feature: $FEATURE_NAME"
        echo "patch: $MAINPATCH"
        echo "branch: $BRANCH_NAME"

        EXISTING_BRANCH=$(git branch -l "$BRANCH_NAME" | tr -d ' ')

        [ "$EXISTING_BRANCH" = "$BRANCH_NAME" ] && {
            echo "branch $EXISTING_BRANCH already present - skipping" 
            continue
        }

        echo "apply patch $BASE on branch $BRANCH_NAME"
        git checkout -b "$BRANCH_NAME"

        [ -n "$DEPENDENCIES" ] && {
            echo "$DEPENDENCIES" | tr ',' '\n' | while read -r dep; do
                apply_patch "../$PATCH_PATH/$dep"
            done
        }

        apply_patch "../$PATCH_PATH/$MAINPATCH"
        make config.h
        make || {
            echo "could not run build"
            exit 1
        }

        make clean
        git add -A                
        git commit -m "applied patch"
        git clean -d -f
        git checkout "$DWM_VERSION"
        patchno=$((patchno+1))
    done < "$DEPS"

    echo "applied $patchno patches"

    return 0
}

reset() {
    ( 
    cd "$PERSONAL_DWM_REPO"
    git reset --hard && git checkout master && git branch | grep -v master | while read -r b; do 
        git branch -D "$b"; git clean -d -f; 
    done 
    git checkout "$DWM_VERSION"
    )
}

print_help() {
    cat <<EOF
    ./dwmgr.sh
       -h : print help
       -d : absolute path to custom dependency file (default deps.csv)
       -s : set up a private repository. DWM patches are automatically fetched 
            and applied. every patch is applied on its own branch
       -r : reset private repostirory (CAUTION: this will delete all branches 
            and reset the copy of your private dwm repository)
EOF
}

while getopts "hsr" opt; do
    case ${opt} in
        h)
            print_help
            exit 0
            ;;
        s)
            setup 
            exit 0
            ;;
        r)
            reset
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
