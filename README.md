# aws-wrapper

Scripts for our most common interactions with AWS. 
For documentation on a particular script, run it without arguments.
Typically, bare servers can be set up with:
```
ruby scripts/ec2_elb_start.rb abc.wgbh-mla-test.org
```
and then we can swap them with
```
ruby scripts/elb_swap.rb abc.wgbh-mla-test.org
```

## Organization

| Scripts | Utility Classes | AWS Wrapper | Client Wrappers | Base Wrapper |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| `scripts/elb_swap.rb` | `lib/elb_swapper.rb` | `lib/aws_wrapper.rb` | `lib/elb_wrapper.rb` | `lib/base_wrapper.rb` |
| `scripts/.........rb` | `lib/.........er.rb` |                      | `lib/..._wrapper.rb` |                       |

Each layer should `require` only from the layer immediately below.

- **Scripts** are for use by the end user. Each should be self-documenting if run without other arguments. Scripts are thin wrappers for ...
- **Utility Classes**, each of which defines one interaction with AWS. These classes are the targets of the tests.
- **AWS Wrapper** simply requires all of the Client Wrappers in one place.
- **Client Wrappers** each define the interactions we need for a particular AWS service.
- **Base Wrapper** provides logging and the like.
