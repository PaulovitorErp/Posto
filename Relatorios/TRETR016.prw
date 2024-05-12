#INCLUDE "rwmake.ch"           	
#INCLUDE "topconn.ch"
#INCLUDE "Protheus.ch"

/*/{Protheus.doc} TRETR016
Amostra - Testemunha [CRC]
@author Ricardo Quintais
@since 24/04/2014
@version 1.0
@return Nulo

@type define
/*/


#DEFINE TAMLINCABEC 55

User Function TRETR016(nOpc)

Local cNumDe      := ""
Local cNumAte     := ""

///////////////////////////////////////////////////////////////////////
///Variaveis de fontes                                             ////
///////////////////////////////////////////////////////////////////////
Private oFont6		:= TFONT():New("ARIAL",7,6,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 6 Normal
Private oFont6N 	:= TFONT():New("ARIAL",7,6,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
Private oFont8		:= TFONT():New("ARIAL",9,8,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 8 Normal
Private oFont8N 	:= TFONT():New("ARIAL",8,8,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
Private oFont10 	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.F.) ///Fonte 10 Normal
Private oFont10S	:= TFONT():New("ARIAL",9,10,.T.,.F.,5,.T.,5,.T.,.T.) ///Fonte 10 Sublinhando
Private oFont10N 	:= TFONT():New("ARIAL",9,10,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
Private oFont11		:= TFONT():New("ARIAL",11,11,,.F.,,,,.T.,.F.) ///Fonte 11 Normal
Private oFont11NS	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.T.) ///Fonte 11 Negrito e Sublinhado
Private oFont11N	:= TFONT():New("ARIAL",11,11,,.T.,,,,.T.,.F.) ///Fonte 11 Negrito
Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
Private oFont13		:= TFONT():New("ARIAL",13,13,,.F.,,,,.T.,.F.) ///Fonte 13 Normal
Private oFont13NS	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.T.) ///Fonte 13 Negrito e Sublinhado
Private oFont13N	:= TFONT():New("ARIAL",13,13,,.T.,,,,.T.,.F.) ///Fonte 13 Negrito
Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

///////////////////////////////////////////////////////////////////////
///Variaveis Impressao                                             ////
///////////////////////////////////////////////////////////////////////
Private cStartPath
Private nLin 	:= 100
Private oPrint	:= TMSPRINTER():New("Amostra - Testemunha [CRC]")
Private nPag	:= 1
Private oBrush1 := TBrush():New( , CLR_GRAY)

////////////////////////////////////////////////////////////////////////
///Outras Variaveis
////////////////////////////////////////////////////////////////////////
Private cPerg   := "TRETR016"
Private cFilZE5 := xFilial("ZE5")  //Tabela de amostra de combustivel 

//Particular
Private _cNMent := ''
Private _cCNPJCli := ''      

////////////////////////////////////////////////////////////////////////
////Tamanho do Papel A4
///////////////////////////////////////////////////////////////////////
//#define DMPAPER_A4 9 // A4 210 x 297 mm
oPrint:SetPaperSize(9)

////////////////////////////////////////////////////////////////////////
/////Orientacao do papel (Retrato ou Paisagem)
////////////////////////////////////////////////////////////////////////
//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem
oPrint:SetPortrait()///Define a orientacao da impressao como retrato

//oPrint:SetPortrait()
//oPrint:Setup()

////////////////////////////////////////////////////////////////////////
///Cria as perguntas no SX1
////////////////////////////////////////////////////////////////////////

ValidPerg()
If !Pergunte(cPerg,.t.)
	Return
Endif

cNumDe      := mv_par01
cNumAte     := mv_par02

cQry:="SELECT * "
cQry+=" FROM "+RetSqlName("ZE5")+" ZE5 "
cQry+=" WHERE ZE5.D_E_L_E_T_ <> '*' "
cQry+="     AND ZE5_FILIAL = '"+cFilZE5+"'  "
cQry+="     AND ZE5_CRC BETWEEN '"+cNumDe+"' AND '"+cNumAte+"'  "

If SELECT("TRB") > 0
	TRB->(DBCLOSEAREA())
Endif

cQry := ChangeQuery(cQry)
TcQuery cQry New Alias "TRB" // Cria uma nova area com o resultado do query
dbSelectArea("TRB")
TRB->(dbGoTop())

While !TRB->(Eof())
	
	fCabecalho()
	
	DbSelectArea("ZE3")
	dbseek(xFilial('ZE3')+TRB->ZE5_CRC)
	nLin+=150
	
	oPrint:Say(nLin, 160,AllTrim('Produto'), oFont12N)
	
	nLin+=50
	oPrint:Box(nLin,145,nLin+130,2100)              
	_cDesc:=Posicione("SB1",1,xFilial("SB1")+AllTrim(TRB->ZE5_PRODUT),"B1_DESC")
	oPrint:Say(nLin+15, 160, AllTrim(TRB->ZE5_PRODUT+"-"+_cDesc), oFont12)
	nLin+=50
	//	oPrint:Say(nLin+15, 160, AllTrim(SZ2->Z2_MUN)+"/"+SZ2->Z2_EST, oFont12)
	
	nLin+=100 //100-50
	oPrint:Say(nLin, 160,AllTrim('Data Coleta'), oFont12N)
	oPrint:Say(nLin, 1100,AllTrim('Numero do lacre'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,1000)
	oPrint:Box(nLin,1085,nLin+080,2100)
	
	oPrint:Say(nLin+15, 160, DTOC(STOD(TRB->ZE5_DATA)), oFont12)
	oPrint:Say(nLin+15, 1100, AllTrim(TRB->ZE5_LACRAM), oFont12)
	
	
	nLin+=100
	oPrint:Say(nLin, 160, AllTrim('Distribuidor'), oFont12N)
	nLin+=50                                                             
	_cDescFor := POSICIONE('SA2',1,XFILIAL('SA2')+TRB->ZE5_FORNEC,'A2_NOME')
	oPrint:Box(nLin,145,nLin+080,2100)
	oPrint:Say(nLin+15, 160, AllTrim(TRB->ZE5_FORNECE+" - "+_cDescFor), oFont12)
	
		
	nLin+=100
	oPrint:Say(nLin, 160, AllTrim('Cnpj Distribuidor'), oFont12N)
	nLin+=50
	_cnPJ := POSICIONE("SA2",1,XFILIAL("SA2")+TRB->ZE5_FORNECE,"A2_CGC")
	oPrint:Box(nLin,145,nLin+080,2100)
	oPrint:Say(nLin+15, 160, AllTrim(_cnPJ), oFont12)
	nLin+=100                                 
	
	oPrint:Say(nLin, 160,AllTrim('Nr. Nota fiscal recebimento'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	oPrint:Say(nLin+15, 160,AllTrim(TRB->ZE5_DOC)+"-"+TRB->ZE5_SERIE, oFont12)
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Transportador'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	_cTxt := POSICIONE("SA4",1,XFILIAL("SA4")+ZE3->ZE3_TRANSP,"A4_NOME")
	oPrint:Say(nLin+15, 160,alltrim(_cTxt), oFont12)
	
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Cnpj Transportador'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	_cTxt := POSICIONE("SA4",1,XFILIAL("SA4")+ZE3->ZE3_TRANSP,"A4_CGC")
	oPrint:Say(nLin+15, 160,alltrim(_cTxt))
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Nome do Motorista'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	_cTxt := POSICIONE("DA4",3,XFILIAL("DA4")+ZE3->ZE3_MOTORI,"DA4_NOME")
	oPrint:Say(nLin+15, 160,alltrim(_cTxt))
	
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('CPF Do Motorista'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	_cTxt := POSICIONE("DA4",3,XFILIAL("DA4")+ZE3->ZE3_MOTORI,"DA4_CGC")
	oPrint:Say(nLin+15, 160,alltrim(_cTxt))
	
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Placa do caminhใo'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)  
	_cPlaca:=AllTrim(ZE3->ZE3_VEICUL)+"-"+AllTrim(ZE3->ZE3_REBOQ1)+"-"+AllTrim(ZE3->ZE3_REBOQ2)
	_cDescPro := POSICIONE("DA3",1,XFILIAL("DA3")+ZE3->ZE3_VEICUL,"DA3_DESC")
	oPrint:Say(nLin+15, 160,alltrim(_cPlaca+_cDescPro))
	
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Razao Social do Revendedor'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
   	oPrint:Say(nLin+15, 160,alltrim(_cNMent))
	
	
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Cnpj do Posto Revendedor'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+080,2100)
	oPrint:Say(nLin+15, 160,alltrim(_cCNPJCli))
	
	                                                                   
	nLin+=100
	oPrint:Say(nLin, 160,AllTrim('Responsแvel pelo recebimento (Nome)'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+120,2100)
	
		
	nLin+=120
	oPrint:Say(nLin, 160,AllTrim('Assinatura do Motorista'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+120,2100)


	nLin+=120
	oPrint:Say(nLin, 160,AllTrim('Assinatura do Responsavel pelo Recebimento'), oFont12N)
	nLin+=50
	oPrint:Box(nLin,145,nLin+120,2100)
	
	fRodape()
	
	TRB->(DbSkip())
EndDO

TRB->(DbCloseArea())

///////////////////////////////////////////////////////////////////////////////////////
////Visualiza a impressao
///////////////////////////////////////////////////////////////////////////////////////
oPrint:Preview()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfCabecalho บAutor ณTotvs               บ Data ณ  13/08/2012 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que monta o cabe็alho da rotina                     บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ RCRC001                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function fCabecalho()

Local nTamTit        := 0

oPrint:StartPage() // Inicia uma nova pagina
cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")
nLin := 147


SM0->(DbSetOrder(1))
SM0->(DbSeek(cempant+cfilant)) //cempant EMPRESA QUE ESTม LOGADA E cfilant ษ A FILIAL QUE ESTA LOGADA
_cCNPJCli := SM0->M0_CGC
_cNMent   := SM0->M0_NOMECOM
_cEndent  := SM0->M0_ENDENT
_cBaiEnt  := SM0->M0_BAIRENT
_cCidEnt  := SM0->M0_CIDENT
_cEstEnt  := SM0->M0_ESTENT
_cCepEnt  := SM0->M0_CEPENT
_cInscri  := SM0->M0_INSC

oPrint:Box(nLin,145,nLin+285,540)
oPrint:SayBitmap(nLin+30, 165, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 342, 198)///Impressao da Logo

oPrint:Box(nLin,540,nLin+120,1850)
cTodaStr := "Modelo 5 - Portaria ANP 248/2000   -   AMOSTRA TESTEMUNHA"
nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
oPrint:Say(nLin+30, 1195, cTodaStr, oFont12n,,,,2)//1120 - ((nTamTit/2)*20)

oPrint:Box(nLin,1850,nLin+120,2300)
oPrint:Say(nLin+15, 2075, "Emissใo:", oFont11N,,,,2) //1985
oPrint:Say(nLin+60, 2075, DtoC(date()), oFont11,,,,2) //1985

nLin+=120
oPrint:Box(nLin,540,nLin+165,2300)

cTodaStr := AllTrim(SM0->M0_NOMECOM)
nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
oPrint:Say(nLin+10, 1400, cTodaStr, oFont12n,,,,2) //1420 - ((nTamTit/2)*20)

cTodaStr := AllTrim(SM0->M0_ENDENT)+", "+AllTrim(SM0->M0_BAIRENT)+", "+AllTrim(SM0->M0_CIDENT)+" - "+AllTrim(SM0->M0_ESTENT)
nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
oPrint:Say(nLin+50, 1400, cTodaStr, oFont10n,,,,2)//1480 - ((nTamTit/2)*20)

cTodaStr := "CEP: "+AllTrim(Transform(SM0->M0_CEPENT,"@R 99.999-999")) +" / "+"FONE: "+AllTrim(Transform(SM0->M0_TEL,"@R (99) 999999999"))
nTamTit  := Len(cTodaStr)
// 1095 ้ o meio da celula, iniciando a impressใo do meio menos a metade do tamanho da string
oPrint:Say(nLin+90, 1400, cTodaStr, oFont12n,,,,2) //1440 - ((nTamTit/2)*20)

nLin+=250

Return NIL


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณfRodape   บAutor  ณTotvs         บ Data ณ  13/08/2012 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ funcao que monta o rodape						          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function fRodape()
/////////////////////////////////////////////////////////////////////////////
////Imprime rodape
/////////////////////////////////////////////////////////////////////////////
/*nLin += 150
oPrint:Say(nLin+30,145, "Recebimento e Inspen็ใo: _______________________________________________  ____/____/____ ", oFont11)
oPrint:Say(nLin+30,2030, "Aprovado", oFont11)
oPrint:Box(nLin+30,2230,nLin+70,2270)
nLin += 80
oPrint:Say(nLin+30,145, "Convers๕es de Peso: _________________________________________________________________ ", oFont11)
oPrint:Say(nLin+30,2030, "Reprovado", oFont11)
oPrint:Box(nLin+30,2230,nLin+70,2270)
nLin += 80
oPrint:Say(nLin+30,145, "Motorista: ___________________________________________________________________________ ", oFont11)
nLin += 80
oPrint:Say(nLin+30,145, "Supervisor da Balan็a: ________________________________________________________________ ", oFont11)

nLin := 100
*/

nLin:=3300
oPrint:Line (nLin, 150, nLin, 2300)
nLin+=20
oPrint:SayBitmap(nLin-10, 150, cStartPath + "logo_totvs.bmp", 228, 050)///Impressao da Logo
oPrint:Say(nLin, 1080, "Microsiga Protheus", oFont10N)
oPrint:Say(nLin, 2300, TIME(), oFont8N,,,,1)
nLin+=50
oPrint:Line (nLin, 150, nLin, 2300)

oPrint:EndPage()

return NIL

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณPrograma   ณ ValidPerg  ณ Autor ณ TOTVS                     ณ Data ณ13/08/2012ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescricao  ณ Cria perguntas no SX1	                                         ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณObservacao ณ Sugestao de Claudio Ferreira                                     ณฑฑ
ฑฑณ           ณ                                                                  ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿*/

Static Function ValidPerg()

dbSelectArea("SX1")
dbSetOrder(1)
cPerg 	:=	PADR(cPerg,10)
U_uAjusSx1( cPerg,"01","Numero De          ?","."     ,"."       ,"mv_CH1","C",06,0,0,"G","","ZE5","","","MV_PAR01","","","","","","","","","","","","","","","","")
U_uAjusSx1( cPerg,"02","Ate Numero         ?","."     ,"."       ,"mv_CH2","C",06,0,0,"G","","ZE5","","","MV_PAR02","","","","","","","","","","","","","","","","")

Return
