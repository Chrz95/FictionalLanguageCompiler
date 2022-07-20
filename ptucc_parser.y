%{
#include <stdarg.h>
#include <stdio.h>	
#include "cgen.h"
#include <stdlib.h>
#include <string.h>	

extern long int yylex(void);
extern int line_num;
%}

%union
{
	char* crepr;
}


%token <crepr> IDENT
%token <crepr> POSINT 
%token <crepr> REAL 
%token <crepr> BOOLEAN
%token <crepr> STRING
%token <crepr> ASSIGN
%token <crepr> KW_PROGRAM 
%token <crepr> KW_BEGIN 
%token <crepr> KW_END
%token <crepr> KW_AND ;	
%token <crepr> KW_DIV;	
%token <crepr> KW_FUNCTION ;	
%token <crepr> KW_MOD ;
%token <crepr> KW_PROCEDURE;
%token <crepr> KW_RESULT;
%token <crepr> ARRAY ;
%token <crepr> KW_DO ;
%token <crepr> KW_GOTO;
%token <crepr> KW_NOT ;
%token <crepr> KW_RETURN;
%token <crepr> KW_BOOLEAN;
%token <crepr> KW_ELSE ;
%token <crepr> KW_IF ;
%token <crepr> KW_OF;
%token <crepr> KW_REAL;
%token <crepr> KW_THEN ;
%token <crepr> KW_CHAR;
%token <crepr> KW_FOR ;
%token <crepr> KW_INTEGER ;
%token <crepr> KW_OR ;
%token <crepr> KW_REPEAT ;
%token <crepr> KW_UNTIL ;
%token <crepr> KW_VAR ;
%token <crepr> KW_WHILE ;
%token <crepr> KW_TO ;
%token <crepr> KW_DOWNTO ;
%token <crepr> KW_DIFFERENT ;
%token <crepr> KW_LESS_OR_EQ ;
%token <crepr> KW_MORE_OR_EQ ;
%token <crepr> KW_AND_SYMB ;
%token <crepr> KW_OR_SYMB ;
%token <crepr> KW_TYPE ;
%token <crepr> KW_TRUE ;
%token <crepr> KW_FALSE ;

%start program

%type <crepr> program_decl body statement_list    
%type <crepr> statement proc_call arguments typedef_array_brackets	
%type <crepr> expression basic_types arrays assignment in_brackets label_body
%type <crepr> array_arg array_brackets FuncReturnTypes proc_def_arg_main
%type <crepr> var_declaration if_statement goto_statement label_decl while_statement for_statement 
%type <crepr> subprogram_def proc_def_arguments names casting after_type_def
%type <crepr> type_def var_decl_more type_def_body loops

%left KW_OR KW_OR_SYMB
%left KW_AND KW_AND_SYMB
%left '<' '>' '=' KW_DIFFERENT KW_LESS_OR_EQ KW_MORE_OR_EQ 
%left '+' '-'
%left '*' '/' KW_DIV KW_MOD
%right KW_NOT '!'
%right '(' ')' 
%precedence ';' 
%precedence IDENT
%precedence KW_THEN KW_BEGIN
%precedence KW_ELSE

%%

/*Επικεφαλίδα κεντρικής μονάδας*/
program: program_decl statement_list body '.'  		
{ 
	/* We have a successful parse! 
		Check for any errors and generate output. 
	*/
	if(yyerror_count==0) 
	{
		puts(c_prologue);
		printf("/* program %s */\n", $1);
		printf("\n%sint main()\n{\n%s\nreturn 0;}\n",$2,$3 );	
	}
};

program_decl : KW_PROGRAM IDENT ';' {$$ = $2;};

body : KW_BEGIN statement_list KW_END {$$ = template("\n%s\n", $2 );}; 

statement_list :  /*empty*/ { $$ = ""; }							
	 			 | statement statement_list {$$ = template("%s\n%s",$1,$2); } 

/* Κλήση statement μέσα στην εντολή σύνθετης μονάδας*/
statement:   subprogram_def  {$$ = template("%s", $1) ;} 
		   | proc_call ';' {$$ = template("%s ;", $1) ;}  
		   | label_decl {$$ = template("%s", $1) ;}  
		   | goto_statement {$$ = template("%s", $1) ;} 	
		   | assignment {$$ = template("%s", $1) ;} 
		   | KW_RETURN { $$ = ""; }
		   | type_def {$$ = template("%s", $1) ;} 
		   | var_declaration {$$ = template("%s", $1) ;} 
		   | loops	{$$ = template("%s", $1) ;} 

 loops:     if_statement  
		   |for_statement
		   |while_statement 

if_statement : KW_IF expression KW_THEN KW_BEGIN statement_list KW_END';' {$$ = template("if (%s)\n{\n%s\n}", $2 , $5) ;}
	          |KW_IF expression KW_THEN KW_BEGIN statement_list KW_END';' KW_ELSE KW_BEGIN statement_list KW_END';' {$$ = template("if (%s)\n{\n%s\n}\nelse{\n%s\n}\n",$2 , $5 , $10) ;}
	          |KW_IF expression KW_THEN statement {$$ = template("if (%s)\n{\n%s\n}", $2 , $4) ;}
	          |KW_IF expression KW_THEN statement KW_ELSE statement {$$ = template("if (%s)\n{\n%s\n}\nelse %s\n",$2 , $4 , $6) ;}
	          |KW_IF expression KW_THEN statement KW_ELSE KW_BEGIN statement_list KW_END';' {$$ = template("if (%s)\n{\n%s\n}\nelse {\n%s\n}",$2 , $4 , $7) ;}
	          |KW_IF expression KW_THEN KW_BEGIN statement_list KW_END ';' KW_ELSE statement {$$ = template("if (%s)\n{\n%s\n}\nelse {\n%s\n}",$2 , $5 , $9) ;}

while_statement :  KW_WHILE expression KW_DO KW_BEGIN statement_list KW_END ';'  {$$ = template("while (%s)\n{\n%s\n}\n",$2 , $5) ;}
		          | KW_REPEAT KW_BEGIN statement_list KW_END';' KW_UNTIL expression {$$ = template("do {%s}\nwhile (%s);\n", $3 , $7) ;}
		          | KW_WHILE expression KW_DO statement {$$ = template("while (%s)\n{\n%s\n}\n",$2 , $4) ;}
		          | KW_REPEAT statement KW_UNTIL expression {$$ = template("do {%s}\nwhile(%s);\n", $2 , $4) ;}

for_statement : KW_FOR IDENT ASSIGN expression KW_TO expression KW_DO KW_BEGIN statement_list KW_END ';'   {$$ = template("for (%s=%s ; %s<=%s ; %s ++)\n{\n%s\n}\n",$2,$4,$2,$6,$2,$9) ;}
	           | KW_FOR IDENT ASSIGN expression KW_DOWNTO expression KW_DO KW_BEGIN statement_list KW_END';'  {$$ = template("for (%s=%s  ; %s>=%s ; %s --)\n{\n%s\n}\n",$2,$4,$2,$6,$2,$9 ) ;}
	           | KW_FOR IDENT ASSIGN expression KW_TO expression KW_DO statement    {$$ = template("for (%s=%s  ; %s<=%s ; %s ++)\n{\n%s\n}\n",$2,$4,$2,$6,$2,$8 ) ;}
	           | KW_FOR IDENT ASSIGN expression KW_DOWNTO expression KW_DO statement {$$ = template("for (%s=%s  ; %s>=%s ; %s --)\n{\n%s\n}\n",$2,$4,$2,$6,$2,$8 ) ;}

label_decl : IDENT ':' label_body {$$ = template("%s : %s",$1,$3) ;}

label_body :    subprogram_def  {$$ = template("%s", $1) ;} 
			   | proc_call ';' {$$ = template("%s ;", $1) ;}  
			   | label_decl ';'{$$ = template("%s", $1) ;}  
			   | goto_statement {$$ = template("%s", $1) ;} 	
			   | assignment  {$$ = template("%s", $1) ;} 
			   | KW_RETURN { $$ = ""; }
			   | type_def {$$ = template("%s", $1) ;} 
			   | var_declaration {$$ = template("%s", $1) ;} 
			   | loops	{$$ = template("%s", $1) ;} 

goto_statement : KW_GOTO IDENT ';'   {$$ = template("goto %s;", $2) ;}

proc_call: IDENT '('arguments')' {$$ = template("%s(%s)", $1, $3);}
	
/*Tα δυνατά ορίσματα μιας συνάρτησης*/
arguments :	/*empty*/ 				 {$$ = "";}
		 | expression				 {$$ = $1;}							
	 	 | expression ',' arguments {$$ = template("%s,%s", $1, $3);}

casting : '('basic_types')' expression {$$ = template("(%s) %s",$2,$4 );} 
			|'('ARRAY array_brackets KW_OF basic_types')' expression 
			{
				char str[50]  ; 
				char* stars = (char*) malloc (50);
				strcpy(str,$3);
				if (!strcmp(str,""))
				{
					$$ = template("(%s*) %s",$5,$7); 
				}
				else 
				{
					int count = 0 ; 
					int i = 0 ; 

					while (str[i]!='\0')
					{
						if (str[i]== '[')
							count++;
					}

					i = 0 ; 
					for (i=0;i<=count;i++)
					{
						stars = strcat(stars,"*");
					}
					$$ = template("(%s%s) %s",$5,stars,$7);
				}				
				
				free(stars);
			} 

expression : POSINT 
			|REAL  
			|arrays
			|IDENT
			|proc_call
			|KW_RESULT {$$ = template("result");}			
			|STRING {$$ = string_ptuc2c($1);}
			|casting
			|KW_TRUE {$$ = template("1");}		
			|KW_FALSE  	{$$ = template("0");}	
			|'+' expression %prec '+' {$$ = template("+%s",$2);}
			|'-' expression %prec '-'  {$$ = template("-%s",$2);}
			|expression '*' expression {$$ = template("%s * %s",$1,$3);}
			|expression '/' expression {$$ = template("%s / %s",$1,$3);}
			|expression KW_DIV expression {$$ = template("%s / %s",$1,$3);}
			|expression KW_MOD expression {$$ = template("%s %s %s", $1,"%",$3);}
			|expression '+' expression {$$ = template("%s + %s",$1,$3);}
			|expression '-' expression {$$ = template("%s - %s",$1,$3);}		
			|KW_NOT expression {$$ = template("!%s",$2);}
			|'!' expression {$$ = template("!%s",$2);}
			|expression '=' expression {$$ = template("%s == %s",$1,$3);}	
			|expression KW_DIFFERENT expression {$$ = template("%s != %s",$1,$3);}
			|expression '<' expression {$$ = template("%s < %s",$1,$3);}
			|expression '>' expression {$$ = template("%s > %s",$1,$3);}
			|expression KW_LESS_OR_EQ expression{$$=template("%s <= %s",$1,$3);} 
			|expression KW_MORE_OR_EQ expression{$$ = template("%s >= %s",$1,$3);}
			|expression KW_AND expression  {$$ = template("%s && %s",$1,$3);}
			|expression KW_OR expression {$$ = template("%s || %s",$1,$3);}
			|expression KW_AND_SYMB expression  {$$ = template("%s && %s",$1,$3);}
			|expression KW_OR_SYMB expression {$$ = template("%s || %s",$1,$3);}
			|'('in_brackets')' {$$ = template("(%s)",$2);}

in_brackets :POSINT 
			|REAL  			
			|proc_call
			|KW_RESULT			
			|STRING {$$ = string_ptuc2c ($1);}
			|casting
			|KW_TRUE {$$ = template("1");}		
			|KW_FALSE  	{$$ = template("0");}			
			|'+' expression %prec '+' {$$ = template("+%s",$2);}
			|'-' expression %prec '-'  {$$ = template("-%s",$2);}
			|expression '*' expression {$$ = template("%s * %s",$1,$3);}
			|expression '/' expression {$$ = template("%s / %s",$1,$3);}
			|expression KW_DIV expression {$$ = template("%s / %s",$1,$3);}
			|expression KW_MOD expression {$$ = template("%s %s %s",$1,"%",$3);}
			|expression '+' expression {$$ = template("%s + %s",$1,$3);}
			|expression '-' expression {$$ = template("%s - %s",$1,$3);}		
			|KW_NOT expression {$$ = template("!%s",$2);}
			|'!' expression {$$ = template("!%s",$2);}
			|expression '=' expression {$$ = template("%s == %s",$1,$3);}	
			|expression KW_DIFFERENT expression {$$ = template("%s != %s",$1,$3);}
			|expression '<' expression {$$ = template("%s < %s",$1,$3);}
			|expression '>' expression {$$ = template("%s > %s",$1,$3);}
			|expression KW_LESS_OR_EQ expression{$$=template("%s <= %s",$1,$3);} 
			|expression KW_MORE_OR_EQ expression{$$ = template("%s >=% s",$1,$3);}
			|expression KW_AND expression  {$$ = template("%s && %s",$1,$3);}
			|expression KW_OR expression {$$ = template("%s || %s",$1,$3);}
			|expression KW_AND_SYMB expression  {$$ = template("%s && %s",$1,$3);}
			|expression KW_OR_SYMB expression {$$ = template("%s || %s",$1,$3);}
	
assignment : IDENT ASSIGN expression ';'  {$$ = template("%s = %s ;",$1,$3); }	
	   		| KW_RESULT ASSIGN expression ';' {$$ = template("result = %s ;",$3); }	
					
/*Basic data types*/
basic_types : KW_BOOLEAN {$$ = template("int");}
		    | KW_INTEGER {$$ = template("int");}
		    | KW_REAL {$$ = template("double");}
	        | KW_CHAR {$$ = template("char");}
		    | IDENT {$$ = template("%s",$1);}			

proc_def_arg_main : names ':' ARRAY KW_OF basic_types {$$ = template("%s %s", $3, $1 );} 
		  | names ':' basic_types { $$ = template("%s %s", $3,  $1);}
			
proc_def_arguments :  /*empty*/	{ $$ = ""; }	
		   			 | proc_def_arg_main {$$ = template("%s" ,$1);}				
		   			 | proc_def_arg_main ';' proc_def_arguments  {; $$ = template("%s , %s" , $1, $3); }	

/*Basic definition of matrix*/
arrays : ARRAY array_brackets KW_OF basic_types {$$ = template("%s%s",$4 ,$2);}; 

/* Allows multi-dimensional matrices*/
array_brackets : /*empty*/	      { $$ = "";}				
	 	 		| '['array_arg']' array_brackets  { $$ = template("[%s]%s",$2,$4);}; 

/*Function complex data type*/
subprogram_def : KW_FUNCTION IDENT '('proc_def_arguments')' ':' FuncReturnTypes ';' statement_list body ';'{$$ = template("\n%s %s (%s)\n{\n%s result;\n%s\n%sreturn result;\n}\n",$7,$2,$4,$7,$9,$10); }  
				| KW_PROCEDURE IDENT '('proc_def_arguments')' ';' statement_list body ';' {$$ = template("\nvoid %s (%s)\n{\n%s\n%sreturn;\n}\n",$2,$4,$7,$8);}  

/*Function allowed return data types*/
FuncReturnTypes : basic_types
	   			| arrays

/*Array allowed arguments (must be positive integers)*/
array_arg :	  POSINT ;
			 | array_arg '+' array_arg  {$$ = template("%s + %s", $1, $3);};
			 | array_arg '-' array_arg  {if ((atof($1) - atof($3)) >= 0) {$$ = template("%s - %s", $1 ,$3);} else {yyerror("(Positive number expected!)\n",yyerror_count);yyerror_count++;}}
			 | array_arg '*' array_arg  {if ((atof($1) * atof($3)) >= 0) {$$ = template("%s * %s", $1,$3);} else {yyerror("(Positive number expected!)\n",yyerror_count);yyerror_count++;}}
			 | array_arg '/' array_arg  { double num = (atol($1) / atol($3)) ; int intpart = (int) num ; double decpart = num - intpart ; 
					 					if (num >= 0) {$$ = template("%s / %s", $1,$3);} else {yyerror("(Positive number expected!)\n",yyerror_count);yyerror_count++;}
					 					if (decpart == 0) {$$ = template("%s / %s", $1,$3);} else {yyerror("(Integer expected!)\n",yyerror_count);yyerror_count++;}}

/*Change the name of a definition (like type_def of C language)*/ 	
type_def : KW_TYPE type_def_body {$$ = template("%s",$2);}	

type_def_body :  IDENT '=' basic_types after_type_def {$$ = template("typedef %s %s;\n%s",$3,$1,$4);}	
				|IDENT '='  KW_FUNCTION '('proc_def_arguments')' ':' FuncReturnTypes after_type_def {$$ = template("typedef %s (*%s) (%s);\n%s",$8,$1,$5,$9);}	
				|IDENT '='  ARRAY typedef_array_brackets KW_OF basic_types after_type_def {if (strcmp($4,"")) {$$ = template("typedef %s%s %s;\n%s",$6,$4,$1,$7);} 
																						  else $$ = template("typedef %s* %s;\n%s",$6,$1,$7);}; 

typedef_array_brackets :  /*empty*/	                              {$$ = "";}				
	 	 				| '['array_arg']' typedef_array_brackets  {$$ = template("*%s",$4);};  	
				
after_type_def : ';' type_def_body {$$ = template("%s",$2);}
				| ';'   { $$ = "";}
					
var_declaration : KW_VAR names ':' basic_types var_decl_more{$$ = template("%s %s;\n%s",$4,$2,$5);}	
		  		 |KW_VAR names ':' ARRAY array_brackets KW_OF basic_types var_decl_more 
		  		 { // Place the brackets in the correct place
						 char* names = (char *) malloc (200); 
						 char* new_name = (char *) malloc (200);

						 names = strtok($2,",") ;
						 new_name = strcat(new_name , names);
						 new_name = strcat(new_name , $5);
						 names = strtok(NULL,",");

						while (names != NULL)
						{	
							new_name = strcat(new_name , ",");
							new_name = strcat(new_name , names);
							new_name = strcat(new_name , $5);						
							names = strtok(NULL,",");
						} 
						
						$$ = template("%s %s%s ;",$7,new_name,$8);
						free (names);
						free (new_name);
					}	
								
var_decl_more :   ';' names ':' basic_types var_decl_more  {$$ = template("%s %s;\n%s", $4, $2,$5);} 
				  |';' names ':' ARRAY array_brackets KW_OF basic_types var_decl_more  
					{ // Place the brackets in the correct place
						 char* names = (char *) malloc (200); 
						 char* new_name = (char *) malloc (200);

						 names = strtok($2,",") ;
						 new_name = strcat(new_name , names);
						 new_name = strcat(new_name , $5);
						 names = strtok(NULL,",");

						while (names != NULL)
						{	
							new_name = strcat(new_name , ",");
							new_name = strcat(new_name , names);
							new_name = strcat(new_name , $5);						
							names = strtok(NULL,",");
						} 
						
						$$ = template("%s %s%s ;",$7,new_name,$8);
						free (names);
						free (new_name);
					}					
					| ';' {$$ = template("");} 

names : IDENT 
       |IDENT ',' names {$$ = template("%s , %s", $1 , $3);} 				

%%

