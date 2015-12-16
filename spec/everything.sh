#!/bin/sh
# Simply exercises all of the scripts, rather than calling them each by hand.

if [ $# -ne '1' ]; then
  echo "Expects exactly one argument, not $#"
  exit 1
fi

NAME=$@

# Provides STDIN which is consumed by destroy.rb.
echo $NAME | \
   ruby scripts/build.rb --name $NAME --skip_updates --debug \
&& ssh `ruby scripts/ssh_opt.rb --name demo.$NAME --debug` 'hostname; whoami' \
&& ruby scripts/sudo.rb --name demo.$NAME --command 'hostname; whoami' --debug \
&& ruby scripts/swap_and_rsync.rb --name $NAME --debug \
&& ruby scripts/group_add.rb --user `aws iam get-user | cut -f 7` --group $NAME --debug \
&& ruby scripts/list.rb --name $NAME --flat --debug \
&& ruby scripts/destroy.rb --name $NAME --debug