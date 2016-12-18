%{

char* troca_aspas( char* lexema );

%}

DELIM   [\t ]
LINHA   [\n]
NUMERO  [0-9]
LETRA   [A-Za-z_]
INT     {NUMERO}+
DOUBLE  {NUMERO}+("."{NUMERO}+)?
ID      {LETRA}({LETRA}|{NUMERO})*
CSTRING "'"([^\n']|"''")*"'"

COMMENT "(*"([^*]|"*"[^)])*"*)"

%%

{LINHA}    { nlinha++; }
{DELIM}    {}
{COMMENT}  {}

"Var"      { yylval = Atributos( yytext ); return TK_VAR; }
"Program"  { yylval = Atributos( yytext ); return TK_PROGRAM; }
"🔓"    { yylval = Atributos( yytext ); return TK_BEGIN; }
"🔒"      { yylval = Atributos( yytext ); return TK_END; }
"💬"  { yylval = Atributos( yytext ); return TK_WRITELN; }
"🤔"       { yylval = Atributos( yytext ); return TK_IF; }
"⤵️"     { yylval = Atributos( yytext ); return TK_THEN; }
"💩"     { yylval = Atributos( yytext ); return TK_ELSE; }
"🔂"      { yylval = Atributos( yytext ); return TK_FOR; }
"To"       { yylval = Atributos( yytext ); return TK_TO; }
"Do"       { yylval = Atributos( yytext ); return TK_DO; }
"Array"    { yylval = Atributos( yytext ); return TK_ARRAY; }
"Of"       { yylval = Atributos( yytext ); return TK_OF; }
"⚙" { yylval = Atributos( yytext ); return TK_FUNCTION; }
"〰"      { yylval = Atributos( yytext ); return TK_MOD; }
"🔙"      { yylval = Atributos( yytext ); return TK_RETURN; }


"🌜"    { yylval = Atributos( yytext ); return TK_ABRE_PAREN; }
"🌛"    { yylval = Atributos( yytext ); return TK_FECHA_PAREN; }

"🔢"       { yylval = Atributos( yytext ); return TK_EINTEGER; }
"☯"       { yylval = Atributos( yytext ); return TK_EBOOL; }
"®"       { yylval = Atributos( yytext ); return TK_EREAL; }
"©"       { yylval = Atributos( yytext ); return TK_ECHAR; }
"🔠"       { yylval = Atributos( yytext ); return TK_ESTRING; }

"➕"       { yylval = Atributos( yytext ); return TK_ADD; }
"➖"       { yylval = Atributos( yytext ); return TK_SUB; }
"✖️"       { yylval = Atributos( yytext ); return TK_MULT; }
"➗"       { yylval = Atributos( yytext ); return TK_DIV; }

".."       { yylval = Atributos( yytext ); return TK_PTPT; }
":="       { yylval = Atributos( yytext ); return TK_ATRIB; }
"<="       { yylval = Atributos( yytext ); return TK_MEIG; }
">="       { yylval = Atributos( yytext ); return TK_MAIG; }
"<>"       { yylval = Atributos( yytext ); return TK_DIF; }
"And"       { yylval = Atributos( yytext ); return TK_AND; }
"Or"       { yylval = Atributos( yytext ); return TK_OR; }
"❗️"       { yylval = Atributos( yytext ); return TK_NOT; }


{CSTRING}  { yylval = Atributos( troca_aspas( yytext ), Tipo( "string" ) ); 
             return TK_CSTRING; }
{ID}       { yylval = Atributos( yytext ); return TK_ID; }
{INT}      { yylval = Atributos( yytext, Tipo( "int" ) ); return TK_CINT; }
{DOUBLE}   { yylval = Atributos( yytext, Tipo( "double" ) ); return TK_CDOUBLE; }

.          { yylval = Atributos( yytext ); return *yytext; }

%%

char* troca_aspas( char* lexema ) {
  int n = strlen( lexema );
  lexema[0] = '"';
  lexema[n-1] = '"';
  
  return lexema;
}

 


