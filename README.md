# travix_auth

Little utility to add haxelib credentials as an ecrypted entry in .travis.yml's environment variable list.

It is supposed to be used with some automated haxelib submission mechanisms, such as `travix_release`


### Prerequisites

This cli requires the travis gem to work.

Install ruby and then run: `gem install travis`

### Usage

```
haxelib run travix auth encrypt <options>
```

options:
```
  --username, -u: (required)
    Haxelib username
  --password, -p: (required)
    Haxelib password
  --repo, -r: (required)
    Github repo in the form of <owner>/<repo>. Example: back2dos/travix
  --add, -a:
    Automatically add an entry to .travis.yml (Refer to travis doc). Will print out the encrypted string if omitted.
```