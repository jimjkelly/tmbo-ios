This isn't finished yet. It's barely even started.

Cloning
=======

This project contains multiple git submodules. After cloning this repo, you'll need to run `git submodule update --init` to get them.

In the absence of a working login mechanism, when you run the app for the first time it will break near where you're supposed to insert your token. Remember to run it once and then revert the file so you don't accidentally check in a token. They're easy to revoke, but they're also SCM clutter.

Submodules
----------
* Peter Hosey's [ISO 8601 Date Formatter](https://github.com/boredzo/iso-8601-date-formatter)
* Mattt Thompson's [AFNetworking](https://github.com/AFNetworking/AFNetworking)

License
=======
TMBO: The App! is available under the MIT license. See the LICENSE file for more info.
