#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} TRETR013
Relatório de Transferencia de Cheques

@author Pablo Cavalcante / Rafael Brito
@since 10/04/2014
@version 1.0

@param nOpc, numeric, opção: 1 - Remessa de Cheque Troco (retaguarda) / 2 - Transferência de Cheque Troco (retaguarda) / 3 - Impressão da Lista de Cheques Troco (PDV)
@param aItensCh, array, array de cheques
@type function
/*/
User Function TRETR013(nOpc,aItensCh)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Variaveis de Tipos de fontes que podem ser utilizadas no relatório   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private oFont6		:= TFONT():New("ARIAL",06,06,,.F.,,,,.T.,.F.) ///Fonte 6 Normal
	Private oFont6N 	:= TFONT():New("ARIAL",06,06,,.T.,,,,.T.,.F.) ///Fonte 6 Negrito
	Private oFont8		:= TFONT():New("ARIAL",08,08,,.F.,,,,.T.,.F.) ///Fonte 8 Normal
	Private oFont8N 	:= TFONT():New("ARIAL",08,08,,.T.,,,,.T.,.F.) ///Fonte 8 Negrito
	Private oFont10 	:= TFONT():New("ARIAL",09,09,,.F.,,,,.T.,.F.) ///Fonte 10 Normal
	Private oFont10S	:= TFONT():New("ARIAL",09,09,,.F.,,,,.T.,.T.) ///Fonte 10 Sublinhando
	Private oFont10N 	:= TFONT():New("ARIAL",09,09,,.T.,,,,.T.,.F.) ///Fonte 10 Negrito
	Private oFont12		:= TFONT():New("ARIAL",12,12,,.F.,,,,.T.,.F.) ///Fonte 12 Normal
	Private oFont12NS	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.T.) ///Fonte 12 Negrito e Sublinhado
	Private oFont12N	:= TFONT():New("ARIAL",12,12,,.T.,,,,.T.,.F.) ///Fonte 12 Negrito
	Private oFont14		:= TFONT():New("ARIAL",14,14,,.F.,,,,.T.,.F.) ///Fonte 14 Normal
	Private oFont14NS	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.T.) ///Fonte 14 Negrito e Sublinhado
	Private oFont14N	:= TFONT():New("ARIAL",14,14,,.T.,,,,.T.,.F.) ///Fonte 14 Negrito
	Private oFont16 	:= TFONT():New("ARIAL",16,16,,.F.,,,,.T.,.F.) ///Fonte 16 Normal
	Private oFont16N	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.F.) ///Fonte 16 Negrito
	Private oFont16NS	:= TFONT():New("ARIAL",16,16,,.T.,,,,.T.,.T.) ///Fonte 16 Negrito e Sublinhado
	Private oFont20N	:= TFONT():New("ARIAL",20,20,,.T.,,,,.T.,.F.) ///Fonte 20 Negrito
	Private oFont22N	:= TFONT():New("ARIAL",22,22,,.T.,,,,.T.,.F.) ///Fonte 22 Negrito

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Variveis para impressão                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private cStartPath
	Private nLin 		:= 0
	Private nMargemL    := 80
	Private nMargemR    := 2350
	Private nMargemT	:= 80
	Private nMargemB	:= 3300
	Private nCenterPg	:= 1200
	Private oPrint		:= TMSPRINTER():New("")
	Private nPag		:= 0
	Private cPerg 		:= "TRETR013"
	Private nQtCh		:= 0
	Private nTtCh 		:= 0
	Private cTitRel		:= ""

	cTitRel := "Transferência de Cheque Troco" + iif((Type("_cTitCX")<>"U").and.!Empty(_cTitCX),_cTitCX,"")

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Define Tamanho do Papel                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	#define DMPAPER_A4 9 //Papel A4
	oPrint:setPaperSize( DMPAPER_A4 )
	//TMSPrinter(): SetPaperSize ()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Orientacao do papel (Retrato ou Paisagem)                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oPrint:SetPortrait()///Define a orientacao da impressao como retrato
	//oPrint:SetLandscape() ///Define a orientacao da impressao como paisagem

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Variveis Colunas                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private a1TitItens 	:= {"Banco" , "Agencia"   	, "Conta"	    , "N. Cheque"	, "Data"	, "Valor"  }
	Private a1ColPos 	:= {0		, 150			, 400			, 650	        , 900	    , 1450	   }
	Private a1ColAlign 	:= {0		, 0				, 0				, 0		        , 0	 	    , 1		   }

	nPag := 0

	Cabec()
	CXDestino(nOpc)

	CabItens(a1ColPos,a1TitItens,a1ColAlign)
	ItensCH(nOpc,aItensCh)

	nLin += 50
	ImpTotais()

	Rod()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pre-visualiza a impressão 				                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oPrint:Preview()

return


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta o cabeçalho principal 				                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function Cabec()

	oPrint:StartPage() // Inicia uma nova pagina
	cStartPath := GetPvProfString(GetEnvServer(),"StartPath","ERROR",GetAdv97())
	cStartPath += If(Right(cStartPath, 1) <> "\", "\", "")

	nLin := nMargemT
	oPrint:SayBitmap(nLin, nMargemL, cStartPath + iif(FindFunction('U_URETLGRL'),U_URETLGRL(),"lgrl01.bmp"), 200, 120) //Impressao da Logo
	oPrint:Say(nLin + 50, nCenterPg, cTitRel, oFont14N,,,,2)
	oPrint:Say(nLin, nMargemR, "Página: " + strzero(++nPag,3), oFont10,,,,1)
	nLin += 140
	oPrint:Say(nLin, nMargemR, "Dt. Emissão: " + DTOC(dDatabase) + " " + TIME(), oFont10,,,,1)
	oPrint:Say(nLin, nMargemL+200, AllTrim(SM0->M0_NOME) + " / " + AllTrim(SM0->M0_NOMECOM), oFont10)
	nLin += 60
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 20

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta o rodapé principal 				                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function Rod()

	nLin := nMargemB
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)

	oPrint:EndPage() //finaliza pagina

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta as informações do cabeçalho do relatorio                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function CXDestino(nOpc)
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)
	Local lSrvPDV := SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

	If Type("cPDVDes") == "U" //PDV destino
		cPDVDes := Iif(lSrvPDV,LJGetStation("LG_PDV"),"") //codigo do PDV
	EndIf

	If Type("cEstDes") == "U" //estação destino
		cEstDes := Iif(lSrvPDV,LJGetStation("LG_CODIGO"),"") //codigo da estação
	EndIf

	nTab := 270

	If !Empty(cPDVDes)
		oPrint:Say(nLin, nMargemL, "PDV: ", oFont10N)
		oPrint:Say(nLin, nMargemL + nTab, cPDVDes, oFont10)
	EndIf

	If Type("cPDVOri") <> "U" .and. !Empty(cPDVOri)
		oPrint:Say(nLin, nMargemL+800, "PDV Origem: ", oFont10N)
		oPrint:Say(nLin, nMargemL+800 + nTab, cPDVOri, oFont10)
	EndIf
	nLin += 50

	If !Empty(cEstDes)
		oPrint:Say(nLin, nMargemL, "Descrição: ", oFont10N)
		oPrint:Say(nLin, nMargemL + nTab, POSICIONE("SLG",1,XFILIAL("SLG")+cEstDes,"LG_NOME"), oFont10)
	EndIf

	If Type("cEstOri") <> "U" .and. !Empty(cEstOri)
		oPrint:Say(nLin, nMargemL+800, "Descrição: ", oFont10N)
		oPrint:Say(nLin, nMargemL+800 + nTab, POSICIONE("SLG",1,XFILIAL("SLG")+cEstOri,"LG_NOME"), oFont10)
	EndIf
	nLin += 50

	If nOpc == 3 .and. SA6->(!Eof()) .and. !Empty(xNumCaixa())
		If Type("cOpeDes") == "U"
			cOpeDes := xNumCaixa() //codigo do OPERADOR
		EndIf
		oPrint:Say(nLin, nMargemL, "Operador: ", oFont10N)
		oPrint:Say(nLin, nMargemL + nTab, AllTrim(SA6->A6_COD)+" - "+AllTrim(SA6->A6_NOME), oFont10)
		nLin += 50
	ElseIf lChTrOp
		If Type("cOpeOri") <> "U" .and. !Empty(cOpeOri) .and. Type("cNomeOr") <> "U" .and. !Empty(cNomeOr) .and. ;
				Type("cOpeDes") <> "U" .and. !Empty(cOpeDes) .and. Type("cNomeDe") <> "U" .and. !Empty(cNomeDe)
			oPrint:Say(nLin, nMargemL, "Operador: ", oFont10N)
			oPrint:Say(nLin, nMargemL + nTab, AllTrim(cOpeDes)+" - "+AllTrim(cNomeDe), oFont10)
			oPrint:Say(nLin, nMargemL+800, "Operador Origem: ", oFont10N)
			oPrint:Say(nLin, nMargemL+800 + nTab, AllTrim(cOpeOri)+" - "+AllTrim(cNomeOr), oFont10)
			nLin += 50
		ElseIf Type("cOpeDes") <> "U" .and. !Empty(cOpeDes) .and. Type("cNomeDe") <> "U" .and. !Empty(cNomeDe)
			oPrint:Say(nLin, nMargemL, "Operador: ", oFont10N)
			oPrint:Say(nLin, nMargemL + nTab, AllTrim(cOpeDes)+" - "+AllTrim(cNomeDe), oFont10)
			nLin += 50
		EndIf
	EndIf

	nLin += 10
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 20

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta o cabeçalho dos itens           	                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function CabItens(aColPos,aTitItens,aColAlign)
	Local nI

	for nI := 1 to len(aTitItens)
		oPrint:Say(nLin, nMargemL+aColPos[nI], aTitItens[nI], oFont10N,,,,aColAlign[nI])
	next nI

	nLin += 50
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 20

Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta a lista de cheques.........     	                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ItensCH(nOpc,aItensCh)
	Local aArea    := GetArea()
	Local nPosMark := iif(Type("oGet5")=="U", 1, aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="MARK"}))
	Local aCheqs   := iif(nOpc<>3 .and. Type("oGet5")<>"U", oGet5:aCols, aItensCh)
	Local nX

	DbSelectArea("UF2")
	UF2->(DbSetOrder(1)) //UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM

	nQtCh := 0
	nTtCh := 0

	For nX := 1 to len(aCheqs)
		If aCheqs[nX][nPosMark] == "LBOK"

			nQtCh += 1

			If nOpc == 3

				nTtCh += aItensCh[nX,7]

				If nLin >= nMargemB
					Rod()
					Cabec()
					CabItens(a1ColPos,a1TitItens,a1ColAlign)
				EndIf

				// "Banco" , "Agencia"   	, "Conta"	    , "N. Cheque"	, "Data"	, "Valor"
				nCol := 1
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], aItensCh[nX,2]   , oFont10,,,,a1ColAlign[nCol++]) //Banco
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], aItensCh[nX,3]   , oFont10,,,,a1ColAlign[nCol++]) //Agencia
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], aItensCh[nX,4]   , oFont10,,,,a1ColAlign[nCol++]) //Conta
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], aItensCh[nX,6]   , oFont10,,,,a1ColAlign[nCol++]) //N. Cheque
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], dtoc(ddatabase), oFont10,,,,a1ColAlign[nCol++]) //Data
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], Alltrim(Transform(aItensCh[nX,7],"@E 999,999,999.99")), oFont10,,,,a1ColAlign[nCol++]) //Valor

				nLin += 50
			Else

				nRecno := aCheqs[nX][aScan(oGet5:aHeader,{|x| AllTrim(x[2])=="RECNO"})]
				UF2->(dbgoto(nRecno))
				nTtCh += UF2->UF2_VALOR

				If nLin >= nMargemB
					Rod()
					Cabec()
					CabItens(a1ColPos,a1TitItens,a1ColAlign)
				EndIf

				// "Banco" , "Agencia"   	, "Conta"	    , "N. Cheque"	, "Data"	, "Valor"
				nCol := 1
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], UF2->UF2_BANCO , oFont10,,,,a1ColAlign[nCol++]) //Banco
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], UF2->UF2_AGENCI, oFont10,,,,a1ColAlign[nCol++]) //Agencia
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], UF2->UF2_CONTA , oFont10,,,,a1ColAlign[nCol++]) //Conta
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], UF2->UF2_NUM   , oFont10,,,,a1ColAlign[nCol++]) //N. Cheque
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], dtoc(ddatabase), oFont10,,,,a1ColAlign[nCol++]) //Data
				oPrint:Say(nLin, nMargemL+a1ColPos[nCol], Alltrim(Transform(UF2->UF2_VALOR,"@E 999,999,999.99")), oFont10,,,,a1ColAlign[nCol++]) //Valor

				nLin += 50
			EndIf
		EndIf

	Next nX

	//Impressão do totalizador
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 10

	RestArea(aArea)
Return

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Imprime subtotais                                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ImpTotais()

	oPrint:Say(nLin, nMargemL+000, "Quantidade", oFont10N)
	oPrint:Say(nLin, nMargemL+300, Alltrim(Transform(nQtCh,"@E 999,999,999")), oFont10N,,,,2)
	oPrint:Say(nLin, nMargemL+600, "Total", oFont10N)
	oPrint:Say(nLin, nMargemL+900, Alltrim(Transform(nTtCh,"@E 999,999,999.99")), oFont10N,,,,2)
	nLin += 50
	oPrint:Line(nLin, nMargemL, nLin, nMargemR)
	nLin += 60
	oPrint:Say(nLin, nMargemL, "Eu ______________________________________________________________________________________, me responsabilizo", oFont10)
	nLin += 50
	oPrint:Say(nLin, nMargemL, "cívil e criminalmente pela guarda dos cheques relacionados acima.", oFont10)
	nLin += 50

Return
