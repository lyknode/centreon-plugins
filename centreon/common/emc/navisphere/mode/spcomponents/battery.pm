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

package centreon::common::emc::navisphere::mode::spcomponents::battery;

use strict;
use warnings;

my @conditions = (
    ['^(Not Ready|Testing|Unknown)$' => 'WARNING'],
    ['^(?!(Present|Valid)$)' => 'CRITICAL'],
);

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking batteries");
    $self->{components}->{battery} = {name => 'battery', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'battery'));
    
    # SPS means = Standby Power Supply
    
    # Enclosure SPE SPS A State:  Present
    while ($self->{response} =~ /^(?:Bus\s+(\d+)\s+){0,1}Enclosure\s+(\S+)\s+(SPS)\s+(\S+)\s+State:\s+(.*)$/mgi) {
        my ($state, $instance) = ($5, "$2.$3.$4");
        if (defined($1)) {
            $instance = "$1.$2.$3.$4";
        }
        
        next if ($self->check_exclude(section => 'battery', instance => $instance));
        $self->{components}->{battery}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("Battery '%s' state is %s.",
                                                        $instance, $state)
                                    );
        foreach (@conditions) {
            if ($state =~ /$$_[0]/i) {
                $self->{output}->output_add(severity =>  $$_[1],
                                            short_msg => sprintf("Battery '%s' state is %s",
                                                        $instance, $state));
                last;
            }
        }
    }
}

1;
