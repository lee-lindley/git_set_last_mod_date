#!/usr/bin/env perl

# git-utimes: update file times to last commit on them
# Tom Christiansen <tchrist@perl.com>
#
# NOTE: I do not have any licence for this. The original was written by Tom Christiansen and
# rights to it are his. I doubt he cares if you use it, but that is your problem. I make no waranty.
#
# I changed his original because it was not working for me. I do not know if porcelain had
# changed out from under it or I just did not like some of the decisions. This works for
# me. -- Lee Lindley

use v5.10;      # for pipe open on a list
use strict;
use warnings;
use constant DEBUG => !!$ENV{DEBUG};


#die "did not find variable GIT_DIR in environment" unless $ENV{GIT_DIR};
#chdir($ENV{GIT_DIR});
my $git_dir = qx{git rev-parse --git-dir 2>/dev/null};
die "not in a git repository directory" if ($git_dir eq "");
if ($git_dir ne ".git") {
    chdir substr($git_dir,0,-5); # strip the ".git" off the end I think there is a newline or space too
}


my @gitlog = (
    qw[git log --name-only],
    qq[--format=format:"%s" %ct %at],
    @ARGV,
);

open(GITLOG, "-|", @gitlog)             || die "$0: Cannot open pipe from `@gitlog`: $!\n";

our $Oops = 0;
our %Seen;
$/ = "";

while (<GITLOG>) {
    my (@r) = split /\R/;
    my $i = 0;
    # find the starting point for capturing an event for file change
    while ($i < @r && $r[$i] =~ /^"Merge branch/) {
        $i++;
    }
    ;
    next if $i == @r; # it was all merges. skip it.

    my $msg = "";
    if ($r[$i] =~ s/^"(.*)" //) {
        $msg = $1;
    } else { # else odd case of a merge with no commit message
        # so back up one and pick time up from merge
        $i--;
        $r[$i] =~ s/^"(.*)" //
    }

    $r[$i] =~ s/^(\d+) (\d+)$//gm                || die;
    my @times = ($1, $2);               # last one, others are merges

    # We are at a point in the message where we may have files we need to set utime on
    for ($i++; $i < @r; $i++) { # advance through list
        my $file = $r[$i];
        next if $Seen{$file}++;
        next if !-f $file;              # no longer here
        my ($mtime_cur) = (stat(_))[9]; # get existing file mtime. the -f test put it in memory

        # the numbers we have from git are gmt seconds since epic.
        # @times has two numbers - atime and mtime
        # convert them to date/time strings in local timezone and print if we have DEBUG set in environment
        printf "atime=%s mtime=%s exsiting mtime=%s %s -- %s\n",
                (map { scalar localtime $_ } @times, $mtime_cur),
                $file, $msg,
                                        if DEBUG;

        if ($mtime_cur != $times[1]) {
            unless (utime @times, $file) {
                print STDERR "$0: Couldn't reset utimes on $file: $!\n";
                $Oops++;
            }
            #chmod 0755, $file if ($file =~ /\.(pl|sh)$/);
        } elsif (DEBUG) {
            printf "%s: mtime not changed\n", $file;
        }
    }

}
exit $Oops;
