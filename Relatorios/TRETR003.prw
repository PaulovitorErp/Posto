#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR003
Relatório Produtos que estão parados no estoque de exposição e que tem estoque maior que o giro por período
@author Maiki Perin
@since 09/05/2014
@version 1.0
@param Nao recebe parametros
@return nulo
/*/
User Function TRETR003()

	Local oReport

	oReport:= ReportDef()
	oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Definição do Relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ReportDef()

	Local oReport

	Local oSection1, oSection2

	Local cTitle    := "Produtos que estão parados no estoque de exposição e que tem estoque maior que o giro por período"
	//Local nTamSX1   := Len(SX1->X1_GRUPO)

	oReport:= TReport():New("TRETR003",cTitle,"TRETR003",{|oReport| PrintReport(oReport)},"Este relatório apresenta uma relação de Produtos que estão parados no estoque de exposição e que tem estoque maior que o giro por período.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta grupo de perguntas (TRETR003)                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	/*dbSelectArea("SX1")
	If dbSeek(PADR("TRETR003",nTamSX1)+"01") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"02") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"03") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"04") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"05") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"06") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"07") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR003",nTamSX1)+"08") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf*/

	U_uAjusSx1("TRETR003","01","Período referencia de    ?","","","mv_ch1","D",08,0,0,"G","","","","","mv_par01","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","02","Período referencia ate   ?","","","mv_ch2","D",08,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","03","Do Armazem         		 ?","","","mv_ch3","C",02,0,0,"G","","NNR","","","mv_par03","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","04","Ate o Armazem      		 ?","","","mv_ch4","C",02,0,0,"G","","NNR","","","mv_par04","","","","ZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","05","Do Grupo	       		 ?","","","mv_ch5","C",04,0,0,"G","","SBM","","","mv_par05","","","","    ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","06","Ate o Grupo        		 ?","","","mv_ch6","C",04,0,0,"G","","SBM","","","mv_par06","","","","ZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","07","Produto de         		 ?","","","mv_ch7","C",15,0,0,"G","","SB1","","","mv_par07","","","","               ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","08","Produto ate        		 ?","","","mv_ch8","C",15,0,0,"G","","SB1","","","mv_par08","","","","ZZZZZZZZZZZZZZZ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR003","09","Dias exposição prateleira?","","","mv_ch9","N",2,0,0,"G","","","","","mv_par09","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})

	Pergunte(oReport:GetParam(),.F.)

	oSection1 := TRSection():New(oReport,"Período",{})
	oSection1:SetHeaderPage(.T.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1,"DT_DE"	 ,, "PERIODO DE",	"@D",10)
	TRCell():New(oSection1,"DT_ATE" ,, 	"PERIODO ATE", 	"@D",10)

	oSection2 := TRSection():New(oSection1,"Produtos",{"QRYPROD"})
	oSection2:SetHeaderPage(.F.)
	oSection2:SetHeaderSection(.T.)

	TRCell():New(oSection2,"B1_COD"		,"QRYPROD", "CODIGO", 			PesqPict("SB1","B1_COD"),TamSX3("B1_COD")[1]+1)
	TRCell():New(oSection2,"B1_DESC"	,"QRYPROD", "DESCRIÇÃO", 		PesqPict("SB1","B1_DESC"),TamSX3("B1_DESC")[1]+1)
	TRCell():New(oSection2,"U59_LOCAL"	,"QRYPROD", "ARMAZEM", 			PesqPict("U59","U59_LOCAL"),TamSX3("U59_LOCAL")[1]+1)
	TRCell():New(oSection2,"B2_QATU"	,"QRYPROD", "SALDO ARMAZEM",	PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)
	TRCell():New(oSection2,"GIRO"		,"QRYPROD", "GIRO",				"@E 99,999,999,999.99",14+1)
	TRCell():New(oSection2,"SLD_FILIAL"	,"QRYPROD",	"SALDO FILIAL",		PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)
	TRCell():New(oSection2,"SUGESTAO"	,"QRYPROD", "SUGESTAO",			"@E 99,999,999,999.99",14+1)

Return(oReport)

/*/{Protheus.doc} PrintReport
Processamento do Relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport)

	Local oSection1		:= oReport:Section(1)
	Local oSection2		:= oReport:Section(1):Section(1)

	Local cQry			:= ""
	Local nCont			:= 0

	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf
	
	oSection1:Init()
	oSection2:Init()

	oSection1:Cell("DT_DE"):SetValue(MV_PAR01)
	oSection1:Cell("DT_ATE"):SetValue(MV_PAR02)
	oSection1:PrintLine()

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

	cQry := "SELECT SB1.B1_COD, SB1.B1_DESC, U59.U59_LOCAL, ISNULL(SB2.B2_QATU, 0) AS B2_QATU,"
	cQry += " (SELECT SUM(SD2.D2_QUANT)"
	cQry += "			FROM "+RetSqlName("SD2")+" SD2"
	cQry += "			WHERE SD2.D_E_L_E_T_	= ' '"
	cQry += " 			AND SD2.D2_FILIAL 		= '"+xFilial("SD2")+"'"
	cQry += "			AND SD2.D2_COD			= SB1.B1_COD"
	cQry += " 			AND SD2.D2_EMISSAO		BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"') AS GIRO,"
	cQry += " (SELECT SUM(SB2X.B2_QATU)"
	cQry += " 			FROM "+RetSqlName("SB2")+" SB2X"
	cQry += " 			WHERE SB2X.D_E_L_E_T_	= ' '"
	cQry += " 			AND SB2X.B2_FILIAL 		= '"+xFilial("SB2")+"'"
	cQry += " 			AND SB2X.B2_COD			= SB1.B1_COD) AS SLD_FILIAL"
	cQry += " FROM "+RetSqlName("U59")+" U59 "
	cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON ("
	cQry += " 	SB1.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
	cQry += " 	AND SB1.B1_COD 		= U59.U59_PRODUT "
	cQry += " 	AND SB1.B1_GRUPO	BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'"
	cQry += " )"
	cQry += " LEFT JOIN "+RetSqlName("SB2")+" SB2 ON ("
	cQry += " 	SB2.D_E_L_E_T_ 	= ' ' "
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= U59.U59_PRODUT"
	cQry += " 	AND SB2.B2_LOCAL	= U59.U59_LOCAL"
	cQry += " )"
	cQry += " WHERE U59.D_E_L_E_T_ 	= ' '"
	cQry += " AND U59.U59_FILIAL 	= '"+xFilial("U59")+"'"
	cQry += " AND U59.U59_LOCAL		BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"'"
	cQry += " AND U59.U59_PRODUT	BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"'"

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

		If QRYPROD->B2_QATU > QRYPROD->GIRO
			oSection2:Cell("B1_COD"):SetValue(QRYPROD->B1_COD)
			oSection2:Cell("B1_DESC"):SetValue(QRYPROD->B1_DESC)
			oSection2:Cell("U59_LOCAL"):SetValue(QRYPROD->U59_LOCAL)
			oSection2:Cell("B2_QATU"):SetValue(QRYPROD->B2_QATU)
			oSection2:Cell("GIRO"):SetValue(QRYPROD->GIRO)
			oSection2:Cell("SLD_FILIAL"):SetValue(QRYPROD->SLD_FILIAL)
			oSection2:Cell("SUGESTAO"):SetValue(QRYPROD->GIRO * MV_PAR09)
			oSection2:PrintLine()
		Endif

		oReport:IncMeter()

		QRYPROD->(dbSkip())
	EndDo

	oSection1:Finish()
	oSection2:Finish()

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

Return
