use strict;
use warnings;
use FindBin;                # locate this script
use lib "$FindBin::Bin/.";  # use the parent directory
use Account;
use YAML ('LoadFile', 'Load');

my $config;

# Check if there is input in STDIN
if (! -t STDIN) {
  my @lines = <STDIN>;
  $config = Load(join('', @lines));
} else {
  $config = LoadFile("$FindBin::Bin/../config.yml");
}

my $acct = new Account(
  Server   => $$config{'server_address'},
  User     => $$config{'user'},
  Password => $$config{'password'},
  Ssl      => 1,
  Uid      => 1,
);

$acct->fetch;
$acct->register_seen;

$$config{'command'} ||
  die "No command provided. Please check your config info.";

# if a command line arg was passed we'll use it as the process ID and kill the
# script when that id is no-longer running. Otherwise we will run until
# explicitly killed.
my $keep_running;
if ($ARGV[0]) {
  # Checks if the process is still running
  $keep_running = sub { kill(0, $ARGV[0]); };
} else {
  $keep_running = sub { return 1; };
}

while (&$keep_running()) {
  $acct->fetch;
  if ($acct->has_unseen) {
    system($$config{'command'});
  }
  $acct->register_seen;
  sleep($$config{'refresh_time'});
}
