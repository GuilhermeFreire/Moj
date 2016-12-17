Program HelloWorld;

Function MDC( a, b : Integer; teste : Real ): Integer;
Begin
  If a Mod b = 0 Then
    Result := b
  Else
    Result := MDC( b, a Mod b, 1.0 );
End; 

Begin
  WriteLn( MDC( 48, 32, 1.0 ) );
End.	
