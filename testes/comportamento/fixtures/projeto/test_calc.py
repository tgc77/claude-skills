import unittest

import calc


class TestCalc(unittest.TestCase):
    def test_somar(self):
        self.assertEqual(calc.somar(2, 3), 5)


if __name__ == "__main__":
    unittest.main()
