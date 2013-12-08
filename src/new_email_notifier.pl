use FindBin;                # locate this script
use lib "$FindBin::Bin/.";  # use the parent directory
use Account;
use YAML ('LoadFile', 'Load');


my $config;
if ($ARGV[1]) {
  $config = Load($ARGV[1] . "\n");
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

my $cmd;
-e glob($$config{'sound_file'}) ||
  die "Sound file does not seem to exist. Check provided config info.";
if ($$config{'sound_file'} =~ /\.(wav|flac)$/) {
  $cmd = 'aplay';
} elsif ($$config{'sound_file'} =~ /\.mp3$/) {
  $cmd = 'mpg123';
} else {
  $cmd = 'ogg123';
}

# if a command line arg was passed we'll use it as the mutt ID and kill the
# script when that id is no-longer running. Otherwise we will run until
# specifically killed.
my $keep_running;
if ($ARGV[0]) {
  # Checks if the mutt process is still running
  $keep_running = sub { kill(0, $ARGV[0]); };
} else {
  $keep_running = sub { return 1; };
}

while (&$keep_running()) {
  $acct->fetch;
  if ($acct->has_unseen) {
    system("$cmd $$config{'sound_file'} 2&> /dev/null");
  }
  $acct->register_seen;
  sleep($$config{'refresh_time'});
}
