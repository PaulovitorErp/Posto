#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#INCLUDE "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

/*/{Protheus.doc} TRETR023
Relatório Detalhado de Consumo e Abastecimento de Veículo

@author Pablo Nunes
@since 08/07/2023
/*/
User Function TRETR023()

	Local lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV -> .T. esta executando de um PDV / .F. esta executanto da retaguarda

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
	Private oFont11N	:= TFONT():New('Arial',,11,,.T.,,,,.F.,.F.	) //Fonte 11 Negrito
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
	Private cArquivo	:= "TRETR023_"+DTOS(Date())+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)
	Private oPrint	 	:= Nil
	Private oBrush		:= TBrush():New(,CLR_HGRAY )
	Private nPagina		:= 1
	Private aPosArray   := {"L1_FILIAL","L1_PLACA","L1_CLIENTE","L1_LOJA","A1_NOME","L1_EMISNF","L1_DOC","L1_SERIE","D2_COD","B1_DESC","L1_ODOMETR","QTD","BRT","DES","ACR","ICM","LQD","CST","PMD"}

	Private cPerg		:= "TRETR023"

	If !fValidPerg()
		Return
	EndIf

	oPrint := FwMSPrinter():New(cArquivo,IMP_PDF,.T.,,.T.,,@oPrint,,.T.,.F.)
	oPrint:SetDevice(IMP_PDF)
	oPrint:SetResolution(72)
	oPrint:SetPortrait() // ou SetLandscape() //Define a orientacao da impressao como retrato
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(0,0,0,0)
	oPrint:Setup() //Tela de configurações

	If !lSrvPDV //processando no back-office...
		Processa({|| fCorpoRel()}, "Aguarde...", "Carregando relatório...", .T.)
	Else //no PDV, necessário conectar na retaguarda para pegar os dados...
		Processa({|| fCorpRPDV()}, "Aguarde...", "Carregando relatório...", .T.)
	EndIf

Return

/*/{Protheus.doc} fValidPerg
Perguntas SX1
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fValidPerg()

	Local aMvPar
	Local nMv := 0
	Local cParRel := AllTrim(SM0->M0_CODIGO)+AllTrim(SM0->M0_CODFIL)+cPerg
	Local aParamBox := {}
	Local lRet := .F.
	Local aParam := {STOD(""),STOD(""),space(TamSX3("DA3_FILIAL")[1]),Replicate("Z",TamSX3("DA3_FILIAL")[1]),1,space(TamSX3("L1_PLACA")[1])}

	aAdd(aParamBox,{1,"Período de ",aParam[1],"",'.T.',"",'.T.',50,.T.})
	aAdd(aParamBox,{1,"Período até",aParam[2],"",'.T.',"",'.T.',50,.T.})
	aAdd(aParamBox,{1,"Filial de ",aParam[3],"",'',"SM0",'.T.',0,.F.})
	aAdd(aParamBox,{1,"Filial até",aParam[4],"",'',"SM0",'.T.',0,.F.})
	aAdd(aParamBox,{2,"Desconsidera Devoluções",aParam[5],{"1=Não","2=Sim"},40,"",.F.})
	aAdd(aParamBox,{1,"Placa",aParam[6],"@!R NNN-9N99"/*PesqPict("SL1","L1_PLACA")*/,'',"DA3",'.T.',0,.F.})

	//restauro os parametros usados anteriomente
	For nMv := 1 To Len(aParamBox)
		aParamBox[nMv][3] := &("MV_PAR"+STRZERO(nMv,2)) := aParam[nMv] := ParamLoad(cParRel,aParamBox,nMv,aParamBox[nMv][3])
	Next nMv

	If lRet := ParamBox(aParamBox,"Consumo e Abastecimento de Veículo",@aMvPar,,,,,,,cPerg)

		For nMv := 1 To Len( aMvPar )
			&("MV_PAR"+StrZero(nMv,2,0)) := aMvPar[nMv]
		Next nMv

		//salvo os novos parametros escolhidos
		ParamSave(cParRel,aParamBox,"1")

		//correção de um BUG na função parambox (retorno pode ser caracter e/ou numerico)
		MV_PAR05 := Val(cValToChar(MV_PAR05))

	EndIf

Return lRet

/*/{Protheus.doc} fCabecalho
Função que imprime o cabaçalho do relatório
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fCabecalho()

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin:=100

	//Impressao da Logo
	oPrint:Box(nLin,145,nLin+132,380)
	oPrint:SayBitmap(nLin+45, 170, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 180, 036) //proporção: (L)100 x (A)20

	//Dados da empresa e filtro relatório
	oPrint:Box(nLin,380,nLin+132,1850)
	oPrint:Say(nLin+30, 390, AllTrim(cNomeCom), oFont10N) //SM0->M0_NOMECOM
	oPrint:Say(nLin+70, 390, "Relatório Detalhado de Consumo e Abastecimento de Veículo", oFont11N)
	oPrint:Say(nLin+110, 390, "Período: "+DtoC(MV_PAR01)+" à "+DtoC(MV_PAR02), oFont10N)

	//Numero da página e data e hora
	oPrint:Box(nLin,1850,nLin+132,2300)
	oPrint:SayAlign(nLin+25, 1850, "Página: " + strzero(nPagina,3), oFont9N,450/*largura*/,50/*altura*/,,2,0)
	oPrint:SayAlign(nLin+65, 1850, DTOC(Date())+" "+Time(), oFont9N,450/*largura*/,50/*altura*/,,2,0)

	nLin+=180

	nCol1 := 145
	nCol2 := 365
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Data Emissão", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 645
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Documento", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1110
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Produto", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1360
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Quantidade", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1610
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Valor (R$)", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Odômetro", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 2300
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Empresa", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nLin+=50

Return

/*/{Protheus.doc} fRodape
Função para criar o rodapé do relatório
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fRodape()

	nLin:=2900

	oPrint:Line(nLin,150,nLin,2300)
	nLin+=20
	oPrint:Say(nLin, 1080, "Microsiga Protheus", oFont8N)
	nLin+=10
	oPrint:Line(nLin,150,nLin,2300)

Return

/*/{Protheus.doc} fCorpoRel
Função para preencher o relatório
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fCorpoRel()

	Local cQuery := ""
	Local cCliente := ""
	Local aSM0   := {}

	Private nTotQtd    := 0
	Private nTotVlr    := 0

	Private nTotQtdGer    := 0
	Private nTotVlrGer    := 0

	Private cNomeCom := ""

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

	If Select("QRYSL1") > 0
		QRYSL1->(DbCloseArea())
	EndIf

	cQuery := fRetQuery()

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery New Alias "QRYSL1" // Cria uma nova area com o resultado do query

	fCabecalho()

	While QRYSL1->(!EOF())

		If nLin > 2850
			fRodape()
			NovaPagina()
			nLin+=50
			ImpCliPla(nLin,cCliente,QRYSL1->L1_PLACA)
			nLin+=100
		EndIf

		If cCliente <> (QRYSL1->L1_CLIENTE+QRYSL1->L1_LOJA+" - "+AllTrim(QRYSL1->A1_NOME))
			If !Empty(cCliente)
				ImpTotCli(cCliente)
				nLin+=50
			EndIf
			cCliente := (QRYSL1->L1_CLIENTE+QRYSL1->L1_LOJA+" - "+AllTrim(QRYSL1->A1_NOME))
			nLin+=50
			ImpCliPla(nLin,cCliente,QRYSL1->L1_PLACA)
			nLin+=100
		EndIf

		If nLin > 2850
			fRodape()
			NovaPagina()
			nLin+=50
			ImpCliPla(nLin,cCliente,QRYSL1->L1_PLACA)
			nLin+=100
		EndIf

		nCol1 := 145
		nCol2 := 365
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, DtoC(StoD(QRYSL1->L1_EMISNF)), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

		nCol1 := nCol2
		nCol2 := 645
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, (QRYSL1->L1_DOC+" / "+QRYSL1->L1_SERIE), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

		nCol1 := nCol2
		nCol2 := 1110
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, SubStr(/*AllTrim(QRYSL1->D2_COD)+" - "+*/AllTrim(QRYSL1->B1_DESC),1,35), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

		nCol1 := nCol2
		nCol2 := 1360
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSL1->QTD, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1610
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSL1->LQD, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1860
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(QRYSL1->L1_ODOMETR, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 2300
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, SubStr(AllTrim(QRYSL1->L1_FILIAL)+" - "+AllTrim(FwFilialName(,QRYSL1->L1_FILIAL,1)),1,35), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

		nLin+=50

		nTotQtd += QRYSL1->QTD
		nTotVlr += QRYSL1->LQD

		QRYSL1->(DbSkip())

	EndDo

	QRYSL1->(DbCloseArea()) // fecha a área criada

	ImpTotCli(cCliente)

	nLin+=100
	oPrint:Box(nLin,145,nLin+50,2300)
	nCol1 := 145
	nCol2 := 1110
	oPrint:SayAlign(nLin+10, nCol1+10, "Total Geral", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1360
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotQtdGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1610
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotVlrGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nLin+=50

	fRodape()

	oPrint:Preview() //Visualiza antes de imprimir

	FreeObj(oPrint)
	oPrint := Nil

Return

/*/{Protheus.doc} ImpTotCli
Imprime total por cliente
@author Pablo Nunes
@since 07/07/2023
@param cCliente, character, dados do cliente
/*/
Static Function ImpTotCli(cCliente)

	oPrint:Box(nLin,145,nLin+50,2300)
	nCol1 := 145
	nCol2 := 1110
	oPrint:SayAlign(nLin+10, nCol1+10, "Total do Cliente: "+cCliente, oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1360
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotQtd, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1610
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotVlr, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nTotQtdGer += nTotQtd
	nTotVlrGer += nTotVlr

	nTotQtd := 0
	nTotVlr := 0

Return

/*/{Protheus.doc} NovaPagina
Função que cria uma nova página
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function NovaPagina()  // função que cria uma nova página montando o cabeçalho
	oPrint:endPage()
	nLin := 50
	nPagina += 1
	fCabecalho()
Return

/*/{Protheus.doc} ImpCliPla
Imprime a linha com os dados do cliente e placa
@author Pablo Nunes
@since 07/07/2023
@param nLin, numeric, linha a ser impressa
@param cCliente, character, dados do cliente
@param cPlaca, character, placa
/*/
Static Function ImpCliPla(nLin,cCliente,cPlaca)
	oPrint:Box(nLin,145,nLin+080,2300)
	oPrint:SayAlign(nLin+10, 155, "Cliente: "+cCliente,oFont10N,2280/*largura*/,50/*altura*/,,0,0)
	oPrint:SayAlign(nLin+40, 155, "Placa: "+Transform(cPlaca,"@!R NNN-9N99"), oFont10N,2280/*largura*/,50/*altura*/,,0,0)
Return

/*/{Protheus.doc} fRetQuery
Monta a query de busca
@author Pablo Nunes
@since 07/07/2023
@return character, string SQL de busca das informações
/*/
Static Function fRetQuery()
	Local cQuery := ""
	Local cSGBD	:= AllTrim(Upper(TcGetDb())) // -- Banco de dados atulizado (Para embientes TOP) 			 	

	cQuery += "SELECT L1_FILIAL, L1_PLACA, L1_CLIENTE, L1_LOJA, A1_NOME, L1_EMISNF, L1_DOC, L1_SERIE, D2_COD, B1_DESC, L1_ODOMETR, " + CRLF

	//valores das vendas
	cQuery += " SUM(D2_QUANT) AS QTD, " + CRLF
	cQuery += " SUM(D2_VALBRUT) AS BRT, " + CRLF //-> D2_QUANT * D2_PRUNIT
	cQuery += " SUM(D2_DESCON) AS DES, " + CRLF
	cQuery += " 0 AS ACR, " + CRLF
	cQuery += " SUM(D2_ICMSRET) AS ICM, " + CRLF
	cQuery += " SUM(D2_TOTAL) AS LQD, " + CRLF
	cQuery += " SUM(D2_CUSTO1) AS CST, " + CRLF
	cQuery += " AVG(D2_PRCVEN) AS PMD " + CRLF

	cQuery += " FROM "+RetSqlName("SL1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL1 " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SL2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SL2 ON (SL1.D_E_L_E_T_ = ' ' AND SL1.L1_FILIAL = SL2.L2_FILIAL AND SL1.L1_NUM = SL2.L2_NUM AND SL1.L1_DOC = SL2.L2_DOC AND SL1.L1_SERIE = SL2.L2_SERIE) " + CRLF
	cQuery += " INNER JOIN "+RetSQLName("SD2")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SD2 ON (SD2.D_E_L_E_T_ = ' ' AND SD2.D2_FILIAL = SL2.L2_FILIAL AND SD2.D2_ITEM = SL2.L2_ITEM AND SD2.D2_COD = SL2.L2_PRODUTO AND SD2.D2_DOC = SL2.L2_DOC AND SD2.D2_SERIE = SL2.L2_SERIE)  " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SB1 ON (SB1.D_E_L_E_T_ = ' ' AND SB1.B1_FILIAL = '"+xFilial("SB1")+"' AND SB1.B1_COD = SD2.D2_COD) " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SA1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SA1 ON (SA1.D_E_L_E_T_ = ' ' AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' AND SA1.A1_COD = SL1.L1_CLIENTE AND SA1.A1_LOJA = SL1.L1_LOJA) " + CRLF

	cQuery += " WHERE SL1.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += " AND SL1.L1_EMISNF >= '"+DTOS(MV_PAR01)+"' AND SL1.L1_EMISNF <= '"+DTOS(MV_PAR02)+"' " + CRLF
	cQuery += " AND SL1.L1_FILIAL >= '"+MV_PAR03+"' AND SL1.L1_FILIAL <= '"+MV_PAR04+"' " + CRLF
	If MV_PAR05 == 2 //Desconsidera Devoluções => 2-SIM
		cQuery += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("SD1")+" "+iif("ORACLE"$cSGBD,"","(NOLOCK)")+" SD1 " + CRLF
		cQuery += " WHERE SD1.D_E_L_E_T_ = ' ' " + CRLF
		cQuery += " AND SD1.D1_FILORI = SD2.D2_FILIAL " + CRLF
		cQuery += " AND SD1.D1_NFORI = SD2.D2_DOC " + CRLF
		cQuery += " AND SD1.D1_ITEMORI = SD2.D2_ITEM " + CRLF
		cQuery += " AND SD1.D1_SERIORI = SD2.D2_SERIE " + CRLF
		cQuery += " AND SD1.D1_TIPO = 'D' " + CRLF
		cQuery += " ) " + CRLF
	EndIf
	cQuery += " AND SL1.L1_PLACA = '"+MV_PAR06+"' " + CRLF

	cQuery += " GROUP BY L1_FILIAL, L1_PLACA, L1_CLIENTE, L1_LOJA, A1_NOME, L1_EMISNF, L1_DOC, L1_SERIE, D2_COD, B1_DESC, L1_ODOMETR " + CRLF
	cQuery += " ORDER BY L1_PLACA, L1_CLIENTE, L1_LOJA, L1_FILIAL, L1_EMISNF " + CRLF

Return cQuery

/*/{Protheus.doc} fCorpRPDV
Função para preencher o relatório (no PDV)
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fCorpRPDV()

	Local cCliente := ""
	Local aSM0   := {}
	Local nX := 0

	Private nTotQtd    := 0
	Private nTotVlr    := 0

	Private nTotQtdGer    := 0
	Private nTotVlrGer    := 0

	Private cNomeCom := ""
	Private aDados := {}

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

	aDados := fRetArray()

    If Len(aDados) <= 0
        FreeObj(oPrint)
        oPrint := Nil
        Return
    EndIf

	fCabecalho()

	For nX := 1 to Len(aDados)

		If nLin > 2850
			fRodape()
			NovaPagina()
			nLin+=50
			ImpCliPla(nLin,cCliente,aDados[nX][fRetPosCol("L1_PLACA")])
			nLin+=100
		EndIf

		If cCliente <> (aDados[nX][fRetPosCol("L1_CLIENTE")]+aDados[nX][fRetPosCol("L1_LOJA")]+" - "+AllTrim(aDados[nX][fRetPosCol("A1_NOME")]))
			If !Empty(cCliente)
				ImpTotCli(cCliente)
				nLin+=50
			EndIf
			cCliente := (aDados[nX][fRetPosCol("L1_CLIENTE")]+aDados[nX][fRetPosCol("L1_LOJA")]+" - "+AllTrim(aDados[nX][fRetPosCol("A1_NOME")]))
			nLin+=50
			ImpCliPla(nLin,cCliente,aDados[nX][fRetPosCol("L1_PLACA")])
			nLin+=100
		EndIf

		If nLin > 2850
			fRodape()
			NovaPagina()
			nLin+=50
			ImpCliPla(nLin,cCliente,aDados[nX][fRetPosCol("L1_PLACA")])
			nLin+=100
		EndIf

		nCol1 := 145
		nCol2 := 365
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, DtoC(StoD(aDados[nX][fRetPosCol("L1_EMISNF")])), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

		nCol1 := nCol2
		nCol2 := 645
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, (aDados[nX][fRetPosCol("L1_DOC")]+" / "+aDados[nX][fRetPosCol("L1_SERIE")]), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

		nCol1 := nCol2
		nCol2 := 1110
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, SubStr(/*AllTrim(aDados[nX][fRetPosCol("D2_COD")])+" - "+*/AllTrim(aDados[nX][fRetPosCol("B1_DESC")]),1,35), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

		nCol1 := nCol2
		nCol2 := 1360
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(aDados[nX][fRetPosCol("QTD")], "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1610
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(aDados[nX][fRetPosCol("LQD")], "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 1860
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, Transform(aDados[nX][fRetPosCol("L1_ODOMETR")], "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

		nCol1 := nCol2
		nCol2 := 2300
		oPrint:Box(nLin,nCol1,nLin+50,nCol2)
		oPrint:SayAlign(nLin+10, nCol1+10, SubStr(AllTrim(aDados[nX][fRetPosCol("L1_FILIAL")])+" - "+AllTrim(FwFilialName(,aDados[nX][fRetPosCol("L1_FILIAL")],1)),1,35), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

		nLin+=50

		nTotQtd += aDados[nX][fRetPosCol("QTD")]
		nTotVlr += aDados[nX][fRetPosCol("LQD")]

	Next nX

	ImpTotCli(cCliente)

	nLin+=100
	oPrint:Box(nLin,145,nLin+50,2300)
	nCol1 := 145
	nCol2 := 1110
	oPrint:SayAlign(nLin+10, nCol1+10, "Total Geral", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1360
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotQtdGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nCol1 := nCol2
	nCol2 := 1610
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nTotVlrGer, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)

	nLin+=50

	fRodape()

	oPrint:Preview() //Visualiza antes de imprimir

	FreeObj(oPrint)
	oPrint := Nil

Return

/*/{Protheus.doc} fRetPosCol
Retorna a posição de uma coluna pelo nome...
@author Pablo Nunes
@since 07/07/2023
@param cCol, character, nome da coluna
@return numeric, posição da coluna
/*/
Static Function fRetPosCol(cCol)
Return aScan(aPosArray,{|x| alltrim(x)==cCol})

/*/{Protheus.doc} fRetArray
Faz a chamada da execusão remota da busca dos dados da placa
@author Pablo Nunes
@since 07/07/2023
@return array, registros encontrados
/*/
Static Function fRetArray()
	Local aParam := {}
	Local xRet := Nil
	Local aRet := {}

	CursorArrow()
	CursorWait()

	aParam := {"U_TRETR23A"}
	aParam := {"FindFunction",aParam}
	xRet := Nil
	If STBRemoteExecute("_EXEC_RET",aParam,,,@xRet) //verifica se a função existe na retaguarda
		If ValType(xRet)=="L" .and. xRet
			aParam := {{MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05,MV_PAR06}}
			aParam := {"U_TRETR23A",aParam}
			xRet := Nil
			If STBRemoteExecute("_EXEC_RET",aParam,,,@xRet) //retorna os registros do relatório
				If ValType(xRet)=="A" .and. Len(xRet) >= 0
					aRet := xRet
				Else
                    alert("Não foram encontrados movimentos para essa placa "+Transform(MV_PAR06,"@!R NNN-9N99")+"...")
				EndIf
			Else
				alert("Ocorreu falha na consulta no Back-Office!")
			EndIf
		Else
			alert("Rotina TRETR23A não encontrada no Back-Office!")
		EndIf
	Else
		alert("Ocorreu falha na consulta no Back-Office!")
	EndIf

	CursorArrow()

Return aRet

/*/{Protheus.doc} TRETR23A
Busca os dados de determinada placa na retaguarda
@author Pablo Nunes
@since 07/07/2023
@param aParam, array, lista de parametros da busca
@return array, registros encontrados
/*/
User Function TRETR23A(aMvPar)
	Local aArea := GetArea()
    Local aDados := {}
	Local aReg := {}
    Local nX := 0
	Local aPosArray := {"L1_FILIAL","L1_PLACA","L1_CLIENTE","L1_LOJA","A1_NOME","L1_EMISNF","L1_DOC","L1_SERIE","D2_COD","B1_DESC","L1_ODOMETR","QTD","BRT","DES","ACR","ICM","LQD","CST","PMD"}

	MV_PAR01 := aMvPar[1]
	MV_PAR02 := aMvPar[2]
	MV_PAR03 := aMvPar[3]
	MV_PAR04 := aMvPar[4]
	MV_PAR05 := aMvPar[5]
	MV_PAR06 := aMvPar[6]

	cQuery := fRetQuery()

	If Select("QRYSL1") > 0
		QRYSL1->(DbCloseArea())
	EndIf

	cQuery := ChangeQuery(cQuery)
	TcQuery cQuery New Alias "QRYSL1" // Cria uma nova area com o resultado do query

	While QRYSL1->(!EOF())
		aReg := {}
		For nX:=1 to Len(aPosArray)
			aadd(aReg,&("QRYSL1->"+aPosArray[nX]))
		Next nX
		aadd(aDados,aReg)
		QRYSL1->(DbSkip())
	EndDo

	QRYSL1->(DbCloseArea())

    RestArea(aArea)

Return aDados
