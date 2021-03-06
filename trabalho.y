%{
#include <string>
#include <iostream>
#include <vector>
#include <stdio.h>
#include <stdlib.h>
#include <map>

using namespace std;

int yylex();
void yyerror( const char* st );
void erro( string msg );

// Faz o mapeamento dos tipos dos operadores
map< string, string > tipo_opr;

// Pilha de variáveis temporárias para cada bloco
vector< string > var_temp;

#define MAX_DIM 2 

enum TIPO { FUNCAO = -1, BASICO = 0, VETOR = 1, MATRIZ = 2 };

struct Tipo {
  string tipo_base;
  bool ref = false;
  TIPO ndim;
  //int inicio[MAX_DIM];
  int fim[MAX_DIM];
  vector<Tipo> retorno; // usando vector por dois motivos:
  // 1) Para não usar ponteiros
  // 2) Para ser genérico. Algumas linguagens permitem mais de um valor
  //    de retorno.
  vector<Tipo> params;
  
  Tipo() {} // Construtor Vazio
  
  Tipo( string tipo ) {
    tipo_base = tipo;
    ndim = BASICO;
  }
  
  //Tipo( string base, int inicio, int fim  ) {
  Tipo( string base, int fim  ) {
    tipo_base = base;
    ndim = VETOR;
    //this->inicio[0] = inicio;
    this->fim[0] = fim;
  }
  
  //Tipo( string base, int inicio_1, int fim_1, int inicio_2, int fim_2  ) {
  Tipo( string base, int fim_1, int fim_2  ) {
    tipo_base = base;
    ndim = MATRIZ;
    //this->inicio[0] = inicio_1;
    this->fim[0] = fim_1;
    //this->inicio[1] = inicio_2;
    this->fim[1] = fim_2;
  }
  
  Tipo( Tipo retorno, vector<Tipo> params ) {
    ndim = FUNCAO;
    this->retorno.push_back( retorno );
    this->params = params;
  } 
};

struct Atributos {
  string v, c, d; // Valor, tipo, declarações e código gerado.
  Tipo t;
  vector<string> lista_str; // Uma lista auxiliar de strings.
  vector<Tipo> lista_tipo; // Uma lista auxiliar de tipos.
  vector<Atributos> lista_atr; // Uma lista auxiliar de atributos.
  
  Atributos() {} // Constutor vazio
  Atributos( string valor ) {
    v = valor;
  }

  Atributos( string valor, Tipo tipo ) {
    v = valor;
    t = tipo;
  }

  Atributos( string valor, Tipo tipo, string code) {
    v = valor;
    t = tipo;
    c = code;
  }
};

// Declarar todas as funções que serão usadas.
void insere_var_ts( string nome_var, Tipo tipo );
void insere_funcao_ts( string nome_func, Tipo retorno, vector<Tipo> params );
Tipo consulta_ts( string nome_var );
string declara_variavel( string nome, Tipo tipo );
string declara_funcao( string nome, Tipo retorno, vector<string> nomes, vector<Tipo> tipos );
void gera_consulta_tipos( string tipo1, string tipo2 );
Atributos gera_codigo_member(Atributos s1, Atributos s2);

void empilha_ts();
void desempilha_ts();

string gera_nome_var_temp( string tipo );
string gera_label( string tipo );
string gera_teste_limite_array( string indice_1, Tipo tipoArray );
string gera_teste_limite_array( string indice_1, string indice_2, Tipo tipoArray );
string gera_indice_array( string out, string indice_1, string indice_2, Tipo tipoArray );
string gera_indice_array2( string out, string var, string indice_1, string indice_2, Tipo tipoArray );

string gera_atribuicao_array_2D( Tipo tipo, string valor1, string valor2 );

void debug( string producao, Atributos atr );
int toInt( string valor );
string toString( int n );

Atributos gera_codigo_operador( Atributos s1, string opr, Atributos s3 );
Atributos gera_codigo_if( Atributos expr, string cmd_then, string cmd_else );

string traduz_nome_tipo_pascal( string tipo_pascal );

Atributos format_writeln(Atributos s1);

string includes = 
"#include <iostream>\n"
"#include <stdio.h>\n"
"#include <stdlib.h>\n"
"#include <string.h>\n"
"\n"
"using namespace std;\n";


#define YYSTYPE Atributos

%}

%token TK_ID TK_CINT TK_CDOUBLE TK_VAR TK_PROGRAM TK_BEGIN TK_END TK_ATRIB
%token TK_WRITELN TK_SCANLN TK_CSTRING TK_FUNCTION TK_FUNC_CALL TK_MOD
%token TK_MAIG TK_MEIG TK_DIF TK_IF TK_THEN TK_ELSE TK_AND TK_OR
%token TK_FOR TK_TO TK_DO TK_ARRAY TK_OF TK_PTPT
%token TK_WHILE TK_UP TK_SWITCH TK_CASE
%token TK_ABRE_PAREN TK_FECHA_PAREN TK_EXIT TK_DEFAULT
%token TK_EINTEGER TK_EBOOL TK_EREAL TK_ECHAR TK_ESTRING TK_EREF
%token TK_ADD TK_SUB TK_MULT TK_DIV
%token TK_RETURN TK_ABRE_COLCH TK_FECHA_COLCH TK_COMMA TK_MEMBER

%left TK_AND TK_OR TK_NOT TK_TRUE TK_FALSE TK_MEMBER TK_THEN
%nonassoc '<' '>' TK_MAIG TK_MEIG '=' TK_DIF 
%left TK_ADD TK_SUB
%left TK_MULT TK_DIV TK_MOD

%%

S : PROGRAM DECLS MAIN 
    {
      cout << includes << endl;
      cout << $2.c << endl;
      cout << $3.c << endl;
    }
  ;
  
PROGRAM : TK_PROGRAM TK_ID ';' 
          { $$.c = ""; 
            empilha_ts(); }
        ; 
  
DECLS : FUNCTION DECLS
        { $$.c = $2.c + $1.c; }
      | TK_VAR VARS DECLS
        { $$.c = $2.c + $3.c; }
      | 
        { $$.c = ""; }
      ;  

/*
DECL : TK_VAR VARS
       { $$.c = $2.c; }
     | FUNCTION
     ;
*/
    
FUNCTION : { empilha_ts(); }  CABECALHO ';' CORPO { desempilha_ts(); } ';'
           { $$.c = $2.c + " {\n" + $4.c;
		if($2.t.tipo_base == "s")
		  $$.c += "  strncpy( "+ $2.lista_str[0] +", Result, 256 );\n}\n";
		else
		  $$.c += "  return Result;\n}\n"; } 
         ;

CABECALHO : TK_FUNCTION TK_ID OPC_PARAM ':' TIPO_ID
            { 
              Tipo retorno(traduz_nome_tipo_pascal($5.v));
              insere_funcao_ts($2.v, retorno, $3.lista_tipo);
	      $$.c = "";
	      string func_name = "Global_Result_" + $2.v;
	      if(retorno.tipo_base == "s"){
		$$.c += "char " + func_name + "[256];\n";
		$$.t = Tipo("s");
	      }

	      $$.c += declara_funcao($2.v, retorno, $3.lista_str, $3.lista_tipo);
	      $$.lista_str.push_back(func_name);
            }
          ;
          
OPC_PARAM : TK_ABRE_PAREN PARAMS TK_FECHA_PAREN
            { $$ = $2; }
          | TK_ABRE_PAREN TK_FECHA_PAREN
            { $$ = Atributos(); }
          ;
          
PARAMS : PARAM ';' PARAMS 
         { $$.c = $1.c + $3.c; 
           // Concatenar as listas.
           $$.lista_tipo = $1.lista_tipo;
           $$.lista_tipo.insert( $$.lista_tipo.end(), 
                                 $3.lista_tipo.begin(),  
                                 $3.lista_tipo.end() ); 
           $$.lista_str = $1.lista_str;
           $$.lista_str.insert( $$.lista_str.end(), 
                                $3.lista_str.begin(),  
                                $3.lista_str.end() ); 
         }
       | PARAM                  
       ;  
         
PARAM : IDS ':' TIPO_ID 
      {
        Tipo tipo = Tipo( traduz_nome_tipo_pascal( $3.v ) ); 
        
        $$ = Atributos();
        $$.lista_str = $1.lista_str;
        
        for( int i = 0; i < $1.lista_str.size(); i ++ ) 
          $$.lista_tipo.push_back( tipo );
      }
     | IDS ':' TK_EREF TIPO_ID
      {
        Tipo tipo = Tipo( traduz_nome_tipo_pascal( $4.v ) ); 
	tipo.ref = true;
        
        $$ = Atributos();
        $$.lista_str = $1.lista_str;
        
        for( int i = 0; i < $1.lista_str.size(); i ++ ) 
          $$.lista_tipo.push_back( tipo );
      }
     | IDS ':' TK_ARRAY TK_ABRE_COLCH TK_CINT TK_FECHA_COLCH TK_OF TIPO_ID 
      {
        Tipo tipo = Tipo( traduz_nome_tipo_pascal( $8.v ), 
                          toInt( $5.v ) );
        
        $$ = Atributos();
        $$.lista_str = $1.lista_str;
        
        for( int i = 0; i < $1.lista_str.size(); i ++ ) 
          $$.lista_tipo.push_back( tipo );

        /*
        for( int i = 0; i < $1.lista_str.size(); i ++ ) {
          $$.c += declara_variavel( $1.lista_str[i], tipo ) + ";\n";
          insere_var_ts( $1.lista_str[i], tipo );
        }
        */
      }
    | IDS ':' TK_ARRAY TK_ABRE_COLCH TK_CINT TK_COMMA TK_CINT TK_FECHA_COLCH TK_OF TIPO_ID
       {
          Tipo tipo = Tipo(traduz_nome_tipo_pascal( $10.v ), toInt( $5.v ), toInt( $7.v ) );
         
          $$ = Atributos();
          $$.lista_str = $1.lista_str;
        

          for( int i = 0; i < $1.lista_str.size(); i ++ ) 
            $$.lista_tipo.push_back( tipo );

          /*
	  for( int i = 0; i < $1.lista_str.size(); i ++ ) {
            $$.c += declara_variavel( $1.lista_str[i], tipo ) + ";\n";
            insere_var_ts( $1.lista_str[i], tipo );
          }
          */
	}
    ;
          
CORPO : TK_VAR VARS BLOCO
        { $$.c = declara_variavel( "Result", consulta_ts( "Result" ) ) + ";\n" +
                 $2.c + $3.c; }
      | BLOCO
        { $$.c = declara_variavel( "Result", consulta_ts( "Result" ) ) + ";\n" +
                 $1.c; }
      ;    
     
VARS : VAR ';' VARS
       { $$.c = $1.c + $3.c; }
     | 
       { $$ = Atributos(); }
     ;     
     
VAR : IDS ':' TIPO_ID 
      {
        Tipo tipo = Tipo( traduz_nome_tipo_pascal( $3.v ) ); 
        
        $$ = Atributos();
        
        for( int i = 0; i < $1.lista_str.size(); i ++ ) {
          $$.c += declara_variavel( $1.lista_str[i], tipo ) + ";\n";
          insere_var_ts( $1.lista_str[i], tipo );
        }
      }
    | IDS ':' TK_ARRAY TK_ABRE_COLCH TK_CINT TK_FECHA_COLCH TK_OF TIPO_ID 
      {
        Tipo tipo = Tipo( traduz_nome_tipo_pascal( $8.v ), 
                          toInt( $5.v ) );
        
        $$ = Atributos();
        
        for( int i = 0; i < $1.lista_str.size(); i ++ ) {
          $$.c += declara_variavel( $1.lista_str[i], tipo ) + ";\n";
          insere_var_ts( $1.lista_str[i], tipo );
        }
      }
    | IDS ':' TK_ARRAY TK_ABRE_COLCH TK_CINT TK_COMMA TK_CINT TK_FECHA_COLCH TK_OF TIPO_ID
       {
          Tipo tipo = Tipo(traduz_nome_tipo_pascal( $10.v ), toInt( $5.v ), toInt( $7.v ) );
         
          $$ = Atributos();

	  for( int i = 0; i < $1.lista_str.size(); i ++ ) {
            $$.c += declara_variavel( $1.lista_str[i], tipo ) + ";\n";
            insere_var_ts( $1.lista_str[i], tipo );
          }
	}
    ;
    
IDS : IDS ',' TK_ID 
      { $$  = $1;
        $$.lista_str.push_back( $3.v ); }
    | TK_ID 
      { $$ = Atributos();
        $$.lista_str.push_back( $1.v ); }
    ;          

MAIN : BLOCO
       { $$.c = "int main() { \n" + $1.c + "}\n"; } 
     ;
     
BLOCO : TK_BEGIN { var_temp.push_back( "" );} CMDS TK_END
        { string vars = var_temp[var_temp.size()-1];
          var_temp.pop_back();
          $$.c = vars + $3.c; }
      ;  

SCOPE : { empilha_ts(); } TK_VAR VARS INNER_BLOCO { desempilha_ts(); }
        { $$.c = $4.c; var_temp[var_temp.size()-1] += $3.c; }
        ;

INNER_BLOCO : TK_BEGIN CMDS TK_END
            { $$.c = $2.c; }
            ; 

COND_BLOCO : INNER_BLOCO
           | CMD ';'
           ;
      
CMDS : CMD ';' CMDS
       { $$.c = $1.c + $3.c; }
     | CMD_FOR CMDS
       { $$.c = $1.c + $2.c; }
     | CMD_WHILE CMDS
       { $$.c = $1.c + $2.c; }
     | CMD_DO_WHILE CMDS
       { $$.c = $1.c + $2.c; }
     | CMD_SWITCH CMDS
       { $$.c = $1.c + $2.c; }
     | CMD_IF CMDS
       { $$.c = $1.c + $2.c; }
     | { $$.c = ""; }
     ;  
     
CMD : WRITELN
    | E
    | TK_EXIT {$$.c = "  exit( 0 );\n";}
    | SCOPE
    | SCANLN
    | ATRIB 
    | TK_RETURN E
      {
	if( $2.t.tipo_base == "s" ) 
            $$.c = $2.c + "  strncpy( Result, " + $2.v + ", 256 );\n";
	else
	    $$.c = $2.c + "  Result = " + $2.v + ";\n";
      }
    | { $$.c = ""; }
    ;   
        
    
CMD_FOR : TK_FOR NOME_VAR TK_ATRIB E TK_TO E TK_THEN COND_BLOCO 
          { 
            string var_fim = gera_nome_var_temp( $2.t.tipo_base );
            string label_teste = gera_label( "teste_for" );
            string label_fim = gera_label( "fim_for" );
            string condicao = gera_nome_var_temp( "b" );
          
            // Falta verificar os tipos... perde ponto se não o fizer.
	    gera_consulta_tipos( $2.t.tipo_base, $4.t.tipo_base );
            $$.c =  $4.c + $6.c +
                    "  " + $2.v + " = " + $4.v + ";\n" +
                    "  " + var_fim + " = " + $6.v + ";\n" +
                    label_teste + ":;\n" +
                    "  " +condicao+" = "+$2.v + " > " + var_fim + ";\n" + 
                    "  " + "if( " + condicao + " ) goto " + label_fim + 
                    ";\n" +
                    $8.c +
                    "  " + $2.v + " = " + $2.v + " + 1;\n" +
                    "  goto " + label_teste + ";\n" +
                    label_fim + ":;\n";  
          }
        ;

CMD_WHILE : TK_WHILE E TK_THEN COND_BLOCO
	  {
	    string label_teste = gera_label("teste_while");
	    string label_fim = gera_label("fim_while");
	    string condicao = gera_nome_var_temp("b");
	    $$.c = label_teste + ":;\n" + 
		   $2.c +
		   "  " + condicao + " = " + $2.v + " == 0;\n" +
		   "  " + "if( " + condicao + " ) goto " + label_fim + ";\n" + 
		   $4.c +
		   "  goto " + label_teste + ";\n" + 
		   label_fim + ":;\n";
	  }
	  ;

CMD_DO_WHILE : TK_THEN COND_BLOCO TK_WHILE E TK_UP
	  {
	    string label_teste = gera_label("teste_while");
	    string label_fim = gera_label("fim_while");
	    string condicao = gera_nome_var_temp("b");
	    $$.c = label_teste + ":;\n" + 
		   $2.c +
		   $4.c +
		   "  " + condicao + " = " + $4.v + " == 0;\n" +
		   "  " + "if( " + condicao + " ) goto " + label_fim + ";\n" + 
		   "  goto " + label_teste + ";\n" + 
		   label_fim + ":;\n";
	  }
	  ;
    
CMD_IF : TK_IF E TK_THEN COND_BLOCO
         { $$ = gera_codigo_if( $2, $4.c, "" ); }
       | TK_IF E TK_THEN COND_BLOCO TK_ELSE COND_BLOCO
         { $$ = gera_codigo_if( $2, $4.c, $6.c ); }
       ;

CMD_SWITCH : TK_SWITCH TK_ABRE_PAREN TK_ID TK_FECHA_PAREN TK_BEGIN CASES TK_END
	     { 
		string codigo = "";
		vector<string> labels;
		vector<string> temp_vars;
		string end_label = gera_label("end_switch");
		int i = 0;
		for(i = 0; i < $6.lista_atr.size(); i++){
		    if($6.lista_atr[i].v != "default"){
		    	codigo += $6.lista_atr[i].c;
		    	temp_vars.push_back(gera_nome_var_temp("b"));
		    	codigo += "  " + temp_vars[temp_vars.size()-1] + " = "+
				$6.lista_atr[i].v + " == " + $3.v + ";\n";
		    }
		}

		for(i = 0; i < $6.lista_atr.size(); i++){
		    if($6.lista_atr[i].v == "default"){
		    labels.push_back(gera_label("default"));
			codigo += "  goto " + labels[labels.size()-1] + ";\n";
		    }
		    else{
			    labels.push_back(gera_label("case"));
			    codigo += "  if( " + temp_vars[i] + " ) goto "+
					labels[labels.size()-1] + ";\n";
		    }
		}
		for(i = 0; i < $6.lista_atr.size(); i++){
		    codigo += labels[i] + ":;\n"+ $6.lista_str[i]+
				"  goto " + end_label + ";\n";
		}
		$$.c = codigo + end_label + ":;\n";
	     }
	   ;

CASES : CASES TK_CASE E ':' BLOCO
	{
	  $$  = $1;
	  $$.lista_atr.push_back( $3 );
	  $$.lista_str.push_back( $5.c );
	}
      | CASES TK_DEFAULT ':' BLOCO
	{
	  $$  = $1;
	  Atributos aux = Atributos();
	  aux.v = "default";
	  $$.lista_atr.push_back( aux );
	  $$.lista_str.push_back( $4.c );
	}
      |{$$ = Atributos();}
      ;

WRITELN : TK_WRITELN TK_ABRE_PAREN E TK_FECHA_PAREN
          { Atributos cod_print = format_writeln($3);
	    $$.c = $3.c + cod_print.c;
          }
        ;

SCANLN : TK_SCANLN TK_ABRE_PAREN TK_ID TK_FECHA_PAREN
	 { 
	   $3.t = consulta_ts($3.v);
	   $$.c = "  cin >> " + $3.v + ";\n";
	 }
	 | TK_SCANLN TK_ABRE_PAREN TK_ID TK_ABRE_COLCH E TK_FECHA_COLCH TK_FECHA_PAREN
	 { 
	   $3.t = consulta_ts($3.v);
	    string offset = gera_nome_var_temp("i");
	   $$.c = $5.c + "  " + offset + " = " + $5.v;
	   if($3.t.tipo_base == "s")
		$$.c += " * 256";
  	   $$.c + gera_teste_limite_array( offset, $3.t );
	   $$.c += ";\n  cin >> " + $3.v + "[" + offset + "];\n";
	 }
	 | TK_SCANLN TK_ABRE_PAREN TK_ID TK_ABRE_COLCH E TK_COMMA E TK_FECHA_COLCH TK_FECHA_PAREN
	 { 
	   $3.t = consulta_ts($3.v);
	    string offset = gera_nome_var_temp("i");
	   $$.c = $5.c + "  " + offset + " = " + $5.v + " * " + $7.v;
	   if($3.t.tipo_base == "s")
		$$.c += " * 256";
		$$.c += gera_teste_limite_array( offset, $3.t );
	   $$.c += ";\n  cin >> " + $3.v + "[" + offset + "];\n";
	 }
       ;
  
ATRIB : TK_ID TK_ATRIB E 
        { 
          $1.t = consulta_ts( $1.v ) ;
          gera_consulta_tipos( $1.t.tipo_base, $3.t.tipo_base );
          if( $1.t.tipo_base == "s" ) 
            $$.c = $3.c + "  strncpy( " + $1.v + ", " + $3.v + ", 256 );\n";
        //  else if($1.t.tipo_base == "c")
	 //   $$
	  else
            $$.c = $3.c + "  " + $1.v + " = " + $3.v + ";\n"; 
            
          debug( "ATRIB : TK_ID TK_ATRIB E ';'", $$ );
        } 
      | TK_ID TK_ABRE_COLCH E TK_FECHA_COLCH TK_ATRIB E
        { // Falta testar: tipo, limite do array, e se a variável existe
	  $1.t = consulta_ts( $1.v ) ;
	  Tipo tipoArray = consulta_ts($1.v);
          gera_consulta_tipos( $1.t.tipo_base, $6.t.tipo_base );
	  string pos = gera_nome_var_temp("i");
	  if( $1.t.tipo_base == "s" ){
	      string address = gera_nome_var_temp("p");
	      $$.c = $3.c + gera_teste_limite_array( $3.v, tipoArray );
	      $$.c += "  " + pos + " = " + $3.v + " * 256;";
	      $$.c += "  " + address + " = " + $1.v + " + " + pos + ";\n";
              //$$.c += "  strncpy( " + address + ", " + $3.v + ", 256 );\n";
	      $$.c += " snprintf(" + address + ", 256, \"%s\", " + $6.v + ");\n";
	  }
	  else
              $$.c = $3.c + $6.c + gera_teste_limite_array( $3.v, tipoArray ) +
                 "  " + $1.v + "[" + $3.v + "] = " + $6.v + ";\n";
        }
      | TK_ID TK_ABRE_COLCH E TK_COMMA E TK_FECHA_COLCH TK_ATRIB E
        { // Falta testar: tipo, limite do array, e se a variável existe
          $1.t = consulta_ts( $1.v ) ; 
          gera_consulta_tipos( $1.t.tipo_base, $8.t.tipo_base );
          Tipo tipoArray = consulta_ts($1.v);
          $$.c = $3.c + $5.c + $8.c + gera_teste_limite_array( $3.v, $5.v, tipoArray ) + gera_indice_array( $$.v, $3.v, $5.v, tipoArray ) + " = " + $8.v + ";\n";
        }   
      ;   

E : E TK_ADD E
    { $$ = gera_codigo_operador( $1, "+", $3 ); }
  | E TK_SUB E 
    { $$ = gera_codigo_operador( $1, "-", $3 ); }
  | E TK_MULT E
    { $$ = gera_codigo_operador( $1, "*", $3 ); }
  | E TK_MOD E
    { $$ = gera_codigo_operador( $1, "%", $3 ); }
  | E TK_DIV E
    { $$ = gera_codigo_operador( $1, "/", $3 ); }
  | E '<' E
    { $$ = gera_codigo_operador( $1, "<", $3 ); }
  | E '>' E
    { $$ = gera_codigo_operador( $1, ">", $3 ); }
  | E TK_MEIG E
    { $$ = gera_codigo_operador( $1, "<=", $3 ); }
  | E TK_MAIG E
    { $$ = gera_codigo_operador( $1, ">=", $3 ); }
  | E '=' E
    { $$ = gera_codigo_operador( $1, "==", $3 ); }
  | E TK_DIF E
    { $$ = gera_codigo_operador( $1, "!=", $3 ); }
  | E TK_AND E
    { $$ = gera_codigo_operador( $1, "&&", $3 ); }
  | E TK_OR E
    { $$ = gera_codigo_operador( $1, "||", $3 ); }
  | TK_NOT E
    { Atributos blank = Atributos();
      blank.v = "";
      blank.t = Tipo("b");
      $$ = gera_codigo_operador( blank, "!", $2 ); }
  | E TK_MEMBER TK_ID
    { $$ = gera_codigo_member( $1, $3 );}
  | TK_ABRE_PAREN E TK_FECHA_PAREN
    { $$ = $2; }
  | F
  ;
  
F : TK_CINT 
    { $$.v = $1.v; $$.t = Tipo( "i" ); $$.c = $1.c; }
  | TK_CDOUBLE
    { $$.v = $1.v; $$.t = Tipo( "d" ); $$.c = $1.c; }
  | TK_CSTRING
    { $$.v = $1.v; string tipo = ($1.t.tipo_base == "char")? "c": "s";
	$$.t = Tipo( tipo ); $$.c = $1.c; }
  | TK_ID TK_ABRE_COLCH E TK_FECHA_COLCH  
    { 
      Tipo tipoArray = consulta_ts( $1.v );
      $$.t = Tipo( tipoArray.tipo_base );
      if( tipoArray.ndim != 1 )
        erro( "Variável " + $1.v + " não é array de uma dimensão" );
        
      if( $3.t.ndim != 0 || $3.t.tipo_base != "i" )
        erro( "Indice de array deve ser integer de zero dimensão: " +
              $3.t.tipo_base + "/" + toString( $3.t.ndim ) );
        
      $$.v = gera_nome_var_temp( $$.t.tipo_base );
      if ($$.t.tipo_base == "s") {
        string address = gera_nome_var_temp("p");
        string pos = gera_nome_var_temp("i");
        $$.c  = $3.c + gera_teste_limite_array($3.v, tipoArray);
        $$.c += "  " + pos + " = " + $3.v + " * 256;";
        $$.c += "  " + address + " = " + $1.v + " + " + pos + ";\n";
	$$.c += " snprintf(" + $$.v + ", 256, \"%s\", " + address + ");\n";
      } else {
        $$.c = $3.c + gera_teste_limite_array( $3.v, tipoArray ) + "  " + $$.v + " = " + $1.v + "[" + $3.v + "];\n";
      }
    }
  | TK_ID TK_ABRE_COLCH E TK_COMMA E TK_FECHA_COLCH
    {
      // Implementar: vai criar uma temporaria int para o índice e 
      // outra do tipoBase do array para o valor recuperado.
      Tipo tipoArray = consulta_ts($1.v);
      $$.t = Tipo( tipoArray.tipo_base );
      if( tipoArray.ndim != 2)
	erro( "Variável " + $1.v + " não é array de duas dimensões" );

      if( $3.t.ndim != 0 || $3.t.tipo_base != "i" )
        erro( "Primeiro indice de array deve ser integer de zero dimensão: " +
              $3.t.tipo_base + "/" + toString( $3.t.ndim ) );

      if( $5.t.ndim != 0 || $5.t.tipo_base != "i" )
        erro( "Segundo indice de array deve ser integer de zero dimensão: " +
              $5.t.tipo_base + "/" + toString( $5.t.ndim ) );

      $$.v = gera_nome_var_temp( $$.t.tipo_base );
      $$.c = $3.c + $5.c + gera_teste_limite_array( $3.v, $5.v, tipoArray ) + gera_indice_array2( $$.v, $1.v, $3.v, $5.v, tipoArray ) + ";\n";
    }  
  | TK_ID 
    { $$.v = $1.v; $$.t = consulta_ts( $1.v ); $$.c = $1.c; }  
  | TK_ID TK_ABRE_PAREN EXPRS TK_FECHA_PAREN 
    {
	// $$.t = Tipo( "i" );
	Tipo tipo_func = consulta_ts($1.v);
	$$.t = Tipo(tipo_func.retorno[0]);
	$$.v = gera_nome_var_temp($$.t.tipo_base); 
	
	$$.c = $3.c;	
	
	if($$.t.tipo_base != "s"){
		$$.c +=  "  " + $$.v + " = " + $1.v + "( ";
		for( int i = 0; i < $3.lista_str.size() - 1; ++i)
			$$.c += $3.lista_str[i] + ", ";
		$$.c += $3.lista_str[$3.lista_str.size()-1] + " );\n"; 
	}
	else{
		$$.c += $1.v + "( ";
		for( int i = 0; i < $3.lista_str.size() - 1; ++i)
			$$.c += $3.lista_str[i] + ", ";
		$$.c += $3.lista_str[$3.lista_str.size()-1] + " );\n";
		$$.c += "  strncpy( "+ $$.v +", Global_Result_" + $1.v + ", 256 );\n";
	}
	// Checagem de tipos
	if (tipo_func.params.size() != $3.lista_tipo.size())
		erro("Numero incorreto de argumentos");

	for (int i = 0; i < tipo_func.params.size(); ++i) {
		if ($3.lista_tipo[i].tipo_base != tipo_func.params[i].tipo_base)
			erro("Tipo incorreto de argumento");
		if ($3.lista_tipo[i].ndim != tipo_func.params[i].ndim)
			erro("Tipo incorreto de argumento");
	}
    }
  | TK_ID TK_ABRE_PAREN TK_FECHA_PAREN 
    {
	// $$.t = Tipo( "i" );
	Tipo tipo_func = consulta_ts($1.v);
	$$.t = Tipo(tipo_func.retorno[0]);
	$$.v = gera_nome_var_temp($$.t.tipo_base); 
	
	$$.c = "";	
	
	if($$.t.tipo_base != "s"){
		$$.c +=  "  " + $$.v + " = " + $1.v + "();\n"; 
	}
	else{
		$$.c += $1.v + "();\n";
		$$.c += "  strncpy( "+ $$.v +", Global_Result_" + $1.v + ", 256 );\n";
	}
	// Checagem de params
	if (tipo_func.params.size() != 0)
		erro("Numero incorreto de argumentos");
    } 
  ;
  
  
EXPRS : EXPRS ',' E
        { $$ = Atributos();
          $$.c = $1.c + $3.c;
          $$.lista_tipo = $1.lista_tipo; //
          $$.lista_tipo.push_back( $3.t ); //
          $$.lista_str = $1.lista_str;
          $$.lista_str.push_back( $3.v ); }
      | E 
        { $$ = Atributos();
          $$.c = $1.c;
          $$.lista_tipo.push_back( $1.t ); //
          $$.lista_str.push_back( $1.v ); }
      ;  
  
NOME_VAR : TK_ID 
           { $$.v = $1.v; $$.t = consulta_ts( $1.v ); $$.c = $1.c; }
         ; 

TIPO_ID : TK_EINTEGER
	   {$$.v = "Integer";}
	 | TK_EBOOL
	   {$$.v = "Boolean";}
	 | TK_EREAL
	   {$$.v = "Real";}
	 | TK_ECHAR
	   {$$.v = "Char";}
	 | TK_ESTRING
	   {$$.v = "String";}
	 | TK_ID
	   {$$.v = $1.v;}
	 ;
  
%%
int nlinha = 1;

#include "lex.yy.c"

int yyparse();

void debug( string producao, Atributos atr ) {
/*
  cerr << "Debug: " << producao << endl;
  cerr << "  t: " << atr.t << endl;
  cerr << "  v: " << atr.v << endl;
  cerr << "  c: " << atr.c << endl;
*/ 
}

void yyerror( const char* st )
{
  printf( "%s", st );
  printf( "Linha: %d, \"%s\"\n", nlinha, yytext );
}

void erro( string msg ) {
  cerr << "Erro: " << msg << endl; 
  fprintf( stderr, "Linha: %d, [%s]\n", nlinha, yytext );
  exit(1);
}

void inicializa_operadores() {
  // Resultados para o operador "+"
  tipo_opr["i+i"] = "i";
  tipo_opr["i+d"] = "d";
  tipo_opr["d+i"] = "d";
  tipo_opr["d+d"] = "d";
  tipo_opr["s+s"] = "s";
  tipo_opr["s+c"] = "s";
  tipo_opr["s+i"] = "s";
  tipo_opr["s+d"] = "s";
  tipo_opr["s+b"] = "s";
  tipo_opr["c+s"] = "s";
  tipo_opr["i+s"] = "s";
  tipo_opr["d+s"] = "s";
  tipo_opr["b+s"] = "s";
  tipo_opr["c+c"] = "s";
 
  // Resultados para o operador "-"
  tipo_opr["i-i"] = "i";
  tipo_opr["i-d"] = "d";
  tipo_opr["d-i"] = "d";
  tipo_opr["d-d"] = "d";
  
  // Resultados para o operador "*"
  tipo_opr["i*i"] = "i";
  tipo_opr["i*d"] = "d";
  tipo_opr["d*i"] = "d";
  tipo_opr["d*d"] = "d";
  
  // Resultados para o operador "/"
  tipo_opr["i/i"] = "d";
  tipo_opr["i/d"] = "d";
  tipo_opr["d/i"] = "d";
  tipo_opr["d/d"] = "d";
  
  // Resultados para o operador "%"
  tipo_opr["i%i"] = "i";
  
  // Resultados para o operador "<"
  tipo_opr["i<i"] = "b";
  tipo_opr["i<d"] = "b";
  tipo_opr["d<i"] = "b";
  tipo_opr["d<d"] = "b";
  tipo_opr["c<c"] = "b";
  tipo_opr["i<c"] = "b";
  tipo_opr["c<i"] = "b";
  tipo_opr["c<s"] = "b";
  tipo_opr["s<c"] = "b";
  tipo_opr["s<s"] = "b";

  // Resultados para o operador ">"
  tipo_opr["i>i"] = "b";
  tipo_opr["i>d"] = "b";
  tipo_opr["d>i"] = "b";
  tipo_opr["d>d"] = "b";
  tipo_opr["c>c"] = "b";
  tipo_opr["i>c"] = "b";
  tipo_opr["c>i"] = "b";
  tipo_opr["c>s"] = "b";
  tipo_opr["s>c"] = "b";
  tipo_opr["s>s"] = "b";

  // Resultados para o operador "<="
  tipo_opr["i<=i"] = "b";
  tipo_opr["i<=d"] = "b";
  tipo_opr["d<=i"] = "b";
  tipo_opr["d<=d"] = "b";
  tipo_opr["c<=c"] = "b";
  tipo_opr["i<=c"] = "b";
  tipo_opr["c<=i"] = "b";
  tipo_opr["c<=s"] = "b";
  tipo_opr["s<=c"] = "b";
  tipo_opr["s<=s"] = "b";

  // Resultados para o operador ">="
  tipo_opr["i>=i"] = "b";
  tipo_opr["i>=d"] = "b";
  tipo_opr["d>=i"] = "b";
  tipo_opr["d>=d"] = "b";
  tipo_opr["c>=c"] = "b";
  tipo_opr["i>=c"] = "b";
  tipo_opr["c>=i"] = "b";
  tipo_opr["c>=s"] = "b";
  tipo_opr["s>=c"] = "b";
  tipo_opr["s>=s"] = "b";


  // Resultados para o operador "And"
  tipo_opr["b&&b"] = "b";
  // Resultados para o operador "Or"
  tipo_opr["b||b"] = "b";
  
  // Resultados para o operador "="
  tipo_opr["i==i"] = "b";
  tipo_opr["i==d"] = "b";
  tipo_opr["d==i"] = "b";
  tipo_opr["d==d"] = "b";
  tipo_opr["b==b"] = "b";
  tipo_opr["s==s"] = "b";

  // Resultados para o operador "!="
  tipo_opr["i!=i"] = "b";
  tipo_opr["i!=d"] = "b";
  tipo_opr["d!=i"] = "b";
  tipo_opr["d!=d"] = "b";
  tipo_opr["b!=b"] = "b";
  tipo_opr["s!=s"] = "b";

  // Resultados para o operador "!"
  tipo_opr["!b"] = "b";
}

// Uma tabela de símbolos para cada escopo
vector< map< string, Tipo > > ts;

void empilha_ts() {
  map< string, Tipo > novo;
  ts.push_back( novo );
}

void desempilha_ts() {
  ts.pop_back();
}

Tipo consulta_ts( string nome_var ) {
  for( int i = ts.size()-1; i >= 0; i-- )
    if( ts[i].find( nome_var ) != ts[i].end() )
      return ts[i][ nome_var ];
    
  erro( "Variável não declarada: " + nome_var );
  
  return Tipo();
}

void gera_consulta_tipos( string tipo1, string tipo2 ){
  if( tipo1 != tipo2 && !(tipo1 == "d" && tipo2 == "i")){
    cout << "//tipo1 = " + tipo1 + ", tipo2 = " + tipo2;
    erro( "Tipos incompatíveis" );
  }
}

void insere_var_ts( string nome_var, Tipo tipo ) {
  if( ts[ts.size()-1].find( nome_var ) != ts[ts.size()-1].end() )
    erro( "Variável já declarada: " + nome_var + 
          " (" + ts[ts.size()-1][ nome_var ].tipo_base + ")" );
    
  ts[ts.size()-1][ nome_var ] = tipo;
}

void insere_funcao_ts(string nome_func, Tipo retorno, vector<Tipo> params)
{
 	if (ts[0].find(nome_func) != ts[0].end())
		erro("Função já declarada " + nome_func);
	ts[0][nome_func] = Tipo(retorno, params);

	// ATTN: Talvez uma péssima idéia
	/*
	if( ts[ts.size()-2].find( nome_func ) != ts[ts.size()-2].end() )
	erro( "Função já declarada: " + nome_func );

	ts[ts.size()-2][ nome_func ] = Tipo( retorno, params );
	*/
}

string toString( int n ) {
  char buff[100];
  
  sprintf( buff, "%d", n ); 
  
  return buff;
}

int toInt( string valor ) {
  int aux = -1;
  
  if( sscanf( valor.c_str(), "%d", &aux ) != 1 )
    erro( "Numero inválido: " + valor );
  
  return aux;
}
string gera_nome_var_temp( string tipo ) {
  static int n = 0;
  string nome = "t" + tipo + "_" + toString( ++n );
  
  var_temp[var_temp.size()-1] += declara_variavel( nome, Tipo( tipo ) ) + ";\n";
  
  return nome;
}

string gera_label( string tipo ) {
  static int n = 0;
  string nome = "l_" + tipo + "_" + toString( ++n );
  
  return nome;
}

Tipo tipo_resultado( Tipo t1, string opr, Tipo t3 ) {
  if( t1.ndim == 0 && t3.ndim == 0 ) {
    string aux;
    if(opr == "!")
	aux = tipo_opr[opr + t3.tipo_base];
    else
	aux = tipo_opr[ t1.tipo_base + opr + t3.tipo_base ];
  
    if( aux == "" ) 
      erro( "O operador " + opr + " não está definido para os tipos '" +
            t1.tipo_base + "' e '" + t3.tipo_base + "'.");
  
    return Tipo( aux );
  }
  else { // Testes para os operadores de comparacao de array
    string aux;
    aux = tipo_opr[ t1.tipo_base + opr + t3.tipo_base ];
  
    if( aux == "" ) 
      erro( "O operador " + opr + " não está definido para os tipos '" +
            t1.tipo_base + "' e '" + t3.tipo_base + "'.");
  
    return Tipo( aux );
  }  
} 
Atributos gera_codigo_member(Atributos s1, Atributos s2){
    Atributos aux = Atributos();
    string codigo = "";
    string start_for_label = gera_label("for_start");
    string end_for_label = gera_label("for_end");
    string contador = gera_nome_var_temp("i");
    string check_for = gera_nome_var_temp("b");
    string check_content = gera_nome_var_temp("b");
    string found = gera_nome_var_temp("b");
    Tipo tipo_array = consulta_ts(s2.v);
    string either_one = gera_nome_var_temp("b");
    string label_fail = gera_label("fail");
    string temp = gera_nome_var_temp(tipo_array.tipo_base);

    string total_length = gera_nome_var_temp("i");
    int i = 0;
    if(tipo_array.ndim < 1){
	erro("Não é possível usar o operador MEMBER sem um array.");
    }
    if(s1.t.tipo_base != tipo_array.tipo_base){
	aux.v = "0";
    }
    else if(tipo_array.ndim == 1){
	codigo += s1.c + s2.c +
		  "  " + contador + " = 0;\n" +
		  "  " + found + " = 0;\n" +
		  start_for_label + ":;\n" +
		  "  " + check_for + " = " + contador + " >= " +
		  toString(tipo_array.fim[0])+ ";\n" +
		  "  " + either_one + " = " + check_for + " || " + found + ";\n" +
		  "  if(" + either_one + ") goto " + end_for_label + ";\n" +
		  "  " + temp + " = " + s2.v +"[" + contador + "];\n" +
		  "  " + found + " = " + s1.v + " == "+ temp +";\n" +
		  label_fail + ":;\n"
		  "  " + contador + " = " + contador + " + 1;\n" +
		  "  goto " + start_for_label + ";\n" +
		  end_for_label + ":;\n";
	aux.v = found;
	aux.c = codigo;
    }
    else if(tipo_array.ndim == 2){
	codigo += s1.c + s2.c +
		  "  " + contador + " = 0;\n" +
		  "  " + found + " = 0;\n" +
		  "  " + total_length + " = " + toString(tipo_array.fim[0]) + "*" + toString(tipo_array.fim[1]) + ";\n"+
		  start_for_label + ":;\n" +
		  "  " + check_for + " = " + contador + " >= " +
		  total_length + ";\n" +
		  "  " + either_one + " = " + check_for + " || " + found + ";\n" +
		  "  if(" + either_one + ") goto " + end_for_label + ";\n" +
		  "  " + temp + " = " + s2.v +"[" + contador + "];\n" +
		  "  " + found + " = " + s1.v + " == "+ temp +";\n" +
		  label_fail + ":;\n"
		  "  " + contador + " = " + contador + " + 1;\n" +
		  "  goto " + start_for_label + ";\n" +
		  end_for_label + ":;\n";
	aux.v = found;
	aux.c = codigo;
    }
    else{
	erro("Bug sério no compilador! (gera_codigo_member)");
    }
    return aux;
}

Atributos gera_codigo_operador( Atributos s1, string opr, Atributos s3 ) {
  Atributos ss;
  
  ss.t = tipo_resultado( s1.t, opr, s3.t );
  ss.v = gera_nome_var_temp( ss.t.tipo_base );



  if(s1.t.ndim > 0 && s3.t.ndim > 0 ){
    if(s1.t.tipo_base != s3.t.tipo_base){
      ss.c = "  " + ss.v + " = 0;\n";
      return ss;
    }

    if( opr == "==" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_iguais = gera_label( "iguais" );
      string label_dif = gera_label( "dif" );
      string label_end = gera_label( "end" );
      int tamanho;

      if(s1.t.ndim == 1){
        tamanho = s1.t.fim[0];
        if (s1.t.tipo_base == "c") tamanho *= sizeof(char);
        if (s1.t.tipo_base == "i") tamanho *= sizeof(int);
        if (s1.t.tipo_base == "d") tamanho *= sizeof(double);
        if (s1.t.tipo_base == "b") tamanho *= sizeof(bool);
      }else{
        tamanho = s1.t.fim[0] * s1.t.fim[1];
        if (s1.t.tipo_base == "c") tamanho *= sizeof(char);
        if (s1.t.tipo_base == "i") tamanho *= sizeof(int);
        if (s1.t.tipo_base == "d") tamanho *= sizeof(double);
        if (s1.t.tipo_base == "b") tamanho *= sizeof(bool);
      }
 
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = memcmp( " + s1.v + ", " + s3.v + ", " + toString( tamanho ) + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " == 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_iguais + ";\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_iguais + ":;\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  " + label_end + ":;\n";

      return ss;
    }
    if( opr == "!=" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_iguais = gera_label( "iguais" );
      string label_dif = gera_label( "dif" );
      string label_end = gera_label( "end" );
      int tamanho;

      if(s1.t.ndim == 1){
        tamanho = s1.t.fim[0];
        if (s1.t.tipo_base == "c") tamanho *= sizeof(char);
        if (s1.t.tipo_base == "i") tamanho *= sizeof(int);
        if (s1.t.tipo_base == "d") tamanho *= sizeof(double);
        if (s1.t.tipo_base == "b") tamanho *= sizeof(bool);
      }else{
        tamanho = s1.t.fim[0] * s1.t.fim[1];
        if (s1.t.tipo_base == "c") tamanho *= sizeof(char);
        if (s1.t.tipo_base == "i") tamanho *= sizeof(int);
        if (s1.t.tipo_base == "d") tamanho *= sizeof(double);
        if (s1.t.tipo_base == "b") tamanho *= sizeof(bool);
      }
 
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = memcmp( " + s1.v + ", " + s3.v + ", " + toString( tamanho ) + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " != 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_iguais + ";\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_iguais + ":;\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  " + label_end + ":;\n";

      return ss;
    }
  }else{

  
  if (opr == "+" && (s1.t.tipo_base == "s" || s3.t.tipo_base == "s")) {
		const char *fmt1, *fmt3;

		if (s1.t.tipo_base == "s") fmt1 = "%s";
		else if (s1.t.tipo_base == "c") fmt1 = "%c";
		else if (s1.t.tipo_base == "i") fmt1 = "%d";
		else if (s1.t.tipo_base == "d") fmt1 = "%f";
		else if (s1.t.tipo_base == "b") fmt1 = "%d"; // TEMP
		else {
			fprintf(stderr, "Unknown: `%s`\n", &s1.t.tipo_base[0]);
			fmt1 = "%p";
		}

		if (s3.t.tipo_base == "s") fmt3 = "%s";
		else if (s3.t.tipo_base == "c") fmt3 = "%c";
		else if (s3.t.tipo_base == "i") fmt3 = "%d";
		else if (s3.t.tipo_base == "d") fmt3 = "%f";
		else if (s3.t.tipo_base == "b") fmt3 = "%d"; // TEMP
		else {
			fprintf(stderr, "Unknown: `%s`\n", &s3.t.tipo_base[0]);
			fmt3 = "%p";
		}
			
		ss.c  = s1.c + s3.c;
		ss.c += "  snprintf(" + ss.v + ", 256, \"" + fmt1 + fmt3 + "\"," + s1.v + ", " + s3.v + ");\n";
	return ss;
	}

  if( s1.t.tipo_base == "s" && s3.t.tipo_base == "s" ){
    if( opr == "==" ){
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
      ss.c += "  " + ss.v + " = !" + ss.v + ";\n";
    }
    if( opr == "!=" ){
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
    }
    if( opr == ">" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_maior = gera_label( "maior" );
      string label_end = gera_label( "end" );
      
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " > 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_maior + ";\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_maior + ":;\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  " + label_end + ":;\n";
    }
    if( opr == "<" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_maior = gera_label( "maior" );
      string label_end = gera_label( "end" );
      
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " > 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_maior + ";\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_maior + ":;\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  " + label_end + ":;\n";
    }
    if( opr == ">=" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_maior = gera_label( "maior" );
      string label_end = gera_label( "end" );
      
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " >= 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_maior + ";\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_maior + ":;\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  " + label_end + ":;\n";
    }
    if( opr == "<=" ){
      string var_if = gera_nome_var_temp( "b" );
      string label_maior = gera_label( "maior" );
      string label_end = gera_label( "end" );
      
      ss.c = s1.c + s3.c;
      ss.c += "  " + ss.v + " = strcmp( " + s1.v + ", " + s3.v + " );\n";
      ss.c += "  " + var_if + " = " + ss.v + " <= 0;\n";
      ss.c += "  if( " + var_if + " ) goto " + label_maior + ";\n";
      ss.c += "  " + ss.v + " = 0;\n";
      ss.c += "  goto " + label_end + ";\n";
      ss.c += "  " + label_maior + ":;\n";
      ss.c += "  " + ss.v + " = 1;\n";
      ss.c += "  " + label_end + ":;\n";
    }
  }
  else if( s1.t.tipo_base == "s" && s3.t.tipo_base == "c" ) 
    ;
  else if( s1.t.tipo_base == "c" && s3.t.tipo_base == "s" ) 
    ;
  else
    ss.c = s1.c + s3.c + // Codigo das expressões dos filhos da arvore.
           "  " + ss.v + " = " + s1.v + " " + opr + " " + s3.v + ";\n"; 
  }
  debug( "E: E " + opr + " E", ss );
  return ss;
}

Atributos gera_codigo_if( Atributos expr, string cmd_then, string cmd_else ) {
  Atributos ss;
  string label_else = gera_label( "else" );
  string label_end = gera_label( "end" );
  string var_comp = gera_nome_var_temp( "b" );
  
  ss.c = expr.c + 
         "  " + var_comp + " = !" + expr.v + ";\n\n" +
         "  if( " + var_comp + " ) goto " + label_else + ";\n" +
         cmd_then +
         "  goto " + label_end + ";\n" +
         label_else + ":;\n" +
         cmd_else +
         label_end + ":;\n";
         
  return ss;       
}


string traduz_nome_tipo_pascal( string tipo_pascal ) {
  // No caso do Pascal, a comparacao deveria ser case-insensitive
  
  if( tipo_pascal == "Integer" )
    return "i";
  else if( tipo_pascal == "Boolean" )
    return "b";
  else if( tipo_pascal == "Real" )
    return "d";  
  else if( tipo_pascal == "Char" )
    return "c";  
  else if( tipo_pascal == "String" )
    return "s";  
  else 
    erro( "Tipo inválido: " + tipo_pascal );
}

map<string, string> inicializaMapEmC() {
  map<string, string> aux;
  aux["i"] = "int ";
  aux["b"] = "int ";
  aux["d"] = "double ";
  aux["c"] = "char ";
  aux["s"] = "char ";
  aux["p"] = "char *"; ////////
  return aux;
}

string declara_funcao( string nome, Tipo tipo, vector<string> nomes, vector<Tipo> tipos ) {
  static map<string, string> em_C = inicializaMapEmC();
  
  if( em_C[ tipo.tipo_base ] == "" ) 
    erro( "Tipo inválido: " + tipo.tipo_base );
    
  insere_var_ts( "Result", tipo );  
    
  if( nomes.size() != tipos.size() )
    erro( "Bug no compilador! Nomes e tipos de parametros diferentes." );
      
  string aux = "";
  
  for( int i = 0; i < nomes.size(); i++ ) {
    aux += declara_variavel( nomes[i], tipos[i] ) + (i == nomes.size()-1 ? " " : ", ");  
    insere_var_ts( nomes[i], tipos[i] );  
  }
      
  return em_C[ tipo.tipo_base ] + " " + nome + "(" + aux + ")";
}

string declara_variavel( string nome, Tipo tipo ) {
  static map<string, string> em_C = inicializaMapEmC();
  
  if( em_C[ tipo.tipo_base ] == "" ) 
    erro( "Tipo inválido: " + tipo.tipo_base );
    
  string indice;
  int num;
   
  switch( tipo.ndim ) {
    case 0: indice = (tipo.tipo_base == "s" ? "[256]" : "");
            break;
              
    case 1: indice = "[" + toString( 
                  (tipo.fim[0]) *  
                  (tipo.tipo_base == "s" ? 256 : 1)
                ) + "]";
            break; 
            
    case 2: num = tipo.fim[0] * tipo.fim[1];

            indice = "[" + toString( num * (tipo.tipo_base == "s" ? 256 : 1) ) + "]";

            break;
    
    default:
       erro( "Bug muito sério..." );
  }  
  
  if (tipo.ref) {
      if (tipo.tipo_base == "s")
          erro("Strings são referência por padrâo");
      return em_C[ tipo.tipo_base ] + "&" + nome + indice;
  } else {
      return em_C[ tipo.tipo_base ] + nome + indice;
  }
}

string gera_teste_limite_array( string indice_1, Tipo tipoArray ) {
  string var_teste_inicio = gera_nome_var_temp( "b" );
  string var_teste_fim = gera_nome_var_temp( "b" );
  string var_teste = gera_nome_var_temp( "b" );
  string label_end = gera_label( "limite_array_ok" );

  string codigo = "  " + var_teste_fim + " = " + indice_1 + " < " + toString( tipoArray.fim[0] ) + ";\n";                          
  codigo += "  if( " + var_teste_fim + " ) goto " + label_end + ";\n";
  codigo += "  printf( \"Limite de array ultrapassado: %d < %d\", " + indice_1 + ", " + toString( tipoArray.fim[0] ) + " );\n";
  codigo += "  cout << endl;\n";
  codigo += "  exit( 1 );\n";
  codigo += "  " + label_end + ":;\n";
  
  return codigo;
}

string gera_teste_limite_array( string indice_1, string indice_2, Tipo tipoArray ) {
  string var_teste_fim1 = gera_nome_var_temp( "b" );
  string var_teste_fim2 = gera_nome_var_temp( "b" );
  string var_teste = gera_nome_var_temp( "b" );
  string label_end = gera_label( "limite_array_ok" );

  string codigo = "  " + var_teste_fim1 + " = " + indice_1 + " < " + toString( tipoArray.fim[0] ) + ";\n";
  codigo += "  " + var_teste_fim2 + " = " + indice_2 + " < " + toString( tipoArray.fim[1] ) + ";\n";
  codigo += "  " + var_teste + " = " + var_teste_fim1 + " && " + var_teste_fim2 + ";\n";                                
  codigo += "  if( " + var_teste + " ) goto " + label_end + ";\n";
  codigo += "  printf( \"Limite de array ultrapassado: Indice 1: %d < %d, Indice 2: %d < %d\", " + indice_1 + ", " + toString( tipoArray.fim[0] ) + ", " + indice_2 + ", " + toString( tipoArray.fim[1] ) + " );\n";
  codigo += "  cout << endl;\n";
  codigo += "  exit( 1 );\n";
  codigo += "  " + label_end + ":;\n";
  
  return codigo;
}

string gera_indice_array( string out, string indice_1, string indice_2, Tipo tipoArray ){
  string multiplicacao = gera_nome_var_temp( "b" );
  string soma = gera_nome_var_temp( "b" );

  string codigo = "  " + multiplicacao + " = " + indice_1 + " * " + toString( tipoArray.fim[1] ) + ";\n";
  codigo += "  " + soma + " = " + multiplicacao + " + " + indice_2 + ";\n";
  codigo += "  " + out + "[" + soma + "]";

  return codigo;
}

string gera_indice_array2( string out, string var, string indice_1, string indice_2, Tipo tipoArray ){
  string multiplicacao = gera_nome_var_temp( "b" );
  string soma = gera_nome_var_temp( "b" );

  string codigo = "  " + multiplicacao + " = " + indice_1 + " * " + toString( tipoArray.fim[1] ) + ";\n";
  codigo += "  " + soma + " = " + multiplicacao + " + " + indice_2 + ";\n";
  codigo += "  " + out + " = " + var + "[" + soma + "];\n";

  return codigo;
}

Atributos format_writeln(Atributos s1){
  Atributos aux;
  string cod_then = "  cout << \"True\";\n  cout << endl;\n";
  string cod_else = "  cout << \"False\";\n  cout << endl;\n";
  if(s1.t.tipo_base == "b"){
    aux = gera_codigo_if(s1, cod_then, cod_else);
  }
  else{
    aux.c = "  cout << " + s1.v + ";\n  cout << endl;\n";;
  }
  return aux;
}

int main( int argc, char* argv[] )
{
  inicializa_operadores();
  yyparse();
}
