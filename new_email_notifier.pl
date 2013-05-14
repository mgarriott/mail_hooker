use FindBin;                # locate this script
use lib "$FindBin::Bin/.";  # use the parent directory
use Account;
use YAML ('LoadFile');

my $config_file = $ARGV[1] ? $ARGV[1] : "$FindBin::Bin/config.yml";

my $config = LoadFile($config_file);

my $acct = new Account(
  Server   => 'imap.gmail.com',
  User     => $$config{'user'},
  Password => $$config{'password'},
  Ssl      => 1,
  Uid      => 1,
);

$acct->fetch;
$acct->register_seen;

my $cmd;
-e glob($$config{'sound_file'}) ||
  die "Sound file does not seem to exist. Check $config_file";
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
