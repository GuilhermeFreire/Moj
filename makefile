all: remove trabalho entrada.moj
	./trabalho < entrada.moj > gerado.cc
	./gabarito < gerado.cc
	g++ -o saida gerado.cc
	./saida

lex.yy.c: trabalho.lex
	lex trabalho.lex

y.tab.c: trabalho.y
	yacc -v trabalho.y

trabalho: lex.yy.c y.tab.c
	g++ -std=c++11 -o trabalho y.tab.c -lfl

remove: remove.sh
	./remove.sh
