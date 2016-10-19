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

message()
{
  echo "travis_fold:end:$LAST"
  echo
  echo '######################'
  echo '#'
  echo '#' $1
  echo '#'
  echo '######################'
  echo
  echo "travis_fold:start:$1"
  LAST=$1
}

# Without "--unsafe" it requires DNS to be set up, which is one of the last steps in the build,
# ... so this is a little scary, but probably what we want.
# destroy.rb prompts you to re-enter name as confirmation, hence the "echo".
trap "message 'cleanup';
      ( echo $JUST_ONE_NAME | bundle exec scripts/destroy.rb --unsafe --name $JUST_ONE_NAME --debug );
      ( echo $NAME          | bundle exec scripts/destroy.rb --unsafe --name $NAME          --debug );
      echo travis_fold:end:cleanup" EXIT


# Trying to run each script without args gives us the doc strings, 
# and is a loose test of our arg parsing.

message 'build.rb'
! bundle exec scripts/build.rb
bundle exec scripts/build.rb --name $JUST_ONE_NAME --skip_updates --just_one --debug
bundle exec scripts/build.rb --name $NAME --skip_updates --debug
bundle exec scripts/build.rb --name $NAME --setup_load_balancer --debug

message 'ssh_opt.rb'
! bundle exec scripts/ssh_opt.rb && ssh `bundle exec scripts/ssh_opt.rb --name demo.$NAME --debug` 'hostname; whoami'
bundle exec scripts/ssh_opt.rb --name demo.$NAME --ips_by_dns --debug
bundle exec scripts/ssh_opt.rb --name $NAME --ips_by_dns --debug # Should differ from the above.
bundle exec scripts/ssh_opt.rb --name $NAME --ips_by_tag --debug # Should include both.

TARGET=/home/ec2-user/rsync-target

message 'sudo.rb'
! bundle exec scripts/sudo.rb && bundle exec scripts/sudo.rb --name demo.$NAME --command "mkdir $TARGET" --debug
message 'stop.rb'
! bundle exec scripts/stop.rb && bundle exec scripts/stop.rb --name demo.$NAME
message 'start.rb'
! bundle exec scripts/start.rb && bundle exec scripts/start.rb --name demo.$NAME
message 'swap.rb'
! bundle exec scripts/swap.rb && bundle exec scripts/swap.rb --name $NAME --debug
message 'rsync.rb'
! bundle exec scripts/rsync.rb && bundle exec scripts/rsync.rb --name $NAME --path $TARGET --debug
message 'group_add.rb'
! bundle exec scripts/group_add.rb && bundle exec scripts/group_add.rb --user travis_ci --group $NAME --debug
message 'list.rb'
! bundle exec scripts/list.rb && bundle exec scripts/list.rb --name $NAME --flat --debug
message 'destroy.rb'
! bundle exec scripts/destroy.rb # This will fail, and trap will clean up. 