#!/usr/bin/python

import sys
from optparse import OptionParser

import parsers
import writers

class Lesson:
    def __init__ (self, name, owner, version):
        self.name = name
        self.owner = owner
        self.version = version

class Card:
    def __init__ (self, lesson, version, deleted, front_text, front_batch, front_timestamp, reverse_text, reverse_batch, reverse_timestamp):
        self.lesson = lesson
        self.version = version
        self.deleted = deleted
        self.front_text = front_text
        self.front_batch = front_batch
        self.front_timestamp = front_timestamp
        self.reverse_text = reverse_text
        self.reverse_batch = reverse_batch
        self.reverse_timestamp = reverse_timestamp

def ident (x):
    return x

def main ():
    parser = OptionParser ()
    (options, cmdline_args) = parser.parse_args ()
    if len (cmdline_args) != 1:
        sys.stderr.write ("Usage: pauker2cards.py <inputfile>\n")
        exit (1)

    pauker_file = open (cmdline_args [0], "r")
    pauker_data = pauker_file.read ()
    pauker_file.close ()

    lesson = Lesson ("dummy", None, 0)
    parser = parsers.PaukerParser (Card, ident, lesson)
    cards = parser.parse (pauker_data)

    writers.write_cards (lesson, cards, sys.stdout.write)

if __name__ == "__main__":
    main()
