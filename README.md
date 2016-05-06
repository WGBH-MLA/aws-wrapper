# aws-wrapper

Scripts for our most common interactions with AWS. 
For documentation on a particular script, run it without arguments.

Before running any of the examples, you will need to have an AWS IAM user,
with your API credentials in the conventional location: `~/.aws/credentials`.

Typically, bare servers can be set up:
```
ruby scripts/build.rb --name abc.wgbh-mla-test.org
```

and load balancers are then created for the pair:
```
ruby scripts/build.rb --name abc.wgbh-mla-test.org --setup_load_balancer
```

The current user is added to the priv group by default,
but another user can be added to the group:
```
ruby scripts/group_add.rb --user someone_else --group abc.wgbh-mla-test.org
```

and then that user can swap them:
```
ruby scripts/swap.rb --name abc.wgbh-mla-test.org
```

and rsync a given directory from live to demo:
```
ruby scripts/rsync.rb --name abc.wgbh-mla-test.org --path /var/www/abc/something
```

log in to the demo machine:
```
ssh `ruby scripts/ssh_opt.rb --name demo.abc.wgbh-mla-test.org`
```

or just get the IPs:
```
ruby scripts/ssh_opt.rb --name demo.abc.wgbh-mla-test.org --ips_by_dns
ruby scripts/ssh_opt.rb --name abc.wgbh-mla-test.org --ips_by_dns
ruby scripts/ssh_opt.rb --name abc.wgbh-mla-test.org --ips_by_tag
```

or for a one-liner:
```
ruby scripts/sudo.rb --name abc.wgbh-mla-test.org --command 'echo "I am sudo"'
```

to get a handle on all the dependent resources:
```
ruby scripts/list.rb --name abc.wgbh-mla-test.org
```

and if this is development and we want to clear the slate:
```
ruby scripts/destroy.rb --name abc.wgbh-mla-test.org
```

## Organization

| Scripts | Utility Classes | AWS Wrapper | Client Wrappers | Base Wrapper |
| ---- | ---- | ---- | ---- | ---- |
| `scripts/elb_swap.rb` | `lib/util/elb_swapper.rb` | `lib/util/aws_wrapper.rb` | `lib/core/elb_wrapper.rb` | `lib/core/base_wrapper.rb` |
| `scripts/.........rb` | `lib/util/.........er.rb` |  | `lib/core/..._wrapper.rb` |  |

Each layer should `require` only from the layer immediately below.

- **Scripts** are for use by the end user. Each should be self-documenting if run without other arguments. Scripts are thin wrappers for ...
- **Utility Classes**, each of which defines one interaction with AWS. These classes are the targets of the tests.
- **AWS Wrapper** simply requires all of the Client Wrappers in one place.
- **Client Wrappers** each define the interactions we need for a particular AWS service.
- **Base Wrapper** provides logging and the like.

## Reference

The scripts create all kinds of interrelated AWS resources. If you want to keep an eye on them
(may need to change region to match yours):

- [EC2s](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:sort=desc:launchTime)
- [Volumes](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Volumes:sort=desc:createTime)
- [Snapshots](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Snapshots:sort=startTime)
- [Key Pairs](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName)
- [CNAMEs](https://console.aws.amazon.com/route53/home?region=us-east-1)
- [ELBs](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:)
- [Groups](https://console.aws.amazon.com/iam/home?region=us-east-1#groups)
