# mm-utils #

mm-utils: Multimedia File Utilities

Author: Matthew Hall <mhall@mhcomputing.net>

## Brief Tour of the Utilities ##

### bin/detect-bad-videos.pl ###

Uses mplayer to detect poor-quality video files with 320x240 resolution or 
worse. It isn't fully completed yet and needs a bit more work.

### cscope-update.pl, lcscope ###

First script creates discrete, accurate cscope index files for every directory 
in `~/src` or other chosen location.

Second script allows searching these projects based on value of `$PROJECT` 
environment variable.

### bin/dirent-count.pl ###

Counts the number of entries present in all directories under a given set of 
directories, defaulting to the current directory, in a format compatible with 
`sort -n` for analysis of the user's choice.

### bin/duplicate-finder.pl ###

Everybody knows there are many duplicate finders in the world. This one is not 
magical, but it does have a couple of good qualities:

* the code is extremely simple, thus it can be customized with special logic, special output format, etc.

* it avoids hashing files which have unique sizes for performance, not every duplicate finder does this.

### bin/filter-xargs-print0.pl, bin/skip-xargs-print0.pl ###

Sometimes `find` does not support various odd operations, such as matching a 
PCRE against an entire path (not just a directory name, or just a file name). 
This is simple to avoid with conventional `find`, using `grep -P`. However 
with `find -print0` a special extra utility is needed, this is it.

Other times you want to skip the first X entries in the `find -print0` output, 
but `head`, `tail`, etc. don't support `\0`-based lines. This utility does.

### bin/md2html.pl ###

All of the Markdown-to-HTML utilities that I tried to use for crafting simple 
web pages in a text editor on the console of my server, don't put all of the 
necessary prologue and epilogue HTML tags into the files, which means they're 
technically invalid HTML, which won't pass W3C `tidy`, and might render poorly 
in stricter browsers. This utility calls an industry-standard Markdown parser, 
but adds the required tags to make a fully valid document.

### bin/memory-usage.pl ###

This is a tool for doing abstract debugging of memory and CPU consumption 
problems in arbitrary UNIX processes, which can be selected for observation 
via process name regex, or PID list. Logs are created in `$HOME` tracking the 
status of the process. This is very valuable for soak testing, torture 
testing, and long-term stability testing. There might be other tools for this 
but I couldn't find one with all the data in one easy-to-read location.

For more information on the tool, run `memory-usage.pl -h` and experiment. `;)`

### bin/zero-checker.pl ###

This is a utility for determining what percentage of the 1KB blocks in a given 
file consist entirely of `\x00`. I found it useful for getting rid of some 
junk files from some directories I was cleaning up and reorganizing. It could 
also be helpful for identifying files that might benefit from compression.

The algorithm is horribly inefficient, but it worked on my machine. `;)`
