/*
 *  The scanner definition for COOL.
 */

import java_cup.runtime.Symbol;

%%

%{

/*  Stuff enclosed in %{ %} is copied verbatim to the lexer class
 *  definition, all the extra variables/functions you want to use in the
 *  lexer actions should go here.  Don't remove or modify anything that
 *  was there initially.  */

    // Max size of string constants
    static int MAX_STR_CONST = 1025;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();

    private int curr_lineno = 1;
    int get_curr_lineno() {
	return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
	filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
	return filename;
    }
%}

%init{

/*  Stuff enclosed in %init{ %init} is copied verbatim to the lexer
 *  class constructor, all the extra initialization you want to do should
 *  go here.  Dont remove or modify anything that was there initially. */

    // empty for now
%init}

%eofval{

/*  Stuff enclosed in %eofval{ %eofval} specifies java code that is
 *  executed when end-of-file is reached.  If you use multiple lexical
 *  states and want to do something special if an EOF is encountered in
 *  one of those states, place your code in the switch statement.
 *  Ultimately, you should return the EOF symbol, or your lexer won't
 *  work.  */

    switch(yy_lexical_state) {
    case YYINITIAL:
	/* nothing special to do in the initial state */
	break;
	/* If necessary, add code for other states here, e.g:
	   case COMMENT:
	   ...
	   break;
	*/
    }
    return new Symbol(TokenConstants.EOF);
%eofval}

%class CoolLexer
%cup

%%

DARROW    "=>"
LE        "<="
ASSIGN    "<-"
COMMENTL  "(*"
COMMENTR  "*)"
COMMENTN  --
INTCONST  [0-9]+
STRCONST  \"[^"\n]*\"
BOOLCONST t[rR][uU][eE]|f[aA][lL][sS][eE]
TYPEIDENT [A-Z][a-zA-Z0-9_]*
OBJIDENT  [a-z][a-zA-Z0-9_]*
SYMBOL    [-.(){}:@,;+*/~<=]
CLASS    [cC][lL][aA][sS][sS]
ELSE     [eE][lL][sS][eE]
FI       [fF][iI]
IF       [iI][fF]
IN       [iI][nN]
INHERITS [iI][nN][hH][eE][rR][iI][tT][sS]
LET      [lL][eE][tT]
LOOP     [lL][oO][oO][pP]
POOL     [pP][oO][oO][lL]
THEN     [tT][hH][eE][nN]
WHILE    [wW][hH][iI][lL][eE]
CASE     [cC][aA][sS][eE]
ESAC     [eE][sS][aA][cC]
OF       [oO][fF]
NEW      [nN][eE][wW]
ISVOID   [iI][sS][vV][oO][iI][dD]
NOT      [nN][oO][tT]
%x COMMENT_BLOCK COMMENT_LINE STR_BLOCK STR_NUL_ERROR
%%
 /*
  *  Nested comments
  */
{COMMENTN} { BEGIN COMMENT_LINE; }
{COMMENTL} { comment_depth = 1; BEGIN COMMENT_BLOCK; }
<COMMENT_LINE>[^\n]* ;
<COMMENT_LINE>\n {
    curr_lineno++;
    BEGIN 0;
}
<COMMENT_BLOCK>[^*()\n]* ;
<COMMENT_BLOCK>\([^*\n]* ;
<COMMENT_BLOCK>\*[^*)\n]* ;
<COMMENT_BLOCK>\) ;
<COMMENT_BLOCK>\n {
    curr_lineno++;
}
<COMMENT_BLOCK>{COMMENTL} {
    comment_depth++;
}
<COMMENT_BLOCK>{COMMENTR} {
    if (comment_depth == 1) BEGIN 0;
    else if (comment_depth > 1) comment_depth--;
}
<COMMENT_BLOCK><<EOF>> {
    cool_yylval.error_msg = "EOF in comment";
    BEGIN 0;
    return (ERROR);
}
<INITIAL>"*)" {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR);
}
 /*
  *  The multiple-character operators.
  */
{DARROW}   { return (DARROW); }
{ASSIGN}   { return (ASSIGN); }
{LE}       { return (LE); }
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}    { return (CLASS); }
{ELSE}     { return (ELSE); }
{FI}       { return (FI); }
{IF}       { return (IF); }
{IN}       { return (IN); }
{INHERITS} { return (INHERITS); }
{LET}      { return (LET); }
{LOOP}     { return (LOOP); }
{POOL}     { return (POOL); }
{THEN}     { return (THEN); }
{WHILE}    { return (WHILE); }
{CASE}     { return (CASE); }
{ESAC}     { return (ESAC); }
{OF}       { return (OF); }
{NEW}      { return (NEW); }
{ISVOID}   { return (ISVOID); }
{NOT}      { return (NOT); }
{INTCONST} { 
    cool_yylval.symbol = inttable.add_string(yytext);
    return (INT_CONST);
}
{BOOLCONST} {
    for (int i = 0; yytext[i]; i++)
        yytext[i] = tolower(yytext[i]);
    if (strcmp("true", yytext) == 0) { java.lang.Boolean = true; }
    else { java.lang.Boolean = false; }
    return (BOOL_CONST);
}
{TYPEIDENT} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (TYPEID);
}
{OBJIDENT} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (OBJECTID);
}
{SYMBOL} {
    return (int) yytext[0];
}
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\" {
    string_buf_ptr = string_buf;
    BEGIN STR_BLOCK;
}
<STR_BLOCK>\" {
    BEGIN 0;
    *string_buf_ptr = '\0';
    if (string_buf_ptr >= string_buf + MAX_STR_CONST) {
        cool_yylval.error_msg = "String constant too long";
        return (ERROR);
    }
    else {
        cool_yylval.symbol = stringtable.add_string(string_buf);
        return (STR_CONST);
    }
}
<STR_BLOCK>\\b *string_buf_ptr++ = '\b';
<STR_BLOCK>\\t *string_buf_ptr++ = '\t';
<STR_BLOCK>\\n *string_buf_ptr++ = '\n';
<STR_BLOCK>\\f *string_buf_ptr++ = '\f';
<STR_BLOCK>\\\0 { BEGIN STR_NUL_ERROR; }
<STR_BLOCK>\\(.|\n) { *string_buf_ptr++ = yytext[1]; }
<STR_BLOCK>[^"\\\0\n]* {
    if (string_buf_ptr + sizeof(char) * strlen(yytext) < string_buf + MAX_STR_CONST) {
        strcpy(string_buf_ptr, yytext);
    }
    string_buf_ptr += sizeof(char) * strlen(yytext);
}
<STR_BLOCK>\n {
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN 0;
    return (ERROR);
}
<STR_BLOCK><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN 0;
    return (ERROR);
}
<STR_NUL_ERROR>\" {
    cool_yylval.error_msg = "String contains null character";
    BEGIN 0;
    return (ERROR);
}
\n {
    curr_lineno++;
}
[ \f\r\t\v] ;
. { 
    cool_yylval.error_msg = yytext;
    return (ERROR);
}
