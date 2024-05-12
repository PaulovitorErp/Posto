#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR001
Relatório Itens em Estoque que não possuem Estoque de Exposição
@author Maiki Perin
@since 08/05/2014
@version 1.0
@param Nao recebe parametros
@return nulo
/*/
User Function TRETR001()

	Local oReport
	
	oReport:= ReportDef()
	oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Configuração do relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ReportDef()

	Local oReport

	Local oSection1

	Local cTitle    := "Itens em Estoque que não possuem Cadastro de Exposição"
	//Local nTamSX1   := Len(SX1->X1_GRUPO)

	oReport:= TReport():New("TRETR001",cTitle,"TRETR001",{|oReport| PrintReport(oReport)},"Este relatório apresenta uma relação de Produtos em Estoque que não possuem Cadastro de Exposição.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta grupo de perguntas (TRETR001)                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	/*dbSelectArea("SX1")
	If dbSeek(PADR("TRETR001",nTamSX1)+"01") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR001",nTamSX1)+"02") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR001",nTamSX1)+"03") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR001",nTamSX1)+"04") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR001",nTamSX1)+"05") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf
	If dbSeek(PADR("TRETR001",nTamSX1)+"06") .And. X1_GSC == "C"
		Reclock("SX1",.f.)
		dbDelete()
		MsUnlock()
	EndIf*/

	U_uAjusSx1("TRETR001","01","Do Armazem         ?","","","mv_ch1","C",02,0,0,"G","","NNR","","","mv_par01","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR001","02","Ate o Armazem      ?","","","mv_ch2","C",02,0,0,"G","","NNR","","","mv_par02","","","","ZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR001","03","Do Grupo	       ?","","","mv_ch3","C",04,0,0,"G","","SBM","","","mv_par03","","","","    ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR001","04","Ate o Grupo        ?","","","mv_ch4","C",04,0,0,"G","","SBM","","","mv_par04","","","","ZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR001","05","Produto de         ?","","","mv_ch5","C",15,0,0,"G","","SB1","","","mv_par05","","","","               ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR001","06","Produto ate        ?","","","mv_ch6","C",15,0,0,"G","","SB1","","","mv_par06","","","","ZZZZZZZZZZZZZZZ","","","","","","","","","","","","",  {"",""},{"",""},{"",""})

	Pergunte(oReport:GetParam(),.F.)

	oSection1 := TRSection():New(oReport,"Produtos",{"QRYPROD"})
	oSection1:SetHeaderPage(.F.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1,"B2_LOCAL"	,"QRYPROD",	"ARMAZEM", 			PesqPict("SB2","B2_LOCAL"),TamSX3("B2_LOCAL")[1]+1)
	TRCell():New(oSection1,"NNR_DESCRI"	,"QRYPROD",	"DESCRIÇÃO", 		PesqPict("NNR","NNR_DESCRI"),TamSX3("NNR_DESCRI")[1]+1)
	TRCell():New(oSection1,"B1_COD"		,"QRYPROD", "PRODUTO", 			PesqPict("SB1","B1_COD"),TamSX3("B1_COD")[1]+1)
	TRCell():New(oSection1,"B1_DESC"	,"QRYPROD", "DESCRIÇÃO", 		PesqPict("SB1","B1_DESC"),TamSX3("B1_DESC")[1]+1)
	TRCell():New(oSection1,"B2_QATU"	,"QRYPROD", "SALDO ARMAZEM", 	PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)
	TRCell():New(oSection1,"SLD_FILIAL"	,"QRYPROD",	"SALDO FILIAL",		PesqPict("SB2","B2_QATU"),TamSX3("B2_QATU")[1]+1)

Return(oReport)

/*/{Protheus.doc} PrintReport
Processamento do relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport)

	Local oSection1	:= oReport:Section(1)

	Local cQry 		:= ""

	Local nCont		:= 0
	
	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf

	oSection1:Init()

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

	cQry := "SELECT SB2.B2_LOCAL, SB1.B1_LOCPAD, SB1.B1_COD, SB1.B1_DESC, SB2.B2_QATU,"
	cQry += " (	SELECT SUM(SB2.B2_QATU)"
	cQry += " 	FROM "+RetSqlName("SB2")+" SB2"
	cQry += " 	WHERE SB2.D_E_L_E_T_ = ' '"
	cQry += " 	AND SB2.B2_FILIAL 	= '"+xFilial("SB2")+"'"
	cQry += " 	AND SB2.B2_COD		= SB1.B1_COD) AS SLD_FILIAL"
	cQry += " FROM "+RetSqlName("SB1")+" SB1 LEFT JOIN "+RetSqlName("SB2")+" SB2 ON (SB1.B1_COD = SB2.B2_COD)"
	cQry += " WHERE (SB2.D_E_L_E_T_ = ' ' OR SB2.D_E_L_E_T_ IS NULL)"
	cQry += " AND SB1.D_E_L_E_T_ 	= ' '"
	cQry += " AND (SB2.B2_FILIAL 	= '"+xFilial("SB2")+"' OR SB2.B2_FILIAL IS NULL)"
	cQry += " AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"
	cQry += " AND SB1.B1_MSBLQL		<> '1'" //Desbloqueado
	cQry += " AND SB1.B1_XTIPO		= 'V'" //Venda c/ exposição
	cQry += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("U59")+" WHERE D_E_L_E_T_ = ' ' AND U59_PRODUT = SB1.B1_COD)"
	cQry += " AND (SB2.B2_LOCAL		BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' OR SB2.B2_LOCAL IS NULL)"
	cQry += " AND SB1.B1_GRUPO		BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"'"
	cQry += " AND SB1.B1_COD		BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'"
	cQry += " ORDER BY 1,2"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR001.txt",cQry)
	TcQuery cQry NEW Alias "QRYPROD"

	QRYPROD->(dbEval({|| nCont++}))
	QRYPROD->(dbGoTop())

	oReport:SetMeter(nCont)

	While !oReport:Cancel() .And. QRYPROD->(!EOF())

		oReport:IncMeter()

		If oReport:Cancel()
			Exit
		EndIf

		if Empty(QRYPROD->B2_LOCAL)
			oSection1:Cell("B2_LOCAL"):SetValue(QRYPROD->B1_LOCPAD)
			oSection1:Cell("NNR_DESCRI"):SetValue(Posicione("NNR",1,xFilial("NNR")+QRYPROD->B1_LOCPAD,"NNR_DESCRI"))
		else
			oSection1:Cell("B2_LOCAL"):SetValue(QRYPROD->B2_LOCAL)
			oSection1:Cell("NNR_DESCRI"):SetValue(Posicione("NNR",1,xFilial("NNR")+QRYPROD->B2_LOCAL,"NNR_DESCRI"))
		endif
		oSection1:Cell("B1_COD"):SetValue(QRYPROD->B1_COD)
		oSection1:Cell("B1_DESC"):SetValue(QRYPROD->B1_DESC)
		oSection1:Cell("B2_QATU"):SetValue(QRYPROD->B2_QATU)
		oSection1:Cell("SLD_FILIAL"):SetValue(QRYPROD->SLD_FILIAL)
		oSection1:PrintLine()

		oReport:IncMeter()

		QRYPROD->(dbSkip())
	EndDo

	oSection1:Finish()

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

Return
