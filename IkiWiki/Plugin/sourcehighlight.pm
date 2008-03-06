#!/usr/bin/perl
# outline markup

# Hacked by David Bremner from otl.pm by Joey Hess
# GPL2+
package IkiWiki::Plugin::sourcehighlight;

use warnings;
use strict;
use IkiWiki 2.00;

sub import { #{{{
    	hook(type => "htmlize", id => "java", call => \&htmlize);
} # }}}


sub htmlize (@) { #{{{
	my %params=@_;

	# it is not clear that source-hightlight needs this, copied straight from
	# otl
	## Can't use open2 since otl2html doesn't play nice with buffering.
	## Instead, fork off a child process that will run otl2html and feed
	## it the content. Then read otl2html's response.

	my $tries=10;
	my $pid;
	do {
		$pid = open(KID_TO_READ, "-|");
		unless (defined $pid) {
			$tries--;
			if ($tries < 1) {
				debug("failed to fork: $@");
				return $params{content};
			}
		}
	} until defined $pid;

	if (! $pid) {
		$tries=10;
		$pid=undef;

		do {
			$pid = open(KID_TO_WRITE, "|-");
			unless (defined $pid) {
				$tries--;
				if ($tries < 1) {
					debug("failed to fork: $@");
					print $params{content};
					exit;
				}
			}
		} until defined $pid;

		if (! $pid) {
			if (! exec 'source-highlight', '--src-lang=java',  '--output=STDOUT') {
				debug("failed to run source-highlight: $@");
				print $params{content};
				exit;
			}
		}

		print KID_TO_WRITE $params{content};
		close KID_TO_WRITE;
		waitpid $pid, 0;
		exit;
	}
	
	local $/ = undef;
	my $ret=<KID_TO_READ>;
	close KID_TO_READ;
	waitpid $pid, 0;

	return $ret;
} # }}}

1
