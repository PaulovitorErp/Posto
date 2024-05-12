#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7099
O Ponto de Entrada LJ7099, permite retornar uma string no formato XML com informações referentes a um Produto Especifico.
Somente informações do produto específico devem ser retornados, ou seja, qualquer informação adicional pode causar inconsistência do documento eletrônico.

@author Anderson Machado
@since 29/12/2016
@version 1.0
@return cXML, Caracter, String no formato XML contendo as informações do produto específico.
@type function
@obs
O Ponto de Entrada não recebe nenhum parâmetro, porém no momento da execução, o registro estará posicionado no item em questão (SL2);
Como o registro está posicionado no momento da execução do ponto de entrada, é IMPORTANTE que as funções GetArea e RestArea sejam utilizadas;
A string retornada não pode conter caracteres de quebra de linhas (exemplo: CRLF);
A informação do produto específico deve ser retornada por item, ou seja, nesse caso o ponto de entrada será executado para cada item;
Somente um Produto Específico pode ser informado por item;
Para saber quais informações devem ser retornadas, recomendamos a leitura das Normas Técnicas em vigor;

/*/
User Function TPDVP003()

	Local cXML := "", cProdANP := "", cUFCons := ""
	Local aProd	 := {}
	Local aComb  := {}
	Local aGetMvTSS	:= {}
	Local aUF := {}
	Local nPosAux := 0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return cXML
	EndIf

	SB1->( DbSetOrder(1) ) //B1_FILIAL+B1_COD
	SB5->( DbSetOrder(1) ) //B5_FILIAL+B5_COD

	SB1->(DbSeek(xFilial("SB1")+SL2->L2_PRODUTO))
	SB5->(DbSeek(xFilial("SB5")+SL2->L2_PRODUTO))

	cProdANP := IIF(SB1->(FieldPos("B1_CODSIMP")) > 0,SB1->B1_CODSIMP,"")
	If SB5->(FieldPos("B5_CODANP")) > 0 .and. Empty(cProdANP)
		cProdANP := Posicione("SB5",1,xFilial("SB5")+SL2->L2_PRODUTO,"B5_CODANP")
	EndIf

	//conout("LJ7099 - TPDVP003 - Orc: " + SL1->L1_NUM + " / Cod ANP: " + cProdANP )
	LjGrvLog( SL1->L1_NUM, "LJ7099 - TPDVP003 - Orc: " + SL1->L1_NUM + " / Produto: " + SL2->L2_PRODUTO + " / Cod ANP: " + cProdANP)
	If Empty(cProdANP)
		Return cXML
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Preenchimento do Array de UF                                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aadd(aUF,{"RO","11"})
	aadd(aUF,{"AC","12"})
	aadd(aUF,{"AM","13"})
	aadd(aUF,{"RR","14"})
	aadd(aUF,{"PA","15"})
	aadd(aUF,{"AP","16"})
	aadd(aUF,{"TO","17"})
	aadd(aUF,{"MA","21"})
	aadd(aUF,{"PI","22"})
	aadd(aUF,{"CE","23"})
	aadd(aUF,{"RN","24"})
	aadd(aUF,{"PB","25"})
	aadd(aUF,{"PE","26"})
	aadd(aUF,{"AL","27"})
	aadd(aUF,{"MG","31"})
	aadd(aUF,{"ES","32"})
	aadd(aUF,{"RJ","33"})
	aadd(aUF,{"SP","35"})
	aadd(aUF,{"PR","41"})
	aadd(aUF,{"SC","42"})
	aadd(aUF,{"RS","43"})
	aadd(aUF,{"MS","50"})
	aadd(aUF,{"MT","51"})
	aadd(aUF,{"GO","52"})
	aadd(aUF,{"DF","53"})
	aadd(aUF,{"SE","28"})
	aadd(aUF,{"BA","29"})
	aadd(aUF,{"EX","99"})

	//Obtemos a VERSAO da NFC-e do TSS
	aGetMvTSS := LjGetMVTSS("MV_VERNFCE")
	If aGetMvTSS[1]
		cVerAmb := AllTrim( aGetMvTSS[2] )
	EndIf

	cTexto := "LJ7099 - TPDVP003 - DATA: "+ DToC(Date()) +" - HORA: " + Time() + CRLF
	cTexto += CRLF
	cTexto += "cVerAmb: "
	cTexto += cVerAmb + CRLF

	aadd(aProd,	{Val(SL2->L2_ITEM),;
		SL2->L2_PRODUTO,;
		IIf(Val(SB1->B1_CODBAR)==0,"",StrZero(Val(SB1->B1_CODBAR),Len(Alltrim(SB1->B1_CODBAR)),0)),;
		SB1->B1_DESC,;
		SB1->B1_POSIPI,;//Retirada validação do parametro MV_CAPPROD, de acordo com a NT2014/004 não é mais possível informar o capítulo do NCM
		SB1->B1_EX_NCM,;
		SL2->L2_CF,;
		SB1->B1_UM,;
		SL2->L2_QUANT,;
		SL2->L2_VLRITEM,;
		SB1->B1_UM,;
		SL2->L2_QUANT,;
		SL2->L2_VALFRE,;
		SL2->L2_SEGURO,;
		0,;
		0,;// O valor unitario sera obtido pela divisao do valor do produto pela quantidade comercial de acordo com o  Manual do Contribuinte 6.00 realizado na tag <vUnCom>(ConvType(aProd[10]/aProd[09],21,8))
		cProdANP,; //codigo ANP do combustivel
		IIF(SB1->(FieldPos("B1_CODIF"))<>0,SB1->B1_CODIF,""),; //CODIF
		SL2->L2_LOTECTL,;//Controle de Lote
		SL2->L2_NLOTE,;//Numero do Lote
		0,;//Outras despesas + PISST + COFINSST  (Inclusão do valor de PIS ST e COFINS ST na tag vOutros - NT 2011/004).E devolução com IPI. (Nota de compl.Ipi de uma devolução de compra(MV_IPIDEV=F) leva o IPI em voutros)
		0,;//% Redução da Base de Cálculo
		"cCST",;//Cód. Situação Tributária
		"0",;// Tipo de agregação de valor ao total do documento
		"",;//Informacoes adicionais do produto(B5_DESCNFE)
		0,;
		SL2->L2_TES,;
		IIF(SB5->(FieldPos("B5_PROTCON"))<>0,SB5->B5_PROTCON,""),; //Campo criado para informar protocolo ou convenio ICMS
		0,; //IIf(SubStr(SM0->M0_CODMUN,1,2) == "35" .And. cTpPessoa == "EP" .And. nDescIcm > 0, nDescIcm,0),;
		0,;   //aProd[30] - Total imposto carga tributária.
		0,;			//aProd[31] - Desconto Zona Franca PIS
		0,;			//aProd[32] - Desconto Zona Franca CONFINS
		0,;		//aProd[33] - Percentual de ICMS
		"",;  //aProd[34]
		0,;   //aProd[35] - Total carga tributária Federal
		0,;   //aProd[36] - Total carga tributária Estadual
		0,;   //aProd[37] - Total carga tributária Municipal
		"",;	 //aProd[38]
		"",;	 //aProd[39]
		"999",; //aProd[40]
		IIF(SB1->(FieldPos("B1_CEST"))<>0,SB1->B1_CEST,""),; //aProd[41] NT2015/003
		"",; //aprod[42] apenas na entrada é utilizado para montar a tag indPres=1 para nota de devolução de venda
		0,; //aprod[43]  Valor do FECP.
		"",; //aprod[44]  Código de Benefício Fiscal na UF aplicado ao item .
		IIf(SB5->(ColumnPos("B5_2CODBAR")) > 0,IIf(Val(SB5->B5_2CODBAR)==0,"",StrZero(Val(SB5->B5_2CODBAR),Len(Alltrim(SB5->B5_2CODBAR)),0)),""),;//aprod[45]  Código de barra da segunda unidade de medida.
		IIf(SB1->(ColumnPos("B1_CODGTIN")) > 0,SB1->B1_CODGTIN,""),;
		})

	aComb := GeraCD6NFe(2,aProd)

	If Len(aComb[01]) > 0  .And. !Empty(aComb[01][01])
		cXML += '<comb>'
		cXML += '<cProdANP>'+ConvType(aComb[01][01])+'</cProdANP>'
		If cVeramb >= "3.10" .and. Len(aComb[01]) > 4
			cXML += NfeTag('<mixGN>',ConvType(aComb[01][08],7,4))
		EndIf

		If	cVeramb >= "4.00" .and. Len(aComb[01]) > 4
			cXML += '<descANP>'+ConvType(aComb[01][14])+'</descANP>'
			cXML += NfeTag('<pGLP>',ConvType(aComb[01][15],15,4))
			cXML += NfeTag('<pGNn>',ConvType(aComb[01][16],15,4))
			cXML += NfeTag('<pGNi>',ConvType(aComb[01][17],15,4))
			cXML += NfeTag('<vPart>',ConvType(aComb[01][18],13,2))
		Endif

		cXML += NfeTag('<codif>',ConvType(aComb[01][02]))

		cXML += NfeTag('<qTemp>',ConvType(aComb[01][03],12,4))
		//cXML += '<ICMSCONS>'
		cXML += '<UFCons>'+aComb[01][04]+'</UFCons>'
		//cXML += '</ICMSCONS>'
		If Len(aComb[01]) > 4 .and. !Empty(aComb[01][05])
			cXML += '<CIDE>'
			cXML += NfeTag('<qBCProd>',ConvType(aComb[01][05],16,2))
			cXML += NfeTag('<vAliqProd>',ConvType(aComb[01][06],15,4))
			cXML += NfeTag('<vCIDE>',ConvType(aComb[01][07],15,2))
			cXML += '</CIDE>'
		Endif
		/*NT 2015/002
		379 - Rejeição: Grupo de Encerrante na NF-e (modelo 55) para CFOP diferente
		de venda de combustível para consumidor final (CFOP=5.656, 5.667).
		*/
		If Len(aComb[01]) > 4 .and. !Empty(aComb[01][09])
			cXML += '<encerrante>'
			cXML += '<nBico>'+ConvType(aComb[01][09])+'</nBico>'
			cXML += NfeTag('<nBomba>',ConvType(aComb[01][10]))
			cXML += '<nTanque>'+ConvType(aComb[01][11])+'</nTanque>'
			cXML += '<vEncIni>'+ConvType(aComb[01][12],15,3)+'</vEncIni>'
			cXML += '<vEncFin>'+ConvType(aComb[01][13],15,3)+'</vEncFin>'
			cXML += '</encerrante>'
		EndIf
		//NT 001.2023
		If Len(aComb[01]) > 23
			cXML += NfeTag('<pBio>', Iif(aComb[01][24] < 100, ConvType(aComb[01][24],15,4), ConvType(aComb[01][24])))
			If !Empty(aComb[01][25])
				cXML += '<origComb>'
				cXML += '<indImport>' + aComb[01][25] + '</indImport>'
				nPosAux := aScan(aUF,{|x| x[1] == aComb[01][26]})
				if nPosAux > 0
					cXML += '<cUFOrig>' + ConvType(aUF[nPosAux][02]) + '</cUFOrig>'
				endif
				cXML += '<pOrig>' + Iif(aComb[01][27] < 100, ConvType(aComb[01][27],15,4), ConvType(aComb[01][27])) + '</pOrig>'
				cXML += '</origComb>'
			EndIf
		EndIf
		cXML += '</comb>'

	ElseIf !Empty(aProd[01][17])
		cUFCons := GetMv("MV_ESTADO") //SM0->M0_ESTCOB //Posicione("SA1",1,xFilial("SA1")+SL1->L1_CLIENTE+SL1->L1_LOJA,"A1_EST") //-- Venda Presencial
		cXML += '<comb>'
		cXML += '<cProdANP>'+ConvType(aProd[01][17])+'</cProdANP>'
		If cVeramb >= "4.00"
			cDescANP := Posicione("SZO",1,xFilial("SZO")+cProdANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB
			cXML += '<descANP>'+ConvType(cDescANP)+'</descANP>'
		EndIf
		//cXML += NfeTag('<codif>',ConvType(aProd[01][18]))
		cXML += "<UFCons>"+cUFCons+"</UFCons>"
		cXML += '</comb>'
		//Tratamento da CIDE - Ver com a Average
		//Tratamento de ICMS-ST - Ver com fisco
	EndIf

	//IMPORTANTE: As Tags são case sensitive ("sensível a maiúsculas e minúsculas".)
	//ConOut("LJ7099 - Orc: " + SL1->L1_NUM + " Cod ANP: " + cProdANP + " TAG COMBUSTIVEL PARA LUBRIFICANTE" )
Return cXML

//
//--- NFC-e e NF-e Tags de Combustivel
//
Static Function GeraCD6NFe(nTp,aProd)

	Local aArea := GetArea()
	Local aAreaSD2 := SD2->( GetArea() )

	Local cProdANP := "", cDescANP := "", cGrupo := ""
	Local aComb := {}, aCD6 := {}
	Local lInc  := .F.
	Local ix    := 0

	//Alimentação do Grupo de Repasse
	Local nBRICMSO 	:= 0
	Local nICMRETO	:= 0
	Local nBRICMSD 	:= 0
	Local nICMRETD	:= 0

	DEFAULT nTp := 1	//-- Padrao
	DEFAULT aProd := {}

	//-- Inicializa aComb se aProd contiver itens
	For ix:=1 to len(aProd)
		aadd(aComb,{})
	Next ix

	//-- Verifica se existe CD6 para os Itens
	cGrupo := AllTrim( GetMV("MV_COMBUS") )

	SD2->( DbSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	SB1->( DbSetOrder(1) ) //B1_FILIAL+B1_COD
	SB5->( DbSetOrder(1) ) //B5_FILIAL+B5_COD
	CD6->( DbSetOrder(1) ) //CD6_FILIAL+CD6_TPMOV+CD6_SERIE+CD6_DOC+CD6_CLIFOR+CD6_LOJA+CD6_ITEM+CD6_COD+CD6_PLACA+CD6_TANQUE

	SB1->( DbSeek( xFilial("SB1") + SL2->L2_PRODUTO ) )

	//-- Consultar tabela de código ANP
	cProdANP := IIF(SB1->(FieldPos("B1_CODSIMP")) > 0,SB1->B1_CODSIMP,"")
	If SB5->(FieldPos("B5_CODANP")) > 0 .and. Empty(cProdANP)
		cProdANP := Posicione("SB5",1,xFilial("SB5")+SL2->L2_PRODUTO,"B5_CODANP")
	EndIf
	cDescANP := Posicione("SZO",1,xFilial("SZO")+cProdANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB

	//-- Verifica se precisa da TAG Combustivel
	If Empty(cProdANP) .or. !AllTrim(SB1->B1_GRUPO) $ cGrupo

	Else

		//Alimentação do Grupo de Repasse
		If SD2->(FieldPos("D2_BRICMSO")) > 0
			If SD2->(DbSeek(xFilial("SD2")+SL1->(L1_DOC+L1_SERIE+L1_CLIENTE+L1_LOJA)+SL2->L2_PRODUTO+SL2->L2_ITEM))
				nBRICMSO 	:= SD2->D2_BRICMSO
				nICMRETO	:= SD2->D2_ICMRETO
				nBRICMSD 	:= SD2->D2_BRICMSD
				nICMRETD	:= SD2->D2_ICMRETD
			EndIf
		EndIf

		//CD6_FILIAL+CD6_TPMOV+CD6_SERIE+CD6_DOC+CD6_CLIFOR+CD6_LOJA+CD6_ITEM+CD6_COD+CD6_PLACA+CD6_TANQUE
		lInc := CD6->( DbSeek( xFilial("CD6") + "S" + SL1->L1_SERIE + SL1->L1_DOC + SL1->L1_CLIENTE + SL1->L1_LOJA + PadR(SL2->L2_ITEM,TamSx3("CD6_ITEM")[1]) + SL2->L2_PRODUTO ) )

		/*
		Rejeição
		378 - Grupo de Combustível sem a informação de Encerrante
		A regra de validação 378 se aplica somente para os códigos de produtos ANP (cProdANP) abaixo:
		*/
		cProdANP378 := ''
		cProdANP378 += '810101002/' // - ETANOL HIDRATADO ADITIVADO
		cProdANP378 += '810101001/' // - ETANOL HIDRATADO COMUM
		cProdANP378 += '220101005/' // - GÁS NATURAL VEICULAR
		cProdANP378 += '220101006/' // - GÁS NATURAL VEICULAR PADRÃO
		cProdANP378 += '320103001/' // - GASOLINA AUTOMOTIVA PADRÃO
		cProdANP378 += '320102002/' // - GASOLINA C ADITIVADA
		cProdANP378 += '320102001/' // - GASOLINA C COMUM
		cProdANP378 += '320102003/' // - GASOLINA C PREMIUM
		cProdANP378 += '820101033/' // - ÓLEO DIESEL B S10 - ADITIVADO
		cProdANP378 += '820101034/' // - ÓLEO DIESEL B S10 - COMUM
		cProdANP378 += '420106001/' // - ÓLEO DIESEL B S10 AMD 10
		cProdANP378 += '820101011/' // - ÓLEO DIESEL B S1800 Não Rodoviário - Aditivado
		cProdANP378 += '820101003/' // - ÓLEO DIESEL B S1800 Não Rodoviário - Comum
		cProdANP378 += '820101013/' // - ÓLEO DIESEL B S500 - ADITIVADO
		cProdANP378 += '820101012/' // - ÓLEO DIESEL B S500 - COMUM
		cProdANP378 += '420106002/' // - ÓLEO DIESEL B S500 AMD 10
		cProdANP378 += '420301004/' // - OLEO DIESEL DE REFERÊNCIA S300

		RecLock("CD6", !lInc)

		CD6->CD6_FILIAL := xFilial("CD6")
		CD6->CD6_TPMOV	:= "S"
		CD6->CD6_DOC	:= SL1->L1_DOC
		CD6->CD6_SERIE 	:= SL1->L1_SERIE
		CD6->CD6_ESPEC 	:= SL1->L1_ESPECIE
		CD6->CD6_CLIFOR	:= SL1->L1_CLIENTE
		CD6->CD6_LOJA  	:= SL1->L1_LOJA
		CD6->CD6_ITEM  	:= SL2->L2_ITEM
		CD6->CD6_COD   	:= SL2->L2_PRODUTO
		//	CD6->CD6_SEFAZ 	:= SL1->L1_KEYNFCE	(essa informação pelo menos em GO esta negando as notas!!!
		CD6->CD6_HORA  	:= SL1->L1_HORA
		CD6->CD6_CODANP	:= cProdANP
		if CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
			CD6->CD6_DESANP := cDescANP
		endif
		CD6->CD6_QTDE  	:= SL2->L2_QUANT
		CD6->CD6_UFCONS	:= GetMv("MV_ESTADO") //SM0->M0_ESTCOB	//-- Venda Presencial

		if !Empty(SL2->L2_MIDCOD)

			MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
			MID->(DbSeek(xFilial("MID") + SL2->L2_MIDCOD))

			CD6->CD6_TANQUE	:= MID->MID_CODTAN
			CD6->CD6_BICO  	:= Val(MID->MID_CODBIC)
			CD6->CD6_BOMBA 	:= Val(MID->MID_CODBOM)

			//NT 001.2023
			CD6->CD6_CODANP	:= MID->MID_CODANP
			if CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
				cDescANP := Posicione("SZO",1,xFilial("SZO")+MID->MID_CODANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB
				CD6->CD6_DESANP := cDescANP
			endif
			CD6->CD6_INDIMP := MID->MID_INDIMP
			CD6->CD6_UFORIG := MID->MID_UFORIG
			CD6->CD6_PORIG  := MID->MID_PORIG
			CD6->CD6_PBIO 	:= MID->MID_PBIO

			CD6->CD6_ENCINI	:= MID->MID_ENCINI
			CD6->CD6_ENCFIN	:= MID->MID_ENCFIN

		elseif (cProdANP $ cProdANP378) //-- envia os valores zerados

			CD6->CD6_TANQUE	:= Replicate("9",TamSx3("CD6_TANQUE")[1])
			CD6->CD6_BICO  	:= 999
			CD6->CD6_BOMBA 	:= 999

			CD6->CD6_ENCINI	:= 0
			CD6->CD6_ENCFIN	:= SL2->L2_QUANT

		endif

		CD6->( MsUnLock() )

		//-- Carrega dados na aComb
		If nTp == 2

			aadd( aCD6, {	CD6->CD6_CODANP,;
			CD6->CD6_SEFAZ,;
			CD6->CD6_QTAMB,;
			CD6->CD6_UFCONS,;
			CD6->CD6_BCCIDE,;
			CD6->CD6_VALIQ,;
			CD6->CD6_VCIDE,;
			IIf(CD6->(FieldPos("CD6_MIXGN")) > 0,CD6->CD6_MIXGN,""),;
			IIf(CD6->(FieldPos("CD6_BICO")) > 0,CD6->CD6_BICO,""),;
			IIf(CD6->(FieldPos("CD6_BOMBA")) > 0,CD6->CD6_BOMBA,""),;
			IIf(CD6->(FieldPos("CD6_TANQUE")) > 0,CD6->CD6_TANQUE,""),;
			IIf(CD6->(FieldPos("CD6_ENCINI")) > 0,CD6->CD6_ENCINI,""),;
			IIf(CD6->(FieldPos("CD6_ENCFIN")) > 0,CD6->CD6_ENCFIN,""),;
			IIf(CD6->(FieldPos("CD6_DESANP")) > 0,CD6->CD6_DESANP,""),; //--[14] - novo campo NF-e 4.00
			IIf(CD6->(FieldPos("CD6_PGLP")) > 0,CD6->CD6_PGLP,""),; //--[15] - novo campo NF-e 4.00
			IIf(CD6->(FieldPos("CD6_PGNN")) > 0,CD6->CD6_PGNN,""),; //--[16] - novo campo NF-e 4.00
			IIf(CD6->(FieldPos("CD6_PGNI")) > 0,CD6->CD6_PGNI,""),; //--[17] - novo campo NF-e 4.00
			IIf(CD6->(FieldPos("CD6_VPART")) > 0,CD6->CD6_VPART,""),; //--[18] - novo campo NF-e 4.00
			nBRICMSO,; //--[19] D2_BRICMSO -- Alimentação do Grupo de Repasse
			nICMRETO,; //--[20] D2_ICMRETO -- Alimentação do Grupo de Repasse
			nBRICMSD,; //--[21] D2_BRICMSD -- Alimentação do Grupo de Repasse
			nICMRETD,; //--[22] D2_ICMRETD -- Alimentação do Grupo de Repasse
			0,; //--[23] nAliqST <pST>
			IIf(CD6->(ColumnPos("CD6_PBIO")) > 0,CD6->CD6_PBIO,0),; // 24	Estava como o campo
			IIf(CD6->(ColumnPos("CD6_INDIMP")) > 0,CD6->CD6_INDIMP,""),; // 25
			IIf(CD6->(ColumnPos("CD6_UFORIG")) > 0,CD6->CD6_UFORIG,""),; // 26
			IIf(CD6->(ColumnPos("CD6_PORIG")) > 0,CD6->CD6_PORIG,0),; // 27
			CD6->CD6_QTDE,; //--[28]
			SL2->L2_PRODUTO,; //--[29]
			.F. } ) //--[30]

		EndIf

	EndIf

	//-- Deve-se preencher aqui devido a ordem "aProd" no NFSEFAZ
	If nTp == 2

		CD6->( DbSetOrder(1) ) //CD6_FILIAL+CD6_TPMOV+CD6_SERIE+CD6_DOC+CD6_CLIFOR+CD6_LOJA+CD6_ITEM+CD6_COD+CD6_PLACA+CD6_TANQUE
		For ix:=1 to Len(aProd)

			nTP := aScan(aCD6,{|x| !x[30] .and. x[29] == aProd[ix][02] .and. x[28] == aProd[ix][09] })
			If nTP > 0
				aComb[ix] := aClone(aCD6[nTp])
				aCD6[nTp][30] := .T.
			EndIf

		Next ix

	EndIf

	RestArea(aAreaSD2)
	RestArea(aArea)

Return aComb

//
// Converte em valor da STRING em NUMERICO
// Ex.: 1) RetValr("0230011",3) -> 230.011
//      2) RetValr("565654550",2) -> 5,656,545.50
//
Static Function RetValr(cStr,nDec)
	cStr := SubStr(cStr,1,(Len(cStr)-nDec)) + "." + SubStr(cStr,(Len(cStr)-nDec)+1,Len(cStr)-(Len(cStr)-nDec))
Return Val(cStr)

Static Function NfeTag(cTag,cConteudo)

Local cRetorno := ""
If (!Empty(AllTrim(cConteudo)) .And. IsAlpha(AllTrim(cConteudo))) .Or. Val(AllTrim(cConteudo))<>0
	cRetorno := cTag+AllTrim(cConteudo)+SubStr(cTag,1,1)+"/"+SubStr(cTag,2)
EndIf
Return(cRetorno)

Static Function ConvType(xValor,nTam,nDec)

Local cNovo := ""
DEFAULT nDec := 0
Do Case
	Case ValType(xValor)=="N"
		If xValor <> 0
			cNovo := AllTrim(Str(xValor,nTam,nDec))	
		Else
			cNovo := "0"
		EndIf
	Case ValType(xValor)=="D"
		cNovo := FsDateConv(xValor,"YYYYMMDD")
		cNovo := SubStr(cNovo,1,4)+"-"+SubStr(cNovo,5,2)+"-"+SubStr(cNovo,7)
	Case ValType(xValor)=="C"
		If nTam==Nil
			xValor := AllTrim(xValor)
		EndIf
		DEFAULT nTam := 60
		cNovo := AllTrim(NoAcento(SubStr(xValor,1,nTam)))
		//TBC-GO - Converte caracteres especiais
		cNovo := NoCharEsp(cNovo,.T.)
EndCase
Return(cNovo)

Static Function NoAcento(cString)
Local cChar  := ""
Local nX     := 0 
Local nY     := 0
Local cVogal := "aeiouAEIOU"
Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
Local cTrema := "äëïöü"+"ÄËÏÖÜ"
Local cCrase := "àèìòù"+"ÀÈÌÒÙ" 
Local cTio   := "ãõÃÕ"
Local cCecid := "çÇ"
Local cMaior := "&lt;"
Local cMenor := "&gt;"

For nX:= 1 To Len(cString)
	cChar:=SubStr(cString, nX, 1)
	IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
		nY:= At(cChar,cAgudo)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cCircu)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cTrema)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf
		nY:= At(cChar,cCrase)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
		EndIf		
		nY:= At(cChar,cTio)
		If nY > 0          
			cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
		EndIf		
		nY:= At(cChar,cCecid)
		If nY > 0
			cString := StrTran(cString,cChar,SubStr("cC",nY,1))
		EndIf
	Endif
Next

If cMaior$ cString 
	cString := strTran( cString, cMaior, "" ) 
EndIf
If cMenor$ cString 
	cString := strTran( cString, cMenor, "" )
EndIf

cString := StrTran( cString, CRLF, " " )

Return cString


Static Function NoCharEsp(cString,lConverte)

Default lConverte := .F.

If lConverte
	cString := (StrTran(cString,"<","&lt;"))
	cString := (StrTran(cString,">","&gt;"))
	cString := (StrTran(cString,"&","&amp;"))
	cString := (StrTran(cString,'"',"&quot;"))
	cString := (StrTran(cString,"'","&#39;"))
EndIf

Return(cString)
