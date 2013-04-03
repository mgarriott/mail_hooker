use strict;
use FindBin;                 # locate this script
use lib "$FindBin::Bin/..";  # use the parent directory
use Account;

use Test::More tests => 16;

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

$fake_mail{'7002'} = {
                    'INTERNALDATE' => '27-Feb-2013 02:25:56 +0000',
                    'FLAGS' => ''
                  };

ok($acct->has_new_mail, 'Account does have new mail');
is_deeply($acct->get_new_mail, {
                '7002' => {
                      'INTERNALDATE' => '27-Feb-2013 02:25:56 +0000',
                      'FLAGS' => ''
                  },
                },
  'New messages are returned by get_new_mail');

outdate_account(sub { ok($acct->has_new_mail,
      'has_new_mail() fetches if outdated'); });

my $ids = $acct->get_message_ids;
is(@$ids, 3, 'get_message_ids returns list of 3 items');
ok('6999' ~~ $ids, 'get_message_ids contains 6999');
ok('7001' ~~ $ids, 'get_message_ids contains 7001');
ok('7002' ~~ $ids, 'get_message_ids contains 7002');

ok($acct->is_new($acct->{'mail'}{'7002'}), 'is_new returns true for new mail');
ok(!$acct->is_new($acct->{'mail'}{'7001'}), 'is_new returns false for old mail');
