#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR002
Relatório Produtos que possuem Estoque de Exposição e estão em falta
@author Maiki Perin
@since 09/05/2014
@version 1.0
@param Nao recebe parametros
@return nulo
/*/
User Function TRETR002()

	Local oReport

	oReport:= ReportDef()
	oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Configuração do Relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ReportDef()

	Local oReport

	Local oSection1

	Local cTitle    := "Produtos que possuem Estoque de Exposição e estão em falta"
	//Local nTamSX1   := Len(SX1->X1_GRUPO)

	oReport:= TReport():New("TRETR002",cTitle,"TRETR002",{|oReport| PrintReport(oReport)},"Este relatório apresenta uma relação de Produtos em Estoque que possuem Estoque de Exposição e estão em falta.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta grupo de perguntas (TRETR002)                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	/*dbSelectArea("SX1")
	If dbSeek(PADR("TRETR002",nTamSX1)+"01") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR002",nTamSX1)+"02") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR002",nTamSX1)+"03") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR002",nTamSX1)+"04") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR002",nTamSX1)+"05") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR002",nTamSX1)+"06") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf*/

	U_uAjusSx1("TRETR002","01","Do Armazem         ?","","","mv_ch1","C",02,0,0,"G","","NNR","","","mv_par01","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR002","02","Ate o Armazem      ?","","","mv_ch2","C",02,0,0,"G","","NNR","","","mv_par02","","","","ZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR002","03","Do Grupo	       ?","","","mv_ch3","C",04,0,0,"G","","SBM","","","mv_par03","","","","    ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR002","04","Ate o Grupo        ?","","","mv_ch4","C",04,0,0,"G","","SBM","","","mv_par04","","","","ZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR002","05","Produto de         ?","","","mv_ch5","C",15,0,0,"G","","SB1","","","mv_par05","","","","               ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR002","06","Produto ate        ?","","","mv_ch6","C",15,0,0,"G","","SB1","","","mv_par06","","","","ZZZZZZZZZZZZZZZ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})

	Pergunte(oReport:GetParam(),.F.)

	oSection1 := TRSection():New(oReport,"Produtos",{"QRYPROD"})
	oSection1:SetHeaderPage(.F.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1,"B1_COD"		,"QRYPROD", "CODIGO", 							PesqPict("SB1","B1_COD"),TamSX3("B1_COD")[1]+1)
	TRCell():New(oSection1,"B1_DESC"	,"QRYPROD", "DESCRIÇÃO", 						PesqPict("SB1","B1_DESC"),TamSX3("B1_DESC")[1]+1)
	TRCell():New(oSection1,"U59_LOCAL"	,"QRYPROD", "ARMAZEM", 							PesqPict("U59","U59_LOCAL"),TamSX3("U59_LOCAL")[1]+1)
	TRCell():New(oSection1,"B2_QATU"	,"QRYPROD", "SALDO ARMAZEM",					PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)
	TRCell():New(oSection1,"U59_LOCORI"	,"QRYPROD", "LOCAIS DE ORIGEM",					PesqPict("U59","U59_LOCORI"),TamSX3("U59_LOCORI")[1]+1)
	TRCell():New(oSection1,"SLD_LOCORI"	,"QRYPROD", "SALDO LOCAIS DE ORIGEM",			PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)
	TRCell():New(oSection1,"U59_QUANT"	,"QRYPROD", "QTD. CADASTRADA P/ EXPOSIÇÃO",		PesqPict("U59","U59_QUANT"),TamSX3("U59_QUANT")[1]+1)

Return(oReport)

/*/{Protheus.doc} PrintReport
Processamento do Relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return NIl
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport)

	Local oSection1		:= oReport:Section(1)

	Local cQry := cQry2	:= ""

	Local nCont			:= 0

	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf
	
	oSection1:Init()

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

	cQry := "SELECT SB1.B1_COD, SB1.B1_DESC, U59.U59_LOCAL, U59.U59_QUANT, ISNULL(SB2.B2_QATU, 0) AS B2_QATU, U59.U59_LOCORI"
	cQry += " FROM "+RetSqlName("U59")+" U59 "
	cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON ("
	cQry += " 	SB1.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
	cQry += " 	AND SB1.B1_COD 		= U59.U59_PRODUT "
	cQry += " 	AND SB1.B1_GRUPO	BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"'"
	cQry += " )"
	cQry += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON ("
	cQry += " 	SB2.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= U59.U59_PRODUT"
	cQry += " 	AND SB2.B2_LOCAL	= U59.U59_LOCAL"
	cQry += " )"
	cQry += " WHERE U59.D_E_L_E_T_ 	= ' '"
	cQry += " AND U59.U59_FILIAL 	= '"+xFilial("U59")+"'"
	cQry += " AND U59.U59_LOCAL		BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
	cQry += " AND U59.U59_PRODUT	BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'"
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYPROD"

	QRYPROD->(dbEval({|| nCont++}))
	QRYPROD->(dbGoTop())

	oReport:SetMeter(nCont)

	While !oReport:Cancel() .And. QRYPROD->(!EOF())

		oReport:IncMeter()

		If oReport:Cancel()
			Exit
		EndIf

		If Select("QRYSLDLOC") > 0
			QRYSLDLOC->(DbCloseArea())
		Endif

		//busco o total do produto nos armazens de origem (ou nos demais caso nao especificado)
		cQry2 := "SELECT SUM(B2_QATU) AS SLD"
		cQry2 += " FROM "+RetSqlName("SB2")+""
		cQry2 += " WHERE D_E_L_E_T_ <> '*'"
		cQry2 += " AND B2_FILIAL 	= '"+xFilial("SB2")+"'"
		cQry2 += " AND B2_COD		= '"+QRYPROD->B1_COD+"'"
		if Empty(QRYPROD->U59_LOCORI)
			cQry2 += " AND B2_LOCAL <> '"+QRYPROD->U59_LOCAL+"'"
		else
			cQry2 += " AND B2_LOCAL 	IN "+FormatIn(QRYPROD->U59_LOCORI,"/")+""
		endif

		cQry2 := ChangeQuery(cQry2)
		TcQuery cQry2 NEW Alias "QRYSLDLOC"

		If QRYSLDLOC->(!EOF())
			nSld := QRYSLDLOC->SLD
		Else
			nSld := 0
		Endif

		If QRYPROD->B2_QATU + nSld < QRYPROD->U59_QUANT
			oSection1:Cell("B1_COD"):SetValue(QRYPROD->B1_COD)
			oSection1:Cell("B1_DESC"):SetValue(QRYPROD->B1_DESC)
			oSection1:Cell("U59_LOCAL"):SetValue(QRYPROD->U59_LOCAL)
			oSection1:Cell("B2_QATU"):SetValue(QRYPROD->B2_QATU)
			oSection1:Cell("U59_LOCORI"):SetValue(QRYPROD->U59_LOCORI)
			oSection1:Cell("SLD_LOCORI"):SetValue(nSld)
			oSection1:Cell("U59_QUANT"):SetValue(QRYPROD->U59_QUANT)
			oSection1:PrintLine()
		Endif

		oReport:IncMeter()

		QRYPROD->(dbSkip())
	EndDo

	oSection1:Finish()

	If Select("QRYSLDLOC") > 0
		QRYSLDLOC->(DbCloseArea())
	Endif

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

Return
