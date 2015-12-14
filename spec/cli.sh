#!/bin/sh
# Simply exercises each of the scripts, rather than calling each by hand.

ruby scripts/build.rb --name abc.wgbh-mla-test.org \
&& ruby scripts/group_add.rb --user `aws iam get-user | cut -f 7` --group abc.wgbh-mla-test.org \
&& ruby scripts/sudo.rb --name abc.wgbh-mla-test.org --command 'echo "I am sudo"; whoami' \
&& ruby scripts/swap.rb --name abc.wgbh-mla-test.org \
&& ruby scripts/destroy.rb --name abc.wgbh-mla-test.org