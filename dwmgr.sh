#!/bin/sh
# Configuration parameters

set -ex pipefail

PERSONAL_DWM_REPO="my-dwm"
PATCHES_PATH="patches"
DWM_URL="dwm.suckless.org"
PATCH_PATH="${DWM_URL}/${PATCHES_PATH}"
PATCHES_URL="https://${PATCH_PATH}/"
DWM_VERSION="6.2"

clone_repo() { 
    [ -d "$PERSONAL_DWM_REPO" ] || {
        git clone https://git.suckless.org/dwm "$PERSONAL_DWM_REPO"
        #(cd "$PERSONAL_DWM_REPO" && git checkout "$DWM_VERSION")
    }
}

download_patches() {
    wget -q --recursive ‐-mirror \
        --wait=15 --limit-rate=50K \
        --domains "${DWM_URL}" --no-parent "${PATCHES_URL}"
}

prepare_repo() { 
    clone_repo
    cd "$PERSONAL_DWM_REPO"
    find "../${PATCH_PATH}" \
        -type d \
        -mindepth 1 \
        -maxdepth 1 \
        -name "historical" -prune \
        -o -print | while read -r extension; do
            echo "Feature: $(basename "$extension")"

            find "$extension" \
                -type f \
                -name "dwm-*${DWM_VERSION}.diff" \
                | sort \
                | uniq \
                | while read -r patch; do
               
                BASE=$(basename "${patch%.*}")
                PATCH_NAME=$(echo "$BASE" | cut -d '-' -f 2)
                BRANCH_NAME="$PATCH_NAME"
                FEATURE_NAME=$(echo "$BASE" | cut -d '-' -f 3)
                
                [ "$FEATURE_NAME" = "$DWM_VERSION" ] || {
                    BRANCH_NAME="${BRANCH_NAME}_${FEATURE_NAME}"
                }

                EXISTGING_BRANCH=$(git branch -l "$BRANCH_NAME")

                [ "$EXISTGING_BRANCH" = "$BRANCH_NAME" ] && {
                    echo "branch $EXISTGING_BRANCH already present - skipping" 
                    continue
                }

                echo "apply patch $BASE on branch $BRANCH_NAME"
                git checkout -b "$BRANCH_NAME"

                patch -s -t -p1 -F 3 < "$patch" || {
                    echo "Could not apply patch $patch"     
                    echo "returning"
                    exit 1
                }

                git add -A                
                git commit -m "applied patch"
                git checkout origin/master
            done
    done
    return 0
}

prepare_repo
exit 0
