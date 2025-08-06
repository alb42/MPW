unit editunit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver;

procedure EditDocument(Document: string; IsNew: Boolean; var AResponse: TFPHTTPConnectionResponse);
procedure SaveDocument(Params: TStrings; var AResponse: TFPHTTPConnectionResponse);

procedure ListAllFiles(var AResponse: TFPHTTPConnectionResponse);

function INetString(INS: string): string;

implementation

uses
  documentsunit, fpmimetypes, httpprotocol, templateunit, debugunit, responsehelper;


function INetString(INS: String): String;
Var
  INi: Integer;
  INS2: String;
 Begin
   Result := '';
   For INi := 1 to Length(INS) do Begin
     Case Ord(INS[INi]) of
       0..31: INS2 := ' ';
       34: INS2 := '&quot;'; { " Anführungszeichen oben                     }
       38: INS2 := '&amp;'; { &  Ampersand-Zeichen, kaufmännisches Und      }
       60: INS2 := '<'; { <  öffnende spitze Klammer                    }
       62: INS2 := '>'; { >  schließende spitze Klammer                 }
       160: INS2 := ''; {    Erzwungenes Leerzeichen                    }
       161: INS2 := '&iexcl;'; { ¡  umgekehrtes Ausrufezeichen                 }
       162: INS2 := '&cent;'; { ¢  Cent-Zeichen                               }
       163: INS2 := '&pound;'; { £  Pfund-Zeichen                              }
       164: INS2 := '&curren;'; { ¤  Währungs-Zeichen                           }
       165: INS2 := '&yen;'; { ¥  Yen-Zeichen                                }
       166: INS2 := '&brvbar;'; { ¦  durchbrochener Strich                      }
       167: INS2 := '&sect;'; { §  Paragraph-Zeichen                          }
       168: INS2 := '&uml;'; { ¨  Pünktchen oben                             }
       169: INS2 := '&copy;'; { ©  Copyright-Zeichen                          }
       170: INS2 := '&ordf;'; { ª  Ordinal-Zeichen weiblich                   }
       171: INS2 := '&laquo;'; { «  angewinkelte Anführungszeichen links       }
       172: INS2 := '&not;'; { ¬  Verneinungs-Zeichen                        }
       173: INS2 := '&shy;'; { *  kurzer Trennstrich                         }
       174: INS2 := '&reg;'; { ®  Registriermarke-Zeichen                    }
       175: INS2 := '&macr;'; { ¯  Überstrich                                 }
       176: INS2 := '&deg;'; { °  Grad-Zeichen                               }
       177: INS2 := '&plusmn;'; { ±  Plusminus-Zeichen                          }
       178: INS2 := '&sup2;'; { ²  Hoch-2-Zeichen                             }
       179: INS2 := '&sup3;'; { ³  Hoch-3-Zeichen                             }
       180: INS2 := '&acute;'; { ´  Acute-Zeichen                              }
       181: INS2 := '&micro;'; { µ  Mikro-Zeichen                              }
       182: INS2 := '&para;'; { ¶  Absatz-Zeichen                             }
       183: INS2 := '&middot;'; { ·  Mittelpunkt                                }
       184: INS2 := '&cedil;'; { ¸  Häkchen unten                              }
       185: INS2 := '&sup1;'; { ¹  Hoch-1-Zeichen                             }
       186: INS2 := '&ordm;'; { º  Ordinal-Zeichen männlich                   }
       187: INS2 := '&raquo;'; { »  angewinkelte Anführungszeichen rechts      }
       188: INS2 := '&frac14;'; { ¼  ein Viertel                                }
       189: INS2 := '&frac12;'; { ½  ein Halb                                   }
       190: INS2 := '&frac34;'; { ¾  drei Viertel                               }
       191: INS2 := '&iquest;'; { ¿  umgekehrtes Fragezeichen                   }
       192: INS2 := '&Agrave;'; { À  A mit Accent grave                         }
       193: INS2 := '&Aacute;'; { Á  A mit Accent acute                         }
       194: INS2 := '&Acirc;'; { Â  A mit Circumflex                           }
       195: INS2 := '&Atilde;'; { Ã  A mit Tilde                                }
       196: INS2 := '&Auml;'; { Ä  A Umlaut                                   }
       197: INS2 := '&Aring;'; { Å  A mit Ring                                 }
       198: INS2 := '&AElig;'; { Æ  A mit legiertem E                          }
       199: INS2 := '&Ccedil;'; { Ç  C mit Häkchen                              }
       200: INS2 := '&Egrave;'; { È  E mit Accent grave                         }
       201: INS2 := '&Eacute;'; { É  E mit Accent acute                         }
       202: INS2 := '&Ecirc;'; { Ê  E mit Circumflex                           }
       203: INS2 := '&Euml;'; { Ë  E Umlaut                                   }
       204: INS2 := '&Igrave;'; { Ì  I mit Accent grave                         }
       205: INS2 := '&Iacute;'; { Í  I mit Accent acute                         }
       206: INS2 := '&Icirc;'; { Î  I mit Circumflex                           }
       207: INS2 := '&Iuml;'; { Ï  I Umlaut                                   }
       208: INS2 := '&ETH;'; { Ð  Eth (isländisch)                           }
       209: INS2 := '&Ntilde;'; { Ñ  N mit Tilde                                }
       210: INS2 := '&Ograve;'; { Ò  O mit Accent grave                         }
       211: INS2 := '&Oacute;'; { Ó  O mit Accent acute                         }
       212: INS2 := '&Ocirc;'; { Ô  O mit Circumflex                           }
       213: INS2 := '&Otilde;'; { Õ  O mit Tilde                                }
       214: INS2 := '&Ouml;'; { Ö  O Umlaut                                   }
       215: INS2 := '&times;'; { ×  Mal-Zeichen                                }
       216: INS2 := '&Oslash;'; { Ø  O mit Schrägstrich                         }
       217: INS2 := '&Ugrave;'; { Ù  U mit Accent grave                         }
       218: INS2 := '&Uacute;'; { Ú  U mit Accent acute                         }
       219: INS2 := '&Ucirc;'; { Û  U mit Circumflex                           }
       220: INS2 := '&Uuml;'; { Ü  U Umlaut                                   }
       221: INS2 := '&Yacute;'; { Ý  Y mit Accent acute                         }
       222: INS2 := '&THORN;'; { Þ  THORN (isländisch)                         }
       223: INS2 := '&szlig;'; { ß  scharfes S                                 }
       224: INS2 := '&agrave;'; { à  a mit Accent grave                         }
       225: INS2 := '&aacute;'; { á  a mit Accent acute                         }
       226: INS2 := '&acirc;'; { â  a mit Circumflex                           }
       227: INS2 := '&atilde;'; { ã  a mit Tilde                                }
       228: INS2 := '&auml;'; { ä  a Umlaut                                   }
       229: INS2 := '&aring;'; { å  a mit Ring                                 }
       230: INS2 := '&aelig;'; { æ  a mit legiertem e                          }
       231: INS2 := '&ccedil;'; { ç  c mit Häkchen                              }
       232: INS2 := '&egrave;'; { è  e mit Accent grave                         }
       233: INS2 := '&eacute;'; { é  e mit Accent acute                         }
       234: INS2 := '&ecirc;'; { ê  e mit Circumflex                           }
       235: INS2 := '&euml;'; { ë  e Umlaut                                   }
       236: INS2 := '&igrave;'; { ì  i mit Accent grave                         }
       237: INS2 := '&iacute;'; { í  i mit Accent acute                         }
       238: INS2 := '&icirc;'; { î  i mit Circumflex                           }
       239: INS2 := '&iuml;'; { ï  i Umlaut                                   }
       240: INS2 := '&eth;'; { ð  eth (isländisch)                           }
       241: INS2 := '&ntilde;'; { ñ  n mit Tilde                                }
       242: INS2 := '&ograve;'; { ò  o mit Accent grave                         }
       243: INS2 := '&oacute;'; { ó  o mit Accent acute                         }
       244: INS2 := '&ocirc;'; { ô  o mit Circumflex                           }
       245: INS2 := '&otilde;'; { õ  o mit Tilde                                }
       246: INS2 := '&ouml;'; { ö  o Umlaut                                   }
       247: INS2 := '&divide;'; { ÷  Divisions-Zeichen                          }
       248: INS2 := '&oslash;'; { ø  o mit Schrägstrich                         }
       249: INS2 := '&ugrave;'; { ù  u mit Accent grave                         }
       250: INS2 := '&uacute;'; { ú  u mit Accent acute                         }
       251: INS2 := '&ucirc;'; { û  u mit Circumflex                           }
       252: INS2 := '&uuml;'; { ü  u Umlaut                                   }
       253: INS2 := '&yacute;'; { ý  y mit Accent acute                         }
       254: INS2 := '&thorn;'; { þ  thorn (isländisch)                         }
       255: INS2 := '&yuml;'; { ÿ  y Umlaut                                   }
       Else INS2 := INS[INi];
     End;
     Result := Result + INS2;
   End;
 End;

procedure ListAllFiles(var AResponse: TFPHTTPConnectionResponse);
var
  SL: TStringList;
  Txt, Line, NTxt: String;
  i: Integer;
  Mem: TStringStream;
begin
  SL := TStringList.Create;
  GetAllDocumentNames(SL);

  Txt := '<html><body><H1 align="center">List of all Pages</H1><ul>%list%</ul></body></html>';
  //
  NTxt := '<li><A href="/">Main Page</a> - <code>[Main Page](/)</code>';
  for i := 0 to SL.Count - 1 do
  begin
    Line := SL[i];
    NTxt := NTxt + '<li><A href="/' + HTTPEncode(Line) + '">' + INetString(Line) + '</a> - <code>[' + INetString(Line) + '](/' + HTTPEncode(Line) + ')</code>';
  end;
  Txt := StringReplace(Txt, '%list%', NTxt, [rfReplaceAll]);
  Mem := TStringStream.Create(Txt);
  Mem.Position := 0;
  try
    //AResponse.ContentType:=MimeTypes.GetMimeType(ExtractFileExt(FN));
    AResponse.ContentType:=MimeTypes.GetMimeType('.html');
    //WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+']: Serving file: "'+Fn+'". Reported Mime type: '+AResponse.ContentType);
    AResponse.ContentLength:=Mem.Size;
    AResponse.ContentStream:=Mem;
    AResponse.Code := 200;
    AResponse.SendContent;
    //AResponse.ContentStream:=Nil;
  finally
    Mem.Free;
  end;
end;

procedure EditDocument(Document: string; IsNew: Boolean; var AResponse: TFPHTTPConnectionResponse);
var
  AFilename, Txt: String;
  SL: TStringList;
  Mem: TStringStream;
begin
  if IsNew then
  begin
    DebugOut('New document');
    Document := 'New';
  end
  else
    DebugOut('Edit document ' + Document);
  Document := HTTPDecode(Document);
  Txt := '';
  AFilename := IncludeTrailingPathDelimiter(DataFolder) + GetFilename(Document);
  if not IsNew and FileExists(AFilename) then
  begin
    SL := TStringList.Create;
    SL.LoadFromFile(AFilename);
    Txt := SL.Text;
    SL.Free;
  end;
  //
  if (Document = '') and not isNew then
    Document := 'Main Page';
  if IsNew then
    Txt := StringReplace(NewTemplate, '%txt%', Txt, [rfReplaceAll])
  else
    Txt := StringReplace(EditTemplate, '%txt%', Txt, [rfReplaceAll]);
  Txt := StringReplace(Txt, '%name%', Document, [rfReplaceAll]);
  Mem := TStringStream.Create(Txt);
  Mem.Position := 0;
  try
    //AResponse.ContentType:=MimeTypes.GetMimeType(ExtractFileExt(FN));
    AResponse.ContentType:=MimeTypes.GetMimeType('.html');
    //WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+']: Serving file: "'+Fn+'". Reported Mime type: '+AResponse.ContentType);
    AResponse.ContentLength:=Mem.Size;
    AResponse.ContentStream:=Mem;
    AResponse.Code := 200;
    AResponse.SendContent;
    //AResponse.ContentStream:=Nil;
  finally
    Mem.Free;
  end;
end;

function CreateFilename(Document: string): string;
var
  i: LongWord;
begin
  Result := '';
  for i := 1 to Length(Document) do
  begin
    if Document[i] in ['a'..'z','A'..'Z', '0'..'9','_'] then
      Result := Result + Document[i];
  end;
  if Result = '' then
    Exit;
  if FileExists(IncludeTrailingPathDelimiter(DataFolder) + Result + '.md') then
  begin
    i := 1;
    while FileExists(IncludeTrailingPathDelimiter(DataFolder) + Result + '_' + IntToStr(i) + '.md') do
      Inc(i);
    Result := Result + '_' + IntToStr(i) + '.md';
  end;
end;

procedure SaveDocument(Params: TStrings; var AResponse: TFPHTTPConnectionResponse);
var
  Document, AFilename, Txt, DocName: String;
  SL: TStringList;
  Mem: TStringStream;
begin
  Document := Params.Values['name'];
  if Document = '' then
  begin
    Send404(AResponse);
    Exit
  end;
  if Document = 'Main Page' then
    Document := '';
  AFilename := GetFilename(Document);
  if AFilename = '' then
  begin
    AFilename := CreateFilename(Document);
    if AFilename = '' then
    begin
      Send404(AResponse);
      Exit;
    end;
  end;
  SL := TStringList.Create;
  SL.Text := Params.Values['content'];
  SL.SaveToFile(IncludeTrailingPathDelimiter(DataFolder) + AFilename);
  AddNewPageLink(Document, AFilename);
  if Document = '' then
    DocName := 'Main Page';
  Txt := '<html><title>MPW - '+ Document +' saved.</title><body><a href="/' + Document + '">'+Document+DocName+'</a> sucessfully saved.<p>use this snipet when you want to link to that page: <code>[' + INetString(Document) + Docname + '](/' + HTTPEncode(Document) + ')</code></body></html>';
  Mem := TStringStream.Create(Txt);
  Mem.Position := 0;
  try
    //AResponse.ContentType:=MimeTypes.GetMimeType(ExtractFileExt(FN));
    AResponse.ContentType:=MimeTypes.GetMimeType('.html');
    //WriteInfo('Connection ('+aRequest.Connection.ConnectionID+') - Request ['+aRequest.RequestID+']: Serving file: "'+Fn+'". Reported Mime type: '+AResponse.ContentType);
    AResponse.ContentLength:=Mem.Size;
    AResponse.ContentStream:=Mem;
    AResponse.Code := 200;
    AResponse.SendContent;
    //AResponse.ContentStream:=Nil;
  finally
    Mem.Free;
  end;
end;

end.

