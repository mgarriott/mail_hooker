use strict;
use FindBin;                 # locate this script
use lib "$FindBin::Bin/..";  # use the parent directory
use Account;

use Test::More tests => 26;

my $acct = new Account();

my %fake_mail = (
      '6999' => {
                  'INTERNALDATE' => '27-Feb-2013 01:45:40 +0000',
                  'FLAGS' => '\\Seen'
                },
      '7001' => {
                  'INTERNALDATE' => '27-Feb-2013 02:18:56 +0000',
                  'FLAGS' => '\\Seen'
                }
    );

package Account {
  # Redefine the method that actually retrieves mail from the server. And
  # provide something a bit more controlled.
  sub fetch_mail_from_server {
    $acct->{'mail'} = \%fake_mail;
  };
}

sub outdate_account {
  my $func = $_[0];

  my $time_holder = $acct->{'last_updated'};
  $acct->{'last_updated'} = time() - 61;
  &$func();
  $acct->{'last_updated'} = $time_holder;
}

ok(defined $acct,           'new() returned something');
ok($acct->isa('Account'),   ' and it is the right class');

# Account is outdated when first initialized
ok($acct->outdated, 'Account\'s mail is outdated');

# Fetch sets account as up-to-date
$acct->fetch;
ok(!$acct->outdated, 'Account\'s mail is up-to-date');

# Elapsed time greater than 60 seconds flags account as out of date.
outdate_account(sub { ok($acct->outdated, 'Account is outdated'); });

ok(!$acct->has_new_mail, 'Account does NOT have new mail');

is_deeply($acct->get_new_mail, {},
  'Empty hash returned for get_new_mail if there is no new mail');

ok(!$acct->has_unseen, 'Account doesn\'t have unseen mail if none is new');

$fake_mail{'7002'} = {
                    'INTERNALDATE' => '27-Feb-2013 02:25:56 +0000',
                    'FLAGS' => ''
                  };

ok($acct->has_unseen, 'Account has unseen mail if at least one is new');
ok($acct->has_new_mail, 'Account does have new mail');
is_deeply($acct->get_new_mail, {
                '7002' => {
                      'INTERNALDATE' => '27-Feb-2013 02:25:56 +0000',
                      'FLAGS' => ''
                  },
                },
  'New messages are returned by get_new_mail');

$acct->register_seen;
ok(!$acct->has_unseen, 'Account has no unseen messages after registering');

$fake_mail{'7003'} = {
                    'INTERNALDATE' => '27-Feb-2013 03:25:56 +0000',
                    'FLAGS' => ''
                  };

my $new_mail = $acct->get_new_mail;
is(keys($new_mail), 2, 'There are two new messages returned by get_new_mail()');
is_deeply($new_mail, {
                '7002' => {
                      'INTERNALDATE' => '27-Feb-2013 02:25:56 +0000',
                      'FLAGS' => ''
                  },
                 '7003' => {
                    'INTERNALDATE' => '27-Feb-2013 03:25:56 +0000',
                    'FLAGS' => ''
                  }
                },
  'New messages are returned by get_new_mail even when more than one');

outdate_account(sub { ok($acct->has_new_mail,
      'has_new_mail() fetches if outdated'); });

ok($acct->has_unseen,
  'Account has unseen messages after new message comes in');

$acct->register_seen;
ok(!$acct->has_unseen, 'Account has no unseen messages after registering');

my $ids = $acct->get_message_ids;
is(@$ids, 4, 'get_message_ids returns list of 4 items');
ok('6999' ~~ $ids, 'get_message_ids contains 6999');
ok('7001' ~~ $ids, 'get_message_ids contains 7001');
ok('7002' ~~ $ids, 'get_message_ids contains 7002');
ok('7003' ~~ $ids, 'get_message_ids contains 7003');

ok($acct->is_new($acct->{'mail'}{'7002'}), 'is_new returns true for new mail');
ok(!$acct->is_new($acct->{'mail'}{'7001'}), 'is_new returns false for old mail');

ok(!$acct->has_unseen, 'Account has no unseen messages');
delete($fake_mail{'7003'});
ok(!$acct->has_unseen, 'Account has no unseen messages after deleting one');
