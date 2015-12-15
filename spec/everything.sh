#!/bin/sh
# Simply exercises all of the scripts, rather than calling them each by hand.

NAME=abc.wgbh-mla-test.org

echo $NAME | \ # Provides STDIN which is consumed by destroy.rb.
   ruby scripts/build.rb --name $NAME --skip_updates --debug \
&& ruby scripts/group_add.rb --user `aws iam get-user | cut -f 7` --group $NAME --debug \
&& echo `ruby scripts/ssh_opt.rb` 
&& ruby scripts/sudo.rb --name $NAME --command 'echo "I am sudo"; whoami' --debug \
&& ruby scripts/swap.rb --name $NAME --debug \
&& ruby scripts/destroy.rb --name $NAME --debug