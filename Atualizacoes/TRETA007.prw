#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETA007
Rotina Transferência realiza transferência de itens para reposição
@author TOTVS
@since 13/05/2014
@version P11
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA007()
/***********************/ 

Local cTitulo 		:= "Transferências - Itens para Reposição"
Local aButtons 		:= {}  

Private oSay1, oSay2, oSay3, oSay4, oSay5

Private cPerg 		:= "RESTA002"
Private oGet1
Private nCont 		:= 0

Private nAux		:= 0   
Private cArmDest	:= ""

Private oFont14N	:= TFont():New('Arial',,14,,.T.,,,,.F.,.F.) //Fonte 14 Negrito  

Private aArrayRet 	:= {}     

Static oDlgTrf

If !ValidPerg()  
	Return
Endif 

cMV_PAR01 := MV_PAR01
cArmDest  := cMV_PAR01

cMV_PAR02 := MV_PAR02
cMV_PAR03 := MV_PAR03
cMV_PAR04 := MV_PAR04
cMV_PAR05 := MV_PAR05
                     
aObjects := {}
aSizeAut := MsAdvSize()

//Largura, Altura, Modifica largura, Modifica altura
aAdd( aObjects, { 100,	90, .T., .T. } ) //Browse
aAdd( aObjects, { 100,	10,	 .T., .T. } ) //Rodapé

aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 2, 2 }
aPosObj := MsObjSize( aInfo, aObjects, .T. )

DEFINE MSDIALOG oDlgTrf TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

//Armazem destino
@ aPosObj[1,1], 005 SAY oSay1 PROMPT "Armazém destino:" SIZE 60, 007 OF oDlgTrf COLORS CLR_BLUE, 16777215 PIXEL
oSay1:oFont := oFont14N
@ aPosObj[1,1], 060 SAY oSay2 PROMPT cArmDest SIZE 20, 007 OF oDlgTrf COLORS 0, 16777215 PIXEL
oSay2:oFont := oFont14N

//Browse
oGet1 := GetDados1()
oGet1:oBrowse:bHeaderClick := {|oBrw,nCol| IIF(nCol == 1,(CliqueT(),oBrw:SetFocus()),)}
bSvblDblClick := oGet1:oBrowse:bLDblClick
oGet1:oBrowse:bLDblClick := {|| IIF(oGet1:oBrowse:nColPos <> 1,GdRstDblClick(@oGet1,@bSvblDblClick),Clique())}

//Contador
@ aPosObj[2,1], aPosObj[2,2] SAY oSay3 PROMPT "Registros selecionados:" SIZE 80, 007 OF oDlgTrf COLORS 0, 16777215 PIXEL
@ aPosObj[2,1], aPosObj[2,2]+80 SAY oSay4 PROMPT cValToChar(nCont) SIZE 40, 007 OF oDlgTrf COLORS 0, 16777215 PIXEL

//Linha horizontal
@ aPosObj[2,1] + 10, aPosObj[2,2] SAY oSay5 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlgTrf COLORS CLR_GRAY, 16777215 PIXEL

aAdd(aButtons,{"Transferência",{||Param2()},"Parâmetros","Parâmetros"})
aAdd(aButtons,{"Transferência",{||ImpLista()},"Imprimir Lista","Imprimir Lista"})

MsgRun("Selecionando registros...","Aguarde",{|| BuscaDados()}) 

ACTIVATE MSDIALOG oDlgTrf ON INIT EnchoiceBar(oDlgTrf, {|| Processa({|| ConfAlt()},"Realizando transferência...")}, {||oDlgTrf:End()},,aButtons)

Return

/**************************/
Static Function GetDados1()
/**************************/

Local nX, nPosAux
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"OK","B1_COD","B1_DESC","B1_UM","U59_QUANT","B2_QATU","QTD_TRANSF","U59_LOCORI","SALDO_ORI","ARM_PREF"}
Local aAlterFields 	:= {"QTD_TRANSF","ARM_PREF"}

//Define field properties
For nX := 1 to Len(aFields)
	If aFields[nX] == "OK" //Checkbox
	  	Aadd(aHeaderEx, {"","OK","@BMP",2,0,"","€€€€€€€€€€€€€€","C","","","",""})
	ElseIf aFields[nX] == "QTD_TRANSF" //Qtd. a ser transferida
		Aadd(aHeaderEx, {"Qtd. a ser transferida","QTD_TRANSF","@E 99,999,999,999.99",14,2,"","€€€€€€€€€€€€€€","N","","","",""})		
	ElseIf aFields[nX] == "SALDO_ORI" 
		Aadd(aHeaderEx, {"Saldo Total (locais origem)","SALDO_ORI","@E 99,999,999,999.99",14,2,"","€€€€€€€€€€€€€€","N","","","",""})		
	ElseIf aFields[nX] == "ARM_PREF" 
		Aadd(aHeaderEx, {"Local de origem preferencial","ARM_PREF","@!",2,,"U_VldArm(M->ARM_PREF)","€€€€€€€€€€€€€€","C","NNR","","",""})		
	ElseIf !empty(GetSx3Cache( aFields[nX]  ,"X3_CAMPO"))
		If aFields[nX] == "B1_COD" 
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			nPosAux := len(aHeaderEx)
			aHeaderEx[nPosAux][1] := "Produto"
		ElseIf aFields[nX] == "U59_QUANT" 
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			nPosAux := len(aHeaderEx)
			aHeaderEx[nPosAux][1] := "Qtd. para exposição"
		ElseIf aFields[nX] == "U59_LOCORI" 
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
			nPosAux := len(aHeaderEx)
			aHeaderEx[nPosAux][1] := "Locais origem"
    	Else
			aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
		Endif
	Endif
Next 

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache( aFields[nX]  ,"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Else
		Do Case
			Case aFields[nX] == "OK"
				Aadd(aFieldFill, "LBNO")

			Case aFields[nX] == "QTD_TRANSF"
				Aadd(aFieldFill, 0)

			Case aFields[nX] == "ARM_PREF"
				Aadd(aFieldFill, 0)
		EndCase
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1] + 10,aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],GD_UPDATE,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oDlgTrf,aHeaderEx,aColsEx) 

/***************************/
Static Function BuscaDados(lMsg)
/***************************/

Local cQry 	:= cQry2 := ""  
Local nAux	:= 0
Default lMsg := .T.

//Zera o contador
nCont := 0

//Limpa o aCols
aSize(oGet1:aCols,0)

If Select("QRYEST") > 0
	QRYEST->(DbCloseArea())
Endif

cQry := "SELECT SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM, U59.U59_QUANT, ISNULL(SB2.B2_QATU, 0) AS B2_QATU, U59.U59_LOCORI"
cQry += " FROM "+RetSqlName("U59")+" U59 "
cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON ("
cQry += " 	SB1.D_E_L_E_T_ 	= ' ' "
cQry += " 	AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
cQry += " 	AND SB1.B1_COD 		= U59.U59_PRODUT "
cQry += " 	AND SB1.B1_GRUPO	BETWEEN '"+cMV_PAR02+"' AND '"+cMV_PAR03+"'"
cQry += " )"
cQry += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON ("
cQry += " 	SB2.D_E_L_E_T_ 	= ' ' "
cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
cQry += " 	AND SB2.B2_COD		= U59.U59_PRODUT"
cQry += " 	AND SB2.B2_LOCAL	= U59.U59_LOCAL"
cQry += " )"
cQry += " WHERE U59.D_E_L_E_T_ 	= ' '"
cQry += " AND U59.U59_FILIAL 	= '"+xFilial("U59")+"'"
cQry += " AND U59.U59_LOCAL		= '"+cMV_PAR01+"'"
cQry += " AND U59.U59_PRODUT	BETWEEN '"+cMV_PAR04+"' AND '"+cMV_PAR05+"'"
cQry += " AND U59.U59_QUANT		> ISNULL(SB2.B2_QATU, 0) " //Quantidade mínima maior que o saldo atual
cQry += " ORDER BY 1"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\RESTA002.txt",cQry)
TcQuery cQry NEW Alias "QRYEST"

If QRYEST->(!EOF())

	While QRYEST->(!EOF())

		nAux++
	
		If Select("QRYSLDLOC") > 0
			QRYSLDLOC->(DbCloseArea())
		Endif     
		
		cQry2 := "SELECT SUM(B2_QATU) AS SLD" 
		cQry2 += " FROM "+RetSqlName("SB2")+"" 
		cQry2 += " WHERE D_E_L_E_T_ <> '*'" 
		cQry2 += " AND B2_FILIAL 	= '"+xFilial("SB2")+"'"
		cQry2 += " AND B2_COD		= '"+QRYEST->B1_COD+"'"
		cQry2 += " AND B2_LOCAL 	IN "+FormatIn(QRYEST->U59_LOCORI,"/")+""
	
		cQry2 := ChangeQuery(cQry2)
		TcQuery cQry2 NEW Alias "QRYSLDLOC"          
		
		If QRYSLDLOC->(!EOF())
			nSld := QRYSLDLOC->SLD
		Else
			nSld := 0
		Endif

		If nSld > 0 //nSld >= QRYEST->U59_QUANT - QRYEST->B2_QATU
                          
			aAdd(oGet1:aCols,{"LBOK",QRYEST->B1_COD,QRYEST->B1_DESC,QRYEST->B1_UM,QRYEST->U59_QUANT,QRYEST->B2_QATU,;
							QRYEST->U59_QUANT - QRYEST->B2_QATU,QRYEST->U59_LOCORI,nSld,Space(2),.F.})
			nCont++
		Endif
		
		QRYEST->(dbSkip())
	EndDo
Else
	if lMsg
		MsgInfo("Nenhum registro selecionado!! Favor verficar os locais de origem.","Atenção")
	endif
	aAdd(oGet1:aCols,{"LBNO",Space(TamSX3("B1_COD")[1]),Space(TamSX3("B1_DESC")[1]),Space(TamSX3("B1_UM")[1]),0,0,0,;
						Space(TamSX3("U59_LOCORI")[1]),0,Space(2),.F.})
Endif		 

If nAux > 0 .And. nCont == 0 
	if lMsg
		MsgInfo("Nenhum registro selecionado!! Favor verficar os locais de origem.","Atenção")
	endif
	aAdd(oGet1:aCols,{"LBNO",Space(TamSX3("B1_COD")[1]),Space(TamSX3("B1_DESC")[1]),Space(TamSX3("B1_UM")[1]),0,0,0,;
						Space(TamSX3("U59_LOCORI")[1]),0,Space(2),.F.})
Endif                                                                                    

If Select("QRYSLDLOC") > 0
	QRYSLDLOC->(DbCloseArea())
Endif     

If Select("QRYEST") > 0
	QRYEST->(DbCloseArea())
Endif

oGet1:Refresh()
oSay4:Refresh()

Return

/***********************/
Static Function Param2()
/***********************/

If !ValidPerg()  
	Return
Endif  

cMV_PAR01 := MV_PAR01
cMV_PAR02 := MV_PAR02
cMV_PAR03 := MV_PAR03
cMV_PAR04 := MV_PAR04
cMV_PAR05 := MV_PAR05

BuscaDados() 

Return

/*************************/
Static Function ImpLista()
/*************************/

Local oReport

oReport:= ReportDef()
oReport:PrintDialog()

Return

/**************************/
Static Function ReportDef()
/**************************/

Local oReport

Local oSection1
Local oSection2

Local cTitle    := "Lista de Produtos que necessitam de reposição"
//Local nTamSX1   := Len(SX1->X1_GRUPO)

oReport:= TReport():New("TRETA007",cTitle,"",{|oReport| PrintReport(oReport)},"Este relatório apresenta uma lista de Produtos que necessitam de reposição.")
oReport:SetLandscape()   
oReport:HideParamPage()
oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório

oSection1 := TRSection():New(oReport,"Armazens",{}/*{"QRYARM"}*/)
oSection1:SetHeaderPage(.T.)
oSection1:SetHeaderSection(.T.)

TRCell():New(oSection1,"B2_LOCAL"	,"", "ARMAZEM DESTINO", PesqPict("SB2","B2_LOCAL"),TamSX3("B2_LOCAL")[1]+1)
TRCell():New(oSection1,"NNR_DESCRI"	,"", "DESCRIÇÃO",		PesqPict("NNR","NNR_DESCRI"),TamSX3("NNR_DESCRI")[1]+1)

oSection2 := TRSection():New(oSection1,"Produtos",/*{"QRYPROD"}*/)
oSection2:SetHeaderPage(.F.)
oSection2:SetHeaderSection(.T.)  

TRCell():New(oSection2,"B1_COD"		,"", "CODIGO", 						PesqPict("SB1","B1_COD"),		TamSX3("B1_COD")[1]+1)
TRCell():New(oSection2,"B1_DESC"	,"", "DESCRIÇÃO", 					PesqPict("SB1","B1_DESC"),		TamSX3("B1_DESC")[1]+1)
TRCell():New(oSection2,"B1_UM"		,"", "UNIDADE", 					PesqPict("SB1","B1_UM"),		TamSX3("B1_UM")[1]+1)
TRCell():New(oSection2,"U59_QUANT"	,"", "QTD. EXPOSIÇÃO", 				PesqPict("U59","U59_QUANT"),	TamSX3("U59_QUANT")[1]+1)
TRCell():New(oSection2,"B2_QATU"	,"", "SALDO ATUAL", 				PesqPict("SB2","B2_QATU"),		TamSX3("B2_QATU")[1]+1)
TRCell():New(oSection2,"QTD_TRANSF"	,"", "QTD. A SER TRANSFERIDA", 		"@E 99,999,999,999.99",			14+1)
TRCell():New(oSection2,"U59_LOCORI"	,"", "LOCAIS ORIGEM",				PesqPict("SB1","U59_LOCORI"),	TamSX3("U59_LOCORI")[1]+1)
TRCell():New(oSection2,"SALDO_ORI"	,"", "SALDO TOTAL (LOCAIS ORIGEM)",	"@E 99,999,999,999.99",			14+1)

oSection3 := TRSection():New(oSection2,"Produtos",/*{"QRYPROD"}*/)
oSection3:SetHeaderPage(.F.)
oSection3:SetHeaderSection(.T.)  

TRCell():New(oSection3,"LOC_ORI"	,"", "LOCAL ORIGEM",				PesqPict("SB1","U59_LOCORI"),	TamSX3("U59_LOCORI")[1]+1)
TRCell():New(oSection3,"QTD_TRANSF2","", "QTD. A SER TRANSFERIDA", 		"@E 99,999,999,999.99",			14+1)

Return(oReport)                                                               

/***********************************/
Static Function PrintReport(oReport)
/***********************************/

Local oSection1		:= oReport:Section(1)
Local oSection2		:= oReport:Section(1):Section(1)
Local oSection3		:= oReport:Section(1):Section(1):Section(1)

Local nCont			:= 0
Local nAux			:= 0
Local nI,nJ

Local nPosOk		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="OK"})
Local nPosProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_COD"})  
Local nPosDProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_DESC"})        
Local nPosUm		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_UM"})        
Local nPosQtd 		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="U59_QUANT"})
Local nPosSaldo		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B2_QATU"})
Local nPosQtdT 		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="QTD_TRANSF"})
Local nPosLocOri	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="U59_LOCORI"})
Local nPosSldOri	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="SALDO_ORI"})
Local nPosAPref		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="ARM_PREF"})

Local aLocais		:= {}                                    
Local nQtdTransf	:= 0

oSection1:Init()
oSection2:Init()
oSection3:Init()

For nI := 1 To Len(oGet1:aCols)
	If oGet1:aCols[nI][nPosOk] == "LBOK"
		nCont++
	Endif
Next

oReport:SetMeter(nCont)

oReport:IncMeter()

oSection1:Cell("B2_LOCAL"):SetValue(cArmDest)
oSection1:Cell("NNR_DESCRI"):SetValue(Posicione("NNR",1,xFilial("NNR")+cArmDest,"NNR_DESCRI"))
oSection1:PrintLine()

If nAux > 0
	oReport:SkipLine()
Endif

dbSelectArea("SB2")
SB2->(dbSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL
		
For nI := 1 To Len(oGet1:aCols)
	
	If oReport:Cancel()
		Exit
	EndIf             
	
	If oGet1:aCols[nI][nPosOk] == "LBOK"

		oSection2:Cell("B1_COD"):SetValue(oGet1:aCols[nI][nPosProd])
		oSection2:Cell("B1_DESC"):SetValue(oGet1:aCols[nI][nPosDProd])
		oSection2:Cell("B1_UM"):SetValue(oGet1:aCols[nI][nPosUm])
		oSection2:Cell("U59_QUANT"):SetValue(oGet1:aCols[nI][nPosQtd])
		oSection2:Cell("B2_QATU"):SetValue(oGet1:aCols[nI][nPosSaldo])
		oSection2:Cell("QTD_TRANSF"):SetValue(oGet1:aCols[nI][nPosQtdT])
		oSection2:Cell("U59_LOCORI"):SetValue(oGet1:aCols[nI][nPosLocOri])
		oSection2:Cell("SALDO_ORI"):SetValue(oGet1:aCols[nI][nPosSldOri])
		oSection2:PrintLine()
		
		aLocais := StrTokArr(oGet1:aCols[nI][nPosLocOri],"/")
		
		//Ordena o array aLocais
		aLocais := Ordena(oGet1:aCols[nI][nPosProd],aLocais,oGet1:aCols[nI][nPosAPref])		
		
		nQtdTransf := 0
		
		For nJ := 1 To Len(aLocais)
			
			If SB2->(dbSeek(xFilial("SB2")+oGet1:aCols[nI][nPosProd]+aLocais[nJ])) 
				
				If SB2->B2_QATU > 0
						
					If 	nQtdTransf < oGet1:aCols[nI][nPosQtdT]

						nQtdFalt := oGet1:aCols[nI][nPosQtdT] - nQtdTransf
						
						If SB2->B2_QATU <= nQtdFalt
							nQuant := SB2->B2_QATU
						Else 
							nQuant := nQtdFalt
						Endif							
					Else
						Loop
					Endif

					oSection3:Cell("LOC_ORI"):SetValue(aLocais[nJ])
					oSection3:Cell("QTD_TRANSF2"):SetValue(nQuant)
	
					nQtdTransf += nQuant
					
					oReport:SkipLine() 
			    Endif
			Endif
		Next nJ

		oSection3:PrintLine()
	
		oReport:IncMeter()
	Endif
Next nI

If Select("QRYSLD") > 0
	QRYSLD->(DbCloseArea())
Endif     

oSection1:Finish()
oSection2:Finish()
oSection3:Finish()

Return                    

/**************************/
User Function VldArm(_cArm)
/**************************/

Local lRet :=  .F.
Local nI
Local nPosLocOri	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="U59_LOCORI"})
Local aLocais 		:= StrTokArr(oGet1:aCols[oGet1:nAt][nPosLocOri],"/")

For nI := 1 To Len(aLocais)
	If AllTrim(_cArm) == AllTrim(aLocais[nI])
		lRet := .T.
		Exit
	Endif
Next     

If !lRet
	MsgInfo("Local de origem preferencial inválido!!","Atenção")
Endif

Return lRet

/***********************/
Static Function Clique()
/***********************/

If oGet1:aCols[oGet1:nAt][1] == "LBOK"
	oGet1:aCols[oGet1:nAt][1] := "LBNO"
	nCont--
Else
	oGet1:aCols[oGet1:nAt][1] := "LBOK"	
	nCont++
Endif

oGet1:oBrowse:Refresh()
oSay4:Refresh()

Return 

/************************/
Static Function CliqueT()
/************************/
Local nI

If nAux == 1
	nAux := 0
Else
	nCont := 0

	If oGet1:aCols[1][1] == "LBOK"
		For nI := 1 To Len(oGet1:aCols)
			oGet1:aCols[nI][1] := "LBNO"
		Next
		nCont := 0
	Else
		For nI := 1 To Len(oGet1:aCols)
			oGet1:aCols[nI][1] := "LBOK"
			nCont++
		Next
	Endif
	
	nAux := 1
Endif                 

oGet1:oBrowse:Refresh()   
oSay4:Refresh()

Return                    

/************************/
Static Function ConfAlt()          
/************************/

Local nPosOk		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="OK"})
Local nPosProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_COD"})  
Local nPosDProd		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_DESC"})        
Local nPosUm		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="B1_UM"})        
Local nPosQtdT 		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="QTD_TRANSF"})
Local nPosLocOri	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="U59_LOCORI"})
Local nPosSldOri	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="SALDO_ORI"})
Local nPosAPref		:= aScan(oGet1:aHeader,{|x| AllTrim(x[2])=="ARM_PREF"})

Local cDoc			:= GetSX8Num("SD3","D3_DOC")
Local dData			:= cToD("")

Local nAux := nAux2	:= 0
Local aAuto			:= {}

Local aLocais		:= {}  

Local nQtdTransf	:= 0
Local nQtdFalt		:= 0                        
Local nQuant		:= 0
Local nI,nJ, aLinha
Local cCCESEXP		:= SuperGetMv("TP_CCESEXP",,"")

Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.

For nI := 1 To Len(oGet1:aCols)
	If oGet1:aCols[nI][nPosOk] == "LBOK"
    	If Empty(oGet1:aCols[nI][nPosAPref])
    		MsgInfo("A informação <Local de origem preferencial> obrigatória, não foi preenchida para o produto <"+AllTrim(oGet1:aCols[nI][nPosDProd])+">!!","Atenção")
    		Return
    	Endif
	Endif
Next
                       
If MsgYesNo("Será realizada transferência para os registros selecionados, deseja continuar ?")
	
	ProcRegua(Len(oGet1:aCols))  

	//Cabecalho a Incluir
	aAuto := {{cDoc,dDataBase}}//Cabecalho	

	For nI := 1 To Len(oGet1:aCols)
		
		If oGet1:aCols[nI][nPosOk] == "LBOK"
		 
			IncProc()
			nAux++
			
			If oGet1:aCols[nI][nPosSldOri] == 0
				Loop			
			Endif
			        
			nAux2++
			
			aLocais := StrTokArr(oGet1:aCols[nI][nPosLocOri],"/")
			
			//Ordena o array aLocais
			aLocais := Ordena(oGet1:aCols[nI][nPosProd],aLocais,oGet1:aCols[nI][nPosAPref])

			//cria SB2 caso nao exista
			dbSelectArea("SB2")
			dbSetOrder(1)
			MsSeek(xFilial("SB2")+oGet1:aCols[nI][nPosProd]+cArmDest)
			If !Found()
				CriaSB2(oGet1:aCols[nI][nPosProd],cArmDest)
				MsUnLock()
			EndIf
						
			nQtdTransf := 0
			
			For nJ := 1 To Len(aLocais)
				
				If SB2->(dbSeek(xFilial("SB2")+oGet1:aCols[nI][nPosProd]+aLocais[nJ])) 
				
					If SB2->B2_QATU > 0
						
						If 	nQtdTransf < oGet1:aCols[nI][nPosQtdT]

							nQtdFalt := oGet1:aCols[nI][nPosQtdT] - nQtdTransf
							
							If SB2->B2_QATU <= nQtdFalt
								nQuant := SB2->B2_QATU
							Else 
								nQuant := nQtdFalt
							Endif							
						Else
							Loop
						Endif

						aLinha := {}

						//aadd(aLinha,{"ITEM",'00'+cvaltochar(nX),Nil})
						//Origem
						aadd(aLinha,{"D3_COD", oGet1:aCols[nI][nPosProd], Nil}) //Cod Produto origem 
						aadd(aLinha,{"D3_DESCRI", oGet1:aCols[nI][nPosDProd], Nil}) //descr produto origem 
						aadd(aLinha,{"D3_UM", oGet1:aCols[nI][nPosUm], Nil}) //unidade medida origem 
						aadd(aLinha,{"D3_LOCAL", aLocais[nJ], Nil}) //armazem origem 
						aadd(aLinha,{"D3_LOCALIZ", "" ,Nil}) //Informar endereço origem

						//Destino 
						aadd(aLinha,{"D3_COD", oGet1:aCols[nI][nPosProd], Nil}) //cod produto destino 
						aadd(aLinha,{"D3_DESCRI", oGet1:aCols[nI][nPosDProd], Nil}) //descr produto destino 
						aadd(aLinha,{"D3_UM", oGet1:aCols[nI][nPosUm], Nil}) //unidade medida destino 
						aadd(aLinha,{"D3_LOCAL", cArmDest, Nil}) //armazem destino 
						aadd(aLinha,{"D3_LOCALIZ", "",Nil}) //Informar endereço destino

						aadd(aLinha,{"D3_NUMSERI", "", Nil}) //Numero serie
						aadd(aLinha,{"D3_LOTECTL", "", Nil}) //Lote Origem
						aadd(aLinha,{"D3_NUMLOTE", "", Nil}) //sublote origem
						aadd(aLinha,{"D3_DTVALID", dData, Nil}) //data validade 
						aadd(aLinha,{"D3_POTENCI", 0, Nil}) // Potencia
						aadd(aLinha,{"D3_QUANT", nQuant, Nil}) //Quantidade
						aadd(aLinha,{"D3_QTSEGUM", 0, Nil}) //Seg unidade medida
						aadd(aLinha,{"D3_ESTORNO", "", Nil}) //Estorno 
						aadd(aLinha,{"D3_NUMSEQ", "", Nil}) // Numero sequencia D3_NUMSEQ

						aadd(aLinha,{"D3_LOTECTL", "", Nil}) //Lote destino
						aadd(aLinha,{"D3_NUMLOTE", "", Nil}) //sublote destino 
						aadd(aLinha,{"D3_DTVALID", dData, Nil}) //validade lote destino
						aadd(aLinha,{"D3_ITEMGRD", "", Nil}) //Item Grade

						aadd(aLinha,{"D3_CODLAN", "", Nil}) //cat83 prod origem
						aadd(aLinha,{"D3_CODLAN", "", Nil}) //cat83 prod destino 
						aadd(aLinha,{"D3_OBSERVA", "", Nil}) //observacao
						aadd(aLinha,{"D3_CC"	, cCCESEXP, Nil}) //centro custo

						aAdd(aAuto,aLinha)

						nQtdTransf += nQuant
					Endif
				Endif
			Next nJ
		Endif
	Next nI
	
	If nAux > 0    

		If nAux2 > 0

			MSExecAuto({|x,y|mata261(x,y)},aAuto,3)
		
			If lMsErroAuto
				MostraErro()
				RollBackSx8()
			Else
				MsgInfo("Transferência realizada com sucesso!!","Atenção")
				BuscaDados(.F.)
			Endif
		Else
			MsgInfo("Nenhuma transferência realizada.","Atenção")
		Endif
	Else
		MsgInfo("Nenhum registro selecionado.","Atenção")	
	Endif
Endif
                          
Return

/***********************************************/
Static Function Ordena(_cProd,_aArray,_cArmPref) 
/***********************************************/

Local aSld		:= {}
Local nPos		:= 0
Local nX,nY

If Len(_aArray) == 1
	aArrayRet := _aArray
Else
	aAdd(aArrayRet,_cArmPref)

	For nX := 1 To Len(_aArray)
		
		If (nPos := aScan(aArrayRet,{|x| x == _aArray[nX]})) == 0  //01/05

			If Select("QRYSLD") > 0
				QRYSLD->(DbCloseArea())
			Endif     
			
			cQry := "SELECT SUM(B2_QATU) AS SLD" 
			cQry += " FROM "+RetSqlName("SB2")+"" 
			cQry += " WHERE D_E_L_E_T_ <> '*'" 
			cQry += " AND B2_FILIAL 	= '"+xFilial("SB2")+"'"
			cQry += " AND B2_COD		= '"+_cProd+"'"
			cQry += " AND B2_LOCAL 		= '"+_aArray[nX]+"'"
		
			cQry := ChangeQuery(cQry)
			TcQuery cQry NEW Alias "QRYSLD"          
			
			If QRYSLD->(!EOF())
				aAdd(aSld,{_aArray[nX],QRYSLD->SLD})
			Endif
		Endif
	Next
	
	aSort(aSld,,,{|x,y| x[2] < y[2]})
	
	For nY := 1 To Len(aSld)
		aAdd(aArrayRet,aSld[nY][1])
	Next
Endif

If Select("QRYSLD") > 0
	QRYSLD->(DbCloseArea())
Endif     

Return aArrayRet

/**************************/
Static Function ValidPerg() 
/**************************/

Local aHelpPor := {}

//U_uAjusSx1(cPerg,"01","Armazém destino    ?","","","mv_ch1","C",02,0,0,"G","","NNR","","","mv_par01","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
//U_uAjusSx1(cPerg,"02","Do Grupo	       	  ?","","","mv_ch2","C",04,0,0,"G","","SBM","","","mv_par02","","","","    ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
//U_uAjusSx1(cPerg,"03","Ate o Grupo        ?","","","mv_ch3","C",04,0,0,"G","","SBM","","","mv_par03","","","","ZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
//U_uAjusSx1(cPerg,"04","Produto de         ?","","","mv_ch4","C",15,0,0,"G","","SB1","","","mv_par04","","","","               ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
//U_uAjusSx1(cPerg,"05","Produto ate        ?","","","mv_ch5","C",15,0,0,"G","","SB1","","","mv_par05","","","","ZZZZZZZZZZZZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})

Return Pergunte(cPerg,.T.)
