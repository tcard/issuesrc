# issuesrc [![Build Status](https://secure.travis-ci.org/tcard/issuesrc.svg?branch=master)](http://travis-ci.org/tcard/issuesrc) [![Gem Version](https://badge.fury.io/rb/issuesrc.svg)](http://badge.fury.io/rb/issuesrc) [![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://www.rubydoc.info/github/tcard/issuesrc/master)

**WARNING: very early stage of development. Test at your own risk!**

Synchronize in-source commented tasks with your issue tracker.

issuesrc scans your files looking for comments tagged with labels such as TODO, BUG, FIXME, etc., and adds them your issue tracker.

* Newly found tags **will be opened as issues**. Each tag will be edited in the source code to add its issue number next to it.
* From the source code you can change the label or the description of the issue. Running the command again will synchronize changes in the repo.
* You can also **appoint an assignee** by putting her username alongside the tag (eg. `TODO(tcard)`; `TODO(tcard#12345)`).
* Synchronization is one-way; changes that you do to a issuesrc issue from the issue tracker will be lost when you run the program again. You should add any further information as comments.
* When a tag is removed from the code, it is **closed in the issue tracker**.

## Installation

    $ gem install issuesrc

## Usage

issuesrc connects comments found in source code with an issue tracker. It needs to be configured to talk to both.

Configuration is done both via a .toml config file and via command line arguments. See [`example.toml`](https://github.com/tcard/issuesrc/blob/master/example.toml) and run `issuesrc -h` for details.

Currently, issuesrc only supports Git for retrieving source code, and GitHub as issue tracker.

The easiest way to get started would be something like this:

    $ issuesrc --repo youruser/yourrepo --github-token xxxxxxxxxxx

That will extract tasks from the comments at github.com/youruser/yourrepo, open issues for them, add each issue's number next to its comment, and commit and push the changes. (You will thus need to have push access from the environment you run this command in.)

## Contributing

1. Fork it ( https://github.com/tcard/issuesrc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
