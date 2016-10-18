/*
  TFatExpression was originally written by Gasper Kozak, gasper.kozak@email.si
  This component is open source and is free for all uses
  version: 1.0 beta, June 2001
  version: 1.1, June 2002
  version: 1.2, November 2002, Allan Lima, allan.kardek@gmail.com
  version: 1.3, Dezember 2002, Allan Lima, allan.kardek@gmail.com
  version: 1.4, October 2016, Allan Lima, allan.kardek@gmail.com 
*/

const
    ERROR_CHARACTER_ILLEGAL = 'Parse error: illegal character "%s".',
    ERROR_STRING_OPEN = 'Parse error: text string not close',
    ERROR_CALCULATE_SYNTAX = 'Calculate error: syntax tree fault. Token: "%s"',
    ERROR_COMPILE_SYNTAX = 'Compile error: syntax fault.',
    ERROR_UNDECLARED = 'Undeclared identifier: "%s"',
    ERROR_FUNCTION_PARSE = 'Function "%s" parse error.',
    ERROR_FUNCTION_PARAMETER = 'Function "%s" invalid number parameter.',
    ERROR_FUNCTION_INVALID = 'Function "%s" is not valid.',
    ERROR_FUNCTION_HEADER = 'Function header "%s" is not valid.',
    ERROR_FUNCTION_DELIMITOR = ERROR_FUNCTION_PARSE + ': delimitor "%s" expected between arguments.',
    ERROR_FUNCTION_CLOSE = ERROR_FUNCTION_PARSE + ': parenthesis close expected.',
    ERROR_FUNCTION_TYPE = ERROR_FUNCTION_PARSE + ': argurment expected type string.',
    ERROR_FUNCTION_PARENTHESIS = 'Compile error: parenthesis mismatch. Expression: %s',
    ERROR_TOKEN_LIST = 'Tokens list error.',
    STR_BOOLEAN = '&|?',
    STR_OPERATION = '*/^%+-!~',  // supported operations numeric
    STR_RELATION = '<>=<=',      // supported operations relation
    STR_PARAMDELIMITOR =',',     // function parameter delimitor
    STR_OLD_VALUE = '_',
    STR_PARENTHESIS_OPEN = '{[(',
    STR_PARENTHESIS_CLOSE = '}])',
    A_BOOLEAN = ['&', '|', '?'],     // & (and), | (or), ? (xor)
    A_OPERATION = ['/', '-+', '*%^', '~!'],

    ttNone = 0, ttOldValue = 1, ttNumeric = 2, ttOperation = 3,
    ttString = 4, ttParamDelimitor = 5, ttParenthesisOpen = 6,
    ttParenthesisClose = 7, ttRelation = 8, ttBoolean = 9,

    eoInternalFirst = 0, eoEventFirst = 1,
    
    ascii_letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
    digits = '0123456789';

var
    core_version = "1.4",
    core_author  = "Allan Lima <allan.kardek@gmail.com>",

    ExpVariable = function (varName, varValue) {
        this.varName = varName;
        this.varValue = varValue;
    },
  
    /* Class used by TExpParser and TExpNode for breaking text into tokens and building a syntax tree */
    ExpToken = function (tokenText, tokenType) {
        this.tokenText = tokenText;
        this.tokenType = tokenType;
    },
  
    ExpParser = function (expression) {
        this.expression = expression;
        this.tokens = [];
        this._variables = [];
        this._pos = 0;
        this._error = '';
    },
  
    ExpNode = function (owner, parentNode, tokens) {
      
        this.owner  = owner;
        this.parent = parentNode;

        if (parentNode) {
            this.level = parentNode.level + 1;
        } else {
            this.level = 0;
        }

        this.tokens     = tokens.slice(0);  // python: self.tokens = tokens[:]
        this.childLeft  = [];
        this.childRight = [];

    },

    ExpFunction = function (owner) {

        this.owner = owner;
        this._text = '';       // AsString texto completo da função
        this.funcname = '';     // Nome da função
        this.head = '';
        this.bold = '';      // corpo da função, após = 
        this.args = [];
        this.values = [];

    },
    
    formatSimple;

/**
 * Expose `FatExpression`.
 */
   
exports = module.exports = FatExpression;

    
/* implementacion */

formatSimple = function(text, args) {
    if ( args.length > 0 ) {
        for (var i = 0; i < args.length; i++) {
            text = text.replace('%s', args[i]);
        }
    }
    return text;
}

ExpParser.prototype.tokenCount = function () {
	return this.tokens.length;
};
  
ExpParser.prototype.addVariables = function (variables) {
	
    var item, value, sname, svalue;

    if ( typeof variables === 'string' ) {
        this.addVariables(variables.split(';'));
    } else {
        for (var i = 0; i < variables.length; i++) {
            item = variables[i];
		    if ( item.indexOf('=') > -1 ) {
                value = item.split('=', 2);
			    sname = value[0].toLowerCase();
                svalue = value[1];
                this.setVariable(sname, svalue);
            }
	    }
    }
	
}
      
ExpParser.prototype.validate = function () {
    var pilha = [], ch;
    for (var i = 0; i < this.expression.length; i++) {
        ch = this.expression.charAt(i);
        if (STR_PARENTHESIS_OPEN.indexOf(ch) > -1) {
            pilha.push(ch);
        } else if (STR_PARENTHESIS_CLOSE.indexOf(ch) > -1) {
            if (pilha.length === 0) {
                this._error = ERROR_COMPILE_SYNTAX;
                return false;
            }
            if (pilha[pilha.length-1] !== STR_PARENTHESIS_OPEN.charAt(STR_PARENTHESIS_CLOSE.indexOf(ch))) {
                this._error = formatSimple(ERROR_FUNCTION_PARENTHESIS, [this.expression]);
				return false;
            }
			pilha.pop();
        }
	}
	if (pilha.length > 0) {
		this._error = ERROR_COMPILE_SYNTAX;
		return false;
	}
    
    return true;
    
};

ExpParser.prototype.getTokenType = function(s, first) {
    var p;
    
    if (s === STR_PARAMDELIMITOR) { return ttParamDelimitor; }

    if (STR_OPERATION.indexOf(s) > -1) { return ttOperation; }
    
    if (STR_PARENTHESIS_OPEN.indexOf(s) > -1) { return ttParenthesisOpen; }
    
    if (STR_PARENTHESIS_CLOSE.indexOf(s) >-1) { return ttParenthesisClose; }
    
    if (STR_RELATION.indexOf(s) > -1) { return ttRelation; }
    
    if (STR_BOOLEAN.indexOf(s) > -1) { return ttBoolean; }
    
    if ( (digits+'.').indexOf(s) > -1 ) { return ttNumeric; }
    
    if (s === STR_OLD_VALUE) { return ttOldValue; }
        
    // legal variable name characters
    if (first === true) {
        p = ascii_letters.indexOf(s);
    } else {
        p = (ascii_letters+digits).indexOf(s);
    }
        
    if (p > -1) {
        return ttString;
    } else {
        return ttNone;
    }
    
};

ExpParser.prototype.findVariable = function(name) {
	var i, sname = name.trim().toLowerCase();
    for (i = 0; i < this._variables.length; i++ ) {
        if ( this._variables[i].varName === sname ) {
            return this._variables[i].varValue;
        }
    }
    return null; 
}

ExpParser.prototype.setVariable = function(name, value) {
    var v = -1, sname = name.toLowerCase();
    for (var i = 0; i < this._variables.length; i++ ) {
        if ( this._variables[i].varName === sname ) {
            v = i;
            break;
        }
    }

    if ( v === -1 ) 
        this._variables.push(new ExpVariable(sname, value));
    else
        this._variables[v].varValue = value;

}

ExpParser.prototype.createToken = function (tokenText, tokenType) {
    var token = new ExpToken(tokenText, tokenType);
    this.tokens.push(token);
    return token;
};

ExpParser.prototype.readNextToken = function () {

    var ch, firstType, part, nextType;
    
    if (this._pos > this.expression.length-1)
        return null;

    do {
        ch = this.expression[this._pos];
        this._pos += 1;
    } while ( (ch === ' ') && (this._pos < this.expression.length-1) );
    
    firstType = this.getTokenType(ch, true);

    if (firstType === ttNone) {
        throw formatSimple(ERROR_CHARACTER_ILLEGAL, [ch]);
    }

    if ([ttOperation, ttParenthesisOpen, ttParenthesisClose, ttBoolean].indexOf(firstType) > -1) {
        return this.createToken(ch, firstType);
    }
     
    if (firstType === ttRelation) {

        if (this._pos < this.expression.length) {
            part = ch;
            ch   = this.expression[this._pos];
            nextType = this.getTokenType(ch, false);

            if ( (firstType === nextType) && (firstType === ttRelation) && (STR_RELATION.indexOf(part+ch) > -1) ) {
                this._pos += 1;
                part = part + ch;
            }

        }
            
        return this.createToken(part, firstType);
    }
    
    part = ch;

    while (this._pos < this.expression.length) {

        ch       = this.expression[this._pos];
        nextType = this.getTokenType(ch, false);

        if ( (nextType === firstType) || (firstType === ttString && nextType === ttNumeric) ) {
            part += ch;
        } else {
            return this.createToken(part, firstType);
        }

        this._pos += 1;
    }
    

    return this.createToken(part, firstType);
    
};

ExpParser.prototype.readFirstToken = function () {
    this.tokens = [];
    this._pos = 0;
    return this.readNextToken();
 };
 
/* class ExpNode
    syntax-tree node. this engine uses a bit upgraded binary-tree
*/
 
ExpNode.prototype.tokenCount = function () {
    return this.tokens.length;
};

ExpNode.prototype.token = function () {
    if (this.tokens.length > 1) {
        throw ERROR_TOKEN_LIST;
    }
	return this.tokens[0];
};

ExpNode.prototype._removeSorroundingParenthesis = function () {
    var iFirst = 0,
        iLast  = this.tokens.length-1,
        i, iLevel, bSorrounding;

    while (iLast > iFirst) {

        if ( (this.tokens[iFirst].tokenType === ttParenthesisOpen) && (this.tokens[iLast].tokenType === ttParenthesisClose) ) {

            i = 0;
            iLevel = 0;
            bSorrounding = true;

            do {

                if (this.tokens[i].tokenType === ttParenthesisOpen) {
                    iLevel += 1;
                } else if (this.tokens[i].tokenType === ttParenthesisClose) {
                    iLevel -= 1;
                }
                
                if ( (iLevel === 0) && (i < this.tokens.length-1) ) {
                    bSorrounding = false;
                    break;
                }

                i += 1;

            } while (i < this.tokens.length);

            if (bSorrounding) {
                this.tokens.pop();
                this.tokens.shift();
            } else {
                return;
            }

        } else {
            return;
        } // if

        iFirst = 0;
        iLast = this.tokens.length-1;
        
    }  // while

};

ExpNode.prototype._parseFunction = function () {
    var i, lTokens = [], iDelimitor, iDelimitorLevel;
    
    if ( (this.tokens.length < 3) ||
         (this.tokens[0].tokenType !== ttString) ||
         (this.tokens[1].tokenType !== ttParenthesisOpen) ||
         (this.tokens[this.tokens.length-1].tokenType !== ttParenthesisClose) ) {
        return false;
    }

	this.tokens.pop();
	this.tokens.splice(1, 1);

	while ( this.tokens.length > 1 ) {

        lTokens = [];
        iDelimitor = -1;
        iDelimitorLevel = 0;

        for (i = 1; i < this.tokens.length; i++) {  // i in range(1, self.tokenCount):

            if (this.tokens[i].tokenType === ttParenthesisOpen) {
                iDelimitorLevel += 1;
            } else if (this.tokens[i].tokenType === ttParenthesisClose) {
                iDelimitorLevel -= 1;
            } else if ( (this.tokens[i].tokenType === ttParamDelimitor) && (iDelimitorLevel === 0) ) {
                iDelimitor = i - 1;
                this.tokens.splice(i, 1);  // python: self.tokens.pop(i)
                break;
            }

            if (iDelimitorLevel < 0) {
               throw formatSimple(ERROR_FUNCTION_PARSE, [this.tokens[i].tokenText]);
            }
                
        }
        
        if ( iDelimitor === -1 ) {
            iDelimitor = this.tokens.length-1;
        }

        for (i = 1; i < iDelimitor+1; i++) { // python: for (i in range(1, iDelimitor+1))
            lTokens.push(this.tokens[1]);
            this.tokens.splice(1, 1);  // python: self.tokens.pop(1)
        }

        var child = new ExpNode(this.owner, this, lTokens);
        child.build();
        this.childRight.push(child);
        
    }
    
	return true;
    
};

ExpNode.prototype._splitToChildren = function (tokenIndex) {

	var i, iTokenCount = this.tokens.length,
        left  = [], rigth = [], child;

    if (tokenIndex < iTokenCount - 1) {
        for (i = iTokenCount-1; i > tokenIndex; i--) { // for i in range(iTokenCount-1, tokenIndex, -1):
            rigth.unshift(this.tokens[i]);             //     rigth.insert(0, this.tokens[i])
            this.tokens.splice(i, 1);                  //     self.tokens.pop(i)
        }
        
        child = new ExpNode(this.owner, this, rigth);
        this.childRight.push(child);
        child.build();
        
    }

    if (tokenIndex > 0) {
        for (i = 0; i < tokenIndex; i++) { //for i in range(tokenIndex-1, -1, -1)
            left.push(this.tokens[0]);     //    left.insert(0, self.tokens[i])
            this.tokens.shift();         //      self.tokens.pop(i)
        }
        child = new ExpNode(this.owner, this, left);
        this.childLeft.push(child);
        child.build();
    }
    
};

/* Least Significant Operation Token Index */
ExpNode.prototype._findLSOTI = function () {
	
    var token, posArray, iLevel, iBoolean, iOperation,
        iPriorityBoolean, iPriorityOperation, iPriorityRelation, iNewPriorityBoolean, iNewPriorityOperation;
    
    posArray = function (substr, aString) {
        var s, result = -1;
        for (var i = 0; i < aString.length; i++) {
            s = aString[i];
            result = s.indexOf(substr);
            if ( result > -1 ) {
                return (i+1)*10+result;
            }
        }
        return result;
    };

    iLevel = 0;
    iBoolean = 0;
    iOperation = 0;

    iPriorityBoolean = -1;
    iPriorityOperation = -1;
    iPriorityRelation = -1;

    for (var i = 0; i < this.tokens.length; i++) {

        token = this.tokens[i];

        if (token.tokenType === ttParenthesisOpen) {
            iLevel += 1;
        } else if (token.tokenType === ttParenthesisClose) {
            iLevel -= 1;
        }

        if (iLevel < 0) {
            throw formatSimple(ERROR_FUNCTION_PARENTHESIS, [this.owner.text]);
        }

        if ( (iLevel === 0) && (token.tokenType === ttBoolean) ) {
            iNewPriorityBoolean = posArray(token.tokenText, A_BOOLEAN);
            if ( (iPriorityBoolean === -1) || (iNewPriorityBoolean <= iPriorityBoolean) ) {
                iPriorityBoolean = iNewPriorityBoolean;
                iBoolean = i;
            }

        } else if ( (iLevel === 0) && (token.tokenType === ttRelation) ) {
            iPriorityRelation = i;

        } else if ( (iLevel === 0) && (token.tokenType === ttOperation) ) {
            iNewPriorityOperation = posArray(token.tokenText, A_OPERATION);
            if ( (iPriorityOperation === -1) || (iNewPriorityOperation <= iPriorityOperation) ) {
                iPriorityOperation = iNewPriorityOperation;
                iOperation = i;
            }
        }
    }

	if (iPriorityBoolean > -1) {
        return iBoolean;
    } else if (iPriorityRelation > -1) {
        return iPriorityRelation;
    } else if (iPriorityOperation > -1) {
        return iOperation;
    } else {
        return -1;
	}

}

ExpNode.prototype.build = function () {

    var iLSOTI;
    
    this._removeSorroundingParenthesis();

    if ( this.tokens.length < 2 ) {
        return this;
    }

    iLSOTI = this._findLSOTI();

    if ( iLSOTI < 0 ) {
        if (!this._parseFunction()) {
            throw ERROR_COMPILE_SYNTAX + '. Expression: '+this.owner._text;
        }
    } else {
        this._splitToChildren(iLSOTI);
    }

    return this;
    
}

ExpNode.prototype.evaluate = function () {

    var value, args = [], token;

    for (var i = 0; i < this.childRight.length; i++) {
        value = this.childRight[i].calculate();
        args.push(value);
    }
    
    value = null;
    token = this.token();

    if ( this.owner instanceof FatExpression ) { // if isinstance(self.owner, FatExpression):
        value = this.owner.evaluate(token.tokenText, args);
    } else if ( this.owner instanceof ExpFunction ) {
        value = this.owner.evalArgs(token.tokenText, args);
    }

    if ( value === null ) {
        throw formatSimple(ERROR_UNDECLARED, [token.tokenText]);
    }

    return value;

}

ExpNode.prototype.operParamateres = function () {

    var token = this.token(), result = true;

    if ([ttOperation, ttRelation, ttBoolean].indexOf(token.tokenType) > -1) {

        if ( (token.tokenText === '-') && (this.childLeft.length === 0) && (this.childRight.length === 1) ) {
            result = true;
        } else if (token.tokenText === '!')  { // factorial
            result = ( (this.childLeft.length === 1) && (this.childRight.length === 0) );
        } else if (token.tokenText === '~')  { // negation
            result = ( (this.childLeft.length === 0) && (this.childRight.length === 1) );
        } else if (STR_OPERATION.indexOf(token.tokenText) > -1) {
            result = ( (this.childLeft.length === 1) && (this.childRight.length === 1) );
        } else if (STR_RELATION.indexOf(token.tokenText) > -1) {
            result = ( (this.childLeft.length === 1) && (this.childRight.length === 1) );
        } else if (A_BOOLEAN.indexOf(token.tokenText) > -1) {
            result = ( (this.childLeft.length === 1) && (this.childRight.length === 1) );
        }
    }
    
    return result;
    
}

ExpNode.prototype.factorial = function (num) {

    // If the number is less than 0, reject it.
    if (num < 0) {
        return -1;
    }  else if (num === 0) {	// If the number is 0, its factorial is 1.
        return 1;
    }  else {   // Otherwise, call this recursive procedure again.
        return (num * this.factorial(num - 1));
    }
    
}

ExpNode.prototype.calculate = function () {

    if (this.tokens.length !== 1) {
        return 0;
    }

    var token = this.token(), result = 0, left, rigth;

    if (!this.operParamateres()) {
        throw formatSimple(ERROR_CALCULATE_SYNTAX, [token.tokenText]);
    }

    if ( token.tokenType === ttOldValue ) {
        result = this.owner._value_old;

    } else if (token.tokenType === ttNumeric) {
        result = parseFloat(token.tokenText);

    } else if (token.tokenType === ttString) {
        if (token.tokenText.toLowerCase() === 'true') {
            result = 1;
        } else if (token.tokenText.toLowerCase() === 'false') {
            result = 0;
        } else {
            result = this.evaluate();
        }

    } else if (token.tokenType === ttOperation) {

        if (token.tokenText === '+') {
            result = (this.childLeft[0].asFloat() + this.childRight[0].asFloat());
        } else if (token.tokenText === '-') {
            if ( (this.childLeft.length === 0) && (this.childRight.length === 1) ) {
                result = this.childRight[0].calculate()*(-1);
            } else {
                result = this.childLeft[0].asFloat() - this.childRight[0].asFloat();
            }
        } else if ( token.tokenText === '*' ) {
            result = this.childLeft[0].asFloat() * this.childRight[0].asFloat();
        } else if ( token.tokenText === '/' ) {
            result = this.childLeft[0].asFloat() / this.childRight[0].asFloat();
        } else if ( token.tokenText === '^' ) {
            result = Math.pow( this.childLeft[0].asFloat(), this.childRight[0].asFloat());
        } else if ( token.tokenText === '%' ) {  // module
            result = this.childLeft[0].asInt() % this.childRight[0].asInt();
        } else if ( token.tokenText === '!' ) { // factorial
            result = this.factorial(this.childLeft[0].asInt());
        } else if ( token.tokenText === '~' ) {
            if ( this.childRight[0].asInt() === 1 ) {
                result = 0;
            } else {
                result = 1;
            }
        }

    } else if (token.tokenType === ttBoolean) {

        left  = this.childLeft[0].asFloat();
        rigth = this.childRight[0].asFloat();

        if ( (token.tokenText === '&') && (left+rigth === 2) ) {
            result = 1;
        } else if ( (token.tokenText === '|') && (left+rigth === 2) ) {
            result = 1;
        } else if ( (token.tokenText === '?') && (left+rigth === 1) ) {
            result = 1;
        }

    } else if (token.tokenType === ttRelation) {

        left  = this.childLeft[0].calculate();
        rigth = this.childRight[0].calculate();

        if ( (token.tokenText === '>') && (left > rigth) ) {
            result = 1;
        } else if (token.tokenText === '<' && left < rigth) {
            result = 1;
        } else if (token.tokenText === '<=' && left >= rigth) {
            result = 1;
        } else if ( (token.tokenText === '>=') && (left >= rigth) ) {
            result = 1;
        } else if ( (token.tokenText === '<>') && (left !== rigth) ) {
            result = 1;
        } else if ( (token.tokenText === '=') && (left === rigth) ) {
           result = 1;
        }
    
    }

    return result;
	
}  // calculate

ExpNode.prototype.asFloat = function() {
	var value = this.calculate();
	if ( typeof(value) === 'string') {
		value = parseFloat(value);
	}
    return value;
}

ExpNode.prototype.asInt = function() {
    return Math.round(this.calculate());
}

/* ExpFunction */

ExpFunction.prototype.argCount = function () {
    return this.args.length;
}

ExpFunction.prototype.call = function (values) {
    var parser, token, tree;

    if ( this.args.length !== values.length ) {
        throw formatSimple(ERROR_FUNCTION_PARAMETER, [this.name]);
    }

    this.values = values.slice(0);

    parser = new ExpParser(this.bold);
    token = parser.readFirstToken();

    while ( token !== null ) {
        token = parser.readNextToken();
    }

    tree = new ExpNode(this, null, parser.tokens);
    tree.build();

    return tree.calculate();

}

ExpFunction.prototype.evalArgs = function (text, args) {
    for (var i = 0; i < this.args.length; i++) {
        if ( this.args[i].toLowerCase() === text.toLowerCase() ) {
            return this.values[i];
        }
    }

    if ( this.owner instanceof FatExpression ) {
        return this.owner.evaluate(text, args);
    } else {
        return 0;
    }

}

ExpFunction.prototype.setHeader = function(value) {

    this.args = [];
    this.head = value;
    this.funcname = '';

    var ExpectFuncName = true,
        ExpectParenthesisOpen = true,
        ExpectDelimitor = false,
        ExpectParenthesisClose = false, parser, token;
    
    parser = new ExpParser(value);
    token = parser.readFirstToken();

    while ( token !== null ) {

        if ( ExpectFuncName ) {

            if ( token.tokenType !== ttString ) {
                throw formatSimple(ERROR_FUNCTION_INVALID, [this._text]);
            }

            this.funcname = token.tokenText;
            ExpectFuncName = false;

        } else if ( ExpectParenthesisOpen ) {

            if ( token.tokenType !== ttParenthesisOpen ) {
                throw formatSimple(ERROR_FUNCTION_HEADER, [value]);
            }

            ExpectParenthesisOpen  = false;
            ExpectParenthesisClose = true;

        } else if ( !ExpectParenthesisClose ) {
            throw formatSimple(ERROR_FUNCTION_HEADER, [value]);

        } else if ( ExpectDelimitor ) {

            if ( (token.tokenType !== ttParamDelimitor) && (token.tokenType !== ttParenthesisClose) ) {
                throw formatSimple(ERROR_FUNCTION_DELIMITOR, [this.funcname, STR_PARAMDELIMITOR]);
            }

            ExpectDelimitor = false;

            if ( token.tokenType === ttParenthesisClose ) {
                ExpectParenthesisClose = false;
            }

        } else if ( token.tokenType === ttString ) {
            this.args.push(token.tokenText);
            ExpectDelimitor = true;

        } else {
            throw formatSimple(ERROR_FUNCTION_TYPE, [this.funcname]);
        }

        token = parser.readNextToken();

    }

    if ( ExpectFuncName ) {
        throw formatSimple(ERROR_FUNCTION_HEADER, [value]);
    }

    if ( ExpectParenthesisClose ) {
        throw formatSimple(ERROR_FUNCTION_CLOSE, [this.funcname]);
    }

}

ExpFunction.prototype.asString = function (value) {
    var i = value.indexOf('='), h, b;
    if ( i === -1 ) {
        throw formatSimple(ERROR_FUNCTION_INVALID, [value]);
    }

    h = value.substring(0, i);
    b = value.substring(i+1);  // python: head, self.function = value.split('=', 1)

    this._text = value;
    this.bold = b;
    this.setHeader(h);

}

/* FatExpression */
function FatExpression() {

    this.compiled      = false;
    this.evaluateOrder = eoInternalFirst;
    this.functions     = [];
    this.expParser     = new ExpParser();
    this._text         = [];
    this._evaluates    = [];
    this._value        = null;
    this._value_old    = null;

}

FatExpression.prototype.addVariables = function(variables) {
    this.expParser.addVariables(variables);
}

FatExpression.prototype.clearVariables = function () {
    this.expParser._variables = [];
}

FatExpression.prototype.addEvaluate = function (evaluate) {
    this._evaluates.push(evaluate);
}

FatExpression.prototype.clearEvaluate = function () {
    this._evaluates = [];
}

FatExpression.prototype.compile = function () {
    
    var text, variable, expression, lista, value, token, tree;
    
    for (var i = 0; i < this._text.length; i++) {

        text = this._text[i];

        if ( text.trim() === '' ) {
           continue;
        }
        
        if ( text.indexOf(':') > -1 ) {
            lista = text.split(':');
            variable = lista[0];
            expression = lista[1];
        } else {
            variable = '';
            expression = text.trim();
        }

        this.expParser.expression = expression;
        this.expParser.validate();

        token = this.expParser.readFirstToken();
        while ( token !== null ) {
            token = this.expParser.readNextToken();
        }

        tree = new ExpNode(this, null, this.expParser.tokens);
        tree.build();
        
        this._value = tree.calculate();
        this._value_old = this._value;

        if ( variable !== '' ) {
            this.expParser.setVariable(variable, this._value);
        }
        
    }
    
    //this.expParser._variables = [];
    
}

FatExpression.prototype.findFunction = function (findname) {
    var _function;
    for (var i = 0; i < this.functions.length; i++) {
        _function = new ExpFunction(this);
        _function.asString(this.functions[i]);
        if ( _function.funcname.toLowerCase() === findname.toLowerCase() ) {
            return _function;
        }
    }
    return null;
}

FatExpression.prototype.evaluate = function (text, args) {
  
    var i, value, _function, _text;
    
    _text = text.trim().toLowerCase();
    
    if ( this.evaluateOrder === eoEventFirst ) {
        value = this.evaluateCustom(_text, args);
        if ( value !== null) {
            return value;
        }
        for (i = 0; i < this._evaluates.length; i++) {
            value = this._evaluates[i](_text, args);
            if ( value !== null ) {
                return value;
            }
        }
    }
    
    value = this.expParser.findVariable(_text);
    
    if ( value !== null ) {
        return value;
    }

    _function = this.findFunction(_text);
    
    if ( _function !== null ) {
        return _function.call(args);
    }

    if ( this.evaluateOrder === eoInternalFirst ) {
        value = this.evaluateCustom(_text, args);
        if ( value !== null) {
            return value;
        }
        for (i = 0; i < this._evaluates.length; i++) {
            value = this._evaluates[i](_text, args);
            if ( value !== null ) {
                return value;
            }
        }
    }
    
    return null;

}

FatExpression.prototype.value = function () {

    if ( this._value_old === null ) {
        this._value_old = 0.0;
    }
    
    this._value = 0.0;
    
    this.compile();
    
    return this._value;

}

FatExpression.prototype.getBoolean = function () {
    if ( this.value() === 0 ) {
        return false;
    } else {
        return true;
    }
}

FatExpression.prototype.getInteger = function () {
    return this.value().toInteger();
}

FatExpression.prototype.getString = function () {
    return this.value().toFixed(4);
}

FatExpression.prototype.addFunctions = function (functions) {
	var _fs;
    if (typeof functions === 'string') {
        _fs = functions.split(';');
    } else {
        _fs = functions;
    }
    for (var i = 0; i < _fs.length; i++) {
       this.functions.push(_fs[i]);
    }
}

FatExpression.prototype.clearFunctions = function () {
    this.functions = [];
}

FatExpression.prototype.getText = function () {
    return this._text.join(';');
}

FatExpression.prototype.setText = function (value) {

    this.compiled = false;

    if ( typeof value === 'string' ) {
        if ( value.indexOf(';') > -1 ) {
            this._text = value.split(';');
        } else {
            this._text = [value];
        }
    } else {
        this._text = value.slice(); //  python: value[:];
    }

}

FatExpression.prototype.evaluateCustom = function (text, args) {

    var argCount = args.length, errorParameter;

    errorParameter = function (paramCount) {
        if ( (paramCount === null) || (argCount !== paramCount) ) {
            throw formatSimple(ERROR_FUNCTION_PARAMETER, [text]);
        }
    };

    if ( text === 'abs' ) {
        errorParameter(1);
        return Math.abs(args[0]);

    } else if ( text === 'frac' ) {
        errorParameter(1);
        return args[0] - Math.trunc(args[0]);

    } else if ( text === 'max' ) {
        return Math.max(args);

    } else if ( text === 'min' ) {
        return Math.min(args);

    } else if ( text === 'mod' ) {
        errorParameter(2);
        return Math.trunc(args[0]) % Math.trunc(args[1]);

    } else if ( text === 'round' ) {
        var iDec = 2;
        if ( argCount === 0 ) {
            errorParameter();
        } else if ( argCount === 2 ) {
            iDec = Math.trunc(args[1]);
        }
    
        return parseFloat(args[0]).toFixed(iDec);

    } else if ( text === 'sign' ) {
        errorParameter(1);
        if ( args[0] === Math.abs(args[0]) ) {
            return 1;
        } else if ( args[0] === 0 ) {
            return 0;
        } else {
            return -1;
        }

    } else if ( text === 'sqrt' ) {   // Returns the square root of X.
        errorParameter(1);
        return Math.sqrt(args[0]);

    } else if ( text === 'sin' ) {    // Returns the sine of the angle in radians.
        errorParameter(1);
        return Math.sin(args[0]);

    } else if ( text === 'cos' ) {   // Calculates the cosine of an angle.
        errorParameter(1);
        return Math.cos(args[0]);

    } else if ( text === 'tan' ) {
        errorParameter(1);
        return Math.tan(args[0]);

    } else if ( text === 'atan' ) {  // Calculates the arctangent of a given number.
        errorParameter(1);
        return Math.atan(args[0]);

    } else if ( text === 'log' ) {   // Returns the natural log of a real expression.
        errorParameter(1);
        return Math.log(args[0]);

    } else if ( text === 'exp' ) {   // Returns the exponential of X.
        errorParameter(1);
        return Math.exp(args[0]);

    //} else if ( text === 'sum' ) {
    //      return sum(args);

    } else if ( text === 'trunc' ) {
        errorParameter(1);
        return Math.trunc(args[0]);

    } else if ( text === 'and' ) {

        for ( var i = 0; i < args.length; i++) {
            if ( args[i] === 'false' ) {
                return 0;
            } else if ( !Boolean(args[i]) ) {
                return 0;
            }
        }
            
        return 1;

    } else if ( text === 'or' ) {
            
        for ( var i = 0; i < args.length; i++) {
            if ( (args[i] !== 'false') || Boolean(args[i]) ) {
                return 0;
            }
        }
            
        return 1;
            
    } else if ( text === 'if' ) {
        errorParameter(3);
        if ( Boolean(args[0]) ) {
            return args[1];
        } else {
            return args[2];
        }

    } else if ( text === 'random' ) {
        errorParameter(0);
        return Math.random();
    }
    
    return null;

}
