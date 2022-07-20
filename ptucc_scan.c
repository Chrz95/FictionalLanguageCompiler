
#include <stdio.h>

extern char* yytext;
extern int line_num;
extern int yylex();

int main()
{
	int token;

	printf("Tokenize ptuc from standard input\n");
	while((token = yylex())!=EOF) {
		printf("token: %3d : %s \n",  token, yytext);
	}
}


