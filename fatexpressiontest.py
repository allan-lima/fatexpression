# -*- coding: utf-8 -*-

"""
Classe de testes da classe FatExpression
"""

import fatexpression
import unittest

def processo(text, args):
    if text == 'b':
        return 23

class TestFatExpression(unittest.TestCase):

    def start(self, text):
        self.exp.text = text
        return self.exp.value

    def setUp(self):
        self.exp = fatexpression.FatExpression()
        self.exp.addEvaluate(processo)
        self.exp.addVariables({'c':30, 'd':20})
        self.exp.addFunctions(['x(a,b)=a*b', 'x2(a)=a'])

    def test0(self):
        self.assertEqual(self.start('{2*3+[(10+2)/(5+1)]+2}'), 10)

    def test1(self):
        self.assertEqual(self.start('4*(2+(10/5)+(5^2))'), 116)

    def test2(self):
        self.assertEqual(self.start('x2(3)'), 3)

    def test3(self):
        self.assertEqual(self.start('x(c,x2(2))'), 60)

    def test4(self):
        self.assertEqual(self.start('x(x(c,x2(4)),x2(3))'), 360)

    def test5(self):
        self.assertEqual(self.start('(1+2)*3'), 9)

    def test6(self):
        self.assertEqual(self.start('1+2*3'), 7)

    def test7(self):
        self.assertEqual(self.start('1+(2*3)'), 7)

    def test8(self):
        self.assertEqual(self.start('1*2+3'), 5)

    def test9(self):
        self.assertEqual(self.start('3!'), 6)

    def test10(self):
        self.assertEqual(self.start('3!*2'), 12)

    def test12(self):
        self.assertEqual(self.start('a:2;_+a+B+c;_+a'), 59)

    def test13(self):
        self.assertEqual(self.start('~(3<2)'), 1)

    def test14(self):
        self.assertEqual(self.start('1|1'), 1)

    def test15(self):
        self.assertEqual(self.start('1?1'), 0)

    def test16(self):
        self.assertEqual(self.start('6/2.5'), 2.4)

    def test17(self):
        self.assertEqual(self.start('3<2&1'), 0)

    def test18(self):
        self.assertEqual(self.start('x:2;(-x)*3'), -6)

    def test19(self):
        self.assertEqual(self.start('if(1,2,3)+if(0,2,3)'), 5)

    def test20(self):
        self.assertEqual(self.start('log(1)'), 0)

if __name__ == '__main__':
    unittest.main()