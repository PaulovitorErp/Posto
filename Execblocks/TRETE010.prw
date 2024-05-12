#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE010
Detalhamento LMC
@author Maiki Perin
@since 20/02/2015
@version 1.0
@param Data e Produto
@return nulo
/*/

#DEFINE __AHEADER_TITLE__		01	//01 -> Titulo
#DEFINE __AHEADER_PICTURE__		03	//03 -> Picture
#DEFINE __AHEADER_TYPE__		08	//08 -> Tipo

/**********************************/
User Function TRETE010(dData,cProd)
/**********************************/

Local cTitulo 		:= "Detalhamento Página LMC"
Local oButton1, oButton2

Private dDataLMC 	:= dData
Private cProdLMC	:= cProd

Private oFolder
Private oGet1
Private oGet2
Private oGet3

Private oModel	 	:= FWModelActive()
Private oModelMIE  	:= oModel:GetModel("MIEMASTER")

Static oDlg

aObjects := {}
aSizeAut := MsAdvSize()

//Largura, Altura, Modifica largura, Modifica altura
aAdd(aObjects, {100, 090, .T., .T.}) //Folder
aAdd(aObjects, {100, 005, .T., .F.}) //Linha horizontal
aAdd(aObjects, {100, 005, .F., .F.}) //Botao

aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 3, 3 }
aPosObj := MsObjSize( aInfo, aObjects, .T. )

DEFINE MSDIALOG oDlg TITLE cTitulo From aSizeAut[7],0 TO aSizeAut[6],aSizeAut[5] OF oMainWnd PIXEL

//Folder
@ aPosObj[1,1] - 30, aPosObj[1,2] FOLDER oFolder SIZE aPosObj[1,4], aPosObj[1,3] OF oDlg ITEMS "Entradas","Vendas","Est. Fechamento X Medições" COLORS 0, 16777215 PIXEL
oFolder:nOption := 1

//Pasta Recebimentos
//Browse
oGet1 := GetDados1()
SelGet1()

//Pasta Vendas
//Browse
oGet2 := GetDados2()
SelGet2()

//Pasta Medições X Est. Fechamento
//Browse
oGet3 := GetDados3()
SelGet3()

//Linha horizontal
@ aPosObj[2,1] - 10, aPosObj[2,2] SAY oSay3 PROMPT Repl("_",aPosObj[1,4]) SIZE aPosObj[1,4], 007 OF oDlg COLORS CLR_GRAY, 16777215 PIXEL

//Botão Exportar Excel
@ aPosObj[3,1] - 5, aPosObj[1,4] - 130 BUTTON oButton2 PROMPT "Exp. Excel" SIZE 060, 010 OF oDlg;
 ACTION Processa({|| ExpExcel(IIF(oFolder:nOption == 1,oGet1:aHeader,IIF(oFolder:nOption == 2,oGet2:aHeader,oGet3:aHeader)),;
 IIF(oFolder:nOption == 1,oGet1:aCols,IIF(oFolder:nOption == 2,oGet2:aCols,oGet3:aCols)),;
 IIF(oFolder:nOption == 1,"Recebimentos" + " - " + AllTrim(oModelMIE:GetValue("MIE_CODPRO")) + " - " + DToC(oModelMIE:GetValue("MIE_DATA")),;
 IIF(oFolder:nOption == 2,"Vendas" + " - " + AllTrim(oModelMIE:GetValue("MIE_CODPRO")) + " - " + DToC(oModelMIE:GetValue("MIE_DATA")),;
 "Est. Fechamento X Medições" + " - " + AllTrim(oModelMIE:GetValue("MIE_CODPRO")) + " - " + DToC(oModelMIE:GetValue("MIE_DATA"))))),"Aguarde"}) PIXEL
//Botão Fechar
@ aPosObj[3,1] - 5, aPosObj[1,4] - 60 BUTTON oButton1 PROMPT "Fechar" SIZE 060, 010 OF oDlg ACTION oDlg:End() PIXEL

ACTIVATE MSDIALOG oDlg CENTERED

Return

/**************************/
Static Function GetDados1()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"D1_DOC","D1_SERIE","D1_FORNECE","D1_LOJA","A2_NOME","D1_DTDIGIT","D1_LOCAL","D1_QUANT"}
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

Return MsNewGetDados():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,3] - 26,aPosObj[1,4] - 5,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oFolder:aDialogs[1],aHeaderEx,aColsEx)

/************************/
Static Function SelGet1()
/************************/

Local cQry 		:= ""
Local nTotEnt	:= 0

//Limpa o aCols
aSize(oGet1:aCols,0)

If Select("QRYREC") > 0
	QRYREC->(DbCloseArea())
Endif

cQry := "SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE, SD1.D1_LOJA, SA2.A2_NOME, SD1.D1_DTDIGIT, SD1.D1_LOCAL, SD1.D1_QUANT, SD1.D1_TIPO"

cQry += " FROM "+RetSqlName("SD1")+" SD1 LEFT JOIN "+RetSqlName("SA2")+" SA2 ON SD1.D1_FORNECE		= SA2.A2_COD"
cQry += " 																		AND SD1.D1_LOJA		= SA2.A2_LOJA"
cQry += " 																		AND SA2.D_E_L_E_T_ 	<> '*'"
cQry += " 																		AND SA2.A2_FILIAL	= '"+xFilial("SA2")+"'"

cQry += "								INNER JOIN "+RetSqlName("SF1")+" SF1 ON SD1.D1_DOC			= SF1.F1_DOC"
cQry += " 																		AND SD1.D1_SERIE	= SF1.F1_SERIE"
cQry += " 																		AND SD1.D1_FORNECE	= SF1.F1_FORNECE"
cQry += " 																		AND SD1.D1_LOJA		= SF1.F1_LOJA"
cQry += " 																		AND SF1.D_E_L_E_T_ 	<> '*'"
cQry += " 																		AND SF1.F1_FILIAL	= '"+xFilial("SF1")+"'"
cQry += " 																		AND SF1.F1_XLMC		= 'S'" //Considera LMC

cQry += "								INNER JOIN "+RetSqlName("SF4")+" SF4 ON SD1.D1_TES			= SF4.F4_CODIGO"
cQry += " 																		AND SF4.D_E_L_E_T_ 	<> '*'"
cQry += " 																		AND SF4.F4_FILIAL	= '"+xFilial("SF4")+"'"
cQry += " 																		AND SF4.F4_ESTOQUE	= 'S'" //Movimenta estoque

cQry += " WHERE SD1.D_E_L_E_T_ 	<> '*'"
cQry += " AND SD1.D1_FILIAL		= '"+xFilial("SD1")+"'"
cQry += " AND SD1.D1_COD		= '"+cProdLMC+"'"
cQry += " AND SD1.D1_DTDIGIT	= '"+DToS(dDataLMC)+"'"
cQry += " AND SD1.D1_TIPO		IN ('N','D')" //Diferente de Complementos e Beneficiamento
cQry += " ORDER BY 7,5,1,2"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYREC.txt",cQry)
TcQuery cQry NEW Alias "QRYREC"

If QRYREC->(!EOF())

	While QRYREC->(!EOF())

		aAdd(oGet1:aCols,{	QRYREC->D1_DOC,;
							QRYREC->D1_SERIE,;
							QRYREC->D1_FORNECE,;
							QRYREC->D1_LOJA,;
							IIF(QRYREC->D1_TIPO <> "D",QRYREC->A2_NOME,Posicione("SA1",1,xFilial("SA1")+QRYREC->D1_FORNECE+QRYREC->D1_LOJA,"A1_NOME")),;
							DToC(SToD(QRYREC->D1_DTDIGIT)),;
							QRYREC->D1_LOCAL,;
							QRYREC->D1_QUANT,;
							.F.})

		nTotEnt += QRYREC->D1_QUANT

		QRYREC->(dbSkip())
	EndDo
Else
	aAdd(oGet1:aCols,{Space(TamSX3("D1_DOC")[1]),Space(TamSX3("D1_SERIE")[1]),Space(TamSX3("D1_FORNECE")[1]),Space(TamSX3("D1_LOJA")[1]),;
		Space(TamSX3("A2_NOME")[1]),Space(TamSX3("D1_EMISSAO")[1]),Space(TamSX3("D1_LOCAL")[1]),0,.F.})
Endif

aAdd(oGet1:aCols,{"TOTAL",Space(TamSX3("D1_SERIE")[1]),Space(TamSX3("D1_FORNECE")[1]),Space(TamSX3("D1_LOJA")[1]),;
	Space(TamSX3("A2_NOME")[1]),Space(TamSX3("D1_EMISSAO")[1]),Space(TamSX3("D1_LOCAL")[1]),nTotEnt,.F.})

If Select("QRYREC") > 0
	QRYREC->(DbCloseArea())
Endif

oGet1:Refresh()

Return

/**************************/
Static Function GetDados2()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"MIC_CODTAN", "MIC_CODBIC" ,"MIC_CODBOM","MIC_NLOGIC","FECH","ABERT","AFERIC","VENDAS"}
Local aAlterFields 	:= {}

//Define field properties
For nX := 1 to Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	ElseIf aFields[nX] == "FECH" //+ Fechamento
		Aadd(aHeaderEx, {"+ Fechamento","FECH","@E 99,999,999.999",12,3,"","€€€€€€€€€€€€€€","N","","","",""})
	ElseIf aFields[nX] == "ABERT" //- Abertura
		Aadd(aHeaderEx, {"- Abertura","ABERT","@E 99,999,999.999",12,3,"","€€€€€€€€€€€€€€","N","","","",""})
	ElseIf aFields[nX] == "AFERIC" //- Aferições
		Aadd(aHeaderEx, {"- Aferições","AFERIC","@E 99,999,999.999",12,3,"","€€€€€€€€€€€€€€","N","","","",""})
	ElseIf aFields[nX] == "VENDAS" //Vendas
		Aadd(aHeaderEx, {"= Vendas no Bico","VENDAS","@E 99,999,999.999",12,3,"","€€€€€€€€€€€€€€","N","","","",""})
	Endif
Next

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Else
		Do Case
			Case aFields[nX] == "FECH"
				Aadd(aFieldFill, 0)
			Case aFields[nX] == "ABERT"
				Aadd(aFieldFill, 0)
			Case aFields[nX] == "AFERIC"
				Aadd(aFieldFill, 0)
			Case aFields[nX] == "VENDAS"
				Aadd(aFieldFill, 0)
		EndCase
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,3] - 26,aPosObj[1,4] - 5,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oFolder:aDialogs[2],aHeaderEx,aColsEx)

/************************/
Static Function SelGet2()
/************************/

Local nX
Local oLMC := TLmcLib():New(cProdLMC, dDataLMC)
Local aDados
Local nTotAferic := 0
Local nTotVendas := 0

//Limpa o aCols
aSize(oGet2:aCols,0)

oLMC:SetTRetVen(2) //1=Vlr Total Vendas; 2=Array Dados; 3=Qtd Registros
oLMC:SetDRetVen({"_TANQUE", "_BICO", "_BOMBA", "_NLOGIC", "_FECH", "_ABERT", "_AFERIC", "_VDBICO"})

//retorna dados de vendas
aDados := oLMC:RetVen()

//coloco dados no acols 
oGet2:aCols := aDados

//somando totais
for nX := 1 to len(aDados)
	nTotAferic += aDados[nX][7]
	nTotVendas += aDados[nX][8]
next nX

aAdd(oGet2:aCols,{"TOTAL","","","",0,0,nTotAferic,nTotVendas,.F.})

oGet2:Refresh()

Return

/**************************/
Static Function GetDados3()
/**************************/

Local nX
Local aHeaderEx 	:= {}
Local aColsEx 		:= {}
Local aFieldFill 	:= {}

Local aFields 		:= {"ESTLMC","ESTFECH","MEDICAO","DIFERENCA"}
Local aAlterFields 	:= {}

//Define field properties
For nX := 1 to Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	ElseIf aFields[nX] == "ESTLMC" //Est. LMC
		Aadd(aHeaderEx, {"Est. LMC","ESTLMC","@!",2,,"","€€€€€€€€€€€€€€","C","","","",""})
	ElseIf aFields[nX] == "ESTFECH" //Est. Fechamento
		Aadd(aHeaderEx, {"+ Est. Fechamento","ESTFECH","@E 999,999.999",10,3,"","€€€€€€€€€€€€€€","N","","","",""})
	ElseIf aFields[nX] == "MEDICAO" //Medição
		Aadd(aHeaderEx, {"- Medição","MEDICAO","@E 999,999",6,0,"","€€€€€€€€€€€€€€","N","","","",""})
	ElseIf aFields[nX] == "DIFERENCA" //Diferença
		Aadd(aHeaderEx, {"= Diferença","DIFERENCA","@E 999,999.999",10,3,"","€€€€€€€€€€€€€€","N","","","",""})
	Endif
Next

For nX := 1 To Len(aFields)
	If !empty(GetSx3Cache(aFields[nX],"X3_CAMPO"))
		aAdd(aFieldFill, CriaVar(aFields[nX]))
	Endif
Next

aAdd(aFieldFill, .F.)
aAdd(aColsEx, aFieldFill)

Return MsNewGetDados():New(aPosObj[1,1] - 30,aPosObj[1,2],aPosObj[1,3] - 26,aPosObj[1,4] - 5,,"AllwaysTrue","AllwaysTrue",,aAlterFields,,999,;
		"AllwaysTrue","","AllwaysTrue",oFolder:aDialogs[3],aHeaderEx,aColsEx)

/************************/
Static Function SelGet3()
/************************/

Local cQry 		:= ""
Local cQry2		:= ""
Local nI
Local nEstMed	:= 0

Local nTotEst	:= 0
Local nTotMed	:= 0
Local nTotDif	:= 0
Local lHasDados := Type("__aDados") == "U"
Local nQTQLMC := SuperGetMv("MV_XQTQLMC",,20) //Quantidade de tanques para apuração LMC

//Limpa o aCols
aSize(oGet3:aCols,0)

For nI := 1 To nQTQLMC

	nEstMed := 0

	If Select("QRYTQ") > 0
		QRYTQ->(dbCloseArea())
	Endif

	cQry := "SELECT MHZ_CODTAN"
	cQry += " FROM "+RetSqlName("MHZ")+""
	cQry += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry += " AND MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
	cQry += " AND MHZ_CODPRO	= '"+cProdLMC+"'"
	cQry += " AND MHZ_CODTAN	= '"+StrZero(nI,2)+"'"
	cQry += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DToS(oModelMIE:GetValue("MIE_DATA"))+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DToS(oModelMIE:GetValue("MIE_DATA"))+"'))"
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYTQ"

	If QRYTQ->(!EOF())

		If Select("QRYMED") > 0
			QRYMED->(DbCloseArea())
		Endif

		cQry2 := "SELECT TQK_TANQUE, SUM(TQK_QTDEST) AS ESTMED"
		cQry2 += " FROM "+RetSqlName("TQK")+""
		cQry2 += " WHERE D_E_L_E_T_ = ' '"
		cQry2 += " AND TQK_FILIAL	= '"+xFilial("TQK")+"'"
		cQry2 += " AND TQK_DTMEDI	= '"+DToS(dDataLMC)+"'"
		cQry2 += " AND TQK_TANQUE	= '"+QRYTQ->MHZ_CODTAN+"'"
		cQry2 += " AND TQK_PRODUT	= '"+cProdLMC+"'"
		cQry2 += " AND TQK_TANQUE + TQK_TQFISC + TQK_HRMEDI IN ("
		cQry2 += " 		SELECT TQK_TANQUE + TQK_TQFISC + MAX(TQK_HRMEDI)"
		cQry2 += " 		FROM "+RetSqlName("TQK")+""
		cQry2 += " 		WHERE D_E_L_E_T_	= ' '"
		cQry2 += " 		AND TQK_FILIAL		= '"+xFilial("TQK")+"'"
		cQry2 += " 		AND TQK_DTMEDI		= '"+DToS(dDataLMC)+"'"
		cQry2 += " 		AND TQK_TANQUE		= '"+QRYTQ->MHZ_CODTAN+"'"
		cQry2 += " 		AND TQK_PRODUT		= '"+cProdLMC+"'"
		cQry2 += " 		GROUP BY TQK_TANQUE, TQK_TQFISC "
		cQry2 += " )"
		cQry2 += " GROUP BY TQK_TANQUE"

		cQry2 := ChangeQuery(cQry2)
		TcQuery cQry2 NEW Alias "QRYMED"

		While QRYMED->(!EOF())

			nEstMed += QRYMED->ESTMED

			QRYMED->(DbSkip())
		EndDo

		If lHasDados //Type("__aDados") == "U"
			if MIE->(FieldPos( 'MIE_VTAQ'+StrZero(nI,2) ))>0

				AAdd(oGet3:aCols,{	StrZero(nI,2),;
				&("MIE->MIE_VTAQ" + StrZero(nI,2)),;
									nEstMed,;
									&("MIE->MIE_VTAQ" + StrZero(nI,2)) - nEstMed,;
									.F.})
				nTotEst += &("MIE->MIE_VTAQ" + StrZero(nI,2))
				nTotMed += nEstMed
				nTotDif += &("MIE->MIE_VTAQ" + StrZero(nI,2)) - nEstMed

			endif
		Else

			AAdd(oGet3:aCols,{	StrZero(nI,2),;
								__aDados[Len(__aDados)][19][nI],;
								nEstMed,;
								__aDados[Len(__aDados)][19][nI] - nEstMed,;
								.F.})
			nTotEst += __aDados[Len(__aDados)][19][nI]
			nTotMed += nEstMed
			nTotDif += __aDados[Len(__aDados)][19][nI] - nEstMed
		Endif
	Endif
Next

AAdd(oGet3:aCols,{	"TOTAL",;
					nTotEst,;
					nTotMed,;
					nTotDif,;
					.F.})

If Select("QRYMED") > 0
	QRYMED->(DbCloseArea())
Endif

If Select("QRYTQ") > 0
	QRYTQ->(dbCloseArea())
Endif

oGet3:Refresh()

Return

/***************************************************************************/
Static Function ExpExcel(aHeader,aCols,cWorkSheet,cTable,lTotalize,lPicture)
/***************************************************************************/

Local oFWMSExcel := FWMSExcel():New()

Local oMsExcel

Local aCells

Local cType
Local cColumn

Local cFile
Local cFileTMP

Local cPicture

Local lTotal

Local nRow
Local nRows
Local nField
Local nFields

Local nAlign
Local nFormat

Local uCell

DEFAULT cWorkSheet := "GETDADOS"
DEFAULT cTable     := cWorkSheet
DEFAULT lTotalize  := .F.
DEFAULT lPicture   := .F.

BEGIN SEQUENCE

	oFWMSExcel:AddworkSheet(cWorkSheet)
	oFWMSExcel:AddTable(cWorkSheet,cTable)

	nFields := Len(aHeader)

	For nField := 1 To nFields
		cType   := aHeader[nField][__AHEADER_TYPE__]
		nAlign  := IF(cType=="C",1,IF(cType=="N",3,2))
		nFormat := IF(cType=="D",4,IF(cType=="N",2,1))
		cColumn := aHeader[nField][__AHEADER_TITLE__]
		lTotal  := (lTotalize .and. cType == "N")
		oFWMSExcel:AddColumn(@cWorkSheet,@cTable,@cColumn,@nAlign,@nFormat,@lTotal)
	Next nField

	aCells := Array(nFields)

	nRows := Len(aCols)
	For nRow := 1 To nRows
		For nField := 1 To nFields
			uCell := aCols[nRow][nField]
			IF (lPicture)
				cPicture  := aHeader[nField][__AHEADER_PICTURE__]
				IF .NOT.(Empty(cPicture))
					uCell := Transform(uCell,cPicture)
				EndIF
			EndIF
			aCells[nField] := uCell
		Next nField
		oFWMSExcel:AddRow(@cWorkSheet,@cTable,aClone(aCells))
	Next nRow

	oFWMSExcel:Activate()

	cFile := (CriaTrab(NIL, .F.) + ".xml")

	While File(cFile)
		cFile := (CriaTrab(NIL, .F.) + ".xml")
	End While

	oFWMSExcel:GetXMLFile(cFile)
	oFWMSExcel:DeActivate()

	IF .NOT.(File(cFile))
		cFile := ""
		BREAK
	EndIF

	cFileTMP := (GetTempPath() + cFile)
	IF .NOT.(__CopyFile(cFile , cFileTMP))
		fErase(cFile)
		cFile := ""
		BREAK
	EndIF

	fErase(cFile)

	cFile := cFileTMP

	IF .NOT.(File(cFile))
		cFile := ""
		BREAK
	EndIF

	IF .NOT.(ApOleClient("MsExcel"))
		BREAK
	EndIF

	oMsExcel := MsExcel():New()
	oMsExcel:WorkBooks:Open( cFile )
	oMsExcel:SetVisible(.T.)
	oMsExcel := oMsExcel:Destroy()

END SEQUENCE

oFWMSExcel := FreeObj(oFWMSExcel)

Return
