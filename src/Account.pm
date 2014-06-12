package Account;
1;

use strict;
use warnings;
use Mail::IMAPClient;
use Time::HiRes;

sub new {
  my $self = {};

  my @conn = @_[1..$#_];
  $self->{'conn'} = \@conn;

  return bless $self;
}

sub fetch_mail_from_server {
  my $self = shift;

  my $conn = $self->{'conn'};
  my $imap = Mail::IMAPClient->new(@$conn) or return 0;

  $imap->select('Inbox')
    or die "Select 'Inbox' error: ", $imap->LastError, "\n";

  $self->{'mail'} = $imap->fetch_hash("FLAGS", "INTERNALDATE")
    or die "Fetch mail error: ", $imap->LastError, "\n";

  $imap->logout
    or die "Logout error: ", $imap->LastError, "\n";
}

sub fetch {
  my $self = shift;
  my $result = $self->fetch_mail_from_server;
  $self->{'last_updated'} = time();
  return $result;
}

# Return true if the current mail information is outdated, i.e. more than 60
# seconds old.
sub outdated {
  my $self = shift;

  if (defined $self->{'last_updated'}) {
    my $time_elapsed = time() - $self->{'last_updated'};
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
  my $self = shift;

  if ($self->outdated) {
    $self->fetch;
  }

  my $result = 0;

  foreach(values(%{ $self->{'mail'} })) {
    if ($self->is_new($_)) {
      $result = 1;
      last;
    }
  }

  return $result;
}

# Return all the message ids
sub get_message_ids {
  my $self = shift;

  my @keys = keys(%{ $self->{'mail'} });
  return \@keys;
}

# Return all new messages
sub get_new_mail {
  my $self = shift;
  my %result = ();

  while((my $k, my $v) = each(%{$self->{'mail'}})) {
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

    my @new_keys = keys(%{$self->get_new_mail});
    my @seen_keys = keys(%{$self->{'seen'}});

    # I understand that smartsearch is experimental, and I don't wish to be
    # reminded...
    no warnings;
    foreach(@new_keys) {
      unless ($_ ~~ @seen_keys) {
        return 1;
      }
    }
    use warnings;

    return 0;
  }
}

sub register_seen {
  my $self = shift;

  $self->{'seen'} = $self->get_new_mail;
}
