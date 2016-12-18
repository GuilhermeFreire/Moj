all: remove trabalho entrada5.moj gabarito
	./trabalho < entrada5.moj > gerado.cc
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

gabarito: gabarito_files/lex.yy.c gabarito_files/y.tab.c
	g++ -o gabarito gabarito_files/y.tab.c -lfl
