package Account;
1;

use Mail::IMAPClient;
use Time::HiRes;

sub new {
  $self = {};

  my %hash = @_[1..$#_];

  $self->{'imap'} = Mail::IMAPClient->new(%hash);
  return bless $self;
}

sub fetch_mail_from_server {
  $self = shift;
  $self->{'imap'}->select('Inbox')
    or die "Select '$Opt{folder}' error: ", $self->{'imap'}->LastError, "\n";

  $self->{'mail'} = $self->{'imap'}->fetch_hash("FLAGS", "INTERNALDATE")
    or die "Fetch mail '$Opt{folder}' error: ", $self->{'imap'}->LastError, "\n";

  $self->{'imap'}->logout
    or die "Logout error: ", $self->{'imap'}->LastError, "\n";
}

sub fetch {
  $self = shift;
  $self->fetch_mail_from_server;
  $self->{'last_updated'} = time();
}

# Return true if the current mail information is outdated, i.e. more than 60
# seconds old.
sub outdated {
  $self = shift;

  if (defined $self->{'last_updated'}) {
    $time_elapsed = time() - $self->{'last_updated'};
    if ($time_elapsed >= 60) {
      return 1;
    } else {
      return 0;
    }
  } else {
    return 1;
  }
}

# Return true if this account has new mail
sub has_new_mail {
  $self = shift;

  if ($self->outdated) {
    $self->fetch;
  }

  my $result = 0;

  foreach(values($self->{'mail'})) {
    if ($self->is_new($_)) {
      $result = 1;
      last;
    }
  }

  return $result;
}

# Return all the message ids
sub get_message_ids {
  $self = shift;

  $keys = ['6999', '7001', '7002'];
  return $keys;
}

# Return all new messages
sub get_new_mail {
  my $self = shift;
  my %result = ();

  foreach(($k, $v) = each($self->{'mail'})) {
    if ($self->is_new($v)) {
      $result{$k} = $v;
    }
  }

  return \%result;
}

# Check if given message is new
sub is_new {
  my $self = shift;
  my $msg = $_[0];
  if ($msg->{"FLAGS"} eq '') {
    return 1;
  } else {
    return 0;
  }
}
