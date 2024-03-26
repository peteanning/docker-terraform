export WORKSPACE=~/workdir

. .bash_aliases

# is this an interactive shell?
if [[ $- == *i* ]]; then
    # set up ssh key server
    if [[ -x /usr/bin/keychain ]]; then
        eval $(keychain --eval --ignore-missing the ~/.ssh/peter_anning_gmail)
    fi
fi


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

