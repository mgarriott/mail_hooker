# MailHooker #

MailHooker is small utility, written in perl, that allows a user to hook a
command to execute when new email is received.

## Dependencies ##

- Perl v5.18 or greater *May be work with older versions, but no promises*
- [Mail::IMAPClient](http://search.cpan.org/~plobbes/Mail-IMAPClient-3.35/)
- [Perl YAML](http://search.cpan.org/dist/YAML/)

## Configuration ##

At the root of the project is a file named config.yml.sample. Edit the
settings to meet your needs, and rename the file to config.yml.

Seeing as how the config.yml file contains your account information, I would
advise changing the file permissions to prevent other user's from reading it.

    chmod 600 config.yml

If this solution isn't secure enough for you, see below for a solution
involving encryption with gpg.

## Running the Script ##

**Before running the script, ensure that all dependencies are installed**

### Using the Standard Config.yml Location ###

If you've created your config.yml file in the project's root directory, you
can run the script with:

    perl /path/to/mail_hooker/src/mail_hooker.pl

### Using a Non-Standard Config File Location ###

If STDIN is provided, MailHooker will assume this is your configuration. Thus,
if you'd like to create your configuration file in a non-standard location you
can do so with the following:

    perl /path/to/mail_hooker/src/mail_hooker.pl < /path/to/my/config.yml

### Running Alongside Another Application ###

MailHooker can be tied into the process ID of another command. If the other
command finishes, or is killed, MailHooker will detect this and exit. This
feature allows a user to run MailHooker as though it were dependant on
another program.

For example, if you only want MailHooker to run when you are using mutt,
you could create the following wrapper script:

    #!/usr/bash

    # Enable job control so that we can use 'fg'
    set -m

    # Start the mutt email client
    mutt &

    mutt_pid=$!
    perl /path/to/mail_hooker/src/mail_hooker.pl $mutt_pid &

    fg 1 # Bring mutt to the foreground (our first job)

When you run this script, mutt will open with MailHooker in the background.
When mutt is closed, MailHooker will stop automatically.

### Encrypting Your Config File with GPG ###

If you are a real security stickler, you can encrypt your config file with
GPG, and run the decrypter when calling MailHooker.

    gpg --batch -d config.yml.gpg | perl src/mail_hooker.pl

GPG will prompt you for your password, and then pass the decrypted file
straight into MailHooker.

## Contributing ##

If you are interesting in contributing to MailHooker please ensure your
commits follow a few simple guidelines.

- Write tests, both for new functionality and for bug fixes.
- Avoid trailing whitespace.
- Format commit messages in the imperative present tense.

## License ##

BSD 2-Clause (see LICENSE file).
