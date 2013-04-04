use FindBin;                # locate this script
use lib "$FindBin::Bin/.";  # use the parent directory
use Account;
use YAML ('LoadFile');

my $config = LoadFile("$FindBin::Bin/config.yml");

my $acct = new Account(
  Server   => 'imap.gmail.com',
  User     => $$config{'user'},
  Password => $$config{'password'},
  Ssl      => 1,
  Uid      => 1,
);

$acct->fetch;
$acct->register_seen;

while (kill(0, $ARGV[0])) { # While the mutt process is still running...
  $acct->fetch;
  if ($acct->has_unseen) {
    system('aplay ~/bin/finished.wav 2&> /dev/null');
  }
  $acct->register_seen;
  sleep($$config{'refresh_time'});
}
