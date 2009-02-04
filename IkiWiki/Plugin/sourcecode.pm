#!/usr/bin/perl
# markup source files
# Originally by Will Uther
# from http://ikiwiki.info/todo/automatic_use_of_syntax_plugin_on_source_code_files/discussion/
# 2009/02/03
package IkiWiki::Plugin::sourcecode;

use warnings;
use strict;
use IkiWiki 2.00;
use open qw{:utf8 :std};

my %metaheaders;

sub import {
    hook(type => "getsetup", id => "sourcecode", call => \&getsetup);
    hook(type => "checkconfig", id => "sourcecode", call => \&checkconfig);
    hook(type => "pagetemplate", id => "sourcecode", call => \&pagetemplate);
}

sub getsetup () {
    return 
        plugin => {
            safe => 1,
            rebuild => 1, # format plugin
        },
        sourcecode_command => {
            type => "string",
            example => "/usr/bin/source-highlight",
            description => "The command to execute to run source-highlight",
            safe => 0,
            rebuild => 1,
        },
        sourcecode_lang => {
            type => "string",
            example => "c,cpp,h,java",
            description => "Comma separated list of suffixes to recognise as source code",
            safe => 1,
            rebuild => 1,
        },
        sourcecode_linenumbers => {
            type => "boolean",
            example => 1,
            description => "Should we add line numbers to the source code",
            safe => 1,
            rebuild => 1,
        },
        sourcecode_css => {
            type => "string",
            example => "sourcecode_style",
            description => "page to use as css file for source",
            safe => 1,
            rebuild => 1,
        },
}

sub checkconfig () {
    if (! $config{sourcecode_lang}) {
        error("The sourcecode plugin requires a list of suffixes in the 'sourcecode_lang' config option");
    }

    if (! $config{sourcecode_command}) {
        $config{sourcecode_command} = "source-highlight";
    }

    if (! length `which $config{sourcecode_command} 2>/dev/null`) {
        error("The sourcecode plugin is unable to find the $config{sourcecode_command} command");
    }

    if (! $config{sourcecode_css}) {
        $config{sourcecode_css} = "sourcecode_style";
    }

    if (! defined $config{sourcecode_linenumbers}) {
        $config{sourcecode_linenumbers} = 1;
    }

    my %langs = ();

    open(LANGS, "$config{sourcecode_command} --lang-list|");
    while (<LANGS>) {
        if ($_ =~ /(\w+) = .+\.lang/) {
            $langs{$1} = 1;
        }
    }
    close(LANGS);

    foreach my $lang (split(/[, ]+/, $config{sourcecode_lang})) {
        if ($langs{$lang}) {
            hook(type => "htmlize", id => $lang, call => \&htmlize, keepextension => 1);
        } else {
            error("Your installation of source-highlight cannot handle sourcecode language $lang!");
        }
    }
}

sub htmlize (@) {
    my %params=@_;

    my $page = $params{page};

    eval q{use FileHandle};
    error($@) if $@;
    eval q{use IPC::Open2};
    error($@) if $@;

    local(*SPS_IN, *SPS_OUT);  # Create local handles

    my @args;

    if ($config{sourcecode_linenumbers}) {
        push @args, '--line-number= ';
    }

    my $pid = open2(*SPS_IN, *SPS_OUT, $config{sourcecode_command},
                    '-s', IkiWiki::pagetype($pagesources{$page}),
                    '-c', $config{sourcecode_css}, '--no-doc',
                    '-f', 'xhtml',
                    @args);

    error("Unable to open $config{sourcecode_command}") unless $pid;

    print SPS_OUT $params{content};
    close SPS_OUT;

    my @html = <SPS_IN>;
    close SPS_IN;

    waitpid $pid, 0;

    my $stylesheet=bestlink($page, $config{sourcecode_css}.".css");
    if (length $stylesheet) {
        push @{$metaheaders{$page}}, '<link href="'.urlto($stylesheet, $page).'"'.
            ' rel="stylesheet"'.
            ' type="text/css" />';
    }

    return '<div id="sourcecode">'."\r\n".join("\r\n",@html)."\r\n</div>\n";
}

sub pagetemplate (@) {
    my %params=@_;

    my $page=$params{page};
    my $template=$params{template};

    if (exists $metaheaders{$page} && $template->query(name => "meta")) {
        # avoid duplicate meta lines
        my %seen;
        $template->param(meta => join("\n", grep { (! $seen{$_}) && ($seen{$_}=1) } @{$metaheaders{$page}}));
    }
}

1

