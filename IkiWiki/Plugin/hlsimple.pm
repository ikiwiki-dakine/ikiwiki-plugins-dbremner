#!/usr/bin/perl
# markup source files
# based on sourcecode.pm, Originally by Will Uther
# from http://ikiwiki.info/todo/automatic_use_of_syntax_plugin_on_source_code_files/discussion/
# 2009/02/03

package IkiWiki::Plugin::hlsimple;

use warnings;
use strict;
use IkiWiki 2.00;
use IkiWiki::Plugin::meta;
use open qw{:utf8 :std};

use Syntax::Highlight::Engine::Simple;


sub import {
    hook(type => "getsetup", id => "hlsimple", call => \&getsetup);
    hook(type => "checkconfig", id => "hlsimple", call => \&checkconfig);
    hook(type => "scan", id => "hlsimple", call => \&scan);
}

sub getsetup () {
    return 
        plugin => {
            safe => 1,
            rebuild => 1, # format plugin
        },
        hlsimple_lang => {
            type => "string",
            example => "{ c=>C,cpp=>Cpp,h=>C,java=>Java }",
            description => "hash mapping suffixes to subclasses of Syntax::Highlight::Engine::Simple",
            safe => 1,
            rebuild => 1,
        },
        hlsimple_css => {
            type => "string",
            example => "hlsimple_style",
            description => "page to use as css file for source",
            safe => 1,
            rebuild => 1,
        },
}

sub checkconfig () {
    if (! $config{hlsimple_lang}) {
	$config{hlsimple_lang}=();
    }

    if (! $config{hlsimple_css}) {
        $config{hlsimple_css} = "hlsimple_style";
    }


    foreach my $key (keys %{$config{hlsimple_lang}}){

	my $highlighter=
	    Syntax::Highlight::Engine::Simple->new(
		type=>$config{hlsimple_lang}->{$key}) || error($@);

	hook(type => "htmlize", id => $key, no_override=>1,
	     call => sub { htmlize(highlighter=>$highlighter, @_) }, 
	     keepextension => 1);
    }
}

sub htmlize (@) {
    my %params=@_;

    my $page = $params{page};

    # the array context is needed to trick meta into actually
    # processing the stylesheet request
    my @discard=(IkiWiki::Plugin::meta::preprocess(stylesheet=> $config{hlsimple_css}, 
				      page=>$page, rel=>"stylesheet"));

    my $highlighter=$params{highlighter};

    return '<div id="hlsimple"><pre>'."\r\n".$highlighter->doStr(str=>$params{content})."\n</pre></div>\r\n";
}

sub scan (@) {
    my %params=@_;

    my $page=$params{page};

}

1

