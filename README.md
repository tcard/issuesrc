# issuesrc

**WARNING: very early stage of development. Test at your own risk!**

Synchronize in-source commented tasks with your issue tracker.

issuesrc scans your files looking for comments tagged with labels such as TODO, BUG, FIXME, etc., and adds them your issue tracker.

* Newly found tags **will be opened as issues**. Each ID will be added in the source code, for keeping them in sync.
* From the source code you can change the label or the description of the issue. 
* You can also **appoint an assignee** by putting her username alongside the tag (eg. `TODO(tcard)`; `TODO(tcard#12345)`).
* Synchronization is one-way; changes that you do in the issue tracker will be lost when you run the program again.
* When a tag is removed from the code, it is **closed in the issue tracker**.

## Installation

    $ gem install issuesrc

## Usage

issuesrc connects comments found in source code with an issue tracker. It needs to be configured to talk to both.

Configuration is done both via a .toml config file and via command line arguments. See `example.toml` and run `issuesrc -h` for details.

Currently, issuesrc only supports Git for retrieving source code, and GitHub as issue tracker.

## Contributing

1. Fork it ( https://github.com/tcard/issuesrc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
