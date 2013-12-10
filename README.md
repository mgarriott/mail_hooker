# MailHooker #

MailHooker is a small Perl utility that allows a user to "hook" a command to
execute when new email messages are received.

## Dependencies ##

- Perl v5.18 or greater *May work with older versions, but no promises*
- [Mail::IMAPClient](http://search.cpan.org/~plobbes/Mail-IMAPClient-3.35/)
- [IO::Socket::SSL](http://search.cpan.org/~sullr/IO-Socket-SSL-1.962/) *For
  SSL / TLS*
- [Perl YAML](http://search.cpan.org/dist/YAML/)

*If you are running Arch Linux, the AUR has packages for these dependencies*

## Configuration ##

At the root of the project is a file named `config.yml.sample`. Edit the
settings to meet your needs, and rename the file to `config.yml`.

Since the `config.yml` file contains your account information, I would advise
changing its permissions to prevent other users from reading it.

    chmod 600 config.yml

If this solution isn't secure enough for you, see below for a solution
involving encryption with GnuPG.

## Running the Script ##

**Before running the script, ensure that all dependencies are installed**

### Using the Standard Config.yml Location ###

If you've created your `config.yml` file in the project's root directory, you
can run the script with:

    perl /path/to/mail_hooker/src/mail_hooker.pl

### Using a Non-Standard Config File Location ###

If `STDIN` is provided, MailHooker will assume this is your configuration.
Thus, if you'd like to create your configuration file in a non-standard
location, run MailHooker with the following:

    perl /path/to/mail_hooker/src/mail_hooker.pl < /path/to/my/config.yml

### Running Alongside Another Application ###

MailHooker can be tied into the process ID of another command. If the other
command finishes, or is killed, MailHooker will detect this and exit. This
feature allows a user to run MailHooker as though it were dependant on
another program.

For example, if you only want MailHooker to run when you are using Mutt,
you could create the following wrapper script:

    #!/bin/bash

    # Enable job control so that we can use 'fg'
    set -m

    # Start the Mutt email client
    mutt &

    mutt_pid=$!
    perl /path/to/mail_hooker/src/mail_hooker.pl $mutt_pid &

    fg 1 # Bring Mutt to the foreground (our first job)

When you run this script, Mutt will open with MailHooker running in the
background. When Mutt is closed, MailHooker will stop automatically.

### Encrypting Your Config File with GnuPG ###

If you are a real security stickler, you can encrypt your config file with
GnuPG, and decrypt the data before passing it to MailHooker.

    gpg --batch -d config.yml.gpg | perl src/mail_hooker.pl

GnuPG will prompt you for your password, and then pass the decrypted config
data straight into MailHooker.

## Contributing ##

If you are interested in contributing to MailHooker please ensure your commits
follow a few simple guidelines.

- Write tests, both for new functionality and for bug fixes.
- Avoid trailing whitespace.
- Format commit messages in the imperative present tense.

## License ##

BSD 2-Clause (see LICENSE file).
