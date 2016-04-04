#!/bin/sh
# Simply exercises all of the scripts, rather than calling them each by hand.

set -e # Exit script on any error
set -v # Print each line before execution
# set -x # Expand variables

if [ $# -ne '1' ]; then
  echo "Expects exactly one argument, not $#"
  exit 1
fi

if ! [ "$@" -eq "$@" ]; then
  # -eq only supports integers, and fails otherwise.
  echo "Expects integer argument, not $@"
  exit 1
fi
NAME=$@.wgbh-mla-test.org
JUST_ONE_NAME=one-$NAME

# Without "--unsafe" it requires DNS to be set up, which is one of the last steps in the build,
# ... so this is a little scary, but probably what we want.
# destroy.rb prompts you to re-enter name as confirmation, hence the "echo".
trap "( echo $JUST_ONE_NAME | ruby scripts/destroy.rb --unsafe --name $JUST_ONE_NAME --debug );
      ( echo $NAME          | ruby scripts/destroy.rb --unsafe --name $NAME          --debug )" EXIT

# Trying to run each script without args gives us the doc strings, 
# and is a loose test of our arg parsing.

! ruby scripts/build.rb
ruby scripts/build.rb --name $JUST_ONE_NAME --skip_updates --just_one --debug
ruby scripts/build.rb --name $NAME --skip_updates --debug
ruby scripts/build.rb --name $NAME --skip_updates --setup_load_balancer --debug

! ruby scripts/ssh_opt.rb && ssh `ruby scripts/ssh_opt.rb --name demo.$NAME --debug` 'hostname; whoami'
ruby scripts/ssh_opt.rb --name demo.$NAME --ips_by_dns --debug
ruby scripts/ssh_opt.rb --name $NAME --ips_by_dns --debug # Should differ from the above.
ruby scripts/ssh_opt.rb --name $NAME --ips_by_tag --debug # Should include both.

TARGET=/home/ec2-user/rsync-target

! ruby scripts/sudo.rb && ruby scripts/sudo.rb --name demo.$NAME --command "mkdir $TARGET" --debug
! ruby scripts/swap.rb && ruby scripts/swap.rb --name $NAME --debug
! ruby scripts/rsync.rb && ruby scripts/rsync.rb --name $NAME --path $TARGET --debug
! ruby scripts/group_add.rb && ruby scripts/group_add.rb --user travis_ci --group $NAME --debug
! ruby scripts/list.rb && ruby scripts/list.rb --name $NAME --flat --debug

! ruby scripts/destroy.rb # Real destroy call is in the trap.