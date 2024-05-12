#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR011
Relatório Itens em Estoque que não possuem Estoque de Exposição
@author Maiki Perin
@since 08/05/2014
@version 1.0
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETR011()
/***********************/

Local oReport

oReport:= ReportDef()
oReport:PrintDialog()

Return

/**************************/
Static Function ReportDef()
/**************************/

Local oReport

Local oSection1, oSection2, oSection3

Local cTitle    := "Preços Negociados X Grupo Cliente/Cliente"
//Local nTamSX1   := Len(SX1->X1_GRUPO)

oReport:= TReport():New("TRETR011",cTitle,"TRETR011",{|oReport| PrintReport(oReport,oSection1, oSection2, oSection3)},"Este relatório apresenta uma relação Preços Negociados X Grupo Cliente/Cliente.")
oReport:SetPortrait()   
oReport:HideParamPage()
oReport:SetUseGC(.F.) //Desabilita o botão <Gestao Corporativa> do relatório

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ajusta grupo de perguntas (RESTR001)                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
/*dbSelectArea("SX1")
If dbSeek(PADR("TRETR011",nTamSX1)+"01") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf	
If dbSeek(PADR("TRETR011",nTamSX1)+"02") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf
If dbSeek(PADR("TRETR011",nTamSX1)+"03") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf
If dbSeek(PADR("TRETR011",nTamSX1)+"04") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf                                 
If dbSeek(PADR("TRETR011",nTamSX1)+"05") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf                                 
If dbSeek(PADR("TRETR011",nTamSX1)+"06") .And. X1_GSC == "C"
	Reclock("SX1",.f.)
	dbDelete()
	MsUnlock()
EndIf*/                                 

U_uAjusSx1("TRETR011","01","Grp. Cliente De		?","","","mv_ch1","C",06,0,0,"G","","ACY","","","mv_par01","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR011","02","Grp. Cliente Ate		?","","","mv_ch2","C",06,0,0,"G","","ACY","","","mv_par02","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR011","03","Cliente De			?","","","mv_ch3","C",06,0,0,"G","","SA1","","","mv_par03","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR011","04","Loja De				?","","","mv_ch4","C",02,0,0,"G","","","","","mv_par04","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR011","05","Cliente Ate			?","","","mv_ch5","C",06,0,0,"G","","SA1","","","mv_par05","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
U_uAjusSx1("TRETR011","06","Loja Ate				?","","","mv_ch6","C",02,0,0,"G","","","","","mv_par06","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})

Pergunte(oReport:GetParam(),.F.)

oSection1 := TRSection():New(oReport,"Cliente",{"QRYCLI"})
oSection1:SetHeaderPage(.F.)
oSection1:SetHeaderSection(.T.)
oSection1:SetPageBreak(.T.)

TRCell():New(oSection1,"UI0_GRPCLI"	,"QRYCLI",	"GRP. CLIENTE",		PesqPict("UI0","UI0_GRPCLI"),TamSX3("UI0_GRPCLI")[1]+1)
TRCell():New(oSection1,"UI0_DESCGR"	,"QRYCLI",	"DESCRICAO",		PesqPict("UI0","UI0_DESCGR"),TamSX3("UI0_DESCGR")[1]+1)
TRCell():New(oSection1,"UI0_CLIENT"	,"QRYCLI", 	"CLIENTE", 			PesqPict("UI0","UI0_CLIENT"),TamSX3("UI0_CLIENT")[1]+1)
TRCell():New(oSection1,"UI0_LOJA"	,"QRYCLI", 	"LOJA",		 		PesqPict("UI0","UI0_LOJA"),TamSX3("UI0_LOJA")[1]+1)
TRCell():New(oSection1,"UI0_NOME"	,"QRYCLI", 	"NOME",		 		PesqPict("UI0","UI0_NOME"),TamSX3("UI0_NOME")[1]+1)

oSection2 := TRSection():New(oReport,"Prestador",{"QRYPRE"})
oSection2:SetHeaderPage(.F.)
oSection2:SetHeaderSection(.T.)
oSection2:SetTotalInLine(.F.)

TRCell():New(oSection2,"UI1_FORNEC"	,"QRYPRE", 	"FORNECEDOR",		PesqPict("UI1","UI1_FORNEC"),TamSX3("UI1_FORNEC")[1]+1)
TRCell():New(oSection2,"UI1_LOJAFO"	,"QRYPRE", 	"LOJA",		 		PesqPict("UI1","UI1_LOJAFO"),TamSX3("UI1_LOJAFO")[1]+1)
TRCell():New(oSection2,"UI1_NOME"	,"QRYPRE", 	"NOME",		 		PesqPict("UI1","UI1_NOME"),TamSX3("UI1_NOME")[1]+1)

oSection3 := TRSection():New(oReport,"Precos",{"QRYPRC"})
oSection3:SetHeaderPage(.F.)
oSection3:SetHeaderSection(.T.)
oSection3:SetTotalInLine(.F.)

TRCell():New(oSection3,"UIB_PRODUT"	,"QRYPRC", 	"PRODUTO",			PesqPict("UIB","UIB_PRODUT"),TamSX3("UIB_PRODUT")[1]+1)
TRCell():New(oSection3,"B1_DESC"	,"QRYPRC", 	"DESCRICAO", 		PesqPict("SB1","B1_DESC"),TamSX3("B1_DESC")[1]+1)
TRCell():New(oSection3,"UH9_PRCUNI"	,"QRYPRC", 	"PRECO BASE", 		PesqPict("UH9","UH9_PRCUNI"),TamSX3("UH9_PRCUNI")[1]+1)
TRCell():New(oSection3,"UIB_DESACR"	,"QRYPRC", 	"DECRES/ACRESC",	PesqPict("UIB","UIB_DESACR"),TamSX3("UIB_DESACR")[1]+1)
TRCell():New(oSection3,"PRCVEN"		,"QRYPRC", 	"PRECO NEGOCIADO",	PesqPict("UH9","UH9_PRCUNI"),TamSX3("UH9_PRCUNI")[1]+1)

Return(oReport)                                                               

/*****************************************************************/
Static Function PrintReport(oReport,oSection1,oSection2,oSection3)
/*****************************************************************/

Local cQry 		:= ""

Local nCont		:= 0
Local nAux		:= 0

If Select("QRYCLI") > 0
	QRYCLI->(DbCloseArea())
Endif

cQry := "SELECT UI0_GRPCLI, UI0_DESCGR, UI0_CLIENT, UI0_LOJA, UI0_NOME"
cQry += " FROM "+RetSqlName("UI0")+""
cQry += " WHERE D_E_L_E_T_ 	<> '*'"
cQry += " AND UI0_FILIAL 	= '"+xFilial("UI0")+"'"
cQry += " AND UI0_GRPCLI	BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
cQry += " AND UI0_CLIENT	BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR05+"'"
cQry += " AND UI0_LOJA		BETWEEN '"+MV_PAR04+"' AND '"+MV_PAR06+"'"
cQry += " ORDER BY UI0_DESCGR, UI0_NOME"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETR011.txt",cQry)
TcQuery cQry NEW Alias "QRYCLI"

QRYCLI->(DbEval({|| nCont++}))
QRYCLI->(DbGoTop())

oReport:SetMeter(nCont)

While !oReport:Cancel() .And. QRYCLI->(!EOF())
	
	oReport:IncMeter()

	If oReport:Cancel()
		Exit
	EndIf    

	oSection1:Init()
	
	oSection1:Cell("UI0_GRPCLI"):SetValue(QRYCLI->UI0_GRPCLI)
	oSection1:Cell("UI0_DESCGR"):SetValue(QRYCLI->UI0_DESCGR)
	oSection1:Cell("UI0_CLIENT"):SetValue(QRYCLI->UI0_CLIENT)
	oSection1:Cell("UI0_LOJA"):SetValue(QRYCLI->UI0_LOJA)
	oSection1:Cell("UI0_NOME"):SetValue(QRYCLI->UI0_NOME)
	oSection1:PrintLine()

	If Select("QRYPRE") > 0
		QRYPRE->(DbCloseArea())
	Endif
	
	cQry := "SELECT UI1_FORNEC, UI1_LOJAFO, UI1_NOME"
	cQry += " FROM "+RetSqlName("UI1")+""
	cQry += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry += " AND UI1_FILIAL 	= '"+xFilial("UI1")+"'"
	cQry += " AND UI1_GRPCLI	= '"+QRYCLI->UI0_GRPCLI+"'"
	cQry += " AND UI1_CLIENT	= '"+QRYCLI->UI0_CLIENT+"'"
	cQry += " AND UI1_LOJA		= '"+QRYCLI->UI0_LOJA+"'"
	cQry += " ORDER BY UI1_NOME"
	
	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETR011.txt",cQry)
	TcQuery cQry NEW Alias "QRYPRE"

	While !oReport:Cancel() .And. QRYPRE->(!EOF())
		
		If oReport:Cancel()
			Exit
		EndIf

		oSection2:Init()

		oSection2:Cell("UI1_FORNEC"):SetValue(QRYPRE->UI1_FORNEC)
		oSection2:Cell("UI1_LOJAFO"):SetValue(QRYPRE->UI1_LOJAFO)
		oSection2:Cell("UI1_NOME"):SetValue(QRYPRE->UI1_NOME)
		oSection2:PrintLine()

		oSection3:Init()

		If Select("QRYPRC") > 0
			QRYPRC->(DbCloseArea())
		Endif
		
		cQry := "SELECT UIB.UIB_PRODUT, SB1.B1_DESC, UH9.UH9_PRCUNI, UIB.UIB_DESACR"
		cQry += " FROM "+RetSqlName("UIB")+" UIB INNER JOIN "+RetSqlName("SB1")+" SB1 	ON 	UIB.UIB_PRODUT = SB1.B1_COD"
		cQry += " 																			AND UIB.D_E_L_E_T_ 	<> '*'"
		cQry += " 																			AND SB1.B1_FILIAL 	= '"+xFilial("SB1")+"'"

		cQry += "								INNER JOIN "+RetSqlName("UH9")+" UH9 	ON 	UIB.UIB_FORNEC	= UH9.UH9_FORNEC"
		cQry += " 																		AND UIB.UIB_LOJAFO	= UH9.UH9_LOJA"
		cQry += " 																		AND UIB.UIB_PRODUT	= UH9.UH9_PRODUT"
		cQry += " 																		AND UH9.D_E_L_E_T_	<> '*'"
		cQry += " 																		AND UH9.UH9_FILIAL	= '"+xFilial("UH9")+"'"

		cQry += " WHERE UIB.D_E_L_E_T_ 	<> '*'"
		cQry += " AND UIB.UIB_FILIAL 	= '"+xFilial("UIB")+"'"
		cQry += " AND UIB.UIB_GRPCLI	= '"+QRYCLI->UI0_GRPCLI+"'"
		cQry += " AND UIB.UIB_CLIENT	= '"+QRYCLI->UI0_CLIENT+"'"
		cQry += " AND UIB.UIB_LOJA		= '"+QRYCLI->UI0_LOJA+"'"
		cQry += " AND UIB.UIB_FORNEC	= '"+QRYPRE->UI1_FORNEC+"'"
		cQry += " AND UIB.UIB_LOJAFO	= '"+QRYPRE->UI1_LOJAFO+"'"
		cQry += " ORDER BY SB1.B1_DESC"
		
		cQry := ChangeQuery(cQry)
		//MemoWrite("c:\temp\TRETR011.txt",cQry)
		TcQuery cQry NEW Alias "QRYPRC"
	
		While !oReport:Cancel() .And. QRYPRC->(!EOF())
			
			If oReport:Cancel()
				Exit
			EndIf

			oSection3:Cell("UIB_PRODUT"):SetValue(QRYPRC->UIB_PRODUT)
			oSection3:Cell("B1_DESC"):SetValue(QRYPRC->B1_DESC)
			oSection3:Cell("UH9_PRCUNI"):SetValue(QRYPRC->UH9_PRCUNI)
			oSection3:Cell("UIB_DESACR"):SetValue(QRYPRC->UIB_DESACR)
			oSection3:Cell("PRCVEN"):SetValue(QRYPRC->UH9_PRCUNI + QRYPRC->UIB_DESACR)
			oSection3:PrintLine()
			    
			
			QRYPRC->(DbSkip())
		EndDo

		oSection3:Finish()
		oSection2:Finish()

		QRYPRE->(DbSkip())
	EndDo

	oSection1:Finish()	
	
	QRYCLI->(DbSkip())
EndDo

If Select("QRYCLI") > 0
	QRYCLI->(DbCloseArea())
Endif

If Select("QRYPRE") > 0
	QRYPRE->(DbCloseArea())
Endif

If Select("QRYPRC") > 0
	QRYPRC->(DbCloseArea())
Endif

Return