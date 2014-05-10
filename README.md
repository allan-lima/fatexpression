#[FatExpression v1.0.0]
###python class used for calculating text-presented expressions

The class FatExpression (Python) is based in TFatExpression (Delphi).

The class TFatExpression by Gasper Kozak (gasper.kozak@email.si)
version: 1.0 beta, June 2001.
version: 1.3, Dezembre 2002. bug fix e new features by Allan Lima

FatExpression and TFatExpression is component used for calculating text-presented expressions.
FatExpression and TFatExpression is open-source and is free for all use.

##Features

- keys, brackets, parenthesis: {}, [], ()
- basic operations:
  addition         +      3 + 2 = 5
  substration      -      3 - 2 = 1
  multiplication   *      3 * 2 = 6
  division         /      3 / 2 = 1.5
  exponentiation   ^      3 ^ 2 = 9
  factorial:       !      3! = 6
  module           %      3 % 2 = 1
  unary minus      -      (-x) = x * (-1)

- relational operations:
  minor            <      3 < 2 = 0
  major            >      3 > 2 = 1
  major or equal   >=     3 >= 2 = 1
  minor or egual   <=     3 <= 2 = 0
  different        <>     3 <> 2 = 1
  egual            =      3 = 2 = 0

- logic operations:
  and              &      1 & 1 = 1, 1 & 0 = 0
  or               |      1 | 0 = 1, 0 | 0 = 0
  exclusive or     ?      1 ? 0 = 1, 1 ? 1 = 0
  negation         ~      ~1 = 0, ~0 = 1

- mathematical functions
  abs, frac, max, min, mod, round, sign
  sqrt, exp, trunc, sum

    $ variables = ['a=1.1','b=2.2','c=3.3']
    $ exp = FatExpression()
    $ exp.addVariables(variables)
    $ exp.text = 'trunc(max(a, b, c))'
    $ print(exp.value)
    $ 3.0
    $ exp.text = 'round(sum(a, b, c))'
    $ print(exp.value)
    $ 7.0

- geometric functions
  sin, cos, tan, atan, log, exp

    $ exp = FatExpression()
    $ exp.text = 'log(1)'
    $ print(exp.value)
    $ 0

- various functions
  and, or, if, random

    $ variables = ['a=1','b=2','c=3']
    $ exp = FatExpression()
    $ exp.addVariables(variables)
    $ exp.text = 'if(a=1, b*10, c*10)'
    $ print(exp.value)
    $ 20.0

- variables:

    $ variables = ['a=1','b=2','c=3'] # variables = {'a':1,'b':2,'c':3} or variables = 'a=1;b=2;c=3'
    $ exp = FatExpression()
    $ exp.addVariables(variables)
    $ exp.text = 'a+b+c'
    $ print(exp.value)
    $ 6.0

- user-defined functions (udf):
  format function_name [ (argument_name [, argument_name ... ]] = expression

    $ functions = ['x(a,b)=a*b', 't1(a)=a+10'] # functions = 'x(a,b)=a*b;t1(a)=a+10'
    $ exp = FatExpression()
    $ exp.addFunctions(functions)
    $ exp.text = 'x(1,3)+t1(2)'
    $ print(exp.value)
    $ 15.0

- evaluate: words are processed by unresolved events "evaluates" recorded addEvaluate().

    $ def test(text, args, argCount):
    $     if text == 'y':
    $         return 3
    $
    $ exp = FatExpression()
    $ exp.addEvaluate(test)
    $ exp.text = 'y*2'
    $ print(exp.value)
    $ 6.0

- multiples lines of FText: undercore is value previous.

    $ exp = FatExpression()
    $ exp.text = ['y*2', '_+3*2']
    $ print(exp.value)
    $ 12.0
    $ exp.text = ['a:y*2', 'a+3*2']
    $ print(exp.value)
    $ 12.0

##Author
- Email: allan.kardek@gmail.com
- GitHub: https://github.com/allan-lima