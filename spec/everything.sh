#!/bin/sh
# Simply exercises all of the scripts, rather than calling them each by hand.

set -e # Exit script on any error
set -v # Print each line before execution
# set -x # Expand variables

if [ $# -ne '1' ]; then
  echo "Expects exactly one argument, not $#"
  exit 1
fi

N=$@
echo $N | egrep '^\d+$' || ( echo "Expects integer argument, not $N" && exit 1 )
NAME=$N.wgbh-mla-test.org

# Without "--unsafe" it requires DNS to be set up, which is one of the last steps in the build,
# ... so this is a little scary, but probably what we want.
# destroy.rb prompts you to re-enter name as confirmation, hence the "echo".
trap "echo $NAME | ruby scripts/destroy.rb --unsafe --name $NAME --debug" EXIT

# Trying to run each script without args gives us the doc strings, 
# and is a loose test of our arg parsing.

! ruby scripts/build.rb && ruby scripts/build.rb --name $NAME --skip_updates --debug
! ruby scripts/build.rb && ruby scripts/build.rb --name $NAME --skip_updates --setup_load_balancer --debug

! ruby scripts/ssh_opt.rb && ssh `ruby scripts/ssh_opt.rb --name demo.$NAME --debug` 'hostname; whoami'
! ruby scripts/sudo.rb && ruby scripts/sudo.rb --name demo.$NAME --command 'hostname; whoami' --debug
! ruby scripts/swap_and_rsync.rb && ruby scripts/swap_and_rsync.rb --name $NAME --debug
! ruby scripts/group_add.rb && ruby scripts/group_add.rb --user travis_ci --group $NAME --debug
! ruby scripts/list.rb && ruby scripts/list.rb --name $NAME --flat --debug