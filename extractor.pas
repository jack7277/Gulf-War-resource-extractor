unit extractor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    btn1: TButton;
    mmo1: TMemo;
    btn2: TButton;
    btn3: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
{$IOChecks off}
procedure extractfiles (fname:string);
const
 MNUM:array [0..11] of byte = (77,65,71,73,67,32,78,85,77,66,69,82);
var
bsize  :Integer;
f, f2 :file of byte;
f3:TextFile;
buf   : PByteArray;
buf2: array of byte;
bpos,cmp, header : Integer;
buffer2, path:string;
cou1,cou2, catalognum, filesnum, testsize:longint;
Size1,size2,strend, strstart, Pos1,i,j, offset, total_file_dir: LongInt;
begin
cmp:=0;
header:=0;
catalognum:=0;
filesnum:=0;

AssignFile(f3, fname+'.txt');
Rewrite(f3);
FileMode := fmShareDenyNone;
AssignFile(F, fname);
Reset(F);
bSize := FileSize(F);
Form1.Mmo1.lines.add(inttostr(bSize));
//Form1.mmo1.Lines.Add(IntToStr(mnum[0]));
GetMem(Buf, bSize); // выделяем память буфферу
Blockread(F, Buf[0], bsize);  // читаем весь файл туда
for cou1:=0 to (bsize-1) do      // header файла cln сделать поиск бинарный
 begin
  cmp:=0;
  for cou2:=0 to 11 do
    if buf[cou1+cou2]=MNUM[cou2] then inc (cmp);
  if cmp=12 then
    begin
      header:=cou1;
      Break;
    end;
 end;
//Form1.Mmo1.lines.add(inttostr(header));
cou1:=0;
total_file_dir:=buf[cou1+0]+256*buf[cou1+1]+256*256*buf[cou1+2]+256*256*256*buf[cou1+3];

cou1:=4; // начинаем читать файл с 4 байта
repeat
 begin
  path:='';
  // размер пути файла/каталога
  Size1:=buf[cou1+0]+256*buf[cou1+1]+256*256*buf[cou1+2]+256*256*256*buf[cou1+3];
  cou1:=cou1+4;
  for cou2:=0 to (Size1-1) do
   path:=path+chr(buf[cou1+cou2]);
  writeln (f3, path); 
  // определяем каталог или файл
  //form1.mmo1.Lines.Add(path[cou1]);
  // Если конец пути = \ тогда создаем каталог
  //if (path[cou1]='\') then MkDir(path);
  cou1:=cou1+size1;
  // определяем размер первый, запакованный
  Size1:=buf[cou1+0]+256*buf[cou1+1]+256*256*buf[cou1+2]+256*256*256*buf[cou1+3];
  //form1.mmo1.Lines.Add(IntToStr(Size1));
  if Size1=0 then
    begin
    MkDir(path);  // если размер 0 то каталог создаем еще раз на всякий
    inc (catalognum); // считаем каталоги
    end;
  // определяем размер второй, распакованный
  cou1:=cou1+4;
  size2:=buf[cou1+0]+256*buf[cou1+1]+256*256*buf[cou1+2]+256*256*256*buf[cou1+3];
  //form1.mmo1.Lines.Add(IntToStr(Size2));
  cou1:=cou1+4;
  offset:=buf[cou1+0]+256*buf[cou1+1]+256*256*buf[cou1+2]+256*256*256*buf[cou1+3];
  if Size1<>0 then Inc(filesnum); // считаем файлы
  if ( (Size1<>0) and (size2=0) ) then  // файл не запакован
    begin
     AssignFile(F2, path);
     Rewrite(f2);
     // for cou2:=0 to (Size1-1) do
     BlockWrite (f2, buf[offset+12], Size1);
     CloseFile(f2);
    end;
  if ( (Size1<>0) and (size2<>0) ) then  // файл запакован RLE
    begin
     AssignFile(F2, path);
     Rewrite(f2);
     SetLength(buf2, size1);
     cou2:=0;
     j:=0;
     repeat
      begin
       for i:=1 to (buf[cou2+offset+12]) do
        begin
         buf2[j]:=buf[cou2+offset+12+1];
         Inc(j);
        end;
       cou2:=cou2+2;
      end;
     until cou2>=size2;
     BlockWrite (f2, buf2[0], Size1);
     //testsize:=filesize(f2);
     CloseFile(f2);
    end;
  cou1:=cou1+4;
  Form1.mmo1.Lines.Add(path+', size1='+inttostr(Size1)+', size2='+inttostr(size2));
 end;

until cou1>=header ;

Form1.mmo1.Lines.Add('files='+inttostr(filesnum)+' , dirs='+inttostr(catalognum)+' ,sum='+inttostr(filesnum+catalognum)+' , total from file='+inttostr(total_file_dir));
if ( (catalognum+filesnum)=total_file_dir ) then Form1.mmo1.Lines.Add('cln read OK') else Form1.mmo1.Lines.Add('cln read FAIL');
FreeMem(Buf); // освободить, закрыть и уйти.
CloseFile (f);
CloseFile(f3);
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  extractfiles ('xgame.cln');
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  extractfiles ('xshell.cln');
end;

procedure TForm1.btn3Click(Sender: TObject);
begin
 extractfiles('xsound.cln');
end;

end.
