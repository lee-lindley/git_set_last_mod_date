# git_set_last_mod_date

Perl script to set file last modification time based on *git* commit timestamp.

Original script courtesy of Tom Christiansen. My modifications were to suit me.

It works fine on any Unix, plus on Windows under *git bash* and *cygwin* assuming you have Perl
installed (which you almost certainly do).

## The issue

Normal *git* checkout/switch/pull/clone operations leave files with practically worthless
last modification times. If you are accustomed to sorting by last modification time,
the situation sucks.

## The solution

Update the last modification time of all files in the repository with the most recent time
the file was *"committed"* in the current git branch. For this purpose we only want to use 
commit's that include the file that are not *Merge branch* commits. In other words, we only
care about the last time the file was edited/changed, but not from a merge. Technically, you
could change it in the middle of a merge, but it is too difficult to tease that out.

## git_set_last_mod_date.pl

The script implements the solution, updating all files found in the git log in non-merge commits
where the existing last modification time does not match the commit log record time.
It uses the *utime* Perl function to set the last modification date.

The script may also update permissions on  \*.pl and \*.sh files to 0755, but only
the files that are also in the git log for which it updates the last modification time. That command
is commented out, but for a repository that is used as local accessories, it may be useful and likely
doesn't hurt anything.

## Implementation

Put the script in a directory in your PATH (/usr/local/bin perhaps) and make it executable (chmod 755 git_set_last_mod_date.pl).
Perl also needs to be in your PATH or else modify the first line of the script to specify
the location of *perl* executable.

Update or add aliases for the most common operations where you want it to run. You can do so
in a git alias or in a regular shell alias or function. For my money the right time to do it
is on any *git checkout*, *git switch* or *git pull* command. I use the following two bash 
shell functions among others:

    gp() {
        git pull 
        git_set_last_mod_date.pl
    }
    gco() {
        git checkout $1
        if [[ $? != 0 ]]; then
            echo "\nHere is a list of branches on the server:"
            git branch -r
            echo "try again with a valid branch name (without the 'origin/' part)"
            echo "\nIf you intend to create a new 'tracking' branch we all share, then issue the following commands:"
            echo "\tgit checkout -b new_branch_name"
            echo "\tgit push -u origin new_branch_name\n"
        else
            git_set_last_mod_date.pl
        fi
    }        
