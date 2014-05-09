# -*- coding: utf-8 -*-

"""
The class FatExpression (Python) is based in TFatExpression (Delphi).

The class TFatExpression by Gasper Kozak (gasper.kozak@email.si)
version: 1.0 beta, June 2001.
version: 1.3, Dezembre 2002. bug fix e new features by Allan Lima (allan.kardek@gmail.com)

FatExpression and TFatExpression is component used for calculating text-presented expressions.
FatExpression and TFatExpression is open-source and is free for all use.

features
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

    >> variables = ['a=1.1','b=2.2','c=3.3']
    >> exp = FatExpression()
    >> exp.addVariables(variables)
    >> exp.text = 'trunc(max(a, b, c))'
    >> print(exp.value)
    >> 3.0
    >> exp.text = 'round(sum(a, b, c))'
    >> print(exp.value)
    >> 7.0

  - geometric functions
    sin, cos, tan, atan, log, exp

    >> exp = FatExpression()
    >> exp.text = 'log(1)'
    >> print(exp.value)
    >> 0

  - various functions
    and, or, if, random

    >> variables = ['a=1','b=2','c=3']
    >> exp = FatExpression()
    >> exp.addVariables(variables)
    >> exp.text = 'if(a=1, b*10, c*10)'
    >> print(exp.value)
    >> 20.0

  - variables:

    >> variables = ['a=1','b=2','c=3'] # variables = {'a':1,'b':2,'c':3} or variables = 'a=1;b=2;c=3'
    >> exp = FatExpression()
    >> exp.addVariables(variables)
    >> exp.text = 'a+b+c'
    >> print(exp.value)
    >> 6.0

  - user-defined functions (udf):
    format function_name [ (argument_name [, argument_name ... ]] = expression

    >> functions = ['x(a,b)=a*b', 't1(a)=a+10'] # functions = 'x(a,b)=a*b;t1(a)=a+10'
    >> exp = FatExpression()
    >> exp.addFunctions(functions)
    >> exp.text = 'x(1,3)+t1(2)'
    >> print(exp.value)
    >> 15.0

  - evaluate: words are processed by unresolved events "evaluates" recorded addEvaluate().

    >> def test(text, args, argCount):
    >>     if text == 'y':
    >>         return 3

    >> exp = FatExpression()
    >> exp.addEvaluate(test)
    >> exp.text = 'y*2'
    >> print(exp.value)
    >> 6.0

  - multiples lines of FText: undercore is value previous.

    >> exp = FatExpression()
    >> exp.text = ['y*2', '_+3*2']
    >> print(exp.value)
    >> 12.0
    >> exp.text = ['a:y*2', 'a+3*2']
    >> print(exp.value)
    >> 12.0

"""

import math, string, random

__version__ = "1.0"
__versionTime__ = "09 mar 2014 22:22"
__author__ = "Allan Lima <allan.kardek@gmail.com>"

ERROR_CHARACTER_ILLEGAL = 'Parse error: illegal character "%s".'
ERROR_STRING_OPEN = 'Parse error: text string not close'
ERROR_CALCULATE_SYNTAX = 'Calculate error: syntax tree fault. Token: "%s"'
ERROR_COMPILE_SYNTAX =  'Compile error: syntax fault.'
ERROR_UNDECLARED = 'Undeclared identifier: "%s"'
ERROR_FUNCTION_PARSE = 'Function "%s" parse error.'
ERROR_FUNCTION_PARAMETER = 'Function "%s" invalid number parameter.'
ERROR_FUNCTION_INVALID = 'Function "%s" is not valid.'
ERROR_FUNCTION_HEADER = 'Function header "%s" is not valid.'
ERROR_FUNCTION_DELIMITOR = ERROR_FUNCTION_PARSE + ': delimitor "%s" expected between arguments.'
ERROR_FUNCTION_CLOSE = ERROR_FUNCTION_PARSE + ': parenthesis close expected.'
ERROR_FUNCTION_TYPE = ERROR_FUNCTION_PARSE + ': argurment expected type string.'
ERROR_FUNCTION_PARENTHESIS = 'Compile error: parenthesis mismatch. Expression: %s'
ERROR_TOKEN_LIST = 'Tokens list error.'

STR_OPERATION = '*/^%+-!~'  # supported operations numeric
STR_RELATION  = '<>=<='     # supported operations relation
STR_PARAMDELIMITOR = ','    # function parameter delimitor
STR_OLD_VALUE = '_'
STR_PARENTHESIS_OPEN = '{[('
STR_PARENTHESIS_CLOSE = '}])'

A_BOOLEAN = ['&', '|', '?'];     # & (and), | (or), ? (xor)
A_OPERATION = ['/', '-+', '*%^', '~!']

ttNone, ttOldValue, ttNumeric, ttOperation, ttString, ttParamDelimitor, \
ttParenthesisOpen, ttParenthesisClose, ttRelation, ttBoolean = range(10)

eoInternalFirst, eoEventFirst = 0, 1

class ExpToken:
    """Class used by TExpParser and TExpNode for breaking text into tokens and building a syntax tree"""
    def __init__(self, tokenText='', tokenType=ttNone):
        self.tokenText = tokenText
        self.tokenType = tokenType

class ExpParser:
    """Engine for breaking text into tokens"""
    def __init__(self, expression=''):
        self.expression = expression
        self._tokens = []
        self._variables = {}
        self._pos = 0

    @property
    def tokens(self):
        return self._tokens

    def addVariables(self, variables):
        if isinstance(variables, str):
            self.addVariables(variables.split(';'))
        elif isinstance(variables, dict):
            for key, value in variables.items():
                self._variables[key.strip().lower()] = float(value)
        else:
            for key, value in [s.split('=') for s in variables]:
                self._variables[key.strip().lower()] = float(value)

    @property
    def tokenCount(self):
        return len(self.tokens)

    def validate(self):

        pilha = []

        for ch in self.expression:
            if ch in STR_PARENTHESIS_OPEN:
                pilha.append(ch)
            elif ch in STR_PARENTHESIS_CLOSE:
                if len(pilha) == 0:
                    raise Exception(ERROR_COMPILE_SYNTAX)
                if pilha[-1] != STR_PARENTHESIS_OPEN[STR_PARENTHESIS_CLOSE.find(ch)]:
                    raise Exception(ERROR_FUNCTION_PARENTHESIS % self.expression)
                pilha.pop(-1)

        if len(pilha) > 0:
            raise Exception(ERROR_COMPILE_SYNTAX)

        return True

    def _getToken(self, index):
        return self.tokens[index]

    def _getTokenType(self, s, first):
        if s == STR_PARAMDELIMITOR:
            return ttParamDelimitor
        elif STR_OPERATION.find(s) > -1:
            return ttOperation
        elif s in STR_PARENTHESIS_OPEN:
            return ttParenthesisOpen
        elif s in STR_PARENTHESIS_CLOSE:
            return ttParenthesisClose
        elif STR_RELATION.find(s) > -1:
            return ttRelation
        elif s in A_BOOLEAN:
            return ttBoolean
        elif s in string.digits+'.':
            return ttNumeric
        elif s == STR_OLD_VALUE:
            return ttOldValue
        else: # legal variable name characters
            if first:
                p = string.ascii_letters.find(s)
            else:
                p = (string.ascii_letters+string.digits).find(s)
            if p > -1:
                return ttString
            else:
                return ttNone

    def findVariable(self, name):
        name = name.strip().lower()
        if name in self._variables:
            return self._variables[name]

    def _setVariable(self, name, value):
        name = name.strip().lower()
        if name:
            self._variables[name] = value

    def readNextToken(self):

        def createToken(tokenText):
            token = ExpToken(tokenText, firstType)
            self._tokens.append(token)
            return token

        if self._pos > len(self.expression)-1:
            return None

        while 1:
            ch = self.expression[self._pos]
            self._pos += 1
            if ch != ' ' or self._pos > len(self.expression)-1:
                break

        firstType = self._getTokenType(ch, True)

        if firstType == ttNone:
            raise Exception(ERROR_CHARACTER_ILLEGAL % ch)

        if firstType in [ttOperation, ttParenthesisOpen, ttParenthesisClose, ttBoolean]:
            return createToken(ch)

        if firstType == ttRelation:

            if self._pos < len(self.expression):
                part = ch
                ch   = self.expression[self._pos]
                nextType = self._getTokenType(ch, False)

                if firstType == nextType and firstType == ttRelation and STR_RELATION.find(part+ch) > -1:
                    self._pos += 1
                    part = part + ch

            return createToken(part)

        part = ch

        while self._pos < len(self.expression):
            ch       = self.expression[self._pos]
            nextType = self._getTokenType(ch, False)

            if (nextType == firstType) or (firstType == ttString and nextType == ttNumeric):
                part += ch
            else:
                return createToken(part)

            self._pos += 1

        return createToken(part)

    def readFirstToken(self):
        self._tokens = []
        self._pos = 0
        return self.readNextToken()


class ExpNode:
    """syntax-tree node. this engine uses a bit upgraded binary-tree"""
    def __init__(self, owner, parentNode, tokens):
        self.owner  = owner
        self.parent = parentNode

        if parentNode:
            self.level = parentNode.level + 1
        else:
            self.level = 0

        self.tokens     = tokens[:]
        self.childLeft  = []
        self.childRight = []

    @property
    def tokenCount(self):
        return len(self.tokens)

    @property
    def token(self):
        if self.tokenCount > 1:
            raise Exception(ERROR_TOKEN_LIST)
        return self.tokens[0]

    def _removeSorroundingParenthesis(self):

        iFirst = 0
        iLast  = self.tokenCount - 1

        while iLast > iFirst:

            if (self.tokens[iFirst].tokenType == ttParenthesisOpen) and (self.tokens[iLast].tokenType == ttParenthesisClose):

                iLevel = i = 0
                bSorrounding = True

                while 1:

                    if self.tokens[i].tokenType == ttParenthesisOpen:
                        iLevel += 1
                    elif self.tokens[i].tokenType == ttParenthesisClose:
                        iLevel -= 1

                    if iLevel == 0 and i < self.tokenCount-1:
                        bSorrounding = False
                        break

                    i += 1

                    if i == self.tokenCount:
                        break

                if bSorrounding:
                    self.tokens.pop(iLast)
                    self.tokens.pop(iFirst)
                else:
                    return

            else:
                return

            iFirst, iLast = 0, self.tokenCount-1

    def _parseFunction(self):

        if not ( (self.tokenCount > 2) and \
                 (self.tokens[0].tokenType == ttString) and \
                 (self.tokens[1].tokenType == ttParenthesisOpen) and \
                 (self.tokens[-1].tokenType == ttParenthesisClose) ):
            return False

        self.tokens.pop(-1)
        self.tokens.pop(1)

        while self.tokenCount > 1:

            lTokens = []
            iDelimitor = -1
            iDelimitorLevel = 0

            for i in range(1, self.tokenCount):
                if self.tokens[i].tokenType == ttParenthesisOpen:
                    iDelimitorLevel += 1
                elif self.tokens[i].tokenType == ttParenthesisClose:
                    iDelimitorLevel -= 1
                elif self.tokens[i].tokenType == ttParamDelimitor and iDelimitorLevel == 0:
                    iDelimitor = i - 1
                    self.tokens.pop(i)
                    break

                if iDelimitorLevel < 0:
                    raise Exception(ERROR_FUNCTION_PARSE % self.tokens[i].tokenText)

            if iDelimitor == -1:
                iDelimitor = self.tokenCount - 1

            for i in range(1, iDelimitor+1):
                lTokens.append(self.tokens[1])
                self.tokens.pop(1)

            child = ExpNode(self.owner, self, lTokens)
            child.build()
            self.childRight.append(child)

        return True

    def _splitToChildren(self, tokenIndex):

        iTokenCount = self.tokenCount
        left  = []
        rigth = []

        if tokenIndex < iTokenCount - 1:
            for i in range(iTokenCount-1, tokenIndex, -1):
                rigth.insert(0, self.tokens[i])
                self.tokens.pop(i)
            child = ExpNode(self.owner, self, rigth)
            self.childRight.insert(0, child)
            child.build()

        if tokenIndex > 0:
            for i in range(tokenIndex-1, -1, -1):
                left.insert(0, self.tokens[i])
                self.tokens.pop(i)
            child = ExpNode(self.owner, self, left)
            self.childLeft.insert(0, child)
            child.build()

    def _findLSOTI(self):
        """Least Significant Operation Token Index"""
        def posArray(substr, aString):
            result = -1
            for i, s in enumerate(aString):
                result = s.find(substr)
                if result > -1:
                    return (i+1)*10+result
            return result

        iPriorityBoolean = iPriorityOperation = iPriorityRelation = -1
        iLevel = iBoolean = iOperation = 0

        for i in range(self.tokenCount):

            token = self.tokens[i]

            if token.tokenType == ttParenthesisOpen:
                iLevel += 1
            elif token.tokenType == ttParenthesisClose:
                iLevel -= 1

            if iLevel < 0:
                raise Exception(ERROR_FUNCTION_PARENTHESIS % self.owner.text)

            elif iLevel == 0 and token.tokenType == ttBoolean:
                iNewPriorityBoolean = posArray(token.tokenText, A_BOOLEAN)
                if iPriorityBoolean == -1 or iNewPriorityBoolean <= iPriorityBoolean:
                    iPriorityBoolean, iBoolean = iNewPriorityBoolean, i

            elif iLevel == 0 and token.tokenType == ttRelation:
                iPriorityRelation = i

            elif iLevel == 0 and token.tokenType == ttOperation:
                iNewPriorityOperation = posArray(token.tokenText, A_OPERATION)
                if iPriorityOperation == -1 or iNewPriorityOperation <= iPriorityOperation:
                    iPriorityOperation, iOperation = iNewPriorityOperation, i

        if iPriorityBoolean > -1:
            return iBoolean
        elif iPriorityRelation > -1:
            return iPriorityRelation
        elif iPriorityOperation > -1:
            return iOperation
        else:
            return -1

    def build(self):

        self._removeSorroundingParenthesis()

        if self.tokenCount < 2:
            return self

        iLSOTI = self._findLSOTI()

        if iLSOTI < 0:
            if not self._parseFunction():
                raise Exception(ERROR_COMPILE_SYNTAX + '. Expression: '+self.owner.text)
        else:
            self._splitToChildren(iLSOTI)

        return self

    def evaluate(self):

        result = None
        args = []

        for node in self.childRight:
            args.append(node.calculate())

        if isinstance(self.owner, FatExpression):
            result = self.owner.evaluate(self.token.tokenText, args)
        elif isinstance(self.owner, ExpFunction):
            result = self.owner.evalArgs(self.token.tokenText, args)

        if result is None:
            raise Exception(ERROR_UNDECLARED % self.token.tokenText)

        return result

    def operParamateres(self):

        token = self.token
        result = True

        if token.tokenType in [ttOperation, ttRelation, ttBoolean]:
            if token.tokenText == '-' and len(self.childLeft) == 0 and len(self.childRight) == 1:
                result = True
            elif token.tokenText == '!': # factorial
                result = len(self.childLeft) == 1 and len(self.childRight) == 0
            elif token.tokenText == '~': # negation
                result = len(self.childLeft) == 0 and len(self.childRight) == 1
            elif STR_OPERATION.find(token.tokenText) > -1:
                result = len(self.childLeft) == 1 and len(self.childRight) == 1
            elif STR_RELATION.find(token.tokenText) > -1:
                result = len(self.childLeft) == 1 and len(self.childRight) == 1
            elif  token.tokenText in A_BOOLEAN:
                result = len(self.childLeft) == 1 and len(self.childRight) == 1

        return result

    def calculate(self):

        result = 0
        if self.tokenCount != 1:
            return result

        token = self.token

        if not self.operParamateres():
            raise Exception(ERROR_CALCULATE_SYNTAX % token.tokenText)

        if token.tokenType == ttOldValue:
            result = self.owner._value_old

        elif token.tokenType == ttNumeric:
            result = float(token.tokenText)

        elif token.tokenType == ttString:
            if token.tokenText.lower() == 'true':
                result = 1
            elif token.tokenText.lower() == 'false':
                result = 0
            else:
                result = self.evaluate()

        elif token.tokenType == ttOperation:
            if token.tokenText == '+':
                result = self.childLeft[0].asFloat() + self.childRight[0].asFloat()
            elif token.tokenText == '-':
                if len(self.childLeft) == 0 and len(self.childRight) == 1:
                    result = self.childRight[0].calculate()*(-1)
                else:
                    result = self.childLeft[0].asFloat() - self.childRight[0].asFloat()
            elif token.tokenText == '*':
                result = self.childLeft[0].asFloat() * self.childRight[0].asFloat()
            elif token.tokenText == '/':
                result = self.childLeft[0].asFloat() / self.childRight[0].asFloat()
            elif token.tokenText == '^':
                result = self.childLeft[0].asFloat()**self.childRight[0].asFloat()
            elif token.tokenText == '%':  # module
                result = int(self.childLeft[0].asFloat()) % int(self.childRight[0].asFloat())
            elif token.tokenText == '!':
                result = int(math.factorial(self.childLeft[0].asFloat()))
            elif token.tokenText == '~':
                if int(self.childRight[0].asFloat()) == 1:
                    result = 0
                else:
                    result = 1

        elif token.tokenType == ttBoolean:
            left  = self.childLeft[0].asFloat()
            rigth = self.childRight[0].asFloat()

            if token.tokenText == '&' and left == 1 and rigth == 1:
                result = 1
            elif token.tokenText == '|' and (left == 1 or rigth == 1):
                result = 1
            elif token.tokenText == '?' and ( (left == 1 and rigth == 0) or (left == 0 and rigth == 1) ):
                result = 1

        elif token.tokenType == ttRelation:
            left  = self.childLeft[0].calculate()
            rigth = self.childRight[0].calculate()

            if token.tokenText == '>' and left > rigth:
                result = 1
            elif token.tokenText == '<' and left < rigth:
                result = 1
            elif token.tokenText == '<=' and left >= rigth:
                result = 1
            elif token.tokenText == '>=' and lefft >= rigth:
                result = 1
            elif token.tokenText == '<>' and left != rigth:
                result = 1
            elif token.tokenText == '=' and left == rigth:
                result = 1

        return result

    def asFloat(self):
        return float(self.calculate())


class ExpFunction:

    def __init__(self, owner):
        self.owner = owner
        self.text = '' # AsString texto completo da função
        self.head = ''
        self.name = ''
        self.function = ''
        self.args = []
        self.values = []

    def __repr__(self):
        return '<ExpFunction: %s>' % self.name

    @property
    def argCount(self):
         return len(self.args)

    def call(self, values):

        if len(self.args) != len(values):
            raise Exception(ERROR_FUNCTION_PARAMETER % self.name)

        self.values = values[:]

        parser = ExpParser(self.function)

        token = parser.readFirstToken()
        while token:
            token = parser.readNextToken()

        tree = ExpNode(self, None, parser.tokens)
        tree.build()

        return tree.calculate()

    def evalArgs(self, text, args):
        for index, value in enumerate(self.args):
            if value.lower() == text.lower():
                return self.values[index]
        if isinstance(self.owner, FatExpression):
            return self.owner.evaluate(text, args)
        else:
            return 0

    def _setHeader(self, value):
        self.args = []
        self.head = value
        self.name = ''

        ExpectFuncName         = True
        ExpectParenthesisOpen  = True
        ExpectDelimitor        = False
        ExpectParenthesisClose = False

        parser = ExpParser(value)

        token = parser.readFirstToken()

        while token:

            if ExpectFuncName:
                if token.tokenType <> ttString:
                    raise Exception(ERROR_FUNCTION_INVALID % self.text)

                self.name = token.tokenText
                ExpectFuncName = False

            elif ExpectParenthesisOpen:
                if token.tokenType <> ttParenthesisOpen:
                    raise Exception(ERROR_FUNCTION_HEADER % value)

                ExpectParenthesisOpen  = False
                ExpectParenthesisClose = True

            elif not ExpectParenthesisClose:
                raise Exception(ERROR_FUNCTION_HEADER % value)

            elif ExpectDelimitor:
                if not (token.tokenType in [ttParamDelimitor, ttParenthesisClose]):
                    raise Exception(ERROR_FUNCTION_DELIMITOR % (self.name, STR_PARAMDELIMITOR))
                ExpectDelimitor = False
                if token.tokenType == ttParenthesisClose:
                    ExpectParenthesisClose = False

            elif token.tokenType == ttString:
                self.args.append(token.tokenText)
                ExpectDelimitor = True
            else:
                raise Exception(ERROR_FUNCTION_TYPE % self.name);

            token = parser.readNextToken()

        if ExpectFuncName:
            raise Exception(ERROR_FUNCTION_HEADER % value)

        if ExpectParenthesisClose:
            raise Exception(ERROR_FUNCTION_CLOSE % self.name)

    def _setAsString(self, value):

        if value.find('=') == -1:
            raise Exception(ERROR_FUNCTION_INVALID % value)

        self.text = value
        head, self.function = value.split('=', 1)

        self._setHeader(head)

class FatExpression(object):

    def __init__(self):
        self.compiled      = False
        self.evaluateOrder = eoInternalFirst
        self.functions     = []
        self.expParser     = ExpParser()
        self._text         = []
        self._evaluates    = [self.evaluateCustom]
        self._value        = None
        self._value_old    = None

    def addVariables(self, variables):
        self.expParser.addVariables(variables)

    def clearVariables(self):
        self.expParser._variables = {}

    def addEvaluate(self, evaluate):
        self._evaluates.append(evaluate)

    def clearEvaluate(self):
        self._evaluates = []

    def compile(self):

        for text in self._text:

            if text.strip() == '':
                continue
            elif ':' in text:
                variable, expression = [s.strip() for s in text.split(':')]
            else:
                variable, expression = ('', text.strip())

            self.expParser.expression = expression
            self.expParser.validate()

            token = self.expParser.readFirstToken()
            while token:
                token = self.expParser.readNextToken()

            tree = ExpNode(self, None, self.expParser.tokens)

            tree.build()
            value = tree.calculate()

            self._value = value
            self._value_old = value

            self.expParser._setVariable(variable, value)

        self.expParser._variables = {}

    def findFunction(self, name):
        for f in self.functions:
            function = ExpFunction(self)
            function._setAsString(f)
            if function.name.lower() == name.lower():
                return function

    def evaluate(self, text, args):
        text = text.strip().lower()
        if self.evaluateOrder == eoEventFirst:
            for evaluate in self._evaluates:
                value = evaluate(text, args)
                if value is not None:
                    return value

        value = self.expParser.findVariable(text)
        if value:
            return value

        function = self.findFunction(text)
        if function:
            return function.call(args)

        if self.evaluateOrder == eoInternalFirst:
            for evaluate in self._evaluates:
                value = evaluate(text, args)
                if value is not None:
                    return value

    @property
    def value(self):
        if self._value_old is None:
            self._value_old = 0.0
        self._value = 0.0
        self.compile()
        return self._value

    def getBoolean(self):
        return bool(self.value)

    def getInteger(self):
        return int(self.value)

    def addFunctions(self, functions):
        if isinstance(functions, str):
            functions = functions.split(';')
        self.functions.extend(functions)

    def clearFunctions(self):
        self.functions = []

    @property
    def text(self):
        result = ''
        for s in self._text:
            if result:
                result += s + ';'
            else:
                result = s
        return result

    @text.setter
    def text(self, value):
        self.compiled = False
        if isinstance(value, list):
            self._text = value[:]
        elif value.find(';') > -1:
            self._text = value.split(';')
        else:
            self._text = [value]

    def evaluateCustom(self, text, args):

        def errorParameter(paramCount=None):
            if paramCount is None or argCount != paramCount:
                raise Exception(ERROR_FUNCTION_PARAMETER % text)

        argCount = len(args)

        if text == 'abs':
            errorParameter(1)
            return abs(args[0])

        elif text == 'frac':
            errorParameter(1)
            return args[0] - int(args[0])

        elif text == 'max':
            return max(args)

        elif text == 'min':
            return min(args)

        elif text == 'mod':
            errorParameter(2);
            return math.fmod(int(args[0]), int(args[1]))

        elif text == 'round':
            if argCount == 1:
                return round(args[0], 2)
            elif argCount == 2:
                return round(args[0], int(args[1]))
            else:
                errorParameter()

        elif text == 'sign':
            errorParameter(1);
            if args[0] == abs(args[0]):
                return 1
            elif args[0] == 0:
                return 0
            else:
                return -1

        elif text == 'sqrt': # Returns the square root of X.
            errorParameter(1)
            return math.sqrt(args[0])

        elif text == 'sin':  # Returns the sine of the angle in radians.
            errorParameter(1)
            return math.sin(args[0])

        elif text == 'cos':  # Calculates the cosine of an angle.
            errorParameter(1);
            return math.cos(args[0])

        elif text == 'tan':
            errorParameter(1)
            return math.tan(args[0])

        elif text == 'atan':  # Calculates the arctangent of a given number.
            errorParameter(1)
            return math.atan(args[0])

        elif text == 'log':   # Returns the natural log of a real expression.
            errorParameter(1)
            return math.log(args[0])

        elif text == 'exp':   # Returns the exponential of X.
            errorParameter(1)
            return math.exp(args[0])

        elif text == 'sum':
            return sum(args)

        elif text == 'trunc':
            errorParameter(1)
            return math.trunc(args[0])

        elif text == 'and':
            for b in args:
              if not bool(b):
                  return 0
            return 1

        elif text == 'or':
            for b in args:
              if bool(b):
                  return 0
            return 1

        elif text == 'if':
            errorParameter(3)
            if bool(args[0]):
                return args[1]
            else:
                return args[2]

        elif text == 'random':
            errorParameter(0);
            return random.random()
