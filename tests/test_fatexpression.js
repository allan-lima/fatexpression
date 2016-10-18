/**
 * node file
 */

var fatexpression = require('d:\\FatExpression\\fatexpression'),
    expression = new fatexpression(),
    test = function(text, value) {
        expression.setText(text);
        var v = expression.value();
        if ( value === null ) {
            console.log('  ok  '+text + ' = ' + v);
        } else if ( v === value ) {
            console.log('  ok  '+text + ' = ' + v);
        } else {
            console.log('  no  '+text + ' = ' + v + '  falha: esperado: '+value);
        }
    };


expression.addEvaluate( function (text, args) {
    if (text === 'b') {	return 23; }
    return null;
});

expression.addVariables('c=30;d=20');
expression.addFunctions(['x(a,b)=a*b', 'x2(a)=a']);

test('{2*3+[(10+2)/(5+1)]+2}', 10);
test('4*(2+(10/5)+(5^2))', 116);
test('x2(3)', 3);
test('x(c,x2(2))', 60);
test('x(x(c,x2(4)),x2(3))', 360);
test('(1+2)*3', 9);
test('1+2*3', 7);
test('1+(2*3)', 7);
test('1*2+3', 5);
test('3!', 6);
test('3!*2', 12);
test('a:2;_+a+B+c;_+a', 59);
test('~(3<2)', 1);
test('1|1', 1);
test('1?1', 0);
test('6/2.5', 2.4);
test('3<2&1', 0);
test('x:2;(-x)*3', -6);
test('if(1,2,3)+if(0,2,3)', 5);
test('log(1)', 0);
