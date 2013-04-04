package Account;
1;

use lib ('/home/matt/.perl5/lib/perl5');
use Mail::IMAPClient;
use Time::HiRes;

sub new {
  $self = {};

  my @conn = @_[1..$#_];
  $self->{'conn'} = \@conn;

  return bless $self;
}

sub fetch_mail_from_server {
  $self = shift;

  $conn = $self->{'conn'};
  my $imap = Mail::IMAPClient->new(@$conn) or die;

  $imap->select('Inbox')
    or die "Select '$Opt{folder}' error: ", $imap->LastError, "\n";

  $self->{'mail'} = $imap->fetch_hash("FLAGS", "INTERNALDATE")
    or die "Fetch mail '$Opt{folder}' error: ", $imap->LastError, "\n";

  $imap->logout
    or die "Logout error: ", $imap->LastError, "\n";
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

  @keys = keys($self->{'mail'});
  return \@keys;
}

# Return all new messages
sub get_new_mail {
  my $self = shift;
  my %result = ();

  while(($k, $v) = each(%{$self->{'mail'}})) {
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

sub has_unseen {
  my $self = shift;

  if (!$self->{'seen'}) {
    # If $self->{'seen'} is undefined return true if there are any new
    # messages
    return $self->has_new_mail;
  } else {
    # Compare new messages hash to seen hash. If they are different return
    # true

    @new_keys = keys(%{$self->get_new_mail});
    @seen_keys = keys(%{$self->{'seen'}});
    foreach(@new_keys) {
      unless ($_ ~~ @seen_keys) {
        return 1;
      }
    }

    return 0;
  }
}

sub register_seen {
  my $self = shift;

  $self->{'seen'} = $self->get_new_mail;
}
