#!/bin/sh
# Configuration parameters


PERSONAL_DWM_REPO="my-dwm"
PATCHES_PATH="patches"
DWM_URL="dwm.suckless.org"
PATCH_PATH="${DWM_URL}/${PATCHES_PATH}"
PATCHES_URL="https://${PATCH_PATH}/"
DWM_VERSION="6.2"
ANOTHER_PATCH_CYCLE=1

SCRIPT=$(readlink -f "$0")
SCRIPTPATH="."
DEPS="../deps.csv"

clone_repo() { 
    [ -d "$PERSONAL_DWM_REPO" ] || {
        git clone https://git.suckless.org/dwm "$PERSONAL_DWM_REPO"
            #(cd "$PERSONAL_DWM_REPO" && git checkout "$DWM_VERSION")
        }
}

download_patches() {
    [ -d "$PATCH_PATH" ] || {
        wget -q --recursive ‐-mirror \
        --domains "${DWM_URL}" --no-parent "${PATCHES_URL}"
    }
}

apply_patch() {
    local patch_file="$1"
    echo "---> apply patch: $patch_file" 
    patch -s -t -p1 -F 3 < "$patch_file" || {
        echo "Could not apply patch $patch_file"     
        echo "returning"
        exit 1
    }
}

process_patches() { 
    clone_repo
    download_patches

    set -e pipefail

    cd "$PERSONAL_DWM_REPO"
    cat $DEPS | while read -r row; do
        MAINPATCH="$(echo $row | cut -d ',' -f 1)"

        DEPENDENCIES="$(echo $row | cut -d ',' -f 2-)"
        FEATURE_NAME="$(basename $(dirname $MAINPATCH))"
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
            echo "$DEPENDENCIES" | tr ',' '\n' | while read dep; do
                apply_patch "../$PATCH_PATH/$dep"
            done
        }

        apply_patch "../$PATCH_PATH/$MAINPATCH"
        make clean && make config.h && make 

        [ $? -eq 0 ] || {
            echo "could not run build"
            exit 1
        }

        git add -A                
        git commit -m "applied patch"
        git clean -d -f
        git checkout "$DWM_VERSION"
    done
}

process_patches
#exit 0
