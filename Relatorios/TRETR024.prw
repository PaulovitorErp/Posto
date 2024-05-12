#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#INCLUDE "fwprintsetup.ch"

#define DMPAPER_A4 9 // A4 210 x 297 mm
#define IMP_PDF 6 // PDF

/*/{Protheus.doc} TRETR024
Impressão do Calculo da Carta Frete

@author Pablo Nunes
@since 12/07/2023
/*/
User Function TRETR024()

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
	Private cArquivo	:= "TRETR024_"+DTOS(Date())+SUBSTR(Time(),1,2)+SUBSTR(Time(),4,2)+SUBSTR(Time(),7,2)
	Private oPrint	 	:= Nil
	Private oBrush		:= TBrush():New(,CLR_HGRAY )
	Private nPagina		:= 1
	Private aPosArray   := {"L1_FILIAL","L1_PLACA","L1_CLIENTE","L1_LOJA","A1_NOME","L1_EMISNF","L1_DOC","L1_SERIE","D2_COD","B1_DESC","L1_ODOMETR","QTD","BRT","DES","ACR","ICM","LQD","CST","PMD"}

	Private cPerg		:= "TRETR024"

    //valida se os objetos utilizados nos dados do relatório são válidos
    If ValType(oGet1) <> "O"
        Return
    EndIf

	oPrint := FwMSPrinter():New(cArquivo,IMP_PDF,.T.,,.T.,,@oPrint,,.T.,.F.)
	oPrint:SetDevice(IMP_PDF)
	oPrint:SetResolution(72)
	oPrint:SetPortrait() // ou SetLandscape() //Define a orientacao da impressao como retrato
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(0,0,0,0)
	oPrint:Setup() //Tela de configurações

	Processa({|| fCorpoRel()}, "Aguarde...", "Carregando relatório...", .T.)

Return

/*/{Protheus.doc} fCorpoRel
Função para preencher o relatório
@author Pablo Nunes
@since 08/07/2023
/*/
Static Function fCorpoRel()

	Local aSM0 := {}
	Local nAux1 := 0
	Local nAux2 := 0
    Local cOpeDes := ""

	Private cNomeCom := ""

	If Findfunction("FindClass") .AND. FindClass("FWSM0Util")
		If Empty(Select("SM0"))
			OpenSM0(cEmpAnt)
		EndIf
		aSM0 := FWSM0Util():GetSM0Data()
		nAux1 := aScan(aSM0, {|x| alltrim(x[1]) == "M0_CGC"})
		nAux2 := aScan(aSM0, {|x| alltrim(x[1]) == "M0_NOMECOM"})
		cNomeCom := Transform(AllTrim(aSM0[nAux1][2]),"@R 99.999.999/9999-99") + " - " + aSM0[nAux2][2]
	Else
		DbSelectArea("SM0")
		cNomeCom := Transform(AllTrim(SM0->M0_CGC),"@R 99.999.999/9999-99") + " - " + SM0->M0_NOMECOM
	EndIf

	fCabecalho()

	// Transportadora: 2 linhas

    SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbSeek(xFilial("SA1")+cCodEmCF+cLojEmCF))

	nCol1 := 145
	nCol2 := 645
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "CNPJ da Transportadora", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(AllTrim(SA1->A1_CGC),"@R 99.999.999/9999-99"), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nLin+=50

	nCol1 := 145
	nCol2 := 645
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Nome da Transportadora", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, SA1->A1_NOME, oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nLin+=100

	// Diferença de Peso: 3 linhas

	fQuadTit("DIFERENÇA DE PESO (kg)",3)
	fLinVlr("Peso carga saída (kg)",oGet1:cText)
	fLinVlr("Peso descarga (kg)",oGet2:cText)
	fLinVlr("Diferença (kg)",oGet3:cText)
	nLin+= 50

	// Cálculo de Tolerância: 2 linhas

	fQuadTit("CÁLCULO DA TOLERÂNCIA (kg)",2)
	fLinVlr("Tolerância (%)",oGet4:cText)
	fLinVlr("Peso tolerância (kg)",oGet5:cText)
	nLin+= 50

	// Critério de Quebra: 1 linha

	fQuadTit("CRITÉRIO DE QUEBRA",1)

	nCol1 := 645
	nCol2 := 1255
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Quebra", oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, oGet6:cText, oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nLin+= 50
	nLin+= 50

	// Calculo da Quebra: 5 linhas

	fQuadTit("CÁLCULO DA QUEBRA (R$)",5)
	    
    nCol1 := 645
	nCol2 := 1255
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Descontar Quebra", oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, Iif(oGet6:cText=="NÃO","N/A",Iif(nRadMenu1==1,"INTEGRAL","PARCIAL")), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,1,0)
    nLin+= 50
	
    fLinVlr("Valor da mercadoria",oGet9:cText)
	fLinVlr("Peso carga saída (kg)",oGet10:cText)
	fLinVlr("Valor / quebra (R$/kg)",oGet11:cText)
	fLinVlr("Valor a ser descontado",oGet12:cText)
	nLin+= 50

	// Calculo do frete sem descontos: 2 linhas

	fQuadTit("CÁLCULO DO FRETE SEM DESCONTOS",2)
	fLinVlr("Peso menor (kg)",oGet7:cText)
	fLinVlr("Frete combinado/ton",oGet8:cText)
    nLin+= 50

	// Calculo do Frete Final: 17 linhas

	fQuadTit("CÁLCULO DO FRETE FINAL",17)
	fLinVlr("Saldo",oGet15:cText)
	fLinVlr("Seguro (-)",oGet16:cText)
	fLinVlr("Imp. Renda na Fonte (-)",oGet17:cText)
	fLinVlr("INSS (-)",oGet18:cText)
	fLinVlr("SEST/SENAT (-)",oGet19:cText)
	fLinVlr("Adiantamento (-)",oGet20:cText)
	fLinVlr("Falta de Mercadoria (kg) (-)",oGet21:cText)
	fLinVlr("Estadia (-)",oGet22:cText)
	fLinVlr("Outros Descontos (-)",oGet23:cText)
	fLinVlr("Pedágio (+/-)",oGet24:cText)
	fLinVlr("Taxa Administrativa (-)",oGet25:cText)
	fLinVlr("Adiant. 1 Comb. (-)",oGet26:cText)
	fLinVlr("Adiant. 2 Comb. (-)",oGet27:cText)
	fLinVlr("Outros Desc. Mot. (-)",oGet28:cText)
	fLinVlr("Desp. Adc. Mot. (-)",oGet29:cText)

	nCol1 := 645
	nCol2 := 1255
	oPrint:Box(nLin,nCol1,nLin+100,nCol2)
	oPrint:SayAlign(nLin+35, nCol1+10, "Saldo Final", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+100,nCol2)
	oPrint:SayAlign(nLin+35, nCol1+10, Transform(oGet30:cText, "@E 999,999,999,999.99"), oFont10N,((nCol2-nCol1)-30)/*largura*/,50/*altura*/,,1,0)

	nLin+= 100
	nLin+= 50

	// Responsável: 1 linha

	nCol1 := 145
	nCol2 := 380
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, "Responsável", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
    If SA6->(!Eof()) .and. !Empty(xNumCaixa())
		If Type("cOpeDes") == "U"
			cOpeDes := xNumCaixa() //codigo do OPERADOR
		EndIf
		cOpeDes := AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME)
	EndIf
	oPrint:SayAlign(nLin+10, nCol1+10, cOpeDes, oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 2300
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, 1860, DTOC(Date()), oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nLin+= 50

	// Assinatura: 2 linhas

	nCol1 := 145
	nCol2 := 645
	oPrint:Box(nLin,nCol1,nLin+100,nCol2)
	oPrint:SayAlign(nLin+35, nCol1+10, "Assinatura", oFont10N,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,2,0)

	nCol1 := nCol2
	nCol2 := 2300
	oPrint:Box(nLin,nCol1,nLin+100,nCol2)

	nLin+= 100

	fRodape()

	oPrint:Preview() //Visualiza antes de imprimir

	FreeObj(oPrint)
	oPrint := Nil

Return

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
	oPrint:Box(nLin,380,nLin+50,1850)
    oPrint:Box(nLin+50,380,nLin+132,1850)
	oPrint:SayAlign(nLin+10, 390, AllTrim(cNomeCom), oFont10N,1450/*largura*/,50/*altura*/,,2,0)
	oPrint:SayAlign(nLin+62, 390, "CÁLCULO DA CARTA FRETE", oFont14N,1450/*largura*/,82/*altura*/,,2,0)

	//Numero da página e data e hora
	oPrint:Box(nLin,1850,nLin+132,2300)
	oPrint:SayAlign(nLin+61, 1860, DTOC(Date())+" "+Time(), oFont10N,430/*largura*/,50/*altura*/,,2,0)

	nLin+=180

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

Static Function fQuadTit(cTexto,nQtdLin)
	nCol1 := 145
	nCol2 := 645
	oPrint:Box(nLin,nCol1,nLin+(50*nQtdLin),nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, cTexto, oFont10N,((nCol2-nCol1)-20)/*largura*/,(50*nQtdLin)-20/*altura*/,,2,0)
Return

Static Function fLinVlr(cTexto,nValor)
	nCol1 := 645
	nCol2 := 1255
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, cTexto, oFont10,((nCol2-nCol1)-20)/*largura*/,50/*altura*/,,0,0)

	nCol1 := nCol2
	nCol2 := 1860
	oPrint:Box(nLin,nCol1,nLin+50,nCol2)
	oPrint:SayAlign(nLin+10, nCol1+10, Transform(nValor, "@E 999,999,999,999.99"), oFont10,((nCol2-nCol1)-30)/*largura*/,50/*altura*/,,1,0)

	nLin+= 50
Return
