#!/usr/bin/env bash
# Update BirdNET-JetsonNano's Git Repo
source /etc/birdnet/birdnet.conf
trap 'exit 1' SIGINT SIGHUP

usage() { echo "Usage: $0 [-r <remote name>] [-b <branch name>]" 1>&2; exit 1; }

USER=$(awk -F: '/1000/ {print $1}' /etc/passwd)
HOME=$(awk -F: '/1000/ {print $6}' /etc/passwd)
my_dir=$HOME/BirdNET-JetsonNano/scripts

# Defaults
remote="origin"
branch="main"

while getopts ":r:b:" o; do
  case "${o}" in
    r)
      remote=${OPTARG}
      git -C $HOME/BirdNET-JetsonNano remote show $remote > /dev/null 2>&1
      ret_val=$?

      if [ $ret_val -ne 0 ]; then
        echo "Error: remote '$remote' not found. Add the upstream remote to your repository and try again."
        exit 1
      fi
      ;;
    b)
      branch=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

sudo_with_user () {
  set -x
  sudo -u $USER "$@"
  set +x
}

# Reset current HEAD to remove any local changes
sudo_with_user git -C $HOME/BirdNET-JetsonNano reset --hard

# Fetches latest changes
sudo_with_user git -C $HOME/BirdNET-JetsonNano fetch $remote $branch

# Switches git to specified branch
sudo_with_user git -C $HOME/BirdNET-JetsonNano switch -C $branch --track $remote/$branch

sudo systemctl daemon-reload
sudo ln -sf $my_dir/* /usr/local/bin/

# The script below handles changes to the host system
# Any additions to the updater should be placed in that file.
sudo $my_dir/update_birdnet_snippets.sh
