#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#include "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

/*/{Protheus.doc} TRETR021
Geração de relatório de lista de vendas dos produtos, agrupado por subcategorias (grupo).

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
User Function TRETR021()

////////////////////// FONTES PARA SEREM UTILIZADAS NO RELATORIO ///////////////////////////

	Private oFont6		:= TFONT():New("Arial",,6,.T.,.F.,5,.T.,5,.T.,.F.	) //Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("Arial",,6,,.T.,,,,.T.,.F.			) //Fonte 6 Negrito
	Private oFont8		:= TFONT():New('Arial',,8,,.F.,,,,.F.,.F.		) //Fonte 9 Normal
	Private oFont8N		:= TFONT():New('Arial',,8,,.T.,,,,.F.,.F.		) //Fonte 9 Negrito
	Private oFont8NI	:= TFONT():New('Times New Roman',,8,,.T.,,,,.F.,.F.,.T.) //Fonte 8 Negrito e Itálico
	Private oFont9		:= TFONT():New('Arial',,9,,.F.,,,,.F.,.F.	) //Fonte 9 Normal
	Private oFont9N	    := TFONT():New('Arial',,9,,.T.,,,,.F.,.F.	) //Fonte 9 Negrito
	Private oFont10		:= TFONT():New('Arial',,10,,.F.,,,,.F.,.F.	) //Fonte 10 Normal
	Private oFont10N	:= TFONT():New('Arial',,10,,.T.,,,,.F.,.F.	) //Fonte 10 Negrito
	Private oFont12	    := TFONT():New('Arial',,12,,.F.,,,,.F.,.F.	) //Fonte 12 Normal
	Private oFont12N	:= TFONT():New('Arial',,12,,.T.,,,,.F.,.F.	) //Fonte 12 Negrito
	Private oFont14N	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.	) //Fonte 14 Negrito
	Private oFont14NI	:= TFONT():New('Times New Roman',,14,,.T.,,,,.F.,.F.,.T.) //Fonte 14 Negrito e Itálico
	Private oFont16N	:= TFONT():New('Arial',,16,,.T.,,,,.F.,.F.	) //Fonte 16 Negrito
	Private oFont16NI	:= TFONT():New('Times New Roman',,16,,.T.,,,,.F.,.F.,.T.) //Fonte 16 Negrito e Itálico

////////////////////////////////////////////////////////////////////////////////////////////
	Private cStartPath
	Private nLin 		:= 50
	Private nCol1, nCol2
	Private cArquivo	:= "TRETR021_"+DTOS(Date())+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)
	Private oPrint	 	:= Nil
	Private oBrush		:= TBrush():New(,CLR_HGRAY )
	Private nPagina		:= 1

	Private cPerg		:= "TRETR021"
	Private oDlg

	If !fValidPerg()
		Return
	Endif

	oPrint := FwMSPrinter():New(cArquivo,IMP_PDF,.T.,,.T.,,,,.T.,.F.)
	oPrint:SetDevice(IMP_PDF)
	oPrint:SetResolution(72)
	oPrint:SetLandscape() //Define a orientacao da impressao como paisagem
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(0,0,0,0)
    oPrint:Setup() //Tela de configurações

	Processa({|| fCorpoRel()}, "Aguarde...", "Carregando relatório...", .T.)

Return()

/*/{Protheus.doc} fValidPerg
Perguntas SX1

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function fValidPerg()

	Local aMvPar
	Local nMv := 0
	Local cParRel := AllTrim(SM0->M0_CODIGO)+AllTrim(SM0->M0_CODFIL)+cPerg
	Local aParamBox := {}
	Local lRet := .F.
	Local aParam := {STOD(""),STOD(""),space(TamSX3("BM_GRUPO")[1]),Replicate("Z",TamSX3("BM_GRUPO")[1]),1,1}

	aAdd(aParamBox,{1,"Período de  ?", aParam[1], "",'.T.',"" ,'.T.', 50, .T.})
	aAdd(aParamBox,{1,"Período até ?", aParam[2], "",'.T.',"" ,'.T.', 50, .T.})
	aAdd(aParamBox,{1,"Grupo de  ?",aParam[3],"","","SBM","",0,.F.})
	aAdd(aParamBox,{1,"Grupo até ?",aParam[4],"","","SBM","",0,.F.})

	aAdd(aParamBox,{2,"Desconsidera Devoluções ?",aParam[5],{"1=Não","2=Sim"},50,"",.F.})
	aAdd(aParamBox,{2,"Tipo de Desc/Acresc ?",aParam[6],{"1=Fiscal","2=Abastecimento"},50,"",.F.})

	//restauro os parametros usados anteriomente
	For nMv := 1 To Len(aParamBox)
		aParamBox[nMv][3] := &("MV_PAR"+STRZERO(nMv,2)) := aParam[nMv] := ParamLoad(cParRel,aParamBox,nMv,aParamBox[nMv][3])
	Next nMv

	If lRet := ParamBox(aParamBox,"Vendas de Produtos por Grupo",@aMvPar,,,,,,,cPerg)

		For nMv := 1 To Len( aMvPar )
			&("MV_PAR"+StrZero(nMv,2,0)) := aMvPar[nMv]
		Next nMv

		//salvo os novos parametros escolhidos
		ParamSave(cParRel,aParamBox,"1")

		//correção de um BUG na função parambox (retorno pode ser caracter e/ou numerico)
		MV_PAR05 := Val(cValToChar(MV_PAR05))
		MV_PAR06 := Val(cValToChar(MV_PAR06))

	EndIf

Return lRet

/*/{Protheus.doc} fCabecalho
Função que imprime o cabaçalho do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function fCabecalho()

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin:=100

	//Impressao da Logo
	oPrint:Box(nLin,050,nLin+132,285)
	oPrint:SayBitmap(nLin+45, 075, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 180, 036) //proporção: (L)100 x (A)20

	//Dados da empresa e filtro relatório
	oPrint:Box(nLin,285,nLin+132,2550)
	oPrint:Say(nLin+30, 295, AllTrim(cNomeCom), oFont10N) //SM0->M0_NOMECOM
	oPrint:Say(nLin+70, 295, "Vendas de Produtos por Grupo", oFont10N)
	oPrint:Say(nLin+110, 295, "Período: "+DtoC(MV_PAR01)+" à "+DtoC(MV_PAR02), oFont10N)

	//Numero da página e data e hora
	oPrint:Box(nLin,2550,nLin+132,3000)
	oPrint:SayAlign(nLin+10+25, 2550, "Página: " + strzero(nPagina,3), oFont9N,450/*largura*/,50/*altura*/,,2,0)
	oPrint:SayAlign(nLin+10+65, 2550, DTOC(Date())+" "+Time(), oFont9N,450/*largura*/,50/*altura*/,,2,0)

	nLin+=180

	nCol1 := 050
	nCol2 := 552
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Item", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 824
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Quantidade", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1096
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Vlr Bruto", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1368
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Desconto", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1640
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Acréscimo", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1912
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "ICMS ST", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 2184
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Vlr Liquido", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 2456
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Vlr Custo", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 2728
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Vlr Lucro", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 3000
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Preço Médio", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nLin+=50

Return()

/*/{Protheus.doc} fRodape
Função para crair o rodapé do relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function fRodape()

	nLin := 2350

	oPrint:Line(nLin,050,nLin,3000)
	oPrint:SayAlign(nLin, 050, "Microsiga Protheus", oFont8N,2950/*largura*/,30/*altura*/,,2,0)
	nLin+=30
	oPrint:Line(nLin,050,nLin,3000)

Return()

/*/{Protheus.doc} fCorpoRel
Função para preencher o relatório

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function fCorpoRel()

	Local cQuery := ""
	Local cGrupo := ""
	Local aSM0   := {}
	Local nVlBrt := 0
	Local nVlDes := 0
	Local nVlAcr := 0
	Local nVlPmd := 0

	Private nTotQtd    := 0
	Private nTotBrt    := 0
	Private nTotDes    := 0
	Private nTotAcr    := 0
	Private nTotIcm    := 0
	Private nTotLqd    := 0
	Private nTotCst    := 0
	Private nTotLcr    := 0

	Private nTotQtdGer    := 0
	Private nTotBrtGer    := 0
	Private nTotDesGer    := 0
	Private nTotAcrGer    := 0
	Private nTotIcmGer    := 0
	Private nTotLqdGer    := 0
	Private nTotCstGer    := 0
	Private nTotLcrGer    := 0

	Private oDlgImp
	Private cNomeCom := ""

	DbSelectArea("SD2")

	If Findfunction("FindClass") .AND. FindClass("FWSM0Util")
		If Empty(Select("SM0"))
			OpenSM0(cEmpAnt)
		EndIf
		aSM0 := FWSM0Util():GetSM0Data()
		nAux := aScan(aSM0, {|x| alltrim(x[1]) == "M0_NOMECOM" })
		cNomeCom := aSM0[nAux][2]
	Else
		DbSelectArea("SM0")
		cNomeCom := SM0->M0_NOMECOM
	EndIf

	If Select("QRYSD2") > 0
		QRYSD2->(DbCloseArea())
	EndIf

	cQuery += "SELECT D2_FILIAL, B1_GRUPO, BM_DESC, D2_COD, B1_DESC, " + CRLF
	cQuery += " SUM(D2_QUANT) AS QTD, " + CRLF
	cQuery += " SUM(D2_VALBRUT) AS BRT, " + CRLF //-> D2_QUANT * D2_PRUNIT
	cQuery += " SUM(D2_DESCON) AS DES, " + CRLF
	cQuery += " 0 AS ACR, " + CRLF
	cQuery += " SUM(D2_ICMSRET) AS ICM, " + CRLF
	cQuery += " SUM(D2_TOTAL) AS LQD, " + CRLF
	cQuery += " SUM(D2_CUSTO1) AS CST, " + CRLF
	If MV_PAR06 == 2 //Tipo de Desc/Acresc ? => 2=Abastecimento
		cQuery += " SUM(ISNULL(MID.MID_LITABA, 0)) AS LITRAGEM, " + CRLF
		cQuery += " SUM(ISNULL(MID.MID_TOTAPA, 0)) AS VTOTAL, " + CRLF
	EndIf
	cQuery += " AVG(D2_PRCVEN) AS PMD " + CRLF
	cQuery += " FROM "+RetSqlName("SD2")+" SD2 " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = SD2.D2_COD) " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SBM")+" SBM ON (SBM.D_E_L_E_T_ = ' ' AND SBM.BM_FILIAL = '"+xFilial("SBM")+"' AND SBM.BM_GRUPO = SB1.B1_GRUPO) " + CRLF
	cQuery += " INNER JOIN "+RetSQLName("SL2")+" SL2 ON (SL2.D_E_L_E_T_ = ' ' AND SD2.D2_FILIAL = SL2.L2_FILIAL AND SD2.D2_ITEM = SL2.L2_ITEM AND SD2.D2_COD = SL2.L2_PRODUTO AND SD2.D2_DOC = SL2.L2_DOC AND SD2.D2_SERIE = SL2.L2_SERIE)  " + CRLF
	If MV_PAR06 == 2 //Tipo de Desc/Acresc ? => 2=Abastecimento
		cQuery += " LEFT JOIN "+RetSqlName("MID")+" MID ON (MID.D_E_L_E_T_ = ' ' AND MID.MID_FILIAL = SL2.L2_FILIAL AND MID.MID_CODABA = SL2.L2_MIDCOD) " + CRLF
	EndIf
	cQuery += " WHERE SD2.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += " AND SD2.D2_FILIAL	= '"+xFilial("SD2")+"' " + CRLF
	cQuery += " AND SD2.D2_EMISSAO >= '"+DTOS(MV_PAR01)+"' AND SD2.D2_EMISSAO <= '"+DTOS(MV_PAR02)+"' " + CRLF
	cQuery += " AND SB1.B1_GRUPO >= '"+MV_PAR03+"' AND SB1.B1_GRUPO <= '"+MV_PAR04+"' " + CRLF
	If MV_PAR05 == 2 //Desconsidera Devoluções => 2-SIM
		cQuery += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("SD1")+" SD1 " + CRLF
		cQuery += " WHERE SD1.D_E_L_E_T_ = ' ' " + CRLF
		cQuery += " AND SD1.D1_FILORI = SD2.D2_FILIAL " + CRLF
		cQuery += " AND SD1.D1_NFORI = SD2.D2_DOC " + CRLF
		cQuery += " AND SD1.D1_ITEMORI = SD2.D2_ITEM " + CRLF
		cQuery += " AND SD1.D1_SERIORI = SD2.D2_SERIE " + CRLF
		cQuery += " AND SD1.D1_TIPO = 'D' " + CRLF
		cQuery += " ) " + CRLF
	EndIf
	cQuery += " GROUP BY D2_FILIAL, B1_GRUPO, BM_DESC, D2_COD, B1_DESC " + CRLF
	cQuery += " ORDER BY D2_FILIAL, B1_GRUPO, D2_COD " + CRLF

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery New Alias "QRYSD2" // Cria uma nova area com o resultado do query

	fCabecalho()

	While QRYSD2->(!EOF())

		If MV_PAR06 == 2 ; //Tipo de Desc/Acresc ? => 2=Abastecimento
			.and. QRYSD2->QTD == QRYSD2->LITRAGEM
			nVlBrt := QRYSD2->VTOTAL
			If QRYSD2->LQD < nVlBrt
				nVlDes := nVlBrt - QRYSD2->LQD
				nVlAcr := 0
			Else
				nVlAcr := QRYSD2->LQD - nVlBrt
				nVlDes := 0
			EndIf
		Else
			nVlBrt := QRYSD2->BRT
			nVlDes := QRYSD2->DES
			nVlAcr := QRYSD2->ACR
		EndIf

		nVlPmd := nVlBrt / QRYSD2->QTD

		If nLin > 2350
			fRodape()
			NovaPagina()
			nLin+=50
			oPrint:Box(nLin,050,nLin+50,3000)
			oPrint:SayAlign(nLin+10, 060, AllTrim(QRYSD2->B1_GRUPO)+" - "+AllTrim(QRYSD2->BM_DESC), oFont10N,2930/*largura*/,50/*altura*/,,0,0)
			nLin+=50
		EndIf

		If cGrupo <> AllTrim(QRYSD2->B1_GRUPO)
			If !Empty(cGrupo)
				ImpTotGrp(cGrupo)
				nLin+=50
			EndIf
			cGrupo := AllTrim(QRYSD2->B1_GRUPO)
			nLin+=50
			oPrint:Box(nLin,050,nLin+50,3000)
			oPrint:SayAlign(nLin+10, 060, AllTrim(QRYSD2->B1_GRUPO)+" - "+AllTrim(QRYSD2->BM_DESC), oFont10N,2930/*largura*/,50/*altura*/,,0,0)
			nLin+=50
		EndIf

		If nLin > 2350
			fRodape()
			NovaPagina()
			nLin+=50
			oPrint:Box(nLin,050,nLin+50,3000)
			oPrint:SayAlign(nLin+10, 060, AllTrim(QRYSD2->B1_GRUPO)+" - "+AllTrim(QRYSD2->BM_DESC), oFont10N,2930/*largura*/,50/*altura*/,,0,0)
			nLin+=50
		EndIf

		nCol1 := 050
		nCol2 := 552
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, AllTrim(QRYSD2->D2_COD)+" - "+AllTrim(QRYSD2->B1_DESC), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

		nCol1 := nCol2
		nCol2 := 824
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSD2->QTD, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1096
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(nVlBrt, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1368
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(nVlDes, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1640
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(nVlAcr, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1912
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSD2->ICM, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 2184
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSD2->LQD, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 2456
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSD2->CST, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 2728
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform((QRYSD2->LQD-QRYSD2->CST), "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 3000
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(nVlPmd, "@E 999,999,999,999.999"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nLin+=50

		nTotQtd += QRYSD2->QTD
		nTotBrt += nVlBrt
		nTotDes += nVlDes
		nTotAcr += nVlAcr
		nTotIcm += QRYSD2->ICM
		nTotLqd += QRYSD2->LQD
		nTotCst += QRYSD2->CST
		nTotLcr += (QRYSD2->LQD - QRYSD2->CST)

		QRYSD2->(DbSkip())

	EndDo

	ImpTotGrp(cGrupo)

	nLin+=100
	oPrint:Box(nLin,050,nLin+50,3000)
	nCol1 := 050
	nCol2 := 552
	oPrint:SayAlign(nLin+10, nCol1+10, "Total Geral", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 824
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotQtdGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1096
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotBrtGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1368
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotDesGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1640
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotAcrGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1912
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotIcmGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2184
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotLqdGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2456
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotCstGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2728
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotLcrGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nLin+=50

	fRodape()

	//// tela de impressão do relatório
	//DEFINE MSDIALOG oDlgImp TITLE "Tela de Impressão" FROM 0,0 TO 200,270 PIXEL
	//DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
	//@ 000, 000 BITMAP oBmp RESNAME "LOGIN" oF oDlgImp SIZE 30, 120 NOBORDER WHEN .F. PIXEL
	//@ 003, 040 SAY "Venda de Produtos por Grupo" FONT oBold PIXEL
	//@ 014, 030 TO 16 ,500 LABEL '' OF oDlgImp  PIXEL
	//@ 030, 040 BUTTON "Configurar" 	SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Setup()
	//@ 030, 090 BUTTON "Imprimir"   	SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Print()
	//@ 050, 040 BUTTON "Visualizar"  SIZE 40,13 PIXEL OF oDlgImp ACTION oPrint:Preview()
	//@ 080, 090 BUTTON "Sair"       SIZE 40,13 PIXEL OF oDlgImp ACTION oDlgImp:End()
	//ACTIVATE MSDIALOG oDlgImp CENTER

	QRYSD2->(DbCloseArea()) // fecha a área criada

	oPrint:Preview() //Visualiza antes de imprimir

    FreeObj(oPrint)
    oPrint := Nil

Return()

Static Function ImpTotGrp(cGrupo)

	oPrint:Box(nLin,050,nLin+50,3000)
	nCol1 := 050
	nCol2 := 552
	oPrint:SayAlign(nLin+10, nCol1+10, "Total do Grupo: "+cGrupo + " - "+ AllTrim(Posicione("SBM",1,xFilial("SBM")+cGrupo,"BM_DESC")), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 824
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotQtd, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1096
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotBrt, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1368
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotDes, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1640
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotAcr, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1912
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotIcm, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2184
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotLqd, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2456
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotCst, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 2728
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotLcr, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	//nCol1 := nCol2
	//nCol2 := 3000
	//oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSD2->PMD, "@E 999,999,999,999.999"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nTotQtdGer += nTotQtd
	nTotBrtGer += nTotBrt
	nTotDesGer += nTotDes
	nTotAcrGer += nTotAcr
	nTotIcmGer += nTotIcm
	nTotLqdGer += nTotLqd
	nTotCstGer += nTotCst
	nTotLcrGer += nTotLcr

	nTotQtd := 0
	nTotBrt := 0
	nTotDes := 0
	nTotAcr := 0
	nTotIcm := 0
	nTotLqd := 0
	nTotCst := 0
	nTotLcr := 0

Return

/*/{Protheus.doc} NovaPagina
Função que cria uma nova página

@type function
@version 12.1.33
@author Pablo Nunes
@since 11/04/2022
/*/
Static Function NovaPagina()  // função que cria uma nova página montando o cabeçalho

	oPrint:endPage()
	nLin := 50
	nPagina += 1
	fCabecalho()

Return()

