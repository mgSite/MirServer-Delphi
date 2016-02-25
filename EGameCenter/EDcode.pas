unit EDcode;

interface

uses
  Windows, SysUtils, Grobal2; {Classes, Hutil32,}

function EncodeMessage(sMsg: TDefaultMessage): string;
function DecodeMessage(Str: string): TDefaultMessage;
function EncodeString(Str: string): string;
function DecodeString(Str: string): string;
function EncodeBuffer(Buf: PChar; bufsize: Integer): string;
procedure DecodeBuffer(Src: string; Buf: PChar; bufsize: Integer);
procedure Decode6BitBuf(sSource: PChar; pBuf: PChar; nSrcLen, nBufLen: Integer);
procedure Encode6BitBuf(pSrc, pDest: PChar; nSrcLen, nDestLen: Integer);
function MakeDefaultMsg(wIdent: Word; nRecog: Integer; wParam, wTag, wSeries: Word): TDefaultMessage;
//var
//  CSEncode: TRTLCriticalSection;

implementation



//var
//  EncBuf,TempBuf:PChar;
function MakeDefaultMsg(wIdent: Word; nRecog: Integer; wParam, wTag, wSeries: Word): TDefaultMessage;
begin
  Result.Recog := nRecog;
  Result.Ident := wIdent;
  Result.Param := wParam;
  Result.tag := wTag;
  Result.Series := wSeries;
end;

procedure Encode6BitBuf(pSrc, pDest: PChar; nSrcLen, nDestLen: Integer);
var
  I, nRestCount, nDestPos: Integer;
  btMade, btCh, btRest: Byte;
begin
  nRestCount := 0;
  btRest := 0;
  nDestPos := 0;
  for I := 0 to nSrcLen - 1 do begin
    if nDestPos >= nDestLen then break;
    btCh := Byte(pSrc[I]);
    btMade := Byte((btRest or (btCh shr (2 + nRestCount))) and $3F);
    btRest := Byte(((btCh shl (8 - (2 + nRestCount))) shr 2) and $3F);
    Inc(nRestCount, 2);

    if nRestCount < 6 then begin
      pDest[nDestPos] := char(btMade + $3C);
      Inc(nDestPos);
    end else begin
      if nDestPos < nDestLen - 1 then begin
        pDest[nDestPos] := char(btMade + $3C);
        pDest[nDestPos + 1] := char(btRest + $3C);
        Inc(nDestPos, 2);
      end else begin
        pDest[nDestPos] := char(btMade + $3C);
        Inc(nDestPos);
      end;
      nRestCount := 0;
      btRest := 0;
    end;
  end;
  if nRestCount > 0 then begin
    pDest[nDestPos] := char(btRest + $3C);
    Inc(nDestPos);
  end;
  pDest[nDestPos] := #0;
end;

procedure Decode6BitBuf(sSource: PChar; pBuf: PChar; nSrcLen, nBufLen: Integer);
const
  Masks: array[2..6] of Byte = ($FC, $F8, $F0, $E0, $C0);
  //($FE, $FC, $F8, $F0, $E0, $C0, $80, $00);
var
  I, {nLen,} nBitPos, nMadeBit, nBufPos: Integer;
  btCh, btTmp, btByte: Byte;
begin
  //  nLen:= Length (sSource);
  nBitPos := 2;
  nMadeBit := 0;
  nBufPos := 0;
  btTmp := 0;
  for I := 0 to nSrcLen - 1 do begin
    if Integer(sSource[I]) - $3C >= 0 then
      btCh := Byte(sSource[I]) - $3C
    else begin
      nBufPos := 0;
      break;
    end;
    if nBufPos >= nBufLen then break;
    if (nMadeBit + 6) >= 8 then begin
      btByte := Byte(btTmp or ((btCh and $3F) shr (6 - nBitPos)));
      pBuf[nBufPos] := char(btByte);
      Inc(nBufPos);
      nMadeBit := 0;
      if nBitPos < 6 then Inc(nBitPos, 2)
      else begin
        nBitPos := 2;
        Continue;
      end;
    end;
    btTmp := Byte(Byte(btCh shl nBitPos) and Masks[nBitPos]); // #### ##--
    Inc(nMadeBit, 8 - nBitPos);
  end;
  pBuf[nBufPos] := #0;

  {
    nLen:= Length (sSource);
    nBitPos:= 2;
    nMadeBit:= 0;
    nBufPos:= 0;
    btTmp:= 0;
    for I:= 1 to nLen do begin
      if Integer(sSource[I]) - $3C >= 0 then
        btCh := Byte(sSource[I]) - $3C
      else begin
        nBufPos := 0;
        break;
      end;
      if nBufPos >= nBufLen then break;
      if (nMadeBit + 6) >= 8 then begin
        btByte := Byte(btTmp or ((btCh and $3F) shr (6- nBitPos)));
        pBuf[nBufPos] := Char(btByte);
        Inc(nBufPos);
        nMadeBit := 0;
        if nBitPos < 6 then Inc (nBitPos, 2)
        else begin
          nBitPos := 2;
          continue;
        end;
      end;
      btTmp:= Byte (Byte(btCh shl nBitPos) and Masks[nBitPos]);   // #### ##--
      Inc(nMadeBit, 8 - nBitPos);
    end;
    pBuf[nBufPos] := #0;
    }
end;





function DecodeMessage(Str: string): TDefaultMessage;
var
  EncBuf: array[0..BUFFERSIZE - 1] of char;
  Msg: TDefaultMessage;
begin
  Decode6BitBuf(PChar(Str), @EncBuf, length(Str), SizeOf(EncBuf));
  Move(EncBuf, Msg, SizeOf(TDefaultMessage));
  Result := Msg;
  {
  try
     EnterCriticalSection (CSencode);
     Decode6BitBuf (str, EncBuf, 1024);
     Move (EncBuf^, msg, sizeof(TDefaultMessage));
     Result := msg;
  finally
   LeaveCriticalSection (CSencode);
  end;
  }
end;


function DecodeString(Str: string): string;
var
  EncBuf: array[0..BUFFERSIZE - 1] of char;
begin
  Decode6BitBuf(PChar(Str), @EncBuf, length(Str), SizeOf(EncBuf));
  Result := StrPas(EncBuf);
  {
    try
      EnterCriticalSection (CSencode);
      Decode6BitBuf (str, EncBuf, BUFFERSIZE);
      Result := StrPas (EncBuf); //error, 1, 2, 3,...
    finally
      LeaveCriticalSection (CSencode);
    end;
  }
end;

procedure DecodeBuffer(Src: string; Buf: PChar; bufsize: Integer);
var
  EncBuf: array[0..BUFFERSIZE - 1] of char;
begin
  Decode6BitBuf(PChar(Src), @EncBuf, length(Src), SizeOf(EncBuf));
  Move(EncBuf, Buf^, bufsize);
  {
  try
     EnterCriticalSection (CSencode);
     Decode6BitBuf (src, EncBuf, BUFFERSIZE);
     Move (EncBuf^, buf^, bufsize);
  finally
   LeaveCriticalSection (CSencode);
  end;
  }
end;


function EncodeMessage(sMsg: TDefaultMessage): string;
var
  EncBuf, TempBuf: array[0..BUFFERSIZE - 1] of char;
begin
  Move(sMsg, TempBuf, SizeOf(TDefaultMessage));
  Encode6BitBuf(@TempBuf, @EncBuf, SizeOf(TDefaultMessage), SizeOf(EncBuf));
  Result := StrPas(EncBuf);
  {
  EnterCriticalSection(CSencode);
  try
    Move (smsg, TempBuf^, sizeof(TDefaultMessage));
    Encode6BitBuf(TempBuf, EncBuf, sizeof(TDefaultMessage), 1024);
    Result:=StrPas(EncBuf);  //Error: 1, 2, 3, 4, 5, 6, 7, 8, 9
  finally
    LeaveCriticalSection(CSencode);
  end;
  }
end;


function EncodeString(Str: string): string;
var
  EncBuf: array[0..BUFFERSIZE - 1] of char;
begin
  Encode6BitBuf(PChar(Str), @EncBuf, length(Str), SizeOf(EncBuf));
  Result := StrPas(EncBuf);
  {
  EnterCriticalSection(CSencode);
  try
    Encode6BitBuf(PChar(str), EncBuf, Length(str), BUFFERSIZE);
    Result:=StrPas(EncBuf);
  finally
    LeaveCriticalSection(CSencode);
  end;
  }
end;


function EncodeBuffer(Buf: PChar; bufsize: Integer): string;
var
  EncBuf, TempBuf: array[0..BUFFERSIZE - 1] of char;
begin
  if bufsize < BUFFERSIZE then begin
    Move(Buf^, TempBuf, bufsize);
    Encode6BitBuf(@TempBuf, @EncBuf, bufsize, SizeOf(EncBuf));
    Result := StrPas(EncBuf);
  end else Result := '';
  {
  EnterCriticalSection (CSencode);
  try
    if bufsize < BUFFERSIZE then begin
      Move (buf^, TempBuf^, bufsize);
      Encode6BitBuf (TempBuf, EncBuf, bufsize, BUFFERSIZE);
      Result := StrPas (EncBuf);
    end else Result := '';
  finally
    LeaveCriticalSection (CSencode);
  end;
  }
end;

initialization
  begin
    //  GetMem (EncBuf, 10240 + 100); //BUFFERSIZE + 100);
    //  GetMem (TempBuf, 10240); //2048);
    //  InitializeCriticalSection (CSEncode);
  end;


finalization
  begin
    //  FreeMem (EncBuf, BUFFERSIZE + 100);
    //  FreeMem (TempBuf, 2048);
    //  DeleteCriticalSection (CSEncode);
  end;
end.
