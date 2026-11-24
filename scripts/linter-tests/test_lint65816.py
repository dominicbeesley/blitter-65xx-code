"""Tests for lint65816. Run from this folder with either:
    python3 -m unittest -v
    python3 -m pytest          (if pytest is installed)

Each cases/*.s file is linted. Lines that should give a message carry
"; EXPECT: error" or "; EXPECT: warning". A "; DEFINES: A B" line passes
-D A -D B. The test fails if the messages (line, level) differ.
"""

import glob
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
import lint65816  # noqa: E402

CASES = sorted(glob.glob(os.path.join(HERE, "cases", "*.s")))


def expected(path):
    exp, defines = set(), {}
    with open(path) as f:
        for n, text in enumerate(f, 1):
            m = re.search(r";\s*EXPECT:\s*(error|warning)", text)
            if m:
                exp.add((n, m.group(1)))
            m = re.search(r";\s*DEFINES:\s*(.*)", text)
            if m:
                defines.update({d: 1 for d in m.group(1).split()})
    return exp, defines


class LintCases(unittest.TestCase):
    pass


def make_test(path):
    def test(self):
        exp, defines = expected(path)
        msgs = lint65816.lint(path, defines, [])
        got = {(m.line, m.level) for m in msgs if m.file == path}
        detail = "\n".join(str(m) for m in msgs)
        self.assertEqual(got, exp, "messages were:\n" + detail)
    return test


for _p in CASES:
    _name = "test_" + os.path.splitext(os.path.basename(_p))[0]
    setattr(LintCases, _name, make_test(_p))

if __name__ == "__main__":
    unittest.main()
