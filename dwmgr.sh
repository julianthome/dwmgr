# Configuration parameters
PERSONAL_DWM_REPO="my-dwm"
PATCHES_PATH="patches"
DWM_URL="dwm.suckless.org"
PATCH_PATH="${DWM_URL}/${PATCHES_PATH}"
PATCHES_URL="https://${PATCH_PATH}/"
DWM_VERSION="6.2"

function clone_repo() { 
    [ -d "$PERSONAL_DWM_REPO" ] || {
        git clone https://git.suckless.org/dwm --depth 1 "$PERSONAL_DWM_REPO"
    }
}

function download_patches() {
    wget -q --recursive ‐-mirror \
        --wait=15 --limit-rate=50K \
        --domains "${DWM_URL}" --no-parent "${PATCHES_URL}"
}

function prepare_repo() { 
    clone_repo
    cd "$PERSONAL_DWM_REPO"
    find "../${PATCH_PATH}" \
        -type d \
        -mindepth 1 \
        -maxdepth 1 \
        -name "historical" -prune \
        -o -print | while read -r extension; do
            echo "Feature: $(basename $extension)"

            find "$extension" -type f -name "dwm-*${DWM_VERSION}.diff" \
                | sort | uniq | while read -r patch; do
                echo "Patch: $patch"
                BASE=$(basename ${patch%.*})
                PATCH_NAME=$(echo $BASE | cut -d '-' -f 2)
                BRANCH_NAME="$PATCH_NAME"
                FEATURE_NAME=$(echo $BASE | cut -d '-' -f 3 | grep -v "$DWM_VERSION")
                [ -n "$FEATURE_NAME" ] && {
                    BRANCH_NAME="${BRANCH_NAME}_${FEATURE_NAME}"
                }
                echo "$BRANCH_NAME" 
                git checkout -b "$BRANCH_NAME"
                git apply $patch || exit 1
                git checkout origin/master
                #BRANCH=$(echo $BASE  | tr -d '.' | tr '/' '_')
                #echo "Branch: $BRANCH"
            done
    done
}

prepare_repo
exit 0
