%{
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ptucc_parser.tab.h"
#include "cgen.h"

int line_num = 1;

/* 
	A primitive macro facility:
	just one macro is allowed to be defined! 
*/
#define MAXMACRO 32

char* mactable[MAXMACRO][2];
int mactable_size = 0;

/* Return 1 on success, 0 on failure (macro table full) */
int set_macro(char* name, char* def);

/* Return def for macro, or NULL if no such macro is defined. */
char* get_macro(char* name);

%}

ID [a-zA-Z_][0-9a-zA-Z_]*
DIGIT  [0-9]
NUMBER  {DIGIT}{DIGIT}* 
DECIMAL ("."{NUMBER})|({NUMBER}("."{NUMBER}?)?)
REAL    {DECIMAL}([eE][+-]?{NUMBER})?
BOOLEAN  ["true"|"false"]
ESC_CHARS  ("\\n"|"\\t"|"\\r"|"\\\\"|"\\\'"|"\\\"")
PUNCT_SYMB     ("!"|"@"|"#"|"$"|"%"|"^"|"&"|"*"|"?"|":"|"."|"("|")"|"+"|"-"|"^"|"="|"/")
ACCEPTABLE_CHARS ([A-Z]|[a-z]|[0-9]|" "|{PUNCT_SYMB})
STRING1  ("\"")({ACCEPTABLE_CHARS}*{ESC_CHARS}*{ACCEPTABLE_CHARS}*)*("\"")
STRING2  ("\'")({ACCEPTABLE_CHARS}*{ESC_CHARS}*{ACCEPTABLE_CHARS}*)*("\'")
STRING   {STRING1}|{STRING2}

%x comment
%x macro

%%

@defmacro[ \r\t]+       BEGIN(macro);
<macro>{ID}             {
							/* Store macro name */
							char* name = strdup(yytext);
							char* def = NULL;
							size_t deflen = 0;
							char c;

							FILE* deff = open_memstream(&def, &deflen);

							while((c=input())!='\n')
							   fputc(c, deff);
							fclose(deff);

							if(!set_macro(name, def))
								yyerror("lexer error: failed to define macro '%s'\n", name);
							BEGIN(INITIAL);
						};

program					return KW_PROGRAM;
begin 					return KW_BEGIN;
end						return KW_END;	
":="       				return ASSIGN ;	
and						return KW_AND ;	
div						return KW_DIV;	
function				return KW_FUNCTION ;	
mod						return KW_MOD ;
procedure				return KW_PROCEDURE;
result					return KW_RESULT;
array					return ARRAY ;
do  					return KW_DO ;
goto					return KW_GOTO;
not						return KW_NOT ;
return  				return KW_RETURN;
boolean					return KW_BOOLEAN;
else 					return KW_ELSE ;
if    					return KW_IF ;
of						return KW_OF;
real 					return KW_REAL;
then					return KW_THEN ;
char 					return KW_CHAR;
for						return KW_FOR ;
integer					return KW_INTEGER ;
or 						return KW_OR ;
repeat					return KW_REPEAT ;
until					return KW_UNTIL ;
var 					return KW_VAR ;
while					return KW_WHILE ;
to 						return KW_TO ;
downto					return KW_DOWNTO ;
"<>"					return KW_DIFFERENT ;
"<="					return KW_LESS_OR_EQ ;
">="					return KW_MORE_OR_EQ ;
"&&"					return KW_AND_SYMB ;
"||"					return KW_OR_SYMB ;
type 					return KW_TYPE ;
true					return KW_TRUE ;
false					return KW_FALSE ;

";"						return ';';		
"+"						return '+';
"*"						return '*';
"."						return '.';
"("						return '(';
")"						return ')';	
"-"						return '-';		
"/"						return '/';
"="						return '=';
"<"						return '<';
">"						return '>';
"!"						return '!';	
","						return ',';	
"["						return '[';	
"]"						return ']';	
":"						return ':';	
   
{ID}  					{
						   char* def = get_macro(yytext);
						   if(def==NULL) {
						   		yylval.crepr = strdup(yytext);
						   		return IDENT;
						   	}
						   for(int i=strlen(def); i>0; i--) {
						   	  unput(def[i-1]);
						   }
						} 		

{NUMBER}				{ yylval.crepr = strdup(yytext); return POSINT; }

{REAL}					{ yylval.crepr = strdup(yytext); return REAL; }

{STRING}				{ yylval.crepr = strdup(yytext); return STRING; }

{BOOLEAN}				{ yylval.crepr = strdup(yytext); return BOOLEAN; }

"(*"					BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*)\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             ++line_num;
<comment>"*"+")"        BEGIN(INITIAL);

[ \r\t]					/* skip whitespace */
\n 						++line_num;
<<EOF>> 				return EOF;

.        { yyerror("Unrecognized token %s : \n", yytext); }

%%

int set_macro(char* name, char* def)
{
	/* Check to see if macro already defined, and redefine it. */
	int i;
	for(i=0; i<mactable_size; i++) {
		if(strcmp(mactable[i][0], name)==0) {
			/* found ! */
			free(name);
			free(mactable[i][1]);
			mactable[i][1] = def;
			break;
		}
	}
	if(i<mactable_size)
		return 1;
	else if(mactable_size < MAXMACRO) {
		/* new entry */
		assert(i==mactable_size);
		mactable[i][0] = name;
		mactable[i][1] = def;
		mactable_size++;
		return 1;
	}
	else
		return 0;
}

char* get_macro(char* name)
{
	for(int i=0;i<mactable_size; i++) {
		if(strcmp(mactable[i][0], name)==0)
			return mactable[i][1];
	}
	return NULL;
}


