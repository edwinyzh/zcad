{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}

unit ugdbltypearray;
{$INCLUDE def.inc}
interface
uses Classes,UGDBStringArray,UGDBOpenArrayOfData,zcadsysvars,gdbasetypes{,UGDBOpenArray,UGDBOpenArrayOfObjects,oglwindowdef},sysutils,gdbase, geometry,
     gl,UGDBTextStyleArray,UGDBSHXFont,UGDBOpenArrayOfObjects,
     varmandef,gdbobjectsconstdef,UGDBNamedObjectsArray,StrProc,shared;
const
     DefaultSHXHeight=1;
     DefaultSHXAngle=0;
     DefaultSHXX=0;
     DefaultSHXY=0;
type
{EXPORT+}
PTDashInfo=^TDashInfo;
TDashInfo=(TDIDash,TDIText,TDIShape);
TAngleDir=(TACAbs,TACRel,TACUpRight);
shxprop=record
                Height,Angle,X,Y:GDBDouble;
                AD:TAngleDir;
                PStyle:PGDBTextStyle;
        end;

BasicSHXDashProp=object(GDBaseObject)
                param:shxprop;
                constructor initnul;
          end;
PTextProp=^TextProp;
TextProp=object(BasicSHXDashProp)
                Text,Style:GDBString;
                //PFont:PGDBfont;
                constructor initnul;
                destructor done;virtual;
          end;
PShapeProp=^ShapeProp;
ShapeProp=object(BasicSHXDashProp)
                SymbolName,FontName:GDBString;
                Psymbol:PGDBsymdolinfo;
                constructor initnul;
                destructor done;virtual;
          end;
GDBDashInfoArray=object(GDBOpenArrayOfData)(*OpenArrayOfData=TDashInfo*)
               end;
GDBDoubleArray=object(GDBOpenArrayOfData)(*OpenArrayOfData=GDBDouble*)
                constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
               end;
GDBShapePropArray=object(GDBOpenArrayOfObjects)(*OpenArrayOfObject=ShapeProp*)
                constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
               end;
GDBTextPropArray=object(GDBOpenArrayOfObjects)(*OpenArrayOfObject=TextProp*)
                constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
               end;
PGDBLtypeProp=^GDBLtypeProp;
GDBLtypeProp=object(GDBNamedObject)
               len:GDBDouble;(*'Length'*)
               h:GDBDouble;(*'Height'*)
               dasharray:GDBDashInfoArray;(*'DashInfo array'*)
               strokesarray:GDBDoubleArray;(*'Strokes array'*)
               shapearray:GDBShapePropArray;(*'Shape array'*)
               Textarray:GDBTextPropArray;(*'Text array'*)
               desk:GDBAnsiString;(*'Description'*)
               constructor init(n:GDBString);
               destructor done;virtual;
               procedure Format;
             end;
PGDBLtypePropArray=^GDBLtypePropArray;
GDBLtypePropArray=array [0..0] of GDBLtypeProp;
PGDBLtypeArray=^GDBLtypeArray;
GDBLtypeArray=object(GDBNamedObjectsArray)(*OpenArrayOfData=GDBLtypeProp*)
                    constructor init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
                    constructor initnul;
                    procedure LoadFromFile(fname:GDBString;lm:TLoadOpt);
                    function createltypeifneed(_source:PGDBLtypeProp):PGDBLtypeProp;
                    {function addlayer(name:GDBString;color:GDBInteger;lw:GDBInteger;oo,ll,pp:GDBBoolean;d:GDBString;lm:TLoadOpt):PGDBLayerProp;virtual;
                    function GetSystemLayer:PGDBLayerProp;
                    function GetCurrentLayer:PGDBLayerProp;
                    function createlayerifneed(_source:PGDBLayerProp):PGDBLayerProp;
                    function createlayerifneedbyname(lname:GDBString;_source:PGDBLayerProp):PGDBLayerProp;}
              end;
{EXPORT-}
implementation
uses
    log;
type
    TSeek=(TSeekInterface,TSeekImplementation);
procedure GDBLtypeProp.format;
var
   PSP:PShapeProp;
   PTP:PTextProp;
   ir,ir2:itrec;
   sh:double;
   i:integer;
   Psymbol:PGDBsymdolinfo;
begin
    h:=0;
    PSP:=shapearray.beginiterate(ir2);
                                       if PSP<>nil then
                                       repeat
                                             sh:=abs(psp^.Psymbol.SymMaxY*psp^.param.Height);
                                             if h<sh then
                                                         h:=sh;
                                             sh:=abs(psp^.Psymbol.SymMinY*psp^.param.Height);
                                             if h<sh then
                                                         h:=sh;
                                             PSP:=shapearray.iterate(ir2);
                                       until PSP=nil;
   PTP:=textarray.beginiterate(ir2);
                                      if PTP<>nil then
                                      repeat
                                            for i:=1 to length(PTP^.Text) do
                                            begin
                                                 if PTP^.param.PStyle<>nil then
                                                 begin
                                                 Psymbol:=PTP^.param.PStyle.pfont^.GetOrReplaceSymbolInfo(byte(PTP^.Text[i]));
                                                 sh:=abs(Psymbol.SymMaxY*PTP^.param.Height);
                                                 if h<sh then
                                                             h:=sh;
                                                 sh:=abs(Psymbol.SymMinY*PTP^.param.Height);
                                                 if h<sh then
                                                             h:=sh;
                                                 end;
                                            end;
                                            PTP:=textarray.iterate(ir2);
                                      until PTP=nil;

end;
constructor GDBLtypeProp.init(n:GDBString);
begin
     inherited;
     len:=0;
     pointer(desk):=nil;
     dasharray.init(10,sizeof(TDashInfo));
     strokesarray.init(10);
     shapearray.init(10);
     Textarray.init(10);
end;
destructor GDBLtypeProp.done;
begin
     dasharray.done;
     strokesarray.done;
     shapearray.done;
     Textarray.done;
     inherited;
end;

constructor GDBLtypeArray.init;
begin
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof(GDBLtypeProp));
end;
constructor GDBLtypeArray.initnul;
begin
  inherited initnul;
  size:=sizeof(GDBLtypeProp);
end;
constructor TextProp.initnul;
begin
     killstring(Text);
     killstring(Style);
     param.PStyle:=nil;
     //param.PFont:=nil;
     inherited;
end;
destructor TextProp.done;
begin
     Text:='';
     Text:='';
     param.PStyle:=nil;
     //PFont:=nil;
end;
constructor BasicSHXDashProp.initnul;
begin
     param.Height:=DefaultSHXHeight;
     param.Angle:=DefaultSHXAngle;
     param.X:=DefaultSHXX;
     param.Y:=DefaultSHXY;
     param.AD:=TACRel;
     param.PStyle:=nil;
end;
constructor ShapeProp.initnul;
begin
     killstring(SymbolName);
     killstring(FontName);
     Psymbol:=nil;
     inherited;
end;
destructor ShapeProp.done;
begin
     SymbolName:='';
     FontName:='';
     Psymbol:=nil;
end;
function GDBLtypeArray.createltypeifneed(_source:PGDBLtypeProp):PGDBLtypeProp;
begin
             result:=nil;
             if _source<>nil then
             begin
             result:=getAddres(_source.Name);
             if result=nil then
             begin
                  if _source<>nil then
                  begin
                       if AddItem(_source.Name,result)=IsCreated then
                       begin
                       result.init(_source.Name);
                       result.len:=_source.len;
                       _source.dasharray.copyto(@result.dasharray);
                       _source.strokesarray.copyto(@result.strokesarray);
                       //_source.shapearray.copyto(@result.shapearray);
                       //_source.Textarray.copyto(@result.Textarray);
                       result.desk:=_source.desk;
                       end;
                  end;
             end;
             end;
end;

procedure GDBLtypeArray.LoadFromFile(fname:GDBString;lm:TLoadOpt);
var
   strings:TStringList=nil;
   line:GDBString;
   i:integer;
   WhatNeed:TSeek;
   LTName,LTDesk,LTClass:GDBString;
   p:PGDBLtypeProp;
function GetStr(var s: String; out dinfo:TDashInfo): String;
var j:integer;
begin
     if length(s)>0 then
     begin
          if s[1]='[' then
                           begin
                                j:=pos(']',s);
                                result:=copy(s,2,j-2);
                                s:=copy(s,j+1,length(s)-j);
                                GetPredStr(s,',');
                                dinfo:=TDIText;
                           end
                       else
                           begin
                           result:=GetPredStr(s,',');
                           dinfo:=TDIDash;
                           end;
     end
     else
        result:='';
end;
procedure CreateLineTypeFrom(var LT:GDBString;pltprop:PGDBLtypeProp);
var
   element,subelement,text_shape,font_style,paramname:String;
   j:integer;
   stroke:GDBDouble;
   dinfo:TDashInfo;
   SP:ShapeProp;
   TP:TextProp;
procedure GetParam(var SHXDashProp:BasicSHXDashProp);
begin
  subelement:=GetPredStr(element,',');
  while subelement<>'' do
  begin
       paramname:=Uppercase(GetPredStr(subelement,'='));
       stroke:=strtofloat(subelement);
       if paramname='X' then
                            SP.param.X:=stroke
  else if paramname='Y' then
                            SP.param.Y:=stroke
  else if paramname='S' then
                            SP.param.Height:=stroke
  else if paramname='A' then
                            begin
                                 SP.param.Angle:=stroke;
                                 SP.param.AD:=TACAbs;
                            end
  else if paramname='R' then
                            begin
                                 SP.param.Angle:=stroke;
                                 SP.param.AD:=TACRel;
                            end
  else if paramname='U' then
                            begin
                                 SP.param.Angle:=stroke;
                                 SP.param.AD:=TACUpRight;
                            end
  else shared.ShowError('CreateLineTypeFrom: unknow value "'+paramname+'"');
       subelement:=GetPredStr(element,',');
  end;
end;
begin
     pltprop^.init(LTName);
     element:=GetStr(LT,dinfo);
     while element<>'' do
     begin
          case dinfo of
                       TDIDash:begin
                                    stroke:=strtofloat(element);
                                    pltprop.len:=pltprop.len+abs(stroke);
                                    pltprop^.strokesarray.add(@stroke);
                               end;
                       TDIText:begin
                                    j:=pos('"',element);
                                    if j>0 then
                                               begin
                                                    TP.initnul;
                                                    TP.Text:=GetPredStr(element,',');
                                                    TP.Style:=GetPredStr(element,',');
                                                    GetParam(TP);
                                                    pltprop^.Textarray.add(@TP);
                                                    killstring(TP.Text);
                                                    killstring(TP.Style);
                                                    TP.done;
                                               end
                                           else
                                               begin
                                                    dinfo:=TDIShape;
                                                    SP.initnul;
                                                    SP.SymbolName:=GetPredStr(element,',');
                                                    SP.FontName:=GetPredStr(element,',');
                                                    GetParam(SP);
                                                    pltprop^.shapearray.add(@SP);
                                                    killstring(SP.SymbolName);
                                                    killstring(SP.FontName);
                                                    SP.done;
                                               end;
                               end;

          end;
          pltprop^.dasharray.Add(@dinfo);
          element:=GetStr(LT,dinfo);
     end;
end;

begin
     strings:=TStringList.Create;
     strings.LoadFromFile(fname);
     WhatNeed:=TSeekInterface;
     for i:=0 to strings.Count-1 do
     begin
          line:=strings.Strings[i];
          if length(line)>1 then
          case line[1] of
                         '*':begin
                                  if WhatNeed=TSeekInterface then
                                  begin
                                       LTName:=GetPredStr(line,',');
                                       LTName:=copy(LTName,2,length(LTName)-1);
                                       LTDesk:=Line;
                                       WhatNeed:=TSeekImplementation;
                                  end;
                             end;
                         'A':begin
                                  if WhatNeed=TSeekImplementation then
                                  begin
                                       LTClass:=GetPredStr(line,',');
                                       case AddItem(LTName,pointer(p)) of
                                                    IsFounded:
                                                              begin
                                                                   if lm=TLOLoad then
                                                                   begin
                                                                        {p^.color:=color;
                                                                        p^.lineweight:=lw;
                                                                        p^._on:=oo;
                                                                        p^._lock:=ll;
                                                                        p^._print:=pp;
                                                                        p^.desk:=d;}
                                                                   end;
                                                              end;
                                                    IsCreated:
                                                              begin
                                                                   CreateLineTypeFrom(line,p);
                                                                   {if uppercase(name)=LNSysDefpoints then
                                                                                                      p^.init(Name,Color,LW,oo,ll,false,d)
                                                                   else
                                                                   p^.init(Name,Color,LW,oo,ll,pp,d);}
                                                              end;
                                                    IsError:
                                                              begin
                                                              end;
                                            end;
                                       WhatNeed:=TSeekInterface;
                                  end;

                             end;
          end;
     end;

     strings.Destroy;
end;

constructor GDBDoubleArray.init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
begin
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof(gdbdouble));
end;
constructor GDBShapePropArray.init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
begin
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof(ShapeProp));
end;
constructor GDBTextPropArray.init({$IFDEF DEBUGBUILD}ErrGuid:pansichar;{$ENDIF}m:GDBInteger);
begin
  inherited init({$IFDEF DEBUGBUILD}ErrGuid,{$ENDIF}m,sizeof(TextProp));
end;

begin
  {$IFDEF DEBUGINITSECTION}LogOut('ugdbltypearray.initialization');{$ENDIF}
end.
