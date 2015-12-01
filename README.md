# aws-wrapper

Scripts for our most common interactions with AWS. 
For documentation on a particular script, run it without arguments.
Typically, bare servers can be set up with:
```
ruby scripts/ec2_elb_start.rb --name abc.wgbh-mla-test.org
```
and then we can swap them with
```
ruby scripts/elb_swap.rb --name abc.wgbh-mla-test.org
```

## Organization

| Scripts | Utility Classes | AWS Wrapper | Client Wrappers | Base Wrapper |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| `scripts/elb_swap.rb` | `lib/util/elb_swapper.rb` | `lib/util/aws_wrapper.rb` | `lib/core/elb_wrapper.rb` | `lib/core/base_wrapper.rb` |
| `scripts/.........rb` | `lib/util/.........er.rb` |                           | `lib/core/..._wrapper.rb` |                            |

Each layer should `require` only from the layer immediately below.

- **Scripts** are for use by the end user. Each should be self-documenting if run without other arguments. Scripts are thin wrappers for ...
- **Utility Classes**, each of which defines one interaction with AWS. These classes are the targets of the tests.
- **AWS Wrapper** simply requires all of the Client Wrappers in one place.
- **Client Wrappers** each define the interactions we need for a particular AWS service.
- **Base Wrapper** provides logging and the like.

## Cleanup

When you're developing, you'll be creating a lot of instances that need to be cleaned up.
Keep an eye on these pages:

- [EC2s](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:sort=desc:launchTime)
- [Volumes](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Volumes:sort=desc:createTime)
- [Key Pairs](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName)
- [CNAMEs](https://console.aws.amazon.com/route53/home?region=us-east-1)
- [ELBs](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:)
