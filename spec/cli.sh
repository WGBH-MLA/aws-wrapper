#!/bin/sh
# Simply exercises each of the scripts, rather than calling each by hand.

NAME=abc.wgbh-mla-test.org

echo $NAME | ruby scripts/build.rb --name $NAME \
&& ruby scripts/group_add.rb --user `aws iam get-user | cut -f 7` --group $NAME \
&& ruby scripts/sudo.rb --name $NAME --command 'echo "I am sudo"; whoami' \
&& ruby scripts/swap.rb --name $NAME \
&& ruby scripts/destroy.rb --name $NAME