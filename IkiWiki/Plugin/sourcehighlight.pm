#!/usr/bin/perl
# outline markup

# Hacked by David Bremner from otl.pm by Joey Hess
# GPL2+
package IkiWiki::Plugin::sourcehighlight;

use warnings;
use strict;
use IkiWiki 2.00;

sub import { #{{{
	hook(type => "getopt", id => "tag", call => \&getopt);
	hook(type => "checkconfig", id => "sourcehightlight", call => \&checkconfig);
} # }}}

sub getopt () { #{{{
	eval q{use Getopt::Long};
	error($@) if $@;
	Getopt::Long::Configure('pass_through');
	GetOptions("highlight-lang=s" => \$config{highlight_lang});
} #}}}


sub checkconfig(@){
    debug("got checkconfig");
    if (!defined $config{highlight_lang}){
	error(gettext("sourcehightlight plugin will not without defining highlight_lang"));
    }

    my @langs=split(",",$config{highlight_lang});

    foreach my $lang (@langs){
	# we should check these for validity
	hook(type => "htmlize", no_override => 1, id => $lang,
	     call => sub { htmlize(lang=>$lang, @_) });
    }

}
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
