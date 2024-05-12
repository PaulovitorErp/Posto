#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETR006
Relatório Trancamento
@author Maiki Perin
@since 21/11/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETR006()

	Local oReport

	oReport:= ReportDef()
	oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Definição do relatorio
@author thebr
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
Static Function ReportDef()

	Local oReport
	//Local oSection1
	Local oSection2, oSection3, oSection4, oSection5, oSection6, oSection7, oSection8

	Local cTitle    := "Trancamento"

	oReport:= TReport():New("TRETR006",cTitle,"TRETR006",{|oReport| PrintReport(oReport)},"Este relatório apresenta uma relação de Produtos de Trancamento.")
	oReport:SetPortrait()
	oReport:HideParamPage()
	oReport:SetUseGC(.F.) 			//Desabilita o botão <Gestao Corporativa> do relatório
	oReport:DisableOrientation()    //Desabilita a seleção da orientação (retrato/paisagem)
	oReport:cFontBody := "Courier new" //"Arial"
	oReport:nFontBody := 8

	U_uAjusSx1("TRETR006","01","Filial		?","","","mv_ch1","C",04,0,0,"G","","SM0","","","mv_par01","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR006","02","Data De		?","","","mv_ch2","D",08,0,0,"G","","","","","mv_par02","","","","","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR006","03","Data Ate		?","","","mv_ch3","D",08,0,0,"G","","","","","mv_par03","","","","  ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR006","04","Produto De	?","","","mv_ch4","C",15,0,0,"G","","SB1","","","mv_par04","","","","               ","","","","","","","","","","","","",{"",""},{"",""},{"",""})
	U_uAjusSx1("TRETR006","05","Produto Ate	?","","","mv_ch5","C",15,0,0,"G","","SB1","","","mv_par05","","","","ZZZZZZZZZZZZZZZ","","","","","","","","","","","","",{"",""},{"",""},{"",""})

	Pergunte(oReport:GetParam(),.F.)

	/*oSection1 := TRSection():New(oReport,"Período",{})
	oSection1:SetHeaderPage(.T.)
	oSection1:SetHeaderSection(.T.)

	TRCell():New(oSection1,"PERIODO",, "PERIODO",	"@!",25)*/

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection2 := TRSection():New(oReport,"Produto",{"QRYPROD"})
	oSection2:SetHeaderPage(.F.)
	oSection2:SetHeaderSection(.T.)

	TRCell():New(oSection2,"PRODUTO",	"QRYPROD",	"PRODUTO", 	"@!",48)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection3 := TRSection():New(oSection2,"CONTROLE DE RECEBIMENTO DE COMBUSTIVEIS",{"QRYNFENT"},,,,"TOTAL NOTAS FISCAIS DE ENTRADA")
	oSection3:SetHeaderPage(.F.)
	oSection3:SetHeaderSection(.T.)

	TRCell():New(oSection3,"ZE4_DTLANC"	,"QRYNFENT",	"DATA", 		PesqPict("ZE4","ZE4_DTLANC"),TamSX3("ZE4_DTLANC")[1]+2)
	TRCell():New(oSection3,"ZE3_NUMERO"	,"QRYNFENT", 	"NRO. CRC",		PesqPict("ZE3","ZE3_NUMERO"),TamSX3("ZE3_NUMERO")[1]+3)
	TRCell():New(oSection3,"ZE3_NOTA"	,"QRYNFENT", 	"DOC.",			PesqPict("ZE3","ZE3_NOTA"),TamSX3("ZE3_NOTA")[1]+1)
	TRCell():New(oSection3,"ZE4_QTDE"	,"QRYNFENT", 	"QTD.", 		"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection4 := TRSection():New(oSection2,"MEDICAO FECHAMENTO",{"QRYMED"},,,,"TOTAIS MEDICAO")
	oSection4:SetHeaderPage(.F.)
	oSection4:SetHeaderSection(.T.)

	TRCell():New(oSection4,"TQK_DTMEDI"	,"QRYMED",	"DATA", 			PesqPict("TQK","TQK_DTMEDI"),TamSX3("TQK_DTMEDI")[1]+2)
	TRCell():New(oSection4,"TQK_TANQUE"	,"QRYMED", 	"TANQUE",			PesqPict("TQK","TQK_TANQUE"),TamSX3("TQK_TANQUE")[1]+1)
	TRCell():New(oSection4,"TQK_TQFISC"	,"QRYMED", 	"TQ.FISICO",		PesqPict("TQK","TQK_TQFISC"),TamSX3("TQK_TQFISC")[1]+1)
	TRCell():New(oSection4,"TQK_QTD"	,"QRYMED", 	"MEDIDA",			PesqPict("TQK","TQK_QTD"),TamSX3("TQK_QTD")[1]+1)
	TRCell():New(oSection4,"TQK_QTDEST"	,"QRYMED", 	"ESTOQUE ATUAL",	PesqPict("TQK","TQK_QTDEST"),TamSX3("TQK_QTDEST")[1]+1)
	TRCell():New(oSection4,"TQK_CAPAC"	,"QRYMED", 	"CAP./DESCARGA",	PesqPict("TQK","TQK_CAPAC"),TamSX3("TQK_CAPAC")[1]+1)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection5 := TRSection():New(oSection2,"TRANCAMENTO DIARIO",{"QRYTRC_D"},,,,"TOTAL DIARIO")
	oSection5:SetHeaderPage(.F.)
	oSection5:SetHeaderSection(.T.)

	TRCell():New(oSection5,"MED_INI"	,"QRYTRC_D",	"ESTOQUE INICIAL", 	PesqPict("TQK","TQK_QTD"),TamSX3("TQK_QTD")[1]+1)
	TRCell():New(oSection5,"MED_FIM"	,"QRYTRC_D", 	"ESTOQUE FINAL",	PesqPict("TQK","TQK_QTD"),TamSX3("TQK_QTD")[1]+1)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection6 := TRSection():New(oSection2,"TOTALIZADOR TRANCAMENTO DIARIO",{},,,,,,,,,,,.T.,,,,,1)
	oSection6:SetHeaderPage(.F.)
	oSection6:SetHeaderSection(.T.)

	TRCell():New(oSection6,"COMPRAS"	,,	"COMPRAS______________",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection6,"VENDA_EST"	,, 	"VENDAS PELO ESTOQUE__",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection6,"VENDA_SIS"	,, 	"VENDAS PELO SISTEMA__",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection6,"AFERICAO"	,, 	"AFERICOES____________",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection6,"RESULT"		,, 	"RESULTADO TRANCAMENTO",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1,,,,,,,,,,,.T.)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection7 := TRSection():New(oSection2,"TRANCAMENTO PERIODO",{"QRYTRC_P"},,,,"TOTAL PERIODO")
	oSection7:SetHeaderPage(.F.)
	oSection7:SetHeaderSection(.T.)

	TRCell():New(oSection7,"MED_INI"	,"QRYTRC_P",	"ESTOQUE INICIAL", 	PesqPict("TQK","TQK_QTD"),TamSX3("TQK_QTD")[1]+1)
	TRCell():New(oSection7,"MED_FIM"	,"QRYTRC_P", 	"ESTOQUE FINAL",	PesqPict("TQK","TQK_QTD"),TamSX3("TQK_QTD")[1]+1)

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection8 := TRSection():New(oSection2,"TOTALIZADOR TRANCAMENTO PERIODO",{},,,,,,,,,,,.T.,,,,,1)
	oSection8:SetHeaderPage(.F.)
	oSection8:SetHeaderSection(.T.)

	TRCell():New(oSection8,"COMPRAS"	,,	"COMPRAS______________",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection8,"VENDA_EST"	,, 	"VENDAS PELO ESTOQUE__",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection8,"VENDA_SIS"	,, 	"VENDAS PELO SISTEMA__",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection8,"AFERICAO"	,, 	"AFERICOES____________",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)
	TRCell():New(oSection8,"RESULT"		,, 	"RESULTADO TRANCAMENTO",	"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1,,,,,,,,,,,.T.)
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	oSection9 := TRSection():New(oSection2,"DETALHAMENTO AFERICOES PERIODO")
	oSection9:SetHeaderPage(.F.)
	oSection9:SetHeaderSection(.T.)

	TRCell():New(oSection9,"DATA"		,,	"DATA",		PesqPict("MID","MID_DATACO"),TamSX3("MID_DATACO")[1]+2)
	TRCell():New(oSection9,"TANQUE"		,,	"TANQUE",	PesqPict("MID","MID_CODTAN"),TamSX3("MID_CODTAN")[1]+1)
	TRCell():New(oSection9,"BICO"		,, 	"BICO",		PesqPict("MID","MID_CODBIC"),TamSX3("MID_CODBIC")[1]+1)
	TRCell():New(oSection9,"AFERICAO"	,, 	"QTD",		"@E 999,999,999,999",TamSX3("D1_QUANT")[1]+1)

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

	//Local oSection1		:= oReport:Section(1)
	Local oSection2		:= oReport:Section(1)
	Local oSection3		:= oReport:Section(1):Section(1)
	Local oSection4		:= oReport:Section(1):Section(2)
	Local oSection5		:= oReport:Section(1):Section(3)
	Local oSection6		:= oReport:Section(1):Section(4)
	Local oSection7		:= oReport:Section(1):Section(5)
	Local oSection8		:= oReport:Section(1):Section(6)
	Local oSection9		:= oReport:Section(1):Section(7)

	Local cMVCombus := AllTrim(SuperGetMv("MV_XCOMBUS",,"")) //Somente combustiveis: GASOLINA, ETANOL e DIESEL

	Local cQry := cQry2	:= cQry3 := cQry4 := cQry5 := cQry6 := cQry7 := cQry8 := cQry9 := ""

	Local nCont			:= 0

	Local nTotEntD		:= 0
	Local nTotEnt		:= 0
	Local nMedIni		:= 0
	Local nMedFim		:= 0
	Local nQtdVen		:= 0
	Local nQtdVenAf		:= 0
	Local nTotEst		:= 0
	Local nTotCapac		:= 0
	Local nTotAferic	:= 0

	Local nLin			:= 0

	Local oFont			:= TFont():New("Courier new"/*'Arial'*/,,10,,.T.,,,,.F.,.F.) 	//Fonte 10 Negrito

	If Empty(Select("SM0"))
		OpenSM0(cEmpAnt)
	EndIf

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

	cQry := "SELECT B1_COD, B1_DESC"
	cQry += " FROM "+RetSqlName("SB1")+""
	cQry += " WHERE D_E_L_E_T_ 	<> '*'"
	cQry += " AND B1_COD		BETWEEN '"+MV_PAR04+"' AND '"+MV_PAR05+"'"
	//cQry += " AND (B1_GRUPO = '0001' OR B1_GRUPO = '0013' OR B1_GRUPO = '0014')" //Combustiveis Ou Arla Ou Arla a Granel
	cQry += " AND B1_GRUPO IN " +FormatIn(cMVCombus,"/")+ " "
	cQry += " AND B1_MSBLQL	<> '1'" //Produto desbloqueado
	cQry += " ORDER BY 2"

	cQry := ChangeQuery(cQry)
	TcQuery cQry NEW Alias "QRYPROD"

	QRYPROD->(dbEval({|| nCont++}))
	QRYPROD->(dbGoTop())

	oReport:SetMeter(nCont)

	While !oReport:Cancel() .And. QRYPROD->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf

		nTotEntD 	:= 0
		nTotEnt 	:= 0
		nMedIni		:= 0
		nMedFim		:= 0
		nQtdVen		:= 0
		nTotEst		:= 0
		nTotCapac	:= 0
		nTotAferic	:= 0

		nLin		:= 0

		/*oSection1:Init()

		oSection1:Cell("PERIODO"):SetValue(DToC(MV_PAR02) + " A " + DToC(MV_PAR03))
		oSection1:PrintLine()

		oSection1:Finish()*/
		oSection2:Init()

		oSection2:Cell("PRODUTO"):SetValue(AllTrim(QRYPROD->B1_COD) + " - " + QRYPROD->B1_DESC)
		oSection2:PrintLine()

		oReport:SkipLine(2)

		nLin := oReport:nRow
		oReport:Say(oReport:nRow,oReport:nCol,"CONTROLE DE RECEBIMENTO DE COMBUSTIVEIS",oFont)
		oReport:XlsNewRow(.T.)
		oReport:XlsNewCell("CONTROLE DE RECEBIMENTO DE COMBUSTIVEIS",.F.,oReport:nCol,,,,"C")
		oReport:SkipLine(1)
		oSection3:Init()

		If Select("QRYNFENT") > 0
			QRYNFENT->(DbCloseArea())
		Endif

		cQry2 := "SELECT SD1.D1_DTDIGIT AS DTDIGIT, 'DEVOLUCAO' AS CRC, SD1.D1_DOC AS DOC,"
		cQry2 += " SUM(SD1.D1_QUANT) AS QTD"
		cQry2 += " FROM "+RetSqlName("SD1")+" SD1, "+RetSqlName("SA1")+" SA1"
		cQry2 += " WHERE SD1.D_E_L_E_T_	<> '*'"
		cQry2 += " AND SA1.D_E_L_E_T_	<> '*'"

		If !Empty(MV_PAR01)
			cQry2 += " AND SD1.D1_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry2 += " AND SD1.D1_FILIAL	= '"+xFilial("SD1")+"'"
		Endif

		cQry2 += " AND SD1.D1_FORNECE	= SA1.A1_COD"
		cQry2 += " AND SD1.D1_LOJA		= SA1.A1_LOJA"
		cQry2 += " AND SD1.D1_TIPO		= 'D'" //Devolução de Venda
		cQry2 += " AND SD1.D1_COD		= '"+QRYPROD->B1_COD+"'"
		cQry2 += " AND SD1.D1_DATORI	BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"'"
		cQry2 += " GROUP BY SD1.D1_DTDIGIT, SD1.D1_DOC"

		cQry2 += " UNION ALL"

		cQry2 += " SELECT ZE4.ZE4_DTLANC AS DTDIGIT, ZE3.ZE3_NUMERO AS CRC, ZE3.ZE3_NOTA AS DOC,"
		cQry2 += " SUM(ZE4.ZE4_QTDE) AS QTD"
		cQry2 += " FROM "+RetSqlName("ZE3")+" ZE3, "+RetSqlName("ZE4")+" ZE4
		cQry2 += " WHERE ZE3.D_E_L_E_T_	<> '*'"
		cQry2 += " AND ZE4.D_E_L_E_T_	<> '*'"

		If !Empty(MV_PAR01)
			cQry2 += " AND ZE3.ZE3_FILIAL	= '"+MV_PAR01+"'"
			cQry2 += " AND ZE4.ZE4_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry2 += " AND ZE3.ZE3_FILIAL	= '"+xFilial("ZE3")+"'"
			cQry2 += " AND ZE4.ZE4_FILIAL	= '"+xFilial("ZE4")+"'"
		Endif

		cQry2 += " AND ZE3.ZE3_NUMERO		= ZE4.ZE4_NUMERO"
		cQry2 += " AND ZE4.ZE4_PRODUT		= '"+QRYPROD->B1_COD+"'"
		cQry2 += " AND ZE4.ZE4_DTLANC		BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"'"
		cQry2 += " GROUP BY ZE4.ZE4_DTLANC, ZE3.ZE3_NUMERO, ZE3.ZE3_NOTA"
		cQry2 += " ORDER BY 1,2"

		cQry2 := ChangeQuery(cQry2)
		//MemoWrite("c:\temp\TRETR006.txt",cQry2)
		TcQuery cQry2 NEW Alias "QRYNFENT"

		While QRYNFENT->(!EOF())

			oSection3:Cell("ZE4_DTLANC"):SetValue(DToC(SToD(QRYNFENT->DTDIGIT)))
			oSection3:Cell("ZE3_NUMERO"):SetValue(QRYNFENT->CRC)
			oSection3:Cell("ZE3_NOTA"):SetValue(QRYNFENT->DOC)
			oSection3:Cell("ZE4_QTDE"):SetValue(QRYNFENT->QTD)
			oSection3:PrintLine()

			If QRYNFENT->DTDIGIT == DToS(MV_PAR03) .And. QRYNFENT->CRC <> "DEVOLUCAO"
				nTotEntD += QRYNFENT->QTD
			Endif

			If QRYNFENT->CRC <> "DEVOLUCAO"
				nTotEnt += QRYNFENT->QTD
			Endif

			QRYNFENT->(dbSkip())
		EndDo

		oReport:Line(oReport:nRow,780,oReport:nRow,940)
		oReport:Say(oReport:nRow,685,Transform(nTotEnt,"@E 999,999,999,999"),oFont)

		oSection3:Finish()

		oReport:SkipLine(3)

		nLin := oReport:nRow
		oReport:Say(oReport:nRow,oReport:nCol,"MEDICAO FECHAMENTO",oFont)
		oReport:XlsNewRow(.T.)
		oReport:XlsNewCell("MEDICAO FECHAMENTO",.F.,oReport:nCol,,,,"C")
		oReport:SkipLine(1)

		oSection4:Init()

		If Select("QRYMED") > 0
			QRYMED->(DbCloseArea())
		Endif

		cQry3 := "SELECT TQK.TQK_DTMEDI, TQK.TQK_TANQUE, TQK.TQK_TQFISC, TQK.TQK_QTD, TQK.TQK_QTDEST, TQK.TQK_CAPAC"
		cQry3 += " FROM "+RetSqlName("TQK")+" TQK, "+RetSqlName("ZE0")+" ZE0,  "+RetSqlName("MHZ")+" MHZ"
		cQry3 += " WHERE TQK.D_E_L_E_T_ <> '*'"
		cQry3 += " AND ZE0.D_E_L_E_T_ 	<> '*'"
		cQry3 += " AND MHZ.D_E_L_E_T_ 	<> '*'"
		If !Empty(MV_PAR01)
			cQry3 += " AND TQK.TQK_FILIAL	= '"+MV_PAR01+"'"
			cQry3 += " AND ZE0.ZE0_FILIAL	= '"+MV_PAR01+"'"
			cQry3 += " AND MHZ.MHZ_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry3 += " AND TQK.TQK_FILIAL	= '"+xFilial("TQK")+"'"
			cQry3 += " AND ZE0.ZE0_FILIAL	= '"+xFilial("ZE0")+"'"
			cQry3 += " AND MHZ.MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
		Endif
		cQry3 += " AND TQK.TQK_TQFISC	= ZE0.ZE0_TANQUE"
		cQry3 += " AND ZE0.ZE0_GRPTQ	= MHZ.MHZ_CODTAN"
		cQry3 += " AND TQK.TQK_DTMEDI	= '"+DToS(MV_PAR03)+"'"
		cQry3 += " AND MHZ.MHZ_CODPRO	= '"+QRYPROD->B1_COD+"'"
		cQry3 += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DToS(MV_PAR03)+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DToS(MV_PAR03)+"'))"
		cQry3 += " AND TQK.TQK_PRODUT	= '"+QRYPROD->B1_COD+"'"

		cQry3 += " AND TQK.TQK_HRMEDI	= (SELECT MAX(TQK_HRMEDI) "
		cQry3 += " 					FROM "+RetSqlName("TQK")+" TQK_1 "
		cQry3 += " 					 WHERE TQK_1.D_E_L_E_T_ <> '*' "
		cQry3 += " 					 AND TQK_1.TQK_FILIAL	= TQK.TQK_FILIAL "
		cQry3 += " 					 AND TQK_1.TQK_PRODUT	= TQK.TQK_PRODUT "
		cQry3 += " 					 AND TQK_1.TQK_DTMEDI	= TQK.TQK_DTMEDI "
		cQry3 += " 					 AND TQK_1.TQK_TANQUE	= TQK.TQK_TANQUE "
		cQry3 += " 					 AND TQK_1.TQK_TQFISC	= TQK.TQK_TQFISC "
		cQry3 += " 					) "
		cQry3 += " ORDER BY 1,2,3"

		cQry3 := ChangeQuery(cQry3)
		//MemoWrite("c:\temp\TRETR006.txt",cQry2)
		TcQuery cQry3 NEW Alias "QRYMED"

		While QRYMED->(!EOF())

			oSection4:Cell("TQK_DTMEDI"):SetValue(DToC(SToD(QRYMED->TQK_DTMEDI)))
			oSection4:Cell("TQK_TANQUE"):SetValue(QRYMED->TQK_TANQUE)
			oSection4:Cell("TQK_TQFISC"):SetValue(QRYMED->TQK_TQFISC)
			oSection4:Cell("TQK_QTD"):SetValue(QRYMED->TQK_QTD)
			oSection4:Cell("TQK_QTDEST"):SetValue(QRYMED->TQK_QTDEST)
			oSection4:Cell("TQK_CAPAC"):SetValue(QRYMED->TQK_CAPAC)
			oSection4:PrintLine()

			nTotEst		+= QRYMED->TQK_QTDEST
			nTotCapac	+= QRYMED->TQK_CAPAC

			QRYMED->(dbSkip())
		EndDo

		oReport:Line(oReport:nRow,580,oReport:nRow,1250)
		oReport:Say(oReport:nRow,780,Transform(nTotEst,"@E 99,999,999"),oFont)
		oReport:Say(oReport:nRow,1050,Transform(nTotCapac,"@E 99,999,999"),oFont)

		oSection4:Finish()

		oReport:SkipLine(3)

		nLin := oReport:nRow
		oReport:Say(oReport:nRow,oReport:nCol,"TRANCAMENTO DIARIO (" + DToC(MV_PAR03) + " A " + DToC(MV_PAR03) + ")",oFont)
		oReport:XlsNewRow(.T.)
		oReport:XlsNewCell("TRANCAMENTO DIARIO (" + DToC(MV_PAR03) + " A " + DToC(MV_PAR03) + ")",.F.,oReport:nCol,,,,"C")
		oReport:SkipLine(1)

		oSection5:Init()

		If Select("QRYTRC_D") > 0
			QRYTRC_D->(DbCloseArea())
		Endif

		cQry4 := "SELECT TQK.TQK_TANQUE, TQK.TQK_QTDEST AS MED_FIM,"

		cQry4 += " (SELECT SUM(TQKINT.TQK_QTDEST) "
		cQry4 += " FROM "+RetSqlName("TQK")+" TQKINT "
		cQry4 += " WHERE TQKINT.D_E_L_E_T_	<> '*' "
		cQry4 += " AND TQKINT.TQK_FILIAL	= TQK.TQK_FILIAL "
		cQry4 += " AND TQKINT.TQK_PRODUT	= TQK.TQK_PRODUT "
		cQry4 += " AND TQKINT.TQK_DTMEDI	= '"+DToS(MV_PAR03 - 1)+"' "
		cQry4 += " AND TQKINT.TQK_TANQUE	= TQK.TQK_TANQUE "
		cQry4 += " AND TQKINT.TQK_TQFISC	= TQK.TQK_TQFISC "
		cQry4 += " AND TQKINT.TQK_HRMEDI	= (SELECT MAX(TQKAUX.TQK_HRMEDI) "
		cQry4 += " 								FROM "+RetSqlName("TQK")+" TQKAUX "
		cQry4 += " 								WHERE TQKAUX.D_E_L_E_T_ <> '*' "
		cQry4 += " 								AND TQKAUX.TQK_FILIAL	= TQKINT.TQK_FILIAL "
		cQry4 += " 								AND TQKAUX.TQK_PRODUT	= TQKINT.TQK_PRODUT "
		cQry4 += " 								AND TQKAUX.TQK_DTMEDI	= TQKINT.TQK_DTMEDI "
		cQry4 += " 								AND TQKAUX.TQK_TANQUE	= TQKINT.TQK_TANQUE "
		cQry4 += " 								AND TQKAUX.TQK_TQFISC	= TQKINT.TQK_TQFISC								 "
		cQry4 += " 							) "
		cQry4 += " ) AS MED_INI "

		cQry4 += " FROM "+RetSqlName("TQK")+" TQK, "+RetSqlName("ZE0")+" ZE0, "+RetSqlName("MHZ")+" MHZ"
		cQry4 += " WHERE TQK.D_E_L_E_T_ <> '*'"
		cQry4 += " AND ZE0.D_E_L_E_T_ 	<> '*'"
		cQry4 += " AND MHZ.D_E_L_E_T_ 	<> '*'"
		If !Empty(MV_PAR01)
			cQry4 += " AND TQK.TQK_FILIAL	= '"+MV_PAR01+"'"
			cQry4 += " AND ZE0.ZE0_FILIAL	= '"+MV_PAR01+"'"
			cQry4 += " AND MHZ.MHZ_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry4 += " AND TQK.TQK_FILIAL	= '"+xFilial("TQK")+"'"
			cQry4 += " AND ZE0.ZE0_FILIAL	= '"+xFilial("ZE0")+"'"
			cQry4 += " AND MHZ.MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
		Endif
		cQry4 += " AND TQK.TQK_TQFISC	= ZE0.ZE0_TANQUE"
		cQry4 += " AND ZE0.ZE0_GRPTQ	= MHZ.MHZ_CODTAN"
		cQry4 += " AND TQK.TQK_DTMEDI	= '"+DToS(MV_PAR03)+"'"
		cQry4 += " AND MHZ.MHZ_CODPRO	= '"+QRYPROD->B1_COD+"'"
		cQry4 += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DToS(MV_PAR03)+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DToS(MV_PAR03)+"'))"
		cQry4 += " AND TQK.TQK_PRODUT	= '"+QRYPROD->B1_COD+"'"
		cQry4 += " AND TQK.TQK_HRMEDI	= (SELECT MAX(TQKAUX2.TQK_HRMEDI) "
		cQry4 += " 					FROM "+RetSqlName("TQK")+" TQKAUX2 "
		cQry4 += " 					WHERE TQKAUX2.D_E_L_E_T_ <> '*' "
		cQry4 += " 					AND TQKAUX2.TQK_FILIAL	= TQK.TQK_FILIAL "
		cQry4 += " 					AND TQKAUX2.TQK_PRODUT	= TQK.TQK_PRODUT "
		cQry4 += " 					AND TQKAUX2.TQK_DTMEDI	= TQK.TQK_DTMEDI "
		cQry4 += " 					AND TQKAUX2.TQK_TANQUE	= TQK.TQK_TANQUE "
		cQry4 += " 					AND TQKAUX2.TQK_TQFISC	= TQK.TQK_TQFISC "
		cQry4 += " 					) "

		cQry4 := ChangeQuery(cQry4)
		//MemoWrite("c:\temp\TRETR006.txt",cQry4)
		TcQuery cQry4 NEW Alias "QRYTRC_D"

		While QRYTRC_D->(!EOF())
			nMedIni += QRYTRC_D->MED_INI
			nMedFim += QRYTRC_D->MED_FIM

			QRYTRC_D->(dbSkip())
		EndDo

		oSection5:Cell("MED_INI"):SetValue(nMedIni)
		oSection5:Cell("MED_FIM"):SetValue(nMedFim)
		oSection5:PrintLine()

		oSection5:Finish()

		oReport:SkipLine()

		oSection6:Init()

		oSection6:Cell("COMPRAS"):SetValue(nTotEntD)
		oSection6:Cell("VENDA_EST"):SetValue((nMedIni + nTotEntD) - nMedFim)

		If Select("QRYVEN_D") > 0
			QRYVEN_D->(DbCloseArea())
		Endif

		cQry5 := "SELECT CASE WHEN SD2.D2_QTDEDEV > 0 THEN SUM(SD2.D2_QUANT - SD2.D2_QTDEDEV) ELSE SUM(SD2.D2_QUANT) END AS QTD"
		cQry5 += " FROM "+RetSqlName("SF2")+" SF2, "+RetSqlName("SD2")+" SD2, "+RetSqlName("SF4")+" SF4"
		cQry5 += " WHERE SF2.D_E_L_E_T_ <> '*'"
		cQry5 += " AND SD2.D_E_L_E_T_ <> '*'"
		cQry5 += " AND SF4.D_E_L_E_T_ <> '*'"

		If !Empty(MV_PAR01)
			cQry5 += " AND SF2.F2_FILIAL	= '"+MV_PAR01+"'"
			cQry5 += " AND SD2.D2_FILIAL	= '"+MV_PAR01+"'"
			cQry5 += " AND SF4.F4_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry5 += " AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"
			cQry5 += " AND SD2.D2_FILIAL	= '"+xFilial("SD2")+"'"
			cQry5 += " AND SF4.F4_FILIAL	= '"+xFilial("SF4")+"'"
		Endif

		cQry5 += " AND SF2.F2_DOC		= SD2.D2_DOC"
		cQry5 += " AND SF2.F2_SERIE		= SD2.D2_SERIE"
		cQry5 += " AND SF2.F2_CLIENTE	= SD2.D2_CLIENTE"
		cQry5 += " AND SF2.F2_LOJA		= SD2.D2_LOJA"
		cQry5 += " AND SD2.D2_TES		= SF4.F4_CODIGO"
		cQry5 += " AND SD2.D2_COD		= '"+QRYPROD->B1_COD+"'"
		cQry5 += " AND SD2.D2_EMISSAO	= '"+DToS(MV_PAR03)+"'"
		cQry5 += " AND SD2.D2_QUANT 	> SD2.D2_QTDEDEV
		cQry5 += " AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR (SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"
		cQry5 += " AND SF2.F2_TIPO 		= 'N'"
		cQry5 += " AND SF4.F4_ESTOQUE	= 'S'"
		cQry5 += " GROUP BY SD2.D2_QTDEDEV"

		cQry5 := ChangeQuery(cQry5)
		TcQuery cQry5 NEW Alias "QRYVEN_D"

		If QRYVEN_D->(!EOF())
			nQtdVen := QRYVEN_D->QTD
		Endif

		oSection6:Cell("VENDA_SIS"):SetValue(nQtdVen)

		If Select("QRYVENAF_D") > 0
			QRYVENAF_D->(DbCloseArea())
		Endif

		cQry8 := "SELECT SUM(MID_LITABA) AS QTD"
		cQry8 += " FROM "+RetSqlName("MID")+""
		cQry8 += " WHERE D_E_L_E_T_ <> '*'"
		If !Empty(MV_PAR01)
			cQry8 += " AND MID_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry8 += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
		Endif
		cQry8 += " AND MID_XPROD		= '"+QRYPROD->B1_COD+"'"
		cQry8 += " AND MID_DATACO	= '"+DToS(MV_PAR03)+"'"
		cQry8 += " AND MID_AFERIR = 'S'" //Aferição

		cQry8 := ChangeQuery(cQry8)
		TcQuery cQry8 NEW Alias "QRYVENAF_D"

		If QRYVENAF_D->(!EOF())
			nQtdVenAf := QRYVENAF_D->QTD
		Endif

		oSection6:Cell("AFERICAO"):SetValue(nQtdVenAf)
		oSection6:Cell("RESULT"):SetValue(nQtdVen - ((nMedIni + nTotEntD) - nMedFim))
		oSection6:PrintLine()

		oSection6:Finish()

		oReport:SkipLine(3)

		nLin := oReport:nRow
		oReport:Say(oReport:nRow,oReport:nCol,"TRANCAMENTO PERIODO (" + DToC(MV_PAR02) + " A " + DToC(MV_PAR03) + ")",oFont)
		oReport:XlsNewRow(.T.)
		oReport:XlsNewCell("TRANCAMENTO PERIODO (" + DToC(MV_PAR02) + " A " + DToC(MV_PAR03) + ")",.F.,oReport:nCol,,,,"C")
		oReport:SkipLine(1)

		oSection7:Init()

		If Select("QRYTRC_P") > 0
			QRYTRC_P->(DbCloseArea())
		Endif

		cQry6 := "SELECT TQK.TQK_TANQUE, TQK.TQK_QTDEST AS MED_FIM,"

		cQry6 += " (SELECT SUM(TQKINT.TQK_QTDEST) "
		cQry6 += " FROM "+RetSqlName("TQK")+" TQKINT "
		cQry6 += " WHERE TQKINT.D_E_L_E_T_	<> '*' "
		cQry6 += " AND TQKINT.TQK_FILIAL	= TQK.TQK_FILIAL "
		cQry6 += " AND TQKINT.TQK_PRODUT	= TQK.TQK_PRODUT "
		cQry6 += " AND TQKINT.TQK_DTMEDI	= '"+DToS(MV_PAR02 - 1)+"' "
		cQry6 += " AND TQKINT.TQK_TANQUE	= TQK.TQK_TANQUE "
		cQry6 += " AND TQKINT.TQK_TQFISC	= TQK.TQK_TQFISC "
		cQry6 += " AND TQKINT.TQK_HRMEDI	= (SELECT MAX(TQKAUX.TQK_HRMEDI) "
		cQry6 += " 								FROM "+RetSqlName("TQK")+" TQKAUX "
		cQry6 += " 								WHERE TQKAUX.D_E_L_E_T_ <> '*' "
		cQry6 += " 								AND TQKAUX.TQK_FILIAL	= TQKINT.TQK_FILIAL "
		cQry6 += " 								AND TQKAUX.TQK_PRODUT	= TQKINT.TQK_PRODUT "
		cQry6 += " 								AND TQKAUX.TQK_DTMEDI	= TQKINT.TQK_DTMEDI "
		cQry6 += " 								AND TQKAUX.TQK_TANQUE	= TQKINT.TQK_TANQUE "
		cQry6 += " 								AND TQKAUX.TQK_TQFISC	= TQKINT.TQK_TQFISC								 "
		cQry6 += " 							) "
		cQry6 += " ) AS MED_INI "

		cQry6 += " FROM "+RetSqlName("TQK")+" TQK, "+RetSqlName("ZE0")+" ZE0, "+RetSqlName("MHZ")+" MHZ"
		cQry6 += " WHERE TQK.D_E_L_E_T_ <> '*'"
		cQry6 += " AND ZE0.D_E_L_E_T_ 	<> '*'"
		cQry6 += " AND MHZ.D_E_L_E_T_ 	<> '*'"
		If !Empty(MV_PAR01)
			cQry6 += " AND TQK.TQK_FILIAL	= '"+MV_PAR01+"'"
			cQry6 += " AND ZE0.ZE0_FILIAL	= '"+MV_PAR01+"'"
			cQry6 += " AND MHZ.MHZ_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry6 += " AND TQK.TQK_FILIAL	= '"+xFilial("TQK")+"'"
			cQry6 += " AND ZE0.ZE0_FILIAL	= '"+xFilial("ZE0")+"'"
			cQry6 += " AND MHZ.MHZ_FILIAL	= '"+xFilial("MHZ")+"'"
		Endif
		cQry6 += " AND TQK.TQK_TQFISC	= ZE0.ZE0_TANQUE"
		cQry6 += " AND ZE0.ZE0_GRPTQ	= MHZ.MHZ_CODTAN"
		cQry6 += " AND TQK.TQK_DTMEDI	= '"+DToS(MV_PAR03)+"'"
		cQry6 += " AND MHZ.MHZ_CODPRO	= '"+QRYPROD->B1_COD+"'"
		cQry6 += " AND ((MHZ_STATUS = '1' AND MHZ_DTATIV <= '"+DToS(MV_PAR03)+"') OR (MHZ_STATUS = '2' AND MHZ_DTDESA >= '"+DToS(MV_PAR03)+"'))"
		cQry6 += " AND TQK.TQK_PRODUT	= '"+QRYPROD->B1_COD+"'"
		cQry6 += " AND TQK.TQK_HRMEDI	= (SELECT MAX(TQKAUX2.TQK_HRMEDI) "
		cQry6 += " 					FROM "+RetSqlName("TQK")+" TQKAUX2 "
		cQry6 += " 					WHERE TQKAUX2.D_E_L_E_T_ <> '*' "
		cQry6 += " 					AND TQKAUX2.TQK_FILIAL	= TQK.TQK_FILIAL "
		cQry6 += " 					AND TQKAUX2.TQK_PRODUT	= TQK.TQK_PRODUT "
		cQry6 += " 					AND TQKAUX2.TQK_DTMEDI	= TQK.TQK_DTMEDI "
		cQry6 += " 					AND TQKAUX2.TQK_TANQUE	= TQK.TQK_TANQUE "
		cQry6 += " 					AND TQKAUX2.TQK_TQFISC	= TQK.TQK_TQFISC "
		cQry6 += " 					) "

		cQry6 := ChangeQuery(cQry6)
		//MemoWrite("c:\temp\RFISR001.txt",cQry6)
		TcQuery cQry6 NEW Alias "QRYTRC_P"

		nMedIni := 0
		nMedFim := 0

		While QRYTRC_P->(!EOF())

			nMedIni += QRYTRC_P->MED_INI
			nMedFim += QRYTRC_P->MED_FIM

			QRYTRC_P->(dbSkip())
		EndDo

		oSection7:Cell("MED_INI"):SetValue(nMedIni)
		oSection7:Cell("MED_FIM"):SetValue(nMedFim)
		oSection7:PrintLine()

		oSection7:Finish()

		oReport:SkipLine()

		oSection8:Init()

		oSection8:Cell("COMPRAS"):SetValue(nTotEnt)
		oSection8:Cell("VENDA_EST"):SetValue((nMedIni + nTotEnt) - nMedFim)

		If Select("QRYVEN_P") > 0
			QRYVEN_P->(DbCloseArea())
		Endif

		cQry7 := "SELECT CASE WHEN SD2.D2_QTDEDEV > 0 THEN SUM(SD2.D2_QUANT - SD2.D2_QTDEDEV) ELSE SUM(SD2.D2_QUANT) END AS QTD"
		cQry7 += " FROM "+RetSqlName("SF2")+" SF2, "+RetSqlName("SD2")+" SD2, "+RetSqlName("SF4")+" SF4"
		cQry7 += " WHERE SF2.D_E_L_E_T_ <> '*'"
		cQry7 += " AND SD2.D_E_L_E_T_ <> '*'"
		cQry7 += " AND SF4.D_E_L_E_T_ <> '*'"

		If !Empty(MV_PAR01)
			cQry7 += " AND SF2.F2_FILIAL	= '"+MV_PAR01+"'"
			cQry7 += " AND SD2.D2_FILIAL	= '"+MV_PAR01+"'"
			cQry7 += " AND SF4.F4_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry7 += " AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"
			cQry7 += " AND SD2.D2_FILIAL	= '"+xFilial("SD2")+"'"
			cQry7 += " AND SF4.F4_FILIAL	= '"+xFilial("SF4")+"'"
		Endif

		cQry7 += " AND SF2.F2_DOC		= SD2.D2_DOC"
		cQry7 += " AND SF2.F2_SERIE		= SD2.D2_SERIE"
		cQry7 += " AND SF2.F2_CLIENTE	= SD2.D2_CLIENTE"
		cQry7 += " AND SF2.F2_LOJA		= SD2.D2_LOJA"
		cQry7 += " AND SD2.D2_TES		= SF4.F4_CODIGO"
		cQry7 += " AND SD2.D2_COD		= '"+QRYPROD->B1_COD+"'"
		cQry7 += " AND SD2.D2_EMISSAO	BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"'"
		cQry7 += " AND SD2.D2_QUANT > SD2.D2_QTDEDEV
		cQry7 += " AND ((SF2.F2_ESPECIE IN('CF','NFCE')) OR (SF2.F2_ESPECIE IN('SPED','') AND SF2.F2_NFCUPOM = ''))"
		cQry7 += " AND SF2.F2_TIPO 		= 'N'"
		cQry7 += " AND SF4.F4_ESTOQUE	= 'S'"
		cQry7 += " GROUP BY SD2.D2_QTDEDEV"

		cQry7 := ChangeQuery(cQry7)
		TcQuery cQry7 NEW Alias "QRYVEN_P"

		If QRYVEN_P->(!EOF())
			nQtdVen := QRYVEN_P->QTD
		Endif

		oSection8:Cell("VENDA_SIS"):SetValue(nQtdVen)

		If Select("QRYVENAF_P") > 0
			QRYVENAF_P->(DbCloseArea())
		Endif

		cQry9 := "SELECT SUM(MID_LITABA) AS QTD"
		cQry9 += " FROM "+RetSqlName("MID")+""
		cQry9 += " WHERE D_E_L_E_T_ <> '*'"
		If !Empty(MV_PAR01)
			cQry9 += " AND MID_FILIAL	= '"+MV_PAR01+"'"
		Else
			cQry9 += " AND MID_FILIAL	= '"+xFilial("MID")+"'"
		Endif
		cQry9 += " AND MID_XPROD = '"+QRYPROD->B1_COD+"'"
		cQry9 += " AND MID_DATACO BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"'"
		cQry9 += " AND MID_AFERIR = 'S' " //Aferição

		cQry9 := ChangeQuery(cQry9)
		TcQuery cQry9 NEW Alias "QRYVENAF_P"

		If QRYVENAF_P->(!EOF())
			nQtdVenAf := QRYVENAF_P->QTD
		Endif

		oSection8:Cell("AFERICAO"):SetValue(nQtdVenAf)
		oSection8:Cell("RESULT"):SetValue(nQtdVen - ((nMedIni + nTotEnt) - nMedFim))
		oSection8:PrintLine()

		oSection8:Finish()
		oSection9:Finish()
		oSection2:Finish()

		oReport:IncMeter()

		oReport:EndPage(.T.)

		QRYPROD->(dbSkip())
	EndDo

	If Select("QRYPROD") > 0
		QRYPROD->(DbCloseArea())
	Endif

	If Select("QRYNFENT") > 0
		QRYNFENT->(DbCloseArea())
	Endif

	If Select("QRYMED") > 0
		QRYMED->(DbCloseArea())
	Endif

	If Select("QRYTRC_D") > 0
		QRYTRC_D->(DbCloseArea())
	Endif

	If Select("QRYVEN_D") > 0
		QRYVEN_D->(DbCloseArea())
	Endif

	If Select("QRYTRC_P") > 0
		QRYTRC_P->(DbCloseArea())
	Endif

	If Select("QRYVEN_P") > 0
		QRYVEN_P->(DbCloseArea())
	Endif

	If Select("QRYVENAF_D") > 0
		QRYVENAF_D->(DbCloseArea())
	Endif

	If Select("QRYVENAF_P") > 0
		QRYVENAF_P->(DbCloseArea())
	Endif

	If Select("QRYAF_P") > 0
		QRYAF_P->(DbCloseArea())
	Endif

Return
