#include "protheus.ch"
#include "topconn.ch"

Static lFatConv 	:= SuperGetMv("MV_XFTCONV",,.F.) //define se abrira modo faturamento conveniencia

/*/{Protheus.doc} TRETE018
Detalhamento Fatura
@author Maiki Perin
@since 07/03/2019
@version P12
@param Recno
@return nulo
/*/

/******************************************************************************/
User Function TRETE018(_cFil,_cCli,_cLojaCli,_cPref,_cTit,_cParc,_cTp,_lFatura)
/******************************************************************************/

Local cTitulo 		:= "Detalhamento Fatura"
Local oGroup1
Local nX

Private cFil 		:= _cFil
Private cCli 		:= _cCli
Private cLojaCli 	:= _cLojaCli
Private cPref		:= _cPref
Private cTit 		:= _cTit
Private cParc		:= _cParc
Private cTp			:= _cTp

Private oGet1, oGet2, oGet3

Private oSay1
Private oButton1

Static oDlgDetFat

aObjects := {}
aSizeAut := MsAdvSize()

//Largura, Altura, Modifica largura, Modifica altura
aAdd(aObjects,{100, 30, .T., .T.}) //Browse 1
aAdd(aObjects,{100, 30, .T., .T.}) //Browse 2
aAdd(aObjects,{100, 30, .T., .T.}) //Browse 3
aAdd(aObjects,{100, 10, .T., .T.}) //Rodapé

aInfo 	:= {aSizeAut[1],aSizeAut[2],aSizeAut[3],aSizeAut[4],2,2}
aPosObj := MsObjSize(aInfo,aObjects,.T.)

DEFINE MSDIALOG oDlgDetFat TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

//Grupo Títulos Origem
@ aPosObj[1,1] - 30, aPosObj[1,2] + 5 GROUP oGroup1 TO aPosObj[1,3] - 30,aPosObj[1,4] - 2 PROMPT "Títulos de Origem" OF oDlgDetFat COLOR 0, 16777215 PIXEL
//Browse Títulos Origem
oGet1 := GetDados1()

//Grupo Boletos
@ aPosObj[2,1] - 30, aPosObj[2,2] + 5 GROUP oGroup1 TO aPosObj[2,3] - 30,aPosObj[2,4] - 2 PROMPT "Boletos" OF oDlgDetFat COLOR 0, 16777215 PIXEL
//Browse Boletos
oGet2 := GetDados2()

//Grupo Notas Fiscais
@ aPosObj[3,1] - 30, aPosObj[3,2] + 5 GROUP oGroup1 TO aPosObj[3,3] - 30,aPosObj[3,4] - 2 PROMPT "Notas Fiscais" OF oDlgDetFat COLOR 0, 16777215 PIXEL
//Browse NFs
oGet3 := GetDados3()

//Linha horizontal
@ aPosObj[4,1] - 5, aPosObj[4,2] SAY oSay1 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgDetFat COLORS CLR_GRAY, 16777215 PIXEL

@ aPosObj[4,1] + 5, aPosObj[4,4] - 40 BUTTON oButton1 PROMPT "Fechar" SIZE 040, 010 OF oDlgDetFat ACTION oDlgDetFat:End() PIXEL

BuscaDad1(_lFatura)
BuscaDad2()
BuscaDad3(_lFatura)

//faço a busca dos dados quando origem é fatura ou renegociação
for nX := 1 to Len(oGet1:aCols)
	if Alltrim(oGet1:aCols[nX][2]) == "FT" .OR. oGet1:aCols[nX][3] == "REN"
		cFil := oGet1:aCols[nX][1]
		cPref := oGet1:aCols[nX][3]
		cTit := oGet1:aCols[nX][4]
		cParc := oGet1:aCols[nX][5]
		cTp := oGet1:aCols[nX][2]
		_lFatura := Alltrim(cTp) == "FT"
		BuscaDad3(_lFatura)
	endif
next nX

ACTIVATE MSDIALOG oDlgDetFat CENTERED

Return

/**************************/
Static Function GetDados1()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}
Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)

Local aFields 		:= IIF(!lFatConv,{"E1_FILIAL","E1_TIPO","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_NATUREZ","E1_PORTADO","E1_AGEDEP","E1_CONTA",;
						"A6_NOME","E1_XPLACA","UF6_DESC","E1_XCOND","E1_EMISSAO","E1_VENCTO","E1_VALOR","E1_DESCONT",;
						"E1_MULTA","E1_JUROS","E1_ACRESC","E1_DECRESC"},;
						{"E1_FILIAL","E1_TIPO","E1_PREFIXO","E1_NUM","E1_PARCELA","E1_NATUREZ","E1_PORTADO","E1_AGEDEP","E1_CONTA",;
						"A6_NOME","E1_XCOND","E1_EMISSAO","E1_VENCTO","E1_VALOR","E1_DESCONT",;
						"E1_MULTA","E1_JUROS","E1_ACRESC","E1_DECRESC"})
Local aAlterFields 	:= {}

//Define field properties
For nX := 1 to Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		if lMVVFilOri .AND. aFields[nX]=="E1_FILIAL"
			aHeaderEx[len(aHeaderEx)][1] := "Filial Origem"
		endif
	Endif
Next

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1] - 20,aPosObj[1,2] + 10,aPosObj[1,3] - 36,aPosObj[1,4] - 7,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlgDetFat,aHeaderEx,aColsEx)

/**********************************/
Static Function BuscaDad1(_lFatura, lGetList)
/**********************************/

Local cQry 		:= ""
Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)
Local cNumLiq := Posicione("SE1",1,xFilial("SE1", cFil) + cPref + cTit + cParc + cTp,"E1_NUMLIQ")
Local aBKpTit := {cPref, cTit, cParc, cTp, cCli, cLojaCli}
Local aAux := {}
Local aTitRet := {}
Default lGetList := .F.

//Limpa o aCols
if !lGetList
	aSize(oGet1:aCols,0)
	aTitRet := oGet1:aCols
endif

If Select("QRYTITORI") > 0
	QRYTITORI->(DbCloseArea())
Endif

cQry := "SELECT DISTINCT SE1.E1_FILIAL, SE1.E1_FILORIG,"
cQry += " SE1.E1_TIPO,"
cQry += " SE1.E1_PREFIXO,"
cQry += " SE1.E1_NUM,"
cQry += " SE1.E1_PARCELA,"
cQry += " SE1.E1_NATUREZ,"
cQry += " SE1.E1_PORTADO,"
cQry += " SE1.E1_AGEDEP,"
cQry += " SE1.E1_CONTA,"
cQry += " SA6.A6_NOME,"

If !lFatConv // Diferente de conveniência
	cQry += " SE1.E1_XPLACA,"
	cQry += " UF6.UF6_DESC,"
EndIf

cQry += " SE1.E1_XCOND,"
cQry += " SE1.E1_EMISSAO,"
cQry += " SE1.E1_VENCTO,"
cQry += " SE1.E1_VALOR,"
cQry += " SE1.E1_DESCONT,"
cQry += " SE1.E1_MULTA,"
cQry += " SE1.E1_JUROS,"
cQry += " SE1.E1_ACRESC,"
cQry += " SE1.E1_DECRESC"
cQry += " FROM "+RetSqlName("SE1")+" SE1	LEFT JOIN "+RetSqlName("SA6")+" SA6		ON SE1.E1_PORTADO	= SA6.A6_COD"
cQry += " 																			AND SE1.E1_AGEDEP	= SA6.A6_AGENCIA"
cQry += " 																			AND SE1.E1_CONTA	= SA6.A6_NUMCON"
cQry += " 																			AND SA6.D_E_L_E_T_	= ' '"
cQry += " 																			AND SA6.A6_FILIAL	= '"+xFilial("SA6", cFil)+"'"

cQry += " 									LEFT JOIN "+RetSqlName("SA1")+" SA1	ON SE1.E1_CLIENTE		= SA1.A1_COD"
cQry += " 																			AND SE1.E1_LOJA		= SA1.A1_LOJA"
cQry += " 																			AND SA1.D_E_L_E_T_	= ' '"
cQry += " 																			AND SA1.A1_FILIAL	= '"+xFilial("SA1", cFil)+"'"

If !lFatConv // Diferente de conveniência
	cQry += " 									LEFT JOIN "+RetSqlName("UF6")+" UF6	ON SA1.A1_XCLASSE	= UF6.UF6_CODIGO"
	cQry += " 																			AND UF6.D_E_L_E_T_	= ' '"
	cQry += " 																			AND UF6.UF6_FILIAL	= '"+xFilial("UF6", cFil)+"'"
EndIf

If _lFatura .AND. !(empty(cNumLiq) .AND. "PARCE. " $ SE1->E1_HIST)
	cQry += " 									INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
	cQry += " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
	cQry += " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
	cQry += " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
	cQry += " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
	cQry += " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
	cQry += " 																			AND FI7.FI7_PRFDES	= '"+cPref+"'"
	cQry += " 																			AND FI7.FI7_NUMDES	= '"+cTit+"'"
	cQry += " 																			AND FI7.FI7_PARDES	= '"+cParc+"'"
	cQry += " 																			AND FI7.FI7_TIPDES	= '"+cTp+"'"
	cQry += " 																			AND FI7.FI7_CLIDES	= '"+cCli+"'"
	cQry += " 																			AND FI7.FI7_LOJDES	= '"+cLojaCli+"'"
	cQry += " 																			AND FI7.D_E_L_E_T_	= ' '"
	cQry += " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7", cFil)+"'"
Endif

cQry += " WHERE SE1.D_E_L_E_T_	= ' '"
cQry += " AND SE1.E1_FILIAL		= '"+xFilial("SE1", cFil)+"'"

If _lFatura .AND. empty(cNumLiq) .AND. "PARCE. " $ SE1->E1_HIST
	cQry += " AND SE1.E1_CLIENTE	= '"+cCli+"'"
	cQry += " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	//E1_HIST: PARCE. 058-000000072/01                                                                             
	aAux := StrToKArr(AllTrim(SubStr(SE1->E1_HIST,8,Len(SE1->E1_HIST)-8)), "/")
	cPref:= SubStr(aAux[1],1,3)
	cTit	:= PadL(SubStr(aAux[1],5,9),tamsx3("E1_NUM")[1],"0")
	cParc:= PadR(aAux[2],tamsx3("E1_PARCELA")[1]," ")

	cQry += " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += " AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += " AND SE1.E1_PARCELA	= '"+cParc+"'"

elseif !_lFatura .AND. cPref == "REN" .AND. "RENEG. " $ SE1->E1_HIST
	cQry += " AND SE1.E1_CLIENTE	= '"+cCli+"'"
	cQry += " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	//E1_HIST: RENEG. 058-000000072/01                                                                             
	aAux := StrToKArr(AllTrim(SubStr(SE1->E1_HIST,8,Len(SE1->E1_HIST)-8)), "/")
	cPref:= SubStr(aAux[1],1,3)
	cTit	:= PadL(SubStr(aAux[1],5,9),tamsx3("E1_NUM")[1],"0")
	cParc:= PadR(aAux[2],tamsx3("E1_PARCELA")[1]," ")

	cQry += " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += " AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += " AND SE1.E1_PARCELA	= '"+cParc+"'"
	cQry += " AND SE1.E1_TIPO		= '"+cTp+"'"

elseif !_lFatura
	cQry += " AND SE1.E1_CLIENTE	= '"+cCli+"'"
	cQry += " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	cQry += " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += " AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += " AND SE1.E1_PARCELA	= '"+cParc+"'"
	cQry += " AND SE1.E1_TIPO		= '"+cTp+"'"
Endif

cQry += " ORDER BY 1,2,5,6"

cPref := aBKpTit[1]
cTit := aBKpTit[2]
cParc := aBKpTit[3]
cTp := aBKpTit[4]
cCli := aBKpTit[5]
cLojaCli := aBKpTit[6]

if ExistBlock("TR018QRY")
	cQry := ExecBlock("TR018QRY",.F.,.F.,{"TITULOS",cQry})
endif

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RFATE011.txt",cQry)
TcQuery cQry NEW Alias "QRYTITORI"

If QRYTITORI->(!EOF())

	While QRYTITORI->(!EOF())

		If !lFatConv // Diferente de conveniência

			aAdd(aTitRet,{iif(lMVVFilOri, QRYTITORI->E1_FILORIG, QRYTITORI->E1_FILIAL),;
								QRYTITORI->E1_TIPO,;
								QRYTITORI->E1_PREFIXO,;
								QRYTITORI->E1_NUM,;
								QRYTITORI->E1_PARCELA,;
								QRYTITORI->E1_NATUREZ,;
								QRYTITORI->E1_PORTADO,;
								QRYTITORI->E1_AGEDEP,;
								QRYTITORI->E1_CONTA,;
								QRYTITORI->A6_NOME,;
								Transform(QRYTITORI->E1_XPLACA,"@!R NNN-9N99"),;
								QRYTITORI->UF6_DESC,;
								QRYTITORI->E1_XCOND,;
								DToC(SToD(QRYTITORI->E1_EMISSAO)),;
								DToC(SToD(QRYTITORI->E1_VENCTO)),;
								QRYTITORI->E1_VALOR,;
								QRYTITORI->E1_DESCONT,;
								QRYTITORI->E1_MULTA,;
								QRYTITORI->E1_JUROS,;
								QRYTITORI->E1_ACRESC,;
								QRYTITORI->E1_DECRESC,;
							.F.})
		Else
			aAdd(aTitRet,{iif(lMVVFilOri, QRYTITORI->E1_FILORIG, QRYTITORI->E1_FILIAL),;
								QRYTITORI->E1_TIPO,;
								QRYTITORI->E1_PREFIXO,;
								QRYTITORI->E1_NUM,;
								QRYTITORI->E1_PARCELA,;
								QRYTITORI->E1_NATUREZ,;
								QRYTITORI->E1_PORTADO,;
								QRYTITORI->E1_AGEDEP,;
								QRYTITORI->E1_CONTA,;
								QRYTITORI->A6_NOME,;
								QRYTITORI->E1_XCOND,;
								DToC(SToD(QRYTITORI->E1_EMISSAO)),;
								DToC(SToD(QRYTITORI->E1_VENCTO)),;
								QRYTITORI->E1_VALOR,;
								QRYTITORI->E1_DESCONT,;
								QRYTITORI->E1_MULTA,;
								QRYTITORI->E1_JUROS,;
								QRYTITORI->E1_ACRESC,;
								QRYTITORI->E1_DECRESC,;
							.F.})
		EndIf

		QRYTITORI->(DbSkip())
	EndDo
Elseif !lGetList

	If !lFatConv // Diferente de conveniência
		aAdd(aTitRet,{Space(4),Space(3),Space(40),Space(55),Space(3),Space(9),Space(1),Space(10),Space(1),Space(10),Space(3),Space(5),Space(10),;
							Space(40),Space(8),Space(6),Space(2),Space(40),Space(40),Space(3),CToD(""),CToD(""),0,0,0,0,0,0,.F.})
	Else
		aAdd(aTitRet,{Space(4),Space(3),Space(40),Space(55),Space(3),Space(9),Space(1),Space(10),Space(1),Space(10),Space(3),Space(5),Space(10),;
							Space(40),Space(8),Space(6),Space(2),Space(3),CToD(""),CToD(""),0,0,0,0,0,0,.F.})
	EndIf
Endif

If Select("QRYTITORI") > 0
	QRYTITORI->(DbCloseArea())
Endif

if !lGetList
	oGet1:Refresh()
endif

Return aTitRet

/**************************/
Static Function GetDados2()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"E1_FILIAL","E1_NUMBCO","E1_NUMBOR","E1_DATABOR","EA_PORTADO","EA_AGEDEP","EA_NUMCON","A6_NOME"}
Local aAlterFields 	:= {}
Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)

//Define field properties
For nX := 1 to Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		if lMVVFilOri .AND. aFields[nX]=="E1_FILIAL"
			aHeaderEx[len(aHeaderEx)][1] := "Filial Origem"
		endif
	Endif
Next

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

If '12' $ cVersao
	Return MsNewGetDados():New(aPosObj[2,1] - 20,aPosObj[2,2] + 10,aPosObj[2,3] - 36,aPosObj[2,4] - 7,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
			"AllwaysTrue","","AllwaysTrue",oDlgDetFat,aHeaderEx,aColsEx)
Else
	Return MsNewGetDados():New(aPosObj[2,1] + 10,aPosObj[2,2] + 10,aPosObj[2,3] - 6,aPosObj[2,4] - 7,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
			"AllwaysTrue","","AllwaysTrue",oDlgDetFat,aHeaderEx,aColsEx)
Endif

/**************************/
Static Function BuscaDad2()
/**************************/

Local cQry 		:= ""
Local lMVVFilOri	:= len(cFilAnt) <> len(AlltriM(xFilial("SE1"))) //SuperGetMV("MV_XFILORI", .F., .F.)

//Limpa o aCols
aSize(oGet2:aCols,0)

If Select("QRYBOL") > 0
	QRYBOL->(DbCloseArea())
Endif

cQry := "SELECT SE1.E1_FILIAL, SE1.E1_FILORIG,"
cQry += " SE1.E1_NUMBCO NOSSONUM,"
cQry += " SE1.E1_NUMBOR NUMBORD,"
cQry += " SE1.E1_DATABOR DTBORDERO,"
cQry += " SEA.EA_PORTADO PORTADO,"
cQry += " SEA.EA_AGEDEP AGENCIA,"
cQry += " SEA.EA_NUMCON CONTA,"
cQry += " SA6.A6_NOME NOMEBANCO"
cQry += " FROM "+RetSqlName("SE1")+" SE1 	INNER JOIN "+RetSqlName("SEA")+" SEA ON SE1.E1_NUMBOR		= SEA.EA_NUMBOR"
cQry += " 																			AND SE1.E1_PREFIXO	= SEA.EA_PREFIXO"
cQry += " 																			AND SE1.E1_NUM		= SEA.EA_NUM"
cQry += " 																			AND SE1.E1_PARCELA	= SEA.EA_PARCELA"
cQry += " 																			AND SE1.E1_TIPO		= SEA.EA_TIPO"
cQry += " 																			AND SEA.D_E_L_E_T_	= ' '"
cQry += " 																			AND SEA.EA_FILIAL	= '"+xFilial("SEA", cFil)+"'"

cQry += " 									LEFT JOIN "+RetSqlName("SA6")+" SA6 ON 	SEA.EA_PORTADO		= SA6.A6_COD"
cQry += " 																			AND SEA.EA_AGEDEP	= SA6.A6_AGENCIA"
cQry += " 																			AND SEA.EA_NUMCON	= SA6.A6_NUMCON"
cQry += " 																			AND SA6.D_E_L_E_T_	= ' '"
cQry += " 																			AND SA6.A6_FILIAL	= '"+xFilial("SA6", cFil)+"'"

cQry += " WHERE SE1.D_E_L_E_T_	= ' '"
cQry += " AND SE1.E1_FILIAL		= '"+xFilial("SE1", cFil)+"'"
cQry += " AND SE1.E1_PREFIXO	= '"+cPref+"'"
cQry += " AND SE1.E1_NUM		= '"+cTit+"'"
cQry += " AND SE1.E1_PARCELA	= '"+cParc+"'"
cQry += " AND SE1.E1_TIPO		= '"+cTp+"'"
cQry += " AND SE1.E1_CLIENTE	= '"+cCli+"'"
cQry += " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
cQry += " ORDER BY 1,2,3,4,5,6"

if ExistBlock("TR018QRY")
	cQry := ExecBlock("TR018QRY",.F.,.F.,{"BOLETO",cQry})
endif

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\DETFAT.txt",cQry)
TcQuery cQry NEW Alias "QRYBOL"

If QRYBOL->(!EOF())

	While QRYBOL->(!EOF())

		aAdd(oGet2:aCols,{iif(lMVVFilOri, QRYBOL->E1_FILORIG, QRYBOL->E1_FILIAL),;
							QRYBOL->NOSSONUM,;
							QRYBOL->NUMBORD,;
							DToC(SToD(QRYBOL->DTBORDERO)),;
							QRYBOL->PORTADO,;
							QRYBOL->AGENCIA,;
							QRYBOL->CONTA,;
							QRYBOL->NOMEBANCO,;
						  	.F.})

		QRYBOL->(DbSkip())
	EndDo
Else
	aAdd(oGet2:aCols,{Space(4),Space(6),Space(6),CToD(""),Space(3),Space(5),Space(10),Space(40),.F.})
Endif

If Select("QRYBOL") > 0
	QRYBOL->(DbCloseArea())
Endif

oGet2:Refresh()

Return

/**************************/
Static Function GetDados3()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"F2_FILIAL","F2_DOC","F2_SERIE","F2_EMISSAO"}
Local aAlterFields 	:= {}

//Define field properties
For nX := 1 to Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Endif
Next

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[3,1] - 20,aPosObj[3,2] + 10,aPosObj[3,3] - 36,aPosObj[3,4] - 7,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlgDetFat,aHeaderEx,aColsEx)

/**********************************/
User Function TRE018NF(_lFatura, lGetList, aVars, l2Niveis)

	Local nX := 1
	Local aTitOrig := {}
	Local aNFRet := {}
	Default l2Niveis := .F. //caso fatura de fatura, olhar notas do(s) titulo(s) de origem

	cFil := aVars[1]
	cPref := aVars[2]
	cTit := aVars[3]
	cParc := aVars[4]
	cTp := aVars[5]
	cCli := aVars[6]
	cLojaCli := aVars[7]

	BuscaDad3(_lFatura, @aNFRet, lGetList) 

	if l2Niveis
		aTitOrig := BuscaDad1(_lFatura, lGetList)
		for nX := 1 to Len(aTitOrig)
			if Alltrim(aTitOrig[nX][2]) == "FT" .OR. aTitOrig[nX][3] == "REN"
				cFil := aTitOrig[nX][1]
				cPref := aTitOrig[nX][3]
				cTit := aTitOrig[nX][4]
				cParc := aTitOrig[nX][5]
				cTp := aTitOrig[nX][2]
				_lFatura := Alltrim(cTp) == "FT"
				BuscaDad3(_lFatura, @aNFRet, lGetList)
			endif
		next nX
	endif

Return aNFRet

Static Function BuscaDad3(_lFatura, aNFRet, lGetList)
/**********************************/

Local cQry 	:= ""
Local cQry2	:= ""
Local cNumLiq := Posicione("SE1",1,xFilial("SE1", cFil) + cPref + cTit + cParc + cTp,"E1_NUMLIQ")
Local aBKpTit := {cPref, cTit, cParc, cTp, cCli, cLojaCli}
Local aAux := {}

Default aNFRet := {}
Default lGetList := .F.

if !lGetList
	//Limpa o aCols
	aSize(oGet3:aCols,0)
endif

If Select("QRYNF") > 0
	QRYNF->(DbCloseArea())
Endif

cQry := "SELECT DISTINCT SF2.F2_FILIAL, SF2.F2_NFCUPOM, SF2.F2_DOC, SF2.F2_SERIE"

cQry += " FROM "+RetSqlName("SF2")+" SF2 	INNER JOIN "+RetSqlName("SE1")+" SE1	ON SE1.E1_NUM		= SF2.F2_DOC"
cQry += " 																			AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
cQry += " 																			AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
cQry += " 																			AND SE1.E1_LOJA		= SF2.F2_LOJA"
cQry += " 																			AND SE1.D_E_L_E_T_	= ' '"
cQry += " 																			AND SE1.E1_FILORIG 	= SF2.F2_FILIAL "

If _lFatura
	if empty(cNumLiq) .AND. "PARCE. " $ SE1->E1_HIST
		
		//E1_HIST: PARCE. 058-000000072/01                                                                             
		aAux := StrToKArr(AllTrim(SubStr(SE1->E1_HIST,8,Len(SE1->E1_HIST)-8)), "/")
		cPref:= SubStr(aAux[1],1,3)
		cTit	:= PadL(SubStr(aAux[1],5,9),tamsx3("E1_NUM")[1],"0")
		cParc:= PadR(aAux[2],tamsx3("E1_PARCELA")[1]," ")

		cQry += " 																	AND SE1.E1_CLIENTE	= '"+cCli+"'"
		cQry += " 																	AND SE1.E1_LOJA		= '"+cLojaCli+"'"
		cQry += " 																	AND SE1.E1_PREFIXO	= '"+cPref+"'"
		cQry += " 																	AND SE1.E1_NUM		= '"+cTit+"'"
		cQry += " 																	AND SE1.E1_PARCELA	= '"+cParc+"'"

	else
		cQry += " 							INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
		cQry += " 																	AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
		cQry += " 																	AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
		cQry += " 																	AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
		cQry += " 																	AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
		cQry += " 																	AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
		cQry += " 																	AND FI7.FI7_PRFDES	= '"+cPref+"'"
		cQry += " 																	AND FI7.FI7_NUMDES	= '"+cTit+"'"
		cQry += " 																	AND FI7.FI7_PARDES	= '"+cParc+"'"
		cQry += " 																	AND FI7.FI7_TIPDES	= '"+cTp+"'"
		cQry += " 																	AND FI7.FI7_CLIDES	= '"+cCli+"'"
		cQry += " 																	AND FI7.FI7_LOJDES	= '"+cLojaCli+"'"
		cQry += " 																	AND FI7.D_E_L_E_T_	= ' '"
		cQry += " 																	AND FI7.FI7_FILIAL	= '"+xFilial("FI7", cFil)+"'"
	endif
Else
	cQry += " 																		AND SE1.E1_CLIENTE	= '"+cCli+"'"
	cQry += " 																		AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	if cPref == "REN"
		//E1_HIST: RENEG. 058-000000072/01                                                                             
		aAux := StrToKArr(AllTrim(SubStr(SE1->E1_HIST,8,Len(SE1->E1_HIST)-8)), "/")
		cPref:= SubStr(aAux[1],1,3)
		cTit	:= PadL(SubStr(aAux[1],5,9),tamsx3("E1_NUM")[1],"0")
		cParc:= PadR(aAux[2],tamsx3("E1_PARCELA")[1]," ")
	endif
	cQry += " 																		AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += " 																		AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += " 																		AND SE1.E1_PARCELA	= '"+cParc+"'"
	cQry += "	 																	AND SE1.E1_TIPO		= '"+cTp+"'"
Endif

cQry += " WHERE SF2.D_E_L_E_T_ 	= ' '"
//cQry += " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
cQry += " AND ((SF2.F2_NFCUPOM	<> ' ' AND SF2.F2_NFCUPOM <> 'MDL-RECORDED') OR (SF2.F2_ESPECIE IN('SPED') AND SF2.F2_NFCUPOM = ''))" //Haja NF s/ CF/NFC-e Ou NF-e PDV
cQry += " ORDER BY 1"

cPref := aBKpTit[1]
cTit := aBKpTit[2]
cParc := aBKpTit[3]
cTp := aBKpTit[4]
cCli := aBKpTit[5]
cLojaCli := aBKpTit[6]

if ExistBlock("TR018QRY")
	cQry := ExecBlock("TR018QRY",.F.,.F.,{"NOTAS",cQry})
endif

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYNF.txt",cQry)
TcQuery cQry NEW Alias "QRYNF"

If QRYNF->(!EOF())

	While QRYNF->(!EOF())

		If Select("QRYNFCF") > 0
			QRYNFCF->(DbCloseArea())
		Endif

		cQry2 := "SELECT SF2.F2_FILIAL,"
		cQry2 += " SF2.F2_DOC,"
		cQry2 += " SF2.F2_SERIE,"
		cQry2 += " SF2.F2_EMISSAO, R_E_C_N_O_ RECSF2"
		cQry2 += " FROM "+RetSqlName("SF2")+" SF2"
		cQry2 += " WHERE SF2.D_E_L_E_T_	= ' '"
		cQry2 += " AND SF2.F2_FILIAL	= '"+QRYNF->F2_FILIAL+"'"
        cQry2 += " AND SF2.F2_DOC		= '"+IIF(!Empty(QRYNF->F2_NFCUPOM),SubStr(QRYNF->F2_NFCUPOM,4,9),QRYNF->F2_DOC)+"'"
        cQry2 += " AND SF2.F2_SERIE		= '"+IIF(!Empty(QRYNF->F2_NFCUPOM),SubStr(QRYNF->F2_NFCUPOM,1,3),QRYNF->F2_SERIE)+"'"
        cQry2 += " ORDER BY 1,2,3"

		cQry2 := ChangeQuery(cQry2)
		//MemoWrite("c:\temp\QRYNFCF.txt",cQry2)
		TcQuery cQry2 NEW Alias "QRYNFCF"

		If QRYNFCF->(!EOF())

			if lGetList
				If aScan(aNFRet,{|x| x[1] == QRYNFCF->F2_FILIAL .And. x[2] == QRYNFCF->F2_DOC .And. x[3] == QRYNFCF->F2_SERIE}) == 0

					aAdd(aNFRet,{QRYNFCF->F2_FILIAL,;
										QRYNFCF->F2_DOC,;
										QRYNFCF->F2_SERIE,;
										DToC(SToD(QRYNFCF->F2_EMISSAO)),;
									QRYNFCF->RECSF2 })
				Endif
			else
				If aScan(oGet3:aCols,{|x| x[1] == QRYNFCF->F2_FILIAL .And. x[2] == QRYNFCF->F2_DOC .And. x[3] == QRYNFCF->F2_SERIE}) == 0

					aAdd(oGet3:aCols,{QRYNFCF->F2_FILIAL,;
										QRYNFCF->F2_DOC,;
										QRYNFCF->F2_SERIE,;
										DToC(SToD(QRYNFCF->F2_EMISSAO)),;
									.F.})
				Endif
			endif
		Endif

		QRYNF->(DbSkip())
	EndDo
Elseif !lGetList
	aAdd(oGet3:aCols,{Space(4),Space(9),Space(3),CToD(""),.F.})
Endif

If Select("QRYNF") > 0
	QRYNF->(DbCloseArea())
Endif

If Select("QRYNFCF") > 0
	QRYNFCF->(DbCloseArea())
Endif

if !lGetList
	oGet3:Refresh()
endif

Return aNFRet
