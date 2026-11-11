#!/usr/bin/env python3
"""Merge two tesseract runs of one image: ocr_fix.py MIXED ENGLISH > text

The rus+eng run reads Russian well but turns short English words made of letters that also exist
in Cyrillic into Cyrillic ("and" -> "апа", "Open" -> "Ореп"). So lines where most words are Latin
are taken from the English-only run instead; Russian lines stay from the mixed run. If the two
runs don't line up, the lookalike Cyrillic letters are swapped back to Latin as a fallback.
"""
import re
import sys

LOOKALIKE = str.maketrans(
    "аеорсухкпнтмвгАЕОРСХКНТМВУ",
    "aeopcyxknhtmbrAEOPCXKHTMBY",
)
CYRILLIC = re.compile(r"[а-яёА-ЯЁ]")
WORD = re.compile(r"[a-zA-Zа-яёА-ЯЁ]+")


def mostly_latin(line):
    """True when the line has more surely-English words than surely-Russian ones.

    A word is surely Russian if it has a letter with no Latin lookalike (и, л, ч, я...), and
    surely English if it came out in Latin; words of lookalike letters only ("но", "апа") could
    be either and don't count.
    """
    english = russian = 0
    for w in WORD.findall(line):
        if not CYRILLIC.search(w):
            english += 1
        elif CYRILLIC.search(w.translate(LOOKALIKE)):
            russian += 1
    return english > russian


def swap_lookalikes(line):
    def swap(m):
        converted = m.group(0).translate(LOOKALIKE)
        return converted if not CYRILLIC.search(converted) else m.group(0)

    return WORD.sub(swap, line)


def main():
    with open(sys.argv[1]) as f:
        mixed = f.read().splitlines()
    with open(sys.argv[2]) as f:
        english = f.read().splitlines()
    aligned = len(mixed) == len(english)

    out = []
    for i, line in enumerate(mixed):
        if not mostly_latin(line):
            out.append(line)
        elif aligned:
            out.append(english[i])
        else:
            out.append(swap_lookalikes(line))
    sys.stdout.write("\n".join(out).strip() + "\n")


main()
