zone2c: compile a zone into a DNS request parser
================================================

This is a mad experiment that doesn't work!

The question was: given a DNS zone file, can you compile it into a
specialized DNS request parser that doesn't need a data structure to
look up domain names?

It would be fun to compile the list of domain names in a zone into a
state machine that makes a single pass over the query name in a DNS
request and at the end can jump directly to code that handles one of
the possible responses:

  * FORMERR - a malformed request
  * REFUSED - not in a known zone
  * NXDOMAIN - unknown name in a known zone
  * no error - a known name

NXDOMAIN
--------

What makes DNS name lookups interesting is having to respond with a
proof that the query name does not exist. To do so the server has to
map the query name to the preceding name according to the canonical
order of domain names. This canonical order is nontrivial:

  * the names are compared label-by-label from right to left
	(labels are the dot-separated words in a domain name)

  * labels are compared lexicographically in the usual way

  * upper-case ASCII letters are treated as lower-case letters

Label lengths
-------------

What makes wire format domain names really horrible for matching with
a finite automaton is the length byte at the start of each label.
Because finite automata normally don't have a way to count, to match a
label length of 22 followed by 22 characters requires 22 states (which
compiles to 22 tests and branches) and this code can't overlap with
the cases for handling label lengths of 21 or 32 etc.

This is probably the main thing that prevents this idea from working.

But we don't have to compile to a classical DFA. This experiment tries
to do that because re2c is convenient for me to use, and I don't know
of a state machine compiler that has more efficient ways to cope with
length prefixes.

So at least this part of the failure is due to a stupid choice of
tool, and possibly not fundamental.

Expansion
---------

This experiment expands a zone file with 4 names into about 1400 lines
of regular expressions. The regexes are compiled by re2c into 56000
lines of C. (This takes a very long time and re2c grows to use about
4GB RAM.) The C compiles to over half a megabyte of object code, which
does nothing except compare a DNS query name to 4 known names that can
be stored in less than 40 bytes.

That's obviously completely unreasonable.

Without the huge blowup caused by matching label lengths, the zone
expands to about 30 lines of regular expressions. These are mostly to
deal with all the points where a query name can diverge from a name in
a zone. For example,

    wild '\x03one\x04zone\x00' |
    wild '\xNNone'  any{NN} '\x04zone\x00' |
    wild '\xNNon' [F-Zf-\xff] any{NN} '\x04zone\x00' |
    wild '\xNNo' [O-Zo-\xff] any{NN} '\x04zone\x00' |
    wild '\xNN' [P-Sp-s] any{NN} '\x04zone\x00' |
    wild '\xNNt' [\x00-G\x5b-g] any{NN} '\x04zone\x00' |
    wild '\xNNth' [\x00-Q\x5b-q] any{NN} '\x04zone\x00' |
    wild '\xNNthr' [\x00-D\x5b-d] any{NN} '\x04zone\x00' |
    wild '\xNNthre' [\x00-D\x5b-d] any{NN} '\x04zone\x00' {
        return (NXDOMAIN){ nsec: "\x03one\x04zone\x00" };
    }

I've replaced the label count shenanigans with NN so you can see the
way my experiment tries to match query names that fall between two
known names.

There's a lot of shared structure here which ought to collapse down to
a plausibly tolerable number of states.

re2c logistics
--------------

Another aspect that could be improved is the restriction on the
overall length of a domain name.

Since finite automata are bad at counting, I've sidestepped this issue
using re2c's input buffer bounds checking. But I chose the wrong
mechanism, causing re2c to do a bounds check in basically all of the
label length counting states, which massively exacerbates the blowup
problem and has horrific effects on the final machine code.

Mechanical sympathy
-------------------

Even if I obtained an ideal state machine compiler, there are good
reasons to think this idea won't work well.

I would call it a success if it's possible to make a finite automaton
of a size comparable to the name lookup data structure that normal DNS
code uses. But hundreds of megabytes is a lot of code...

It will absolutely hammer the CPU's branch predictor.

It will not be friendly to the instruction caches.

I'm still curious how it would compare to a data structure lookup, but
as things stand, I can't even start to find out :-)
