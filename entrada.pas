Program HelloWorld;

Var a: Array[1 .. 10][1 .. 10] Of Real;
Var b, c: Boolean;

Begin
  b := 2;
  c := 1;
  a[5][2] := 1;
  a[5][3] := b Or c;
  WriteLn( a[5][3] );
End.	
