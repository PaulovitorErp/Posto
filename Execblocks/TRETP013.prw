#include "totvs.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETP013
Chamado pelo P.E. PE01NFESEFAZ na montagem do XML
@author TOTVS
@since 13/06/2018
@version P12
@param nulo
@return nulo
/*/

User Function TRETP013()

Local aProd		  	:= PARAMIXB[01]
Local cMensCli		:= PARAMIXB[02]
Local cMensFis		:= PARAMIXB[03]
Local aDest		  	:= PARAMIXB[04]
Local aNota   		:= PARAMIXB[05]
Local aInfoItem		:= PARAMIXB[06]
Local aDupl		  	:= PARAMIXB[07]
Local aTransp		:= PARAMIXB[08]
Local aEntrega		:= PARAMIXB[09]
Local aRetirada		:= PARAMIXB[10]
Local aVeiculo		:= PARAMIXB[11]
Local aReboque		:= PARAMIXB[12]
Local aNfVincRur	:= PARAMIXB[13]
Local aEspVol		:= PARAMIXB[14]
Local aNfVinc		:= PARAMIXB[15]
Local aDetPag		:= PARAMIXB[16]
Local aObsCont		:= PARAMIXB[17]
Local aProcRef		:= PARAMIXB[18]
Local aMed			:= PARAMIXB[19]
Local aLote			:= PARAMIXB[20]
Local aComb			:= Iif(Len(PARAMIXB)>20,PARAMIXB[21],Array(Len(aProd))) //especifico do template do Posto Inteligente
Local cIndPres		:= Iif(Len(PARAMIXB)>21,PARAMIXB[22],"") //especifico do template do Posto Inteligente
Local cModFrete		:= Iif(Len(PARAMIXB)>22,PARAMIXB[23],"") //especifico do template do Posto Inteligente
Local aFat			:= Iif(Len(PARAMIXB)>23,PARAMIXB[24],{}) //especifico do template do Posto Inteligente
Local aTotal		:= Iif(Len(PARAMIXB)>24,PARAMIXB[25],{0,0,0}) //especifico do template do Posto Inteligente
Local aCST			:= Iif(Len(PARAMIXB)>25,PARAMIXB[26],Array(Len(aProd))) //especifico do template do Posto Inteligente
Local aICMS			:= Iif(Len(PARAMIXB)>26,PARAMIXB[27],Array(Len(aProd))) //especifico do template do Posto Inteligente
Local cVerAmb		:= Iif(Len(PARAMIXB)>27,PARAMIXB[28],"") //especifico do template do Posto Inteligente
Local aPIS			:= Iif(Len(PARAMIXB)>28,PARAMIXB[29],Array(Len(aProd))) //especifico do template do Posto Inteligente
Local aCOFINS		:= Iif(Len(PARAMIXB)>29,PARAMIXB[30],Array(Len(aProd))) //especifico do template do Posto Inteligente
Local aICMSMONO		:= Iif(Len(PARAMIXB)>30,PARAMIXB[31],Array(Len(aProd))) //especifico do template do Posto Inteligente

Local aRetorno		:= PARAMIXB
Local aCombBKP		:= {}
Local aCSTBkp		:= {}
Local aICMSBkp		:= {}
Local aPISBkp		:= {}
Local aCOFBkp		:= {}
Local aICMSMonBkp	:= {}

Local aMDL 			:= MDL->( GetArea() )
Local aSF2 			:= SF2->( GetArea() )
Local aSD2 			:= SD2->( GetArea() )
Local aSB1 			:= SB1->( GetArea() )
Local aSF4 			:= SF4->( GetArea() )
Local aSA1 			:= SA1->( GetArea() )
Local aSL1			:= SL1->( GetArea() )

Local nIcmsST		:= 0
Local cMsgAux 		:= ""
Local nPos			:= 0
Local nX 			:= 0
Local nTroco		:= 0
Local nVlPar		:= 0
Local nTotNota		:= 0
Local cGrpComb		:= SuperGetMV("MV_COMBUS",,"0001") //"0001" //AllTrim(GetMv("MV_XCOMBUS"))
Local cGrpArla		:= SuperGetMv("MV_XGRARLA",,"") //mensagem para arla
Local cEstOri 		:= SM0->M0_ESTCOB //Estado de origem
Local aSD2Pro 		:= {}, nPosPrd := 0, nBcIcmsST := 0
Local lCodeBase		:= .F.
Local cGrupo 		:= ""
Local cTXTSep  		:= " /" //caracter que separa as informações
Local cTipo			:= Iif(Len(aNota)>0,aNota[4],"") //"0" - Entrada e "1" - Saída
Local lDados		:= .T.

Local lNfAcobert	:= SuperGetMv("MV_XNFACOB",.F.,.F.)
Local aAuxProd		:= {}
Local nPrUnit		:= 0
Local nValtrib		:= 0

Local lSrvPDV 		:= SuperGetMV("MV_XSRVPDV",,.T.) //Servidor PDV

Local lRodCupom		:= SuperGetMV("MV_XMSGCUP",,.T.) //Msg rodapé cupom
Local lMsgAdic		:= SuperGetMV("MV_XMSGADI",,.T.) //Msg adicionais
Local lMsgArla		:= SuperGetMV("MV_XMSGARL",,.F.) //Mensagem de ICMS do grupo Arla

Local cError 		:= ""
Local cIdEnt 		:= ""
Local cModel		:= "55" //NF-e
Local cMeioPag		:= "15"
Local lVldMeioPag	:= .F.

Local cMsgTermos	:= SuperGetMv("MV_XMSGTER",.F.,"Emitida nos termos do art.231-N-K do RICMS.")
Local cMsgProcon 	:= AllTrim(SuperGetMV("MV_XPROCON",,"")) //Mensagens informativas do cupom fiscal: Procon (Ex.: PROCON MT - Av. Baltazar Navarros, N.567, Bairro Bandeirantes, Cuiabá-MT, CEP 78010-020. Tel: 151 ou (65)3613-2100)
Local cMVXADMFID	:= SuperGetMv("MV_XADMFID",,"")

Local cUltAqui  	:= AllTrim(SuperGetMv("MV_ULTAQUI",,""))
Local cArt274		:= ""
Local lCalcMed 		:= GetNewPar("MV_STMEDIA",.F.) //Define se irá calcular a média do ICMS ST e da BASE do ICMS ST. 
Local lEndFis 		:= GetNewPar("MV_SPEDEND",.F.)

Local lNfCupom		:= .F.
Local cNrNota		:= ""
Local cSerNota		:= ""
Local cCodCli		:= ""
Local cLojaCli		:= ""

Local cCodAnp		:= ""
Local cDescANP		:= """
Local cEstado		:= ""
Local aANPS			:= {}

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).

aadd(aANPS,"210203001")
aadd(aANPS,"210203003")
aadd(aANPS,"210203004")
aadd(aANPS,"210203005")
aadd(aANPS,"420102004")
aadd(aANPS,"420102005")
aadd(aANPS,"420105001")
aadd(aANPS,"420201001")
aadd(aANPS,"420201003")
aadd(aANPS,"420301002")
aadd(aANPS,"820101001")
aadd(aANPS,"820101012")
aadd(aANPS,"820101013")
aadd(aANPS,"820101033")
aadd(aANPS,"820101034")
aadd(aANPS,"320101001")
aadd(aANPS,"320101002")
aadd(aANPS,"320102001")
aadd(aANPS,"320102002")
aadd(aANPS,"320102003")
aadd(aANPS,"320102005")
aadd(aANPS,"320201001")
aadd(aANPS,"810102001")
aadd(aANPS,"810102004")
aadd(aANPS,"810102003")
aadd(aANPS,"320103001")
aadd(aANPS,"320103003")
aadd(aANPS,"320301002")
aadd(aANPS,"320301001")
aadd(aANPS,"320103002")

//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return aRetorno
EndIf

If Len(PARAMIXB)<=20
	AFill(aComb,"")
	AFill(aCST,"")
	AFill(aICMS,"")
	AFill(aPIS,"")
	AFill(aCOFINS,"")
	AFill(aICMSMONO,"")
EndIf

//Remove caracter especial e acento, independente do tipo de Nota - FwCutOff
For nX := 1 To Len(aDest)
	//A1_NOME ou A1_END ou A1_COMPLEM ou A1_BAIRRO ou A1_EMAIL
	If nX == 2 .Or. nX == 3 .Or. nX == 4 .Or. nX == 5 .Or. nX == 6 .Or. nX == 12 .Or. nX == 16
		If ValType(aDest[nX]) == "C"
			aDest[nX] := FwCutOff(aDest[nX],.T.)
		Endif
	Endif
Next nX
//Fim remove acento e caracter especial

//TODO - forçado o indPres igual a 1, quando nota de devolução
If cTipo == "0" .and. SF1->F1_TIPO == "D" //"0" - Entrada e "1" - Saída
	cIndPres := "1"
	cModFrete:= "9"
EndIf

If Len(aNota) == 0 .or. Alltrim( aNota[4] ) <> "1"
	aRetorno := {}
	aadd(aRetorno,aProd)    	//1
	aadd(aRetorno,cMensCli) 	//2
	aadd(aRetorno,cMensFis) 	//3
	aadd(aRetorno,aDest)    	//4
	aadd(aRetorno,aNota)    	//5
	aadd(aRetorno,aInfoItem)    //6
	aadd(aRetorno,aDupl)        //7
	aadd(aRetorno,aTransp)      //8
	aadd(aRetorno,aEntrega)     //9
	aadd(aRetorno,aRetirada)    //10
	aadd(aRetorno,aVeiculo)     //11
	aadd(aRetorno,aReboque)     //12
	aadd(aRetorno,aNfVincRur)   //13
	aadd(aRetorno,aEspVol)  	//14
	aadd(aRetorno,aNfVinc)		//15
	aadd(aRetorno,aDetPag)		//16
	aadd(aRetorno,aObsCont)		//17
	aadd(aRetorno,aProcRef)		//18
	aadd(aRetorno,aMed)			//19
	aadd(aRetorno,aLote)		//20
	aadd(aRetorno,aComb)		//21
	aadd(aRetorno,cIndPres)		//22
	aadd(aRetorno,cModFrete)	//23
	aadd(aRetorno,aFat)			//24
	aadd(aRetorno,aTotal)		//25
	aadd(aRetorno,aCST)			//26
	aadd(aRetorno,aICMS)		//27
	aadd(aRetorno,cVerAmb)		//28
	aadd(aRetorno,aPIS)			//29
	aadd(aRetorno,aCOFINS)		//30
	aadd(aRetorno,aICMSMONO)	//31
	Return aRetorno
EndIf

SD2->( DbSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
SB1->( DbSetOrder(1) ) //B1_FILIAL+B1_COD
SB5->( DbSetOrder(1) ) //B5_FILIAL+B5_COD
DY3->( DbSetOrder(1) ) //DY3_FILIAL+DY3_ONU+DY3_ITEM
SF4->( DbSetOrder(1) ) //F4_FILIAL+F4_CODIGO
SA1->( DbSetOrder(1) ) //A1_FILIAL+A1_COD+A1_LOJA
MDL->( DbSetOrder(2) ) //MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE
SL1->( DbSetOrder(2) ) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
SFT->( DbSetOrder(1) ) //FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
CD2->( DbSetOrder(1) ) //CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODCLI+CD2_LOJCLI+CD2_ITEM+CD2_CODPRO+CD2_IMP

//Conout("	>> TRETP013 - Chamado pelo P.E. PE01NFESEFAZ na montagem do XML - INICIO")
//Conout("	>> DATA: "+ DToC(Date()) +" - HORA: " + Time())

lCodeBase := lSrvPDV

If lCodeBase
	//-- Emitido no PDV deve ser sempre presencial
	//Conout("	>> TRETP013 - Emitido no PDV deve ser sempre presencial ")
	cIndPres := "1"
	cModFrete:= "9"
Endif

If lCodeBase .AND. lMsgArla .AND. !empty(cGrpArla)
	cMsgAux 	:= ""
	aAreaSD2 	:= SD2->( GetArea() )
	aSD2Pro		:= {}

	SD2->( DbSetOrder(3) ) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA))
	While SD2->(!Eof()) .and.  SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == (xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)

		If (AllTrim(SD2->D2_GRUPO) $ (cGrpArla))

			nPosPrd := aScan( aSD2Pro,{|x| AllTrim(x[1])==AllTrim(SD2->D2_COD) .AND. x[3]==SD2->D2_PICM })
			If nPosPrd <= 0
				AAdd(aSD2Pro, {SD2->D2_COD,SD2->D2_GRUPO,SD2->D2_PICM, SD2->D2_VALICM, SD2->D2_BASEICM})
			Else
				aSD2Pro[nPosPrd][4] += SD2->D2_VALICM
				aSD2Pro[nPosPrd][5] += SD2->D2_BASEICM
			EndIf
		EndIf

		SD2->( DbSkip() )
	EndDo

	For nX:=1 to Len(aSD2Pro)
		cMsgAux += " Produto: " + AllTrim(aSD2Pro[nX][1]) + cTXTSep + " BC: R$ " + AllTrim( Transform(aSD2Pro[nX][5],"@E 99,999,999,999.99")) + cTXTSep + " ALIQ.: "+AllTrim(Transform(aSD2Pro[nX][3],"@E 999.99"))+"%" + cTXTSep + " ICMS: R$ "+AllTrim(Transform(aSD2Pro[nX][4],"@E 99,999,999,999.99"))+CRLF
	Next nX

	If !Empty(cMsgAux)
		cMensFis += cMsgAux
	EndIf
	cMsgAux := ""

	RestArea( aAreaSD2 )
endif

//Mensagem adicional e aglutinação de itens para Nota Fiscal de acobertamento
If !lCodeBase .And.;	//Ambiente TOP
 	cTipo == "1"	//Nota fiscal de saída

	cIdEnt 	:= getCfgEntidade(@cError)
	cVerAmb := getCfgVersao(@cError, cIdEnt, cModel)

	If !Empty(cIdEnt) .And. !Empty(cVerAmb)

		If cVeramb >= "4.00"

		 	//-- TBC-GO - tratamento tags de fatura, duplicata, detalhes de pagamento e troco

			//cTexto += "		>> aTotal: " + CRLF
			//cTexto += UtoString(aTotal) + CRLF
			//cTexto += CRLF

			nTotNota := aTotal[02]+aTotal[03]

			//cTexto += "		>> aDetPag: " + CRLF
			//cTexto += UtoString(aDetPag) + CRLF
			//cTexto += CRLF
			//Conout(cTexto)

			//ajusta o tipo do conteúdo do array aDetPag {cForma, Valor, Troco, Tp Integra, CGC Adm Cartao, Cod Bandeira, Autorização TEF, cIndPag}
			For nX:=1 to Len(aDetPag)
				If ValType(aDetPag[nX][02])=="C" //ConvType( aFormasPag[nX][2], 15, 2 )
					aDetPag[nX][02] := Val(aDetPag[nX][02])
				EndIf
				If ValType(aDetPag[nX][03])=="C"
					aDetPag[nX][03] := Val(aDetPag[nX][03])
				EndIf
			Next nX

			//-- tratamento das formas de pagamentos utilizadas

			If nTotNota > 0 //-- nTotNota: Variavel para ter o valor total da nota para ser utilizado na Lei da Transparencia: NFESEFAZ

				nTroco := 0 //-- troco total contido no array de pagementos aDetPag
				nVlPar := 0 //-- total das parcelas de pagamento
				//aDetPag -> {cForma, Valor, Troco, Tp Integra, CGC Adm Cartao, Cod Bandeira, Autorização TEF, cIndPag}

				//-- valido se existe item com as seguintes CFOPs (5929 / 6929) - Notas Fiscais Eletrônicas de Acompanhamento do Cupom Fiscal
				For nX := 1 To Len(aProd)
					If Alltrim(aProd[nX,7]) == '5929' .Or. Alltrim(aProd[nX,7]) == '6929'
						lVldMeioPag := .T.
						Exit
					EndIf
				Next nX

				If lVldMeioPag
					For nX := 1 To Len(aDupl)
						//se existir algum titulo vencido, a forma sera 90-sem pagamento
						If aDupl[nX,2] < DaySum(Date(),1) .Or. cMeioPag == '90'
							cMeioPag 	:= "90" //90-sem pagamento
							aDupl[nX,2]	:= DaySum(Date(),1)
						EndIf
					Next nX
				EndIf

				For nX:=1 to Len(aDetPag)
					nVlPar += aDetPag[nX][02]
					nTroco += aDetPag[nX][03]
					//para nota s/ cupom preencher o campo de meio de pagamento
					If lVldMeioPag
						aDetPag[nX][01] := cMeioPag

						//senao existir cobranca 90-sem pagamento, zera informacoes do aDetPag
						If cMeioPag == '90'
							aDetPag[nX][03]	:= 0
							aDetPag[nX][04]	:= ""
							aDetPag[nX][05]	:= ""
							aDetPag[nX][06]	:= ""
							aDetPag[nX][07]	:= ""
						EndIf
					EndIf
				Next nX

				//realiza tratamento de troco apenas se meio de pagamento for diferente de 90 - Sem pagamento
				If cMeioPag <> '90'

					If nVlPar < nTotNota .OR. lVldMeioPag
						aDetPag[01][02] := nTotNota+nTroco
						aDetPag[01][03] := nTroco
						nVlPar := nTotNota+nTroco
						aTmpaDetPag := aClone(aDetPag)
						aDetPag := {}
						aadd(aDetPag,aTmpaDetPag[01])
					EndIf

					If (nVlPar - nTroco) <> nTotNota
						nTrocoTot := (nVlPar - nTotNota)
						//-- zero todos os trocos
						For nX:=1 to Len(aDetPag)
							aDetPag[nX][03] := 0
						Next nX
						//-- adiciona o troco certo a forma de primeira forma de pagamento que possibilita troco
						For nX:=1 to Len(aDetPag)
							If aDetPag[nX][02] > nTrocoTot
								aDetPag[nX][03] := nTrocoTot
							Else
								aDetPag[nX][03] := 0
							EndIf
						Next nX
					EndIf

				EndIf
			EndIf

			//-- tratamento dados da fatura

			//cTexto += "		>> aFat: " + CRLF
			//cTexto += UtoString(aFat) + CRLF
			//cTexto += CRLF
			//Conout(cTexto)

			If Len(aFat) > 1 .or. Len(aFat) <= 0 .and. Len(aDupl) > 0
				aFat := {{"",0,0,0}}
			EndIf

			If Len(aFat) > 0
			//For nX:=1 to Len(aFat)
				aFat[01][01] := Iif(Len(aDupl)>0,aDupl[01][01],SF2->F2_SERIE+SF2->F2_DOC)	// Nr Duplicata
				aFat[01][02] := nTotNota		// Vlr nota
				aFat[01][03] := 0				// Vlr Desconto aProd[15] Somar
				aFat[01][04] := nTotNota		// Vlr Liquido
			//Next nX
			EndIf

			//-- tratamento dados da duplicata

			//cTexto += "		>> aDupl: " + CRLF
			//cTexto += UtoString(aDupl) + CRLF
			//cTexto += CRLF
			//Conout(cTexto)
			//aadd(aDupl,{E1_PREFIXO+E1_NUM+E1_PARCELA,E1_VENCORI,nValDupl})

			If (Len(aDupl) <= 0) .and. (cMeioPag <> '90')
				aadd(aDupl,{SF2->F2_SERIE+SF2->F2_DOC,DaySum(Date(),1),0})
			EndIf

			nDupl := 0 //-- total das duplicatas
			lDelDup := .F.
			For nX := 1 To Len(aDupl)
				If DtoC(aDupl[nX][02]) < DtoC(DaySum(Date(),1))
					aDupl[nX][02] := DaySum(Date(),1)
				EndIf
				If lDelDup
					aDupl[nX][03] := 0
				ElseIf nDupl + aDupl[nX][03] > nTotNota
					aDupl[nX][03] := nTotNota - nDupl
					nDupl += aDupl[nX][03]
					lDelDup := .T.
				Else
					nDupl += aDupl[nX][03]
				EndIf
			Next nX

			nDifDup := 0 //-- diferença do total de duplicatas e o total da nota
			If Len(aDupl) > 0 .and. (nDupl <> nTotNota)
				If nDupl > nTotNota
					nDifDup := (nDupl - nTotNota)
					For nX := 1 To Len(aDupl)
						If nDifDup >= aDupl[nX][03]
							aDupl[nX][03] -= nDifDup
							nDifDup := 0
						Else
							nDifDup -= aDupl[nX][03]
							aDupl[nX][03] := 0
						EndIf
					Next nX
				Else
					nDifDup := (nTotNota - nDupl)
					aDupl[Len(aDupl)][03] += nDifDup
				EndIf
			EndIf

			aTmpDupl := aClone(aDupl)
			aDupl := {}
			For nX:=1 to Len(aTmpDupl)
				If aTmpDupl[nX][03] > 0
					aadd(aDupl,aTmpDupl[nX])
				EndIf
			Next nX

			//-- Por fim, ordenar o aDupl
			aSort( aDupl, , , { |x,y| x[02]<y[02] } )

			//Obs1: O número de parcelas deve ser informado com 3 algarismos, sequencias e consecutivos. Ex.: "001","002","003",...
			nDup := "001"
			For nX:=1 to Len(aDupl)
				aDupl[nX][01] := nDup
				nDup := Soma1(nDup)
			Next nX

		Endif
	Endif

	MDL->(DbSetOrder(2)) //MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE
	MDL->(DbGoTop())
	MDL->(DbSeek(xFilial("MDL")+SF2->F2_DOC+SF2->F2_SERIE))

	While MDL->(!Eof()) .and. MDL->MDL_FILIAL = xFilial("MDL") .and. MDL->MDL_CUPOM = SF2->F2_DOC .and. AllTrim(MDL->MDL_SERCUP) = SF2->F2_SERIE .and. !(aNota[01]+aNota[02] = MDL->MDL_SERIE+MDL->MDL_NFCUP)
		MDL->(DbSkip())
	EndDo

	//U_UHELP('Log - MDL','Indice (2) -> MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE'+CRLF+MDL->(MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE),'SF2: F2_DOC+F2_SERIE'+CRLF+SF2->F2_DOC+SF2->F2_SERIE+CRLF+CRLF+"aNota - "+UtoString(aNota))

	//Se nota sobre vendas
	If MDL->(!Eof()) .and. MDL->MDL_FILIAL == xFilial("MDL") .and. MDL->(MDL_CUPOM+Padl(MDL_SERCUP,TamSx3("F2_SERIE")[1])) == SF2->F2_DOC+SF2->F2_SERIE .and. aNota[01] == MDL->MDL_SERIE .and. aNota[02] == MDL->MDL_NFCUP //MDL->(Found())
		lNfCupom := .T.

		SF2->(DbSeek(xFilial("SF2")+MDL->MDL_NFCUP+Padl(MDL->MDL_SERIE,TamSx3("F2_SERIE")[1])))

		cNrNota 	:= MDL->MDL_NFCUP
		cSerNota	:= MDL->MDL_SERIE
		cCodCli		:= SF2->F2_CLIENTE
		cLojaCli	:= SF2->F2_LOJA

		if empty(cIndPres)
			cIndPres := "1" //fixado provisóriamente
		endif

		//Mensagem Complementar - Gera NF-e
		If SF2->(FieldPos("F2_XMSGADI")) > 0
			If !Empty(SF2->F2_XMSGADI)
				cMensFis += CRLF + SF2->F2_XMSGADI + CRLF
				lDados := .F.
			EndIf
		EndIf

		//Mensagem ICMS para Arla
		if lMsgArla .AND. !empty(cGrpArla)

			cMsgAux := ""

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Informações adicionais da Nota Fiscal: ICMS para ARLA 	³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cQry:="SELECT D2_COD,D2_GRUPO,D2_PICM, SUM(D2_VALICM) VALICM, SUM(D2_BASEICM) BASEICM FROM " + RetSqlName("SD2")
			cQry+=" WHERE D_E_L_E_T_	= ' ' "
			cQry+=" AND D2_FILIAL 		= '" +xFilial("SD2")+ "' "
			cQry+=" AND D2_DOC+D2_SERIE  IN ("
			cQry+="		SELECT MDL_CUPOM+MDL_SERCUP FROM "+RetSqlName("MDL")+" MDL WHERE MDL.D_E_L_E_T_ = ' ' AND MDL_FILIAL = '"+xFilial("MDL")+"' AND MDL_NFCUP = '"+cNrNota+"' AND MDL_SERIE = '"+cSerNota+"' "
			cQry+=" ) "
			cQry+=" AND D2_CLIENTE 		= '" +cCodCli+ "' "
			cQry+=" AND D2_LOJA 		= '" +cLojaCli+ "' "
			cQry+=" AND D2_GRUPO 		IN " +FormatIn(cGrpArla,"/")+ " "
			cQry+=" GROUP BY D2_COD,D2_GRUPO,D2_PICM"

			cQry:=ChangeQuery(cQry)
			TcQuery cQry New Alias "QRYITEM"

			While !QRYITEM->( Eof() )

				cMsgAux += " Produto: " + AllTrim(QRYITEM->D2_COD) + cTXTSep + " BC: R$ " + AllTrim( Transform(QRYITEM->BASEICM,"@E 99,999,999,999.99")) + cTXTSep + " ALIQ.: "+AllTrim(Transform(QRYITEM->D2_PICM,"@E 999.99"))+"%" + cTXTSep + " ICMS: R$ "+AllTrim(Transform(QRYITEM->VALICM,"@E 99,999,999,999.99"))+CRLF

				QRYITEM->( DbSkip() )
			EndDo

			QRYITEM->( DbCloseArea() )

			If !Empty(cMsgAux)
				cMensFis += cMsgAux
			EndIf

		endif

		If lNfAcobert
			//cMensCli += CRLF + "Emitida nos termos do art.231-N-K do RICMS. " + CRLF
			cMensCli += CRLF + cMsgTermos + Space(1) + CRLF
			cModFrete:= "9"
		Else
			cMensFis += " ### Nota Emitida nos Termos da Portaria CAT 90/00, referenciando os serguintes cupons:"
		Endif

		If lMsgAdic

			MDL->(DbSetOrder(1)) //MDL_FILIAL+MDL_NFCUP+MDL_SERIE+MDL_CUPOM+MDL_SERCUP
			MDL->(DbGoTop())
			MDL->(DbSeek(xFilial("MDL")+cNrNota+cSerNota))

			While MDL->(!EOF()) .And. MDL->(MDL_FILIAL+MDL_NFCUP+MDL_SERIE) == xFilial("MDL")+cNrNota+cSerNota

				cMsgAux		:= ""

				cNrCup  	:= MDL->MDL_CUPOM
				cSerCup 	:= MDL->MDL_SERCUP

				//COMENTADO POR DANILO, pois no padrão ja está jogando a informaçao, e está ficando redundante
				//cMensFis += " NR. CUPOM: " + AllTrim(cNrCup) + " SERIE: " + AllTrim(cSerCup) + cTXTSep

				SL1->( DbSeek( xFilial("SL1") + Padr( Alltrim(cSerCup),TamSX3("L1_SERIE")[1]) + Padr( Alltrim(cNrCup),TamSX3("L1_DOC")[1]) ) )

				If lDados

					if SL1->(FieldPos("L1_NOMMOTO"))>0 .and. !Empty(SL1->L1_NOMMOTO)
						cMsgAux += " MOTORISTA: " + AllTrim(SL1->L1_NOMMOTO) + cTXTSep
					endif

					if !Empty(SL1->L1_PLACA)
						cMsgAux += " PLACA: " + Transform(SL1->L1_PLACA,"@!R NNN-9N99") + cTXTSep
					endif

					if SL1->L1_ODOMETR > 0
						cMsgAux += " KM: " + AllTrim(Transform(SL1->L1_ODOMETR,"@E 99999999999")) + cTXTSep
					endif

					if SL1->(FieldPos("L1_MENNOTA")) > 0 .and. !empty(SL1->L1_MENNOTA)
						cMsgAux += " Obs: " + AllTrim(SL1->L1_MENNOTA)
					endif
					
				Endif

				if !Empty(cMsgAux)
					cMensFis += cMsgAux
				endif

				MDL->(DbSkip())
			EndDo
		Endif

		//--------------------------------------//
		//										//
		//  Compatibilização dos itens da Nota  //
		//										//
		//--------------------------------------//
		aCSTBkp := aClone(aCST)
		aICMSBkp := aClone(aICMS)
		aPISBkp := aClone(aPIS)
		aCOFBkp := aClone(aCOFINS)
		aICMSMonBkp := aClone(aICMSMONO)
		aAuxProd := {}
		aCST 	:= {}
		aICMS 	:= {}
		aPIS	:= {}
		aCOFINS	:= {}
		aICMSMONO := {}

		for nX := 1 to len(aProd)
			if aCSTBkp[nX][1] == "61" .AND. cMVEstado == "GO"
				aProd[nX][44] := "GO890004"
			endif
			nPrUnit := Round(aProd[nX][10]/aProd[nX][9],3)
			
			//se ja tem o mesmo produto e preço unitario
			If (nPos := aScan(aAuxProd,{|x| x[2] == aProd[nX][2] .And. x[16] == nPrUnit })) > 0
				aAuxProd[nPos][9] 	+= aProd[nX][9] // SD2->D2_QUANT 															//Quantidade
				aAuxProd[nPos][10] 	+= aProd[nX][10] // A410Arred(SD2->D2_QUANT * nPrUnit,"L2_VLRITEM")							//Total
				aAuxProd[nPos][12] 	+= aProd[nX][12] // IIF(Empty(SB5->B5_CONVDIP),SD2->D2_QUANT,SB5->B5_CONVDIP*SD2->D2_QUANT) 	//Fator de conversão DIPI
				aAuxProd[nPos][13] 	+= aProd[nX][13] // SD2->D2_VALFRE 															//Valor Frete
				aAuxProd[nPos][14] 	+= aProd[nX][14] // SD2->D2_SEGURO 															//Valor Seguro
				aAuxProd[nPos][15] 	+= aProd[nX][15] // (nDesconto+nDescIcm+nDescRed) 											//Desconto
				aAuxProd[nPos][21] 	+= aProd[nX][21] // IIF((SD2->D2_TIPO == "D" .And. !lIpiDev) .Or. lConsig .Or. (Alltrim(SD2->D2_CF) $ cMVCFOPREM ) .or. (SD2->D2_TIPO == "B" .and. lIpiBenef) .or. (SD2->D2_TIPO=="P" .And. lComplDev .And. !lIpiDev) ,SD2->D2_DESPESA + SD2->D2_VALPS3 + SD2->D2_VALCF3 + SD2->D2_VALIPI + nIcmsST, SD2->D2_DESPESA + SD2->D2_VALPS3 + SD2->D2_VALCF3 + nIcmsST) //Outras dispesas
				aAuxProd[nPos][22] 	+= aProd[nX][22] // nRedBC
				aAuxProd[nPos][26] 	+= aProd[nX][26] // nDescZF
				aAuxProd[nPos][29] 	+= aProd[nX][29] // IIf(SubStr(SM0->M0_CODMUN,1,2) == "35" .And. cTpPessoa == "EP" .And. nDescIcm > 0, nDescIcm,0)
				aAuxProd[nPos][30] 	+= aProd[nX][30] // IIF(FieldPos("D2_TOTIMP")<>0,SD2->D2_TOTIMP,0)
				aAuxProd[nPos][31] 	+= aProd[nX][31] // SD2->D2_DESCZFP
				aAuxProd[nPos][32] 	+= aProd[nX][32] // SD2->D2_DESCZFC
				aAuxProd[nPos][33] 	+= aProd[nX][33] // SD2->D2_PICM
				aAuxProd[nPos][35] 	+= aProd[nX][35] // IIF(FieldPos("D2_TOTFED")<>0,SD2->D2_TOTFED,0)
				aAuxProd[nPos][36] 	+= aProd[nX][36] // IIF(FieldPos("D2_TOTEST")<>0,SD2->D2_TOTEST,0)
				aAuxProd[nPos][37] 	+= aProd[nX][37] // IIF(FieldPos("D2_TOTMUN")<>0,SD2->D2_TOTMUN,0)

				If Len(aICMSBkp[nX]) >= 30 .AND. Len(aICMS[nPos]) >= 30
					aICMS[nPos][5]  += aICMSBkp[nX][5] //If(lNfCupZero .Or. lIcmsPR,0,CD2->CD2_BC),;
					aICMS[nPos][7]  += aICMSBkp[nX][7] //If(lNfCupZero .Or. lIcmsPR,0,nValtrib)
					aICMS[nPos][9]  += aICMSBkp[nX][9] //CD2->CD2_QTRIB,;
					aICMS[nPos][15] += aICMSBkp[nX][15] //IIf(CD2->(ColumnPos("CD2_DESONE")) > 0,CD2->CD2_DESONE,0),;
					aICMS[nPos][16] += aICMSBkp[nX][16] //IIf(CD2->(ColumnPos("CD2_BFCP")) > 0,xFisRetFCP('4.0','CD2','CD2_BFCP'),0),;
					aICMS[nPos][18] += aICMSBkp[nX][18] //IIf(CD2->(ColumnPos("CD2_VFCP")) > 0,xFisRetFCP('4.0','CD2','CD2_VFCP'),0),;
					aICMS[nPos][20] += aICMSBkp[nX][20] //IIf(SFT->(ColumnPos("FT_BSTANT")) > 0,SFT->FT_BSTANT,0),;
					aICMS[nPos][21] += aICMSBkp[nX][21] //IIf(SFT->(ColumnPos("FT_VSTANT")) > 0,xFisRetFCP('4.0','SFT','FT_VSTANT'),0),;
					aICMS[nPos][23] += aICMSBkp[nX][23] //IIf(SFT->(ColumnPos("FT_BFCANTS")) > 0, SFT->FT_BFCANTS,0),;
					aICMS[nPos][25] += aICMSBkp[nX][25] //IIf(SFT->(ColumnPos("FT_VFCANTS")) > 0, SFT->FT_VFCANTS,0),;
					aICMS[nPos][26] += aICMSBkp[nX][26] //IIf(SFT->(ColumnPos("FT_VICPRST")) > 0, SFT->FT_VICPRST,0),;
					aICMS[nPos][27] += aICMSBkp[nX][27] //IIf(SFT->(ColumnPos("CD2_DESCZF")) > 0, CD2->CD2_DESCZF,0),;
					aICMS[nPos][28] += aICMSBkp[nX][28] //IIf(CD2->(ColumnPos("CD2_VFCPDI")) > 0, CD2->CD2_VFCPDI,0),;
					aICMS[nPos][29] += aICMSBkp[nX][29] //Iif(CD2->(ColumnPos("CD2_VFCPEF")) > 0, CD2->CD2_VFCPEF,0),;
					aICMS[nPos][30] += aICMSBkp[nX][30] //IIf(SFT->(ColumnPos("FT_VALICM")) > 0,xFisRetFCP('4.0','SFT','FT_VALICM'),0);
				EndIf

				If Len(aPISBkp[nX]) >= 5 .AND. Len(aPIS[nPos]) >= 5
					aPIS[nPos][2] += aPISBkp[nX][2] //CD2->CD2_BC
					aPIS[nPos][4] += aPISBkp[nX][4] //CD2->CD2_VLTRIB
					aPIS[nPos][5] += aPISBkp[nX][5] //CD2->CD2_QTRIB
				EndIf

				If Len(aCOFBkp[nX]) >= 5 .AND. Len(aCOFINS[nPos]) >= 5
					aCOFINS[nPos][2] += aCOFBkp[nX][2] //CD2->CD2_BC
					aCOFINS[nPos][4] += aCOFBkp[nX][4] //CD2->CD2_VLTRIB
					aCOFINS[nPos][5] += aCOFBkp[nX][5] //CD2->CD2_QTRIB
				EndIf

				If Len(aICMSMonBkp[nX]) >= 30 .AND. Len(aICMSMONO[nPos]) >= 30
					aICMSMONO[nPos][5]  += aICMSMonBkp[nX][5] //If(lNfCupZero .Or. lIcmsPR,0,CD2->CD2_BC),;
					aICMSMONO[nPos][7]  += aICMSMonBkp[nX][7] //If(lNfCupZero .Or. lIcmsPR,0,nValtrib)
					aICMSMONO[nPos][9]  += aICMSMonBkp[nX][9] //CD2->CD2_QTRIB,;
					aICMSMONO[nPos][15] += aICMSMonBkp[nX][15] //IIf(CD2->(ColumnPos("CD2_DESONE")) > 0,CD2->CD2_DESONE,0),;
					aICMSMONO[nPos][16] += aICMSMonBkp[nX][16] //IIf(CD2->(ColumnPos("CD2_BFCP")) > 0,xFisRetFCP('4.0','CD2','CD2_BFCP'),0),;
					aICMSMONO[nPos][18] += aICMSMonBkp[nX][18] //IIf(CD2->(ColumnPos("CD2_VFCP")) > 0,xFisRetFCP('4.0','CD2','CD2_VFCP'),0),;
					aICMSMONO[nPos][20] += aICMSMonBkp[nX][20] //IIf(SFT->(ColumnPos("FT_BSTANT")) > 0,SFT->FT_BSTANT,0),;
					aICMSMONO[nPos][21] += aICMSMonBkp[nX][21] //IIf(SFT->(ColumnPos("FT_VSTANT")) > 0,xFisRetFCP('4.0','SFT','FT_VSTANT'),0),;
					aICMSMONO[nPos][23] += aICMSMonBkp[nX][23] //IIf(SFT->(ColumnPos("FT_BFCANTS")) > 0, SFT->FT_BFCANTS,0),;
					aICMSMONO[nPos][25] += aICMSMonBkp[nX][25] //IIf(SFT->(ColumnPos("FT_VFCANTS")) > 0, SFT->FT_VFCANTS,0),;
					aICMSMONO[nPos][26] += aICMSMonBkp[nX][26] //IIf(SFT->(ColumnPos("FT_VICPRST")) > 0, SFT->FT_VICPRST,0),;
					aICMSMONO[nPos][27] += aICMSMonBkp[nX][27] //IIf(SFT->(ColumnPos("CD2_DESCZF")) > 0, CD2->CD2_DESCZF,0),;
					aICMSMONO[nPos][28] += aICMSMonBkp[nX][28] //IIf(CD2->(ColumnPos("CD2_VFCPDI")) > 0, CD2->CD2_VFCPDI,0),;
					aICMSMONO[nPos][29] += aICMSMonBkp[nX][29] //Iif(CD2->(ColumnPos("CD2_VFCPEF")) > 0, CD2->CD2_VFCPEF,0),;
					aICMSMONO[nPos][30] += aICMSMonBkp[nX][30] //IIf(SFT->(ColumnPos("FT_VALICM")) > 0,xFisRetFCP('4.0','SFT','FT_VALICM'),0);
				EndIf

			Else
				aadd(aAuxProd, aClone(aProd[nX]) )
				aAuxProd[len(aAuxProd)][1] := len(aAuxProd)
				aAuxProd[len(aAuxProd)][16] := nPrUnit
				aAuxProd[len(aAuxProd)][17] := "" //limpo codANP para nota sobre cupom
				If Len(PARAMIXB)>20
					aadd(aCST, aClone(aCSTBkp[nX]) )
					aadd(aICMS, aClone(aICMSBkp[nX]) )
					aadd(aPIS, aClone(aPISBkp[nX]) )
					aadd(aCOFINS, aClone(aCOFBkp[nX]) )
					aadd(aICMSMONO, aClone(aICMSMonBkp[nX]) )
				Else
					aCST := aClone(aCSTBkp)
					aICMS := aClone(aICMSBkp)
					aPIS := aClone(aPISBkp)
					aCOFINS := aClone(aCOFBkp)
					aICMSMONO := aClone(aICMSMonBkp)
				EndIf
			Endif
		next nX

		//Compatibilizacao do valor total do produto devido ao agrupamento por Produto
		For nX:=1 to Len(aAuxProd)
			aAuxProd[nX][16] := Round(aAuxProd[nX][10]/aAuxProd[nX][9],8)
		Next nX

		//Compatibilização dos itens da Nota
		aProd := {}
		aProd := aClone(aAuxProd)

		//---------------------------------------------//
		//											   //
		//  Fim da compatibilização dos itens da Nota  //
		//											   //
		//---------------------------------------------//
	Endif

	//Mensagens informativas do cupom fiscal: Procon
	If !Empty(cMsgProcon)
		cMensCli += " " + cMsgProcon + cTXTSep
	EndIf

Endif

//-- Se tiver no PDV emitindo NF-e devemos acrescentar as informacoes complementares
If lCodeBase //NF-e no PDV (base CODEBASE)

	SL1->( DbSetOrder(2) ) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
	SL1->( DbSeek( xFilial("SL1") + SF2->F2_SERIE + SF2->F2_DOC ) )

	If lRodCupom .and. SL1->( Found() )
		cMensCli += U_TPDVE005()
	Endif

	//-- TBC-GO - tratamento tags de fatura, duplicata, detalhes de pagamento e troco
	cIdEnt 	:= getCfgEntidade(@cError)
	cVerAmb := getCfgVersao(@cError, cIdEnt, cModel)

	If !Empty(cIdEnt) .And. !Empty(cVerAmb)

		If cVeramb >= "4.00"

			nTrocoTot := SL1->L1_TROCO1
			nTotNota  := aTotal[02]+aTotal[03] //-- nTotNota: Variavel para ter o valor total da nota para ser utilizado na Lei da Transparencia: NFESEFAZ

			//-- tratamento dados da fatura

			//cTexto += "		>> aFat: " + CRLF
			//cTexto += UtoString(aFat) + CRLF
			//cTexto += CRLF

			//cTexto += "		>> aTotal: " + CRLF
			//cTexto += UtoString(aTotal) + CRLF
			//cTexto += CRLF

			//cTexto += "		>> aDetPag: " + CRLF
			//cTexto += UtoString(aDetPag) + CRLF
			//cTexto += CRLF

			//Conout(cTexto)

			If Len(aFat) == 0
				aadd(aFat,Nil)
			EndIf

			aFat[01] := { Iif(Len(aDupl)>0,aDupl[01][01],SF2->F2_SERIE+SF2->F2_DOC), nTotNota, 0, nTotNota }

			SE1->(DBSETORDER(1))
			SE1->(DBSEEK(xFilial("SE1")+SF2->F2_SERIE+SF2->F2_DOC))

			//-- tratamento dados da duplicata

			//cTexto += "		>> aDupl: " + CRLF
			//cTexto += UtoString(aDupl) + CRLF
			//cTexto += CRLF
			//Conout(cTexto)
			//aadd(aDupl,{E1_PREFIXO+E1_NUM+E1_PARCELA,E1_VENCORI,nValDupl})

			//Verifico enquanto a duplicata for encontrada, adiciono no array aDupl
			While !SE1->(EOF()) .And. SE1->E1_FILIAL == xFilial("SE1") .And. SE1->E1_PREFIXO == SF2->F2_SERIE .And. SE1->E1_NUM == SF2->F2_DOC
				If !Empty(SE1->E1_PARCELA)
					aadd(aDupl,{SE1->E1_PARCELA,SE1->E1_VENCTO,SE1->E1_VALOR})
				EndIf
				SE1->(DBSKIP())
			EndDo

			If (Len(aDupl) <= 0)
				//aadd(aDupl,{SF2->F2_SERIE+SF2->F2_DOC,DaySum(Date(),1),0})
				aadd(aDupl,{IiF(Empty(SE1->E1_PARCELA),"001", SE1->E1_PARCELA),SE1->E1_VENCTO,0}) // ajustado de DaySum(Date(),1) para SE1->E1_VENCTO
			EndIf

			nDupl := 0 //-- total das duplicatas
			lDelDup := .F.
			For nX := 1 To Len(aDupl)

				aDupl[nX][01] := StrZero(nX,3)

				If aDupl[nX][02] < DaySum(Date(),1)
					aDupl[nX][02] := DaySum(Date(),1)
				EndIf
				If lDelDup
					aDupl[nX][03] := 0
				ElseIf nDupl + aDupl[nX][03] > nTotNota
					aDupl[nX][03] := nTotNota - nDupl
					nDupl += aDupl[nX][03]
					lDelDup := .T.
				Else
					nDupl += aDupl[nX][03]
				EndIf
			Next nX

			nDifDup := 0 //-- diferença do total de duplicatas e o total da nota
			If Len(aDupl) > 0 .and. (nDupl <> nTotNota)
				If nDupl > nTotNota
					nDifDup := (nDupl - nTotNota)
					For nX := 1 To Len(aDupl)
						If nDifDup >= aDupl[nX][03]
							aDupl[nX][03] -= nDifDup
							nDifDup := 0
						Else
							nDifDup -= aDupl[nX][03]
							aDupl[nX][03] := 0
						EndIf
					Next nX
				Else
					nDifDup := (nTotNota - nDupl)
					aDupl[Len(aDupl)][03] += nDifDup
				EndIf
			EndIf

			aTmpDupl := aClone(aDupl)
			aDupl := {}
			For nX:=1 to Len(aTmpDupl)
				If aTmpDupl[nX][03] > 0
					aadd(aDupl,aTmpDupl[nX])
				EndIf
			Next nX

			//-- Por fim, ordenar o aDupl
			aSort( aDupl, , , { |x,y| x[02]<y[02] } )

			//Obs1: O número de parcelas deve ser informado com 3 algarismos, sequencias e consecutivos. Ex.: "001","002","003",...
			nDup := "001"
			For nX:=1 to Len(aDupl)
				aDupl[nX][01] := nDup
				nDup := Soma1(nDup)
			Next nX
			
			//ajusta o tipo do conteúdo do array aDetPag {cForma, Valor, Troco, Tp Integra, CGC Adm Cartao, Cod Bandeira, Autorização TEF, cIndPag}
			For nX:=1 to Len(aDetPag)
				If ValType(aDetPag[nX][02])=="C" //LjConvType( aFormasPag[nX][2], 15, 2 )
					aDetPag[nX][02] := Val(aDetPag[nX][02])
				EndIf
				If ValType(aDetPag[nX][03])=="C"
					aDetPag[nX][03] := Val(aDetPag[nX][03])
				EndIf
			Next nX

			//PABLO: tratamento troco para formas de pagamento
			//-- tratamento das formas de pagamentos utilizadas
			
			If nTotNota > 0 //-- nTotNota: Variavel para ter o valor total da nota para ser utilizado na Lei da Transparencia: NFESEFAZ

				nTroco := 0 //-- troco total contido no array de pagementos aDetPag
				nVlPar := 0 //-- total das parcelas de pagamento
				//aDetPag -> {cForma, Valor, Troco, Tp Integra, CGC Adm Cartao, Cod Bandeira, Autorização TEF, cIndPag}

				For nX:=1 to Len(aDetPag)
					nVlPar += aDetPag[nX][02]
					nTroco += aDetPag[nX][03]
				Next nX

				//realiza tratamento de troco apenas se meio de pagamento for diferente de 90 - Sem pagamento
				If cMeioPag <> '90'

					If nVlPar < nTotNota
						aDetPag[01][02] := nTotNota+nTroco
						aDetPag[01][03] := nTroco
						nVlPar := nTotNota+nTroco
						aTmpaDetPag := aClone(aDetPag)
						aDetPag := {}
						aadd(aDetPag,aTmpaDetPag[01])
					EndIf

					If (nVlPar - nTroco) <> nTotNota
						nTrocoTot := (nVlPar - nTotNota)
						//-- zero todos os trocos
						For nX:=1 to Len(aDetPag)
							aDetPag[nX][03] := 0
						Next nX
						//-- adiciona o troco certo a forma de primeira forma de pagamento que possibilita troco
						For nX:=1 to Len(aDetPag)
							If aDetPag[nX][02] > nTrocoTot
								aDetPag[nX][03] := nTrocoTot
								EXIT //add pois se tiver mais de uma forma maior, estava adicionando varias vezes o troco
							Else
								aDetPag[nX][03] := 0
							EndIf
						Next nX
					EndIf

				EndIf
			EndIf

			//DANILO: Troca forma cartão fidelidade (pegaponto) para outros
			If aScan(aDetPag, {|x| Alltrim(x[1]) $ '03/04' }) > 0 //ids forma cartao
				nValorFid := 0
				cFormaFid := ""
				SL4->(DbSetOrder(1)) //L4_FILIAL+L4_NUM+L4_ORIGEM
				If SL4->( DbSeek( xFilial( "SL4" ) + SL1->L1_NUM ) )
					While SL4->(!EoF()) .AND. SL4->L4_FILIAL + SL4->L4_NUM == SL1->L1_FILIAL + SL1->L1_NUM 
						If SL4->L4_VALOR > 0 .AND. Alltrim(SL4->L4_FORMA) $ 'CC/CD' 
							//pra saber se teve adm de fidelidade
							if SubStr(SL4->L4_ADMINIS,1,3) $ cMVXADMFID//SuperGetMv("MV_XADMFID",,"")
								nValorFid += SL4->L4_VALOR
								if !empty(cFormaFid) .AND. cFormaFid <> AllTrim(SL4->L4_FORMA)
									//Conout("PE01NFESEFAZ - não será trocada forma cartao fidelidade. permitido somente para uma forma: CC ou CD")
									nValorFid := 0
									EXIT
								endif
								cFormaFid := AllTrim(SL4->L4_FORMA)
							endif
						EndIf
						SL4->( DbSkip() )
					EndDo
				EndIf
				if nValorFid > 0 //se tem adm fid
					nPosAux := aScan(aDetPag, {|x| Alltrim(x[1])==iif(cFormaFid=="CC","03","04") .AND. x[2]==nValorFid .AND. x[4]=='2' })
					if nPosAux > 0
						aDetPag[nPosAux][1] := "19" //19=Programa de fidelidade, Cashback, Crédito Virtual 
						//Conout("PE01NFESEFAZ - Trocada forma pagamento XML de cartão para outros. Adm parametro MV_XADMFID.")
					else
						//Conout("PE01NFESEFAZ - Aborta troca forma fidelidade. Não encontrada linha do cartão fidelidade.")
					endif
				endif
			endif

			//-- O valor da aDetPag for menor que o total da nota deveremos agregar o valor do troco
			nVReceb := 0 //total recebido na aDetPag
			For nX:=1 to Len(aDetPag)

				nVReceb += aDetPag[nX][02] //+ aDetPag[nX][03])

				// se o vencimento da duplicata for com a data atual, é ajustado para "cIndPag" com "0" - a vista
		        If aDetPag[nX][01] $ "01/02"
					nValtrib := aScan(aDupl,{ |x| x[02] == Date() .and. x[03] == aDetPag[nX][02]  } )
					If nValtrib > 0
						aDetPag[nX][08] := "0"	//-- A vista
					EndIf
		        EndIf

			Next nX

			If nVReceb <> (nTotNota + nTrocoTot)
				If nVReceb > (nTotNota + nTrocoTot)
					For nX:=1 to Len(aDetPag)
						If (aDetPag[nX][02] - (nVReceb - (nTotNota + nTrocoTot))) > aDetPag[nX][03]
							aDetPag[nX][02] -= (nVReceb - (nTotNota + nTrocoTot))	//-- Este Valor tem que ser Bruto (Total da Nota + Troco)
							Exit
						EndIf
					Next nX
				Else
					aDetPag[01][02] += (nTotNota + nTrocoTot) - nVReceb	//-- Este Valor tem que ser Bruto (Total da Nota + Troco)
				EndIf
			EndIf

			//TODO: Rejeição 436: Informado 99 - Outros como meio de pagamento
			For nX:=1 to Len(aDetPag)
				If aDetPag[nX][1] == "99" //99=Outros
					aDetPag[nX][1] := "05" //05=Crédito Loja  
				EndIf
			Next nX

		EndIf
	EndIf

EndIf

//Remove caracter especial e acento - FwCutOff
//cMensCli := StrTran(cMensCli,chr(13)+chr(10),'')
//cMensFis := AllTrim(cMensFis)
//cMensCli := AllTrim(cMensCli)

cMensCli := StrTran(FwCutOff(cMensCli,.T.),chr(13)+chr(10),'')
cMensFis := AllTrim(FwCutOff(cMensFis,.T.))
cMensCli := AllTrim(cMensCli)

//-- Verifica se existe CD6 para os Itens
if !lNfCupom

	cGrupo := AllTrim( GetMV("MV_COMBUS") )

	aCombBKP := {}

	SB1->( DbSetOrder(1) )
	CD6->( DbSetOrder(1) )

	For nPos:=1 to Len(aProd)

		//-- Produto pertence ao grupo de combustivel? Se encontrar 1 ai sai do laço e repassa a funcao
		//-- para geração da CD6
		SB1->( DbSeek( xFilial("SB1") + aProd[nPos][02] ) )
		If SB1->( Found() ) .and. AllTrim(SB1->B1_GRUPO) $ cGrupo .and. ;
			!CD6->( MsSeek( xFilial("CD6") + "S" + aNota[1] + aNota[2] + SF2->F2_CLIENTE + SF2->F2_LOJA + PadR(StrZero(nPos,2),4) + aProd[nPos][02] ) )

			SL1->( DbSetOrder(2), DbSeek( xFilial("SL1") + aNota[1] + aNota[2] ) )
			aCombBKP 	:= GeraCD6NFe(2, aProd)
			aComb 		:= aClone(aCombBKP)
			Exit
		EndIf

	Next nPos

else 

	For nPos:=1 to Len(aProd)

		cGrupo := AllTrim( GetMV("MV_COMBUS") )
		cCodAnp := ""

		//-- Produto pertence ao grupo de combustivel? Se encontrar 1 ai sai do laço e repassa a funcao
		//-- para geração da CD6
		if SB1->( DbSeek( xFilial("SB1") + aProd[nPos][02] ) )

			if AllTrim(SB1->B1_GRUPO) $ cGrupo

				if SB1->(FieldPos("B1_CODSIMP")) > 0
					cCodAnp := SB1->B1_CODSIMP
				endif

				SB5->(DbSetOrder(1)) // B5_FILIAL+B5_COD
				if empty(cCodAnp) .AND. SB5->(DbSeek(xFilial("SB5") + SB1->B1_COD))
					cCodAnp := SB5->B5_CODANP
				Endif

				If (aScan(aANPS,{|x| x == AllTrim(cCodAnp) })) > 0

					SZO->(DbSetOrder(1)) // ZO_FILIAL+ZO_CODCOMB
					if SZO->(DbSeek(xFilial("SZO") + cCodAnp))
						
						cDescANP 	:= SZO->ZO_DESCRI
						cEstado		:= SM0->M0_ESTCOB

						aComb[nPos,1]  := cCodAnp 
						aComb[nPos,14] := cDescANP
						aComb[nPos,4]  := cEstado
						aComb[nPos,24] := 100 //isso mesmo 

					endif 

				endif

			endif

		EndIf

	Next nPos

endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Informações adicionais da Nota Fiscal: cálculo da substituição tributária³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lCodeBase .OR. lNfCupom

	//Validação para controle das tags que deverão ser preenchidas apenas nas operações não destinadas a consumidor final RS
	lRetEfet := (cMVEstado == "RS" .and. cIndFinal == '0') .or. cMVEstado <> "RS"

	aTotICMSST := {0,0,0}
	For nX := 1 To Len(aProd)

		cArt274 := aProd[nX][48]
		If /*Len(aIcmsST[nX])>0 .And. */Len(aComb[nX]) > 0 /*.And. cVeramb >= "4.00"*/ .and. Len(aCST[nX]) > 0 .and. aCST[nX][1] $ "60" /*.And. aComb[nX][01] $ NfeProdANP()*/

			If lRetEfet

				nBaseIcm := aICMS[nX][20]    //SFT->FT_BSTANT
				nValICM  := aICMS[nX][21]    //SFT->FT_VSTANT
				nAlqICM  := aICMS[nX][22]    //SFT->FT_PSTANT
				nBfcpant := aICMS[nX][23]    //SFT->FT_BFCANTS
				nAfcpant := aICMS[nX][24]    //SFT->FT_PFCANTS
				nVfcpant := aICMS[nX][25]    //SFT->FT_VFCANTS
				nVICPRST := aICMS[nX][26]    // FT_VICPRST  (Tag vICMSSubstituto)

				If aComb[nX][19] > 0
					nSTBase := aComb[nX][19]
					nSTValr := aComb[nX][20]
					nAlqICM := aComb[nX][23]
				ElseIf nBaseIcm > 0 
					nSTBase := nBaseIcm
					nSTValr := nValICM
				Else
					nSTBase := 0
					nSTValr := 0
				Endif		
				nSTPerc := nAlqICM

				If (aCST[nX][01] = "60" /*.or. cCsosn$ "500"*/)
					//Se o parâmetro  MV_ULTAQUI que trata a última aquisição não estiver preenchido usa o modelo antigo de rastro.
					If Empty(cUltAqui) 
						SPEDRastro2(aProd[nX][20],aProd[nX][19],aProd[nX][02],@nBaseIcm,@nValICM,,,lCalcMed,@nAlqICM,,,,,,,,,,,@nBfcpant,@nAfcpant,@nVfcpant)
						
						If nBaseIcm > 0 .and. nValICM>0
							nBaseIcm := aProd[nX][09]*nBaseIcm
							nValICM  := aProd[nX][09]*nValICM
						EndIf
						//Multiplica o valor facp anterior pela quantidade de item.
						If	nBfcpant > 0 .and. nVfcpant>0
							nBfcpant  := aProd[nX][09]*nBfcpant
							nVfcpant  := aProd[nX][09]*nVfcpant
						EndIf
					EndIf
						
					If nBaseIcm > 0 .and. nValICM > 0	.and. nAlqICM > 0
						If Len(cMensFis) > 0 .And. SubStr(cMensFis, Len(cMensFis), 1) <> " "
							cMensFis += " "
						EndIf
						If cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "SP"
							// cMensFis += "Imposto Recolhido por Substituição - Artigo 274 do RICMS (Lei 6.374/89, art.67,Paragrafo 1o., e Ajuste SINIEF-4/93',cláusa terceira, na redação do Ajuste SINIEF-1/94) 'Cod.Produto:  " +ConvType(aProd[nX][02])+" ' Valor da Base de ST: R$ " +str(nBaseIcm,15,2)+" Valor de ICMS ST: R$ "+str(nValICM,15,2)+" "
							If Empty(At("Artigo 274 do RICMS", cMensFis))
								cMensFis += "Imposto Recolhido por Substituição - Artigo 274 do RICMS (Lei 6.374/89, art.67,Paragrafo 1o., e Ajuste SINIEF-4/93',cláusa terceira, na redação do Ajuste SINIEF-1/94) &|"+ConvType(aProd[nX][02])+"|"+AllTrim(str(nValICM,15,2))+"|&"
							Else
								cMensFis := AllTrim(cMensFis) + "|"+ConvType(aProd[nX][02])+"|"+AllTrim(str(nValICM,15,2))+"|&"
							EndIf

						ElseIF cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "PR"  
							If SF4->F4_CODIGO > "500"  /* TES de Saída */  
								//Decreto 6080/2012 com o Regulamento do ICMS está revogado
								cMensFis += " Imposto Recolhido por Substituição - ART. 5º, II , ANEXO IX ,DO RICMS/PR DECRETO 7871/2017 - DOE PR de 02.10.2017, onde o 'Cod.Produto:  " +ConvType(aProd[nX][02])+" '  Valor da Base de ST: R$ " +Alltrim(str(nBaseIcm,15,2))+" Valor de ICMS ST: R$ "+Alltrim(str(nValICM,15,2))+" "
							Else //entrada
								cMensFis += " Imposto Recolhido por Substituição - ART. 5º, I  , ANEXO IX ,DO RICMS/PR DECRETO 7871/2017 - DOE PR de 02.10.2017, onde o 'Cod.Produto:  " +ConvType(aProd[nX][02])+" '  Valor da Base de ST: R$ " +Alltrim(str(nBaseIcm,15,2))+" Valor de ICMS ST: R$ "+Alltrim(str(nValICM,15,2))+" "
							EndIf
							/* Conforme consulta realizado no chamado TIBIKO
							cMensFis += "Imposto Recolhido por Substituição - Artigo 471 do RICMS (Parágrafo 1o, alínea B, inciso II, onde o 'Cod.Produto:  " +ConvType(aProd[nX][02])+" ' Valor da Base de ST: R$ " +str(nBaseIcm,15,2)+" Valor de ICMS ST: R$ "+str(nValICM,15,2)+" "
							*/
						ElseIF cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "SC"  
							lPesFisica := IIF(SA1->A1_PESSOA=="F",.T.,.F.)
							lNContrICM := IIf(Empty(SA1->A1_INSCR) .Or. "ISENT"$SA1->A1_INSCR .Or. "RG"$SA1->A1_INSCR .Or. ( SA1->(FieldPos("A1_CONTRIB"))>0 .And. SA1->A1_CONTRIB == "2"),.T.,.F.)
							
							If !lPesFisica .And. !lNContrICM 
								cMensFis += "Imposto Retido por Substituição Tributária - RICMS-SC/01 - Anexo 3. 'Cod.Produto: " +ConvType(aProd[nX][02])+" '  Valor da Base de ST: R$ " +str(nBaseIcm,15,2)+"  Valor de ICMS ST: R$ "+str(nValICM,15,2)+" "
							EndIf	 	
						ElseIF cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "AM"
							lNContrICM := IIf(Empty(SA1->A1_INSCR) .Or. "ISENT"$SA1->A1_INSCR .Or. "RG"$SA1->A1_INSCR .Or. ( SA1->(FieldPos("A1_CONTRIB"))>0 .And. SA1->A1_CONTRIB == "2"),.T.,.F.)
							
							If (lNContrICM .And. SA1->A1_EST <> "AM") .Or. SA1->A1_EST == "AM"  //Conforme consulta (TGVUIP).
								cMensFis += "Mercadoria já tributada nas demais fases de comercialização - Convênio ou Protocolo ICMS nº "+Alltrim(aProd[nX][28])+ ". Cod.Produto: " +ConvType(aProd[nX][02])+"."
							EndIf
						
						ElseIF cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "RS"			 
							If !Empty(aProd[nX][28])				 	
								cMensFis += "Imposto recolhido por ST nos termos do (Convênio ou Protocolo ICMS nº "+ Alltrim(aProd[nX][28]) +") RICMS-RS. Valor da Base de ICMS ST R$"+ cValToChar(nBaseIcm) +" e valor do ICMS ST R$ "+ cValToChar(nValICM) +". Cod.Produto: " +ConvType(aProd[nX][02])+"." 
							Else
								cMensFis += "Imposto recolhido por ST nos termos do RICMS-RS. Valor da Base de ICMS ST R$"+ cValToChar(nBaseIcm) +" e Valor do ICMS ST R$"+ cValToChar(nValICM) +". Cod.Produto: " +ConvType(aProd[nX][02])+"."
							EndIf					 	
						ElseIf cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "ES" .And. Len(aICMS) > 0 .And. ( nBaseIcm+nValICM > 0 )
							
							nValIcmDif := ( (nBaseIcm *  17 )/ 100 ) -  aICMS[nX][7]
										
							cMensFis += "Imposto Recolhido por Substituição RICMS. Cod.Produto:  " +ConvType(aProd[nX][02])+" Base de cálculo da retenção - R$ " + Alltrim(str(nBaseIcm,15,2))+". " 
							cMensFis += "ICMS da operação própria do contribuinte substituto - R$ "+Alltrim(str(aICMS[nX][7],15,2))+". "
							cMensFis += "ICMS retido pelo contribuinte substituto - R$ " +Alltrim(str(nValIcmDif,15,2))+". "
						ElseIf cArt274 == "1"  .And. IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "MG" .And. Len(aICMS) > 0 .And. ( nBaseIcm+nValICM > 0 )  // Conforme Chamado TIABCS
							
							If Empty(cUltAqui)
								nVICPRST := ( (nBaseIcm * 18 )/ 100 ) - aICMS[nX][7]
							Endif
							
							aTotICMSST[1] += nBaseIcm
							aTotICMSST[2] += nValICM
							aTotICMSST[3] += nVICPRST

							If len(aProd) == nX
								cMensFis += "Imposto Recolhido por Substituição - ICMS retido pelo cliente S.T. DECRETO 43708 19/12/2009."
								cMensFis += " Valor da Base de ST: R$ "+Alltrim(str(aTotICMSST[1],15,2))+"."
								cMensFis += " Valor de ICMS ST: R$ "+Alltrim(str(aTotICMSST[2],15,2))+"."
								cMensFis += " Valor de ICMS: R$"+Alltrim(str(aTotICMSST[3],15,2))+"."
							EndIf

						ElseIf IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "SP" 
							If cIndFinal == "1"
								cMensFis += "Imposto Recolhido por Substituição - Contempla o artigo 313-Z19 do RICMS-SP."
							Else
								//Artigo somente para o estado de SP - DSERTSS1-6532
								//http://tdn.totvs.com.br/pages/releaseview.action?pageId=267795989
								cMensFis += "Imposto Recolhido por Substituição - Contempla os artigos 273, 313 do RICMS. Valor da Base de ST: R$ "+Alltrim(str(nBaseIcm,15,2))+" Valor de ICMS ST: R$ "+Alltrim(str(nValICM,15,2))+" "
							EndIf

						ElseIf IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) == "RJ"
							If aComb[nX][01] $ NfeProdANP()
								//http://jiraproducao.totvs.com.br/browse/DSERTSS1-11434
								cMensFis += "ICMS a ser repassado nos termos do Capítulo V do Convênio ICMS 110/07. Valor da Base de ST: R$ "+Alltrim(str(nBaseIcm,15,2))+" Valor de ICMS ST: R$ "+Alltrim(str(nValICM,15,2))+" "
							ElseIf cArt274 == "1"
								cMensFis += "ICMS RECOLHIDO ANTECIPADO POR SUBS. TRIBUTARIA CONF. INC. II ART 27 DO LIVRO II, E ITEM 23 DO ANEXO I DO LIVRO II DO RICMS"	
							EndIf
						ElseIf nSTBase > 0 .and. nSTValr > 0
							cMensFis += "Produto: " + AllTrim(aProd[nX][02]) + cTXTSep + " BC-ST: R$ " + AllTrim( Transform(nSTBase,"@E 99,999,999,999.99")) + cTXTSep + " ALIQ.: "+AllTrim(Transform(nSTPerc,"@E 999.99"))+"%" + cTXTSep + " ICMS-ST: R$ "+AllTrim(Transform(nSTValr,"@E 99,999,999,999.99"))+" "
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf

	Next nX

EndIf

//POSTO-787 - Arrumar data da Fatura na NF
If lNfCupom .and. !Empty(cNrNota) .and. !Empty(cSerNota)
	aDupl := AjustDtFat(aDupl,cNrNota,cSerNota)
EndIf


RestArea(aSL1)
RestArea(aMDL)
RestArea(aSF2)
RestArea(aSD2)
RestArea(aSB1)
RestArea(aSF4)
RestArea(aSA1)

//Conout("	>> TRETP013 - Chamado pelo P.E. PE01NFESEFAZ na montagem do XML - FIM")
//Conout("	>> DATA: "+ DToC(Date()) +" - HORA: " + Time())
aRetorno := {}
aadd(aRetorno,aProd)    	//1
aadd(aRetorno,cMensCli) 	//2
aadd(aRetorno,cMensFis) 	//3
aadd(aRetorno,aDest)    	//4
aadd(aRetorno,aNota)    	//5
aadd(aRetorno,aInfoItem)    //6
aadd(aRetorno,aDupl)        //7
aadd(aRetorno,aTransp)      //8
aadd(aRetorno,aEntrega)     //9
aadd(aRetorno,aRetirada)    //10
aadd(aRetorno,aVeiculo)     //11
aadd(aRetorno,aReboque)     //12
aadd(aRetorno,aNfVincRur)   //13
aadd(aRetorno,aEspVol)  	//14
aadd(aRetorno,aNfVinc)		//15
aadd(aRetorno,aDetPag)		//16
aadd(aRetorno,aObsCont)		//17
aadd(aRetorno,aProcRef)		//18
aadd(aRetorno,aMed)			//19
aadd(aRetorno,aLote)		//20
aadd(aRetorno,aComb)		//21
aadd(aRetorno,cIndPres)		//22
aadd(aRetorno,cModFrete)	//23
aadd(aRetorno,aFat)			//24
aadd(aRetorno,aTotal)		//25
aadd(aRetorno,aCST)			//26
aadd(aRetorno,aICMS)		//27
aadd(aRetorno,cVerAmb)		//28
aadd(aRetorno,aPIS)			//29
aadd(aRetorno,aCOFINS)		//30
aadd(aRetorno,aICMSMONO)	//31

Return aRetorno

/*/{Protheus.doc} GeraCD6NFe
NFC-e e NF-e Tags de Combustivel
@author thebr
@since 06/02/2019
@version 1.0
@return aComb
@param nTp, numeric, descricao
@param aProd, array, descricao
@type function
/*/
Static Function GeraCD6NFe(nTp,aProd)

	Local aArea := GetArea()
	Local aSL2 := SL2->( GetArea() )
	Local aSD2 := SD2->( GetArea() )

	Local cProdANP := "", cDescANP := "", cGrupo := ""
	Local aComb := {}, aCD6 := {}
	Local aCombMono := {}
	Local lInc  := .F.
	Local ix    := 0

	//Alimentação do Grupo de Repasse
	Local nBRICMSO 	:= 0
	Local nICMRETO	:= 0
	Local nBRICMSD 	:= 0
	Local nICMRETD	:= 0

	Local cMvEstado		:= SuperGetMv("MV_ESTADO",,"")

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

	SL2->( DbSetOrder(3) )
	SL2->( DbSeek( xFilial("SL2") + SL1->L1_SERIE + SL1->L1_DOC ) )

	while !SL2->( Eof() ) .and. SL1->L1_NUM == SL2->L2_NUM .and. SL1->L1_FILIAL == xFilial("SL1")

		SB1->( DbSeek( xFilial("SB1") + SL2->L2_PRODUTO ) )

		//-- Consultar tabela de código ANP
		cProdANP := IIF(SB1->(FieldPos("B1_CODSIMP"))<>0,SB1->B1_CODSIMP,"")
		cProdANP := IIF(!Empty(cProdANP),cProdANP,Posicione("SB5",1,xFilial("SB5")+SL2->L2_PRODUTO,"B5_CODANP"))
		cDescANP := Posicione("SZO",1,xFilial("SZO")+cProdANP,"ZO_DESCRI") //ZO_FILIAL+ZO_CODCOMB

		//-- Verifica se precisa da TAG Combustivel
		if Empty(cProdANP) .or. !AllTrim(SB1->B1_GRUPO) $ cGrupo

			SL2->( DbSkip() )
			Loop

		endif

		//Alimentação do Grupo de Repasse
		If SD2->(FieldPos("D2_BRICMSO")) > 0
			If SD2->(DbSeek(xFilial("SD2")+SL1->(L1_DOC+L1_SERIE+L1_CLIENTE+L1_LOJA)+SL2->L2_PRODUTO+SL2->L2_ITEM))
				nBRICMSO 	:= SD2->D2_BRICMSO
				nICMRETO	:= SD2->D2_ICMRETO
				nBRICMSD 	:= SD2->D2_BRICMSD
				nICMRETD	:= SD2->D2_ICMRETD
			EndIf
		EndIf

		lInc := CD6->( MsSeek( xFilial("CD6") + "S" + SL1->L1_SERIE + SL1->L1_DOC + SL1->L1_CLIENTE + SL1->L1_LOJA + PadR(SL2->L2_ITEM,4) + SL2->L2_PRODUTO ) )

		If lInc
			//Conout("registro CD6 alterado")
		Else
			//Conout("registro CD6 incluido")
		Endif

		RecLock("CD6", !lInc)

			CD6->CD6_FILIAL := xFilial("CD6")
			CD6->CD6_TPMOV	:= "S"
			CD6->CD6_DOC	:= SL1->L1_DOC
			CD6->CD6_SERIE 	:= SL1->L1_SERIE
			CD6->CD6_ESPEC 	:= SF2->F2_ESPECIE
			CD6->CD6_CLIFOR	:= SL1->L1_CLIENTE
			CD6->CD6_LOJA  	:= SL1->L1_LOJA
			CD6->CD6_ITEM  	:= SL2->L2_ITEM
			CD6->CD6_COD   	:= SL2->L2_PRODUTO
	//		CD6->CD6_SEFAZ 	:= SL1->L1_KEYNFCE	(essa informação pelo menos em GO esta negando as notas!!!
			CD6->CD6_HORA  	:= SL1->L1_HORA
			CD6->CD6_CODANP	:= cProdANP
			if CD6->(FieldPos("CD6_DESANP")) > 0 //-- Descrição do produto-ANP (Utilizado na geração da tag <descANP>)
				CD6->CD6_DESANP := cDescANP
			endif
			CD6->CD6_QTDE  	:= SL2->L2_QUANT
			CD6->CD6_VOLUME	:= SL2->L2_QUANT //VALIDAR VOLUME
			CD6->CD6_UFCONS	:= cMvEstado //SM0->M0_ESTCOB	//-- Venda Presencial

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

			endif

		CD6->( MsUnLock() )

		//-- Carrega dados na aComb
		if nTp == 2
			aCombMono := {}

			aAdd(aCombMono, { ;
				IIf(CD6->(ColumnPos("CD6_INDIMP")) > 0,	CD6->CD6_INDIMP,""),;	// 01
				IIf(CD6->(ColumnPos("CD6_UFORIG")) > 0,	CD6->CD6_UFORIG,""),;	// 02
				IIf(CD6->(ColumnPos("CD6_PORIG")) > 0 ,	CD6->CD6_PORIG ,0 );	// 03
			})

			//ix := aScan(aProd,{|x| x[02] == SL2->L2_PRODUTO .and. x[09] == SL2->L2_QUANT })
			//aComb[ ix ] :=
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
							aCombMono,; //25
							CD6->CD6_QTDE,; //--[26]
							SL2->L2_PRODUTO,; //--[27]
							.F. } ) //--[28] 
		endif

		SL2->( DbSkip() )

	enddo

	//-- Deve-se preencher aqui devido a ordem "aProd" no NFSEFAZ
	If nTp == 2

		CD6->( DbSetOrder(1) ) //CD6_FILIAL+CD6_TPMOV+CD6_SERIE+CD6_DOC+CD6_CLIFOR+CD6_LOJA+CD6_ITEM+CD6_COD+CD6_PLACA+CD6_TANQUE
		For ix:=1 to Len(aProd)

			nTP := aScan(aCD6,{|x| !x[28] .and. x[27] == aProd[ix][02] .and. x[26] == aProd[ix][09] })
			If nTP > 0
				aComb[ix] := aClone(aCD6[nTp])
				aCD6[nTp][28] := .T.
			EndIf

		Next ix

	EndIf

	RestArea( aSL2 )
	RestArea( aSD2 )
	RestArea( aArea )

Return aComb

/*/{Protheus.doc} UtoString
Funcao para transformar variavis em string.

@author pablo
@since 27/09/2018
@version 1.0
@return cString
@param xValue, , descricao
@type function
/*/
Static Function UtoString(xValue)

	Local cRet, nI, cType
	Local cAspas := ''//'"'

	cType := valType(xValue)

	DO CASE
		case cType == "C"
			return cAspas+ xValue +cAspas
		case cType == "N"
			return CvalToChar(xValue)
		case cType == "L"
			return if(xValue,'.T.','.F.')
		case cType == "D"
			return cAspas+ DtoC(xValue) +cAspas
		case cType == "U"
			return "null"
		case cType == "A"
			cRet := '['
			For nI := 1 to len(xValue)
				if(nI != 1)
					cRet += ', '
				endif
				cRet += UtoString(xValue[nI])
			Next
			return cRet + ']'
		case cType == "B"
			return cAspas+'Type Block'+cAspas
		case cType == "M"
			return cAspas+'Type Memo'+cAspas
		case cType =="O"
  			return cAspas+'Type Object'+cAspas
  		case cType =="H"
	  		return cAspas+'Type Object'+cAspas
	ENDCASE

return "invalid type"

//
// Converte em valor da STRING em NUMERICO
// Ex.: 1) RetValr("0230011",3) -> 230.011
//      2) RetValr("565654550",2) -> 5,656,545.50
//
Static Function RetValr(cStr,nDec)
	cStr := SubStr(cStr,1,(Len(cStr)-nDec)) + "." + SubStr(cStr,(Len(cStr)-nDec)+1,Len(cStr)-(Len(cStr)-nDec))
Return Val(cStr)


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

static FUNCTION NoAcento(cString)
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

//-----------------------------------------------------------------------
/*/{Protheus.doc} NfeProdANP

Grupo ICMS60 (id:N08) informado indevidamente nas operações
com os produtos combustíveis sujeitos a repasse interestadual
(tag:cProdANP).

@param		Nil  
@return    cString	String contendo os codigos de produto ANP não permitidos para gerar o grupo ICMS60 quando cst 60.
                       
@author Thiago Y. M. Nascimento
@since 21/03/2018
@version 1.0 
/*/
//-----------------------------------------------------------------------
Static Function NfeProdANP()

Local cRetorno 	:= ""

	cRetorno := "210203001|320101001|320101002|320102002|320102001|320102003|320102005|320201001|"
	cRetorno += "320103001|220102001|320301001|320103002|820101032|820101026|820101027|820101004|"
	cRetorno += "820101005|820101022|820101031|820101030|820101014|820101006|820101016|820101015|"
	cRetorno += "820101025|820101017|820101018|820101019|820101020|820101021|420105001|420101005|"
	cRetorno += "420101004|420102005|420102004|420104001|820101033|820101034|420106001|820101011|"
	cRetorno += "820101003|820101013|820101012|420106002|830101001|420301004|420202001|420301001|"
	cRetorno += "420301002|410103001|410101001|410102001|430101004|510101001|510101002|510102001|"
	cRetorno += "510102002|510201001|510201003|510301003|510103001|510301001|"
	
Return cRetorno

/*/{Protheus.doc} AjustDtFat
Rotina que monta os detalhes da fatura, baseado na nota sobre cupom;
Ticket: POSTO-787 - Arrumar data da Fatura na NF

aDupl [1] -> {{"",DATE(),0}}
-> [1] N. DUPLICATA
-> [2] VENCIMENTO
-> [3] VALOR

@type function
@version 12.1.33
@author Pablo Nunes
@since 26/04/2023
@param aDupl, array, array com os dados da fatura: numero, valor, deseconto e liquido
@return array, retorna o aDupl
/*/
Static Function AjustDtFat(aDupl,cNrNota,cSerNota)

	Local cQry := ""
	Local aDupBkp := aClone(aDupl)
	Local nTotAntes := 0
	Local nTotDepois := 0
	DEFAULT aDupl := {{"",DATE(),0}}

	aEval(aDupl, {|x| nTotAntes += x[3] })

	cQry := "select E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VENCORI, E1_VALOR, E1_VLRREAL, E1_VLCRUZ " + CRLF
	cQry += " from " + RetSqlName("MDL") + " MDL " + CRLF
	cQry += " inner join " + RetSqlName("FI7") + " FI7 on (FI7.D_E_L_E_T_ = ' ' and FI7_FILIAL = MDL_FILIAL and FI7_PRFORI = MDL_SERCUP and FI7_NUMORI = MDL_CUPOM) " + CRLF
	cQry += " inner join " + RetSqlName("SE1") + " SE1 on (SE1.D_E_L_E_T_ = ' ' and E1_FILIAL = FI7_FILDES and E1_PREFIXO = FI7_PRFDES and E1_NUM = FI7_NUMDES and E1_PARCELA = FI7_PARDES and E1_TIPO = FI7_TIPDES) " + CRLF
	cQry += " where MDL.D_E_L_E_T_ = ' ' " + CRLF
	cQry += " and MDL_NFCUP = '" + cNrNota + "' " + CRLF
	cQry += " and MDL_SERIE = '" + cSerNota + "' " + CRLF
	cQry += " and MDL_FILIAL = '" + xFilial("MDL") + "' " + CRLF
	cQry += " group by E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VENCORI, E1_VALOR, E1_VLRREAL, E1_VLCRUZ " + CRLF
	cQry += " order by E1_FILIAL, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VENCORI " + CRLF

	If Select("QRYFAT") > 0
		QRYFAT->( DbCloseArea() )
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYFAT"

	If QRYFAT->(!Eof())
		aDupl := {}
		While QRYFAT->(!Eof())
			aadd(aDupl,{QRYFAT->E1_PREFIXO+QRYFAT->E1_NUM+QRYFAT->E1_PARCELA,StoD(QRYFAT->E1_VENCORI),IIF(QRYFAT->E1_VLRREAL>0,QRYFAT->E1_VLRREAL,QRYFAT->E1_VLCRUZ)})
		QRYFAT->(DbSkip())
		EndDo
	EndIf

	QRYFAT->(DbCloseArea())

	aEval(aDupl, {|x| nTotDepois += x[3] })

	if nTotDepois <> nTotAntes
		aDupl := aDupBkp
	endif

	//cTexto += "AjustDtFat >> aDupl: " + CRLF
	//cTexto += UtoString(aDupl) + CRLF
	//cTexto += CRLF
	//Conout(cTexto)

Return aDupl
