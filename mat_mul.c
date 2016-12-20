#include <stdlib.h>
#include <stdio.h>

int seed = 5323;

int pseudo_random() {
    int aux;
    
    seed = (8253729 * seed + 2396403); 

    aux = (seed % 32767 + 32767) % 32767;
    return aux;  
}

// Lembre-se de que se os limites da matriz c forem ultrapassados o programa deve abortar. EM C isso não ocorre.
void multiplica( double a[3][4], double b[4][2], int lin_a, int col_a, int lin_b, int col_b, double c[3][2] ) {
    int i, j, k;
    
    if( lin_b != col_a ) {
        printf( "Matrizes incompativeis para multiplicação\n" );
        exit(0);
    }
    
    for( i = 0; i < lin_a; i++ ){
        for( j = 0; j < col_b; j++ ) {
            c[i][j] = 0;
            for( k = 0; k < lin_b; k++ ){
	      printf("%f = %f + %f * %f = \n", c[i][j], c[i][j], a[i][k], b[k][j]);
              c[i][j] = c[i][j] + a[i][k] * b[k][j];
	      printf("%f, i: %d, j: %d, k: %d\n", c[i][j], i, j, k);
            }
        }
    }
    
}

void imprime( double m[3][2], int l, int c ) {
    int i, j;
    
    for( i = 0; i < l; i++ ) {
        printf( "\n" );
        for( j = 0; j < c; j++ )
            printf( "%0.0lf \t", m[i][j] );
    }
}

void imprimeA( double m[3][4], int l, int c ) {
    int i, j;
    
    for( i = 0; i < l; i++ ) {
        printf( "\n" );
        for( j = 0; j < c; j++ )
            printf( "%0.0lf \t", m[i][j] );
    }
}

void imprimeB( double m[4][2], int l, int c ) {
    int i, j;
    
    for( i = 0; i < l; i++ ) {
        printf( "\n" );
        for( j = 0; j < c; j++ )
            printf( "%0.0lf \t", m[i][j] );
    }
}


int main() {
    double a[3][4], b[4][2], c[3][2];
    int i, j, k;
    
    for( i = 0; i < 3; i++ )
        for( j = 0; j < 4; j++ ) 
            a[i][j] = (pseudo_random() % 10);
            
    imprimeA( a, 3, 4 );
    for( i = 0; i < 4; i++ )
        for( j = 0; j < 2; j++ ) 
            b[i][j] = (pseudo_random() % 10);
    imprimeB( b, 4, 2 );
	printf("\n============\n");
    multiplica( a, b, 3, 4, 4, 2, c );
	printf("\n============\n");
    
    imprime( c, 3, 2 );
    //imprime( c, 3, 3 ); // Deve dar erro de limites de array
    
    
    return 0;
}
