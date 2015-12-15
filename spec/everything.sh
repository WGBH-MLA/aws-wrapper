#!/bin/sh
# Simply exercises all of the scripts, rather than calling them each by hand.

NAME=abc.wgbh-mla-test.org

echo $NAME | \ # Provides STDIN which is consumed by destroy.rb.
   ruby scripts/build.rb --name $NAME --skip_updates --debug \
&& ssh `ruby scripts/ssh_opt.rb` 'hostname; whoami'
&& ruby scripts/sudo.rb --name $NAME --command 'hostname; whoami' --debug \
&& ruby scripts/swap.rb --name $NAME --debug \
&& ruby scripts/group_add.rb --user `aws iam get-user | cut -f 7` --group $NAME --debug \
&& ruby scripts/list.rb --name $NAME --debug \
&& ruby scripts/destroy.rb --name $NAME --debug