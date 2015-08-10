#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::exchange::2010::local::mode::activesyncmailbox;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::2010::activesyncmailbox;

my %threshold = ('warning' => 'warning', 'critical' => 'critical');

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "remote-host:s"       => { name => 'remote_host', },
                                  "remote-user:s"       => { name => 'remote_user', },
                                  "remote-password:s"   => { name => 'remote_password', },
                                  "no-ps"               => { name => 'no_ps', },
                                  "timeout:s"           => { name => 'timeout', default => 50 },
                                  "command:s"           => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "ps-exec-only"        => { name => 'ps_exec_only', },
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical', },
                                  "mailbox:s"           => { name => 'mailbox', },
                                  "password:s"          => { name => 'password', },
                                  "no-trust-ssl"        => { name => 'no_trust_ssl', },
                                });
    $self->{thresholds} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{mailbox}) || $self->{option_results}->{mailbox} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--mailbox' option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{password}) || $self->{option_results}->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--password' option.");
        $self->{output}->option_exit();
    }
    foreach my $th (keys %threshold) {
        next if (!defined($self->{option_results}->{$th}));
        if ($self->{option_results}->{$th} !~ /^(\!=|=){0,1}(.*){0,1}/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold for option '--" . $th . "': " . $self->{option_results}->{$th});
            $self->{output}->option_exit();
        }
        
        my $operator = defined($1) && $1 ne '' ? $1 : '!=';
        my $state = defined($2) && $2 ne '' ? $2 : 'Success';
        $self->{thresholds}->{$th} = { state => $state, operator => $operator, out => $threshold{$th} };
    }
}

sub run {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::exchange::2010::activesyncmailbox::get_powershell(remote_host => $self->{option_results}->{remote_host},
                                                                                             remote_user => $self->{option_results}->{remote_user},
                                                                                             remote_password => $self->{option_results}->{remote_password},
                                                                                             mailbox => $self->{option_results}->{mailbox},
                                                                                             password => $self->{option_results}->{password}, 
                                                                                             no_ps => $self->{option_results}->{no_ps},
                                                                                             no_trust_ssl => $self->{option_results}->{no_trust_ssl}
                                                                                             );
    $self->{option_results}->{command_options} .= " " . $ps;
    my ($stdout) = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                            timeout => $self->{option_results}->{timeout},
                                                            command => $self->{option_results}->{command},
                                                            command_path => $self->{option_results}->{command_path},
                                                            command_options => $self->{option_results}->{command_options});
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    centreon::common::powershell::exchange::2010::activesyncmailbox::check($self, stdout => $stdout, mailbox => $self->{option_results}->{mailbox});
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check activesync to a mailbox.

=over 8

=item B<--remote-host>

Open a session to the remote-host (fully qualified host name). --remote-user and --remote-password are optional

=item B<--remote-user>

Open a session to the remote-host with authentication. This also needs --remote-host and --remote-password.

=item B<--remote-password>

Open a session to the remote-host with authentication. This also needs --remote-user and --remote-host.

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-exec-only>

Print powershell output.

=item B<--warning>

Warning threshold
(If set without value, it's: "!=Success". Need to change if your not US language.
Regexp can be used)

=item B<--critical>

Critical threshold
(If set without value, it's: "!=Success". Need to change if your not US language.
Regexp can be used)

=item B<--mailbox>

Set the mailbox to check (Required).

=item B<--password>

Set the password for the mailbox (Required).

=item B<--no-trust-ssl>

By default, SSL certificate validy is not checked.

=back

=cut