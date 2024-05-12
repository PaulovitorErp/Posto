#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVE005
Rodape do cupom fiscal
Funcao chamada pelo parametro MV_LJFISMS

@author thebr
@since 27/11/2018
@version 1.0
@return cTxt, Texto a ser impresso no rodapé do Cupom, NFC-e ou NF-e

@type function
/*/
user function TPDVE005()

	Local aArea := GetArea()
	Local aAreaSA1 := SA1->(GetArea())
	Local aAreaSL2 := SL2->(GetArea())

	Local cTxt := ""
	Local cTXTSep  := " /" //caracter que separa as informações
	Local cNumSL1 := ""
	Local cAux := ""

	Local cMsgProcon := AllTrim(SuperGetMV("MV_XPROCON",,"")) //Mensagens informativas do cupom fiscal: Procon (Ex.: PROCON MT - Av. Baltazar Navarros, N.567, Bairro Bandeirantes, Cuiabá-MT, CEP 78010-020. Tel: 151 ou (65)3613-2100)
	Local lMsgVend := SuperGetMV("MV_XINFVEN",,.F.) //Habilita dados do vendedor no rodapé do cupom (default .F.)

	//Se vier do recebimento de titulos retorne
	If IsInCallStack("TELAREC")
		Return ""
	EndIf

	//pegando numero do cupom
	If Type('M->LQ_NUM') == 'C'
		cNumSL1 := M->LQ_NUM
	Else
		cNumSL1 := SL1->L1_NUM
	EndIf

	//bomba, bico, encerrantes (EI e EF)
	SL2->(dbsetorder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
	If SL2->(dbseek(xFilial("SL2")+cNumSL1)) //
		While SL2->(!Eof()) .and. xFilial("SL2") == SL2->L2_FILIAL .and. cNumSL1 == SL2->L2_NUM
			If !Empty(SL2->L2_MIDCOD)
				MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
				If MID->(DbSeek(xFilial("MID") + SL2->L2_MIDCOD))
					cTxt += "Item: "+SL2->L2_ITEM + cTXTSep
					cTxt += " Num.Abast: "+SL2->L2_MIDCOD + cTXTSep
					cTxt += " Bomba: "+MID->MID_CODBOM + cTXTSep
					cTxt += " Bico: "+MID->MID_CODBIC + cTXTSep
					If IsInCallStack("U_PE01NFESEFAZ") //ja tem SL1 gravada
						cTxt += " EI: "+Alltrim(Transform(MID->MID_ENCINI,"@E 999,999,999.999")) + cTXTSep
						cTxt += " EF: "+Alltrim(Transform(MID->MID_ENCFIN,"@E 999,999,999.999")) + cTXTSep
					endif
				EndIf
			EndIf
			SL2->(dbskip())
		EndDo
	EndIf

	//Dados Complementares
	If IsInCallStack("U_PE01NFESEFAZ") //ja tem SL1 gravada
		If !Empty(SL1->L1_SERIE)
			cTxt += " Serie: " + AllTrim(SL1->L1_SERIE) + cTXTSep
		EndIf
		If !Empty(SL1->L1_PDV)
			cTxt += " PDV: " + Alltrim(SL1->L1_PDV) + cTXTSep
		EndIf
		If !Empty(SL1->L1_OPERADO)
			cTxt += " OPERADOR: " + PadR(SL1->L1_OPERADO,TamSX3("L1_OPERADO")[1]) + cTXTSep
		EndIf
		If !Empty(SL1->L1_NUMMOV)
			cTxt += " N.MOV: " + PadR(SL1->L1_NUMMOV,TamSX3("L1_NUMMOV")[1]) + cTXTSep
		EndIf
		If !Empty(SL1->L1_ESTACAO)
			cTxt += " ESTACAO: " + PadR(SL1->L1_ESTACAO,TamSX3("L1_ESTACAO")[1]) + cTXTSep
		EndIf
		if !Empty(SL1->L1_PLACA)
			cTxt += " Placa: " + Transform(SL1->L1_PLACA,"@!R NNN-9N99") + cTXTSep
		endif
		if SL1->(ColumnPos("L1_ODOMETR")) > 0 .AND. !Empty(SL1->L1_ODOMETR)
			cTxt += " Odometro: " + Alltrim(Transform(SL1->L1_ODOMETR,"@E 999999999999")) + cTXTSep
		endif
		if SL1->(FieldPos("L1_NOMMOTO")) > 0 .and. !Empty(SL1->L1_NOMMOTO)
			cTxt += " Motorista: " + AllTrim(SL1->L1_NOMMOTO) + cTXTSep
		endif
		if SL1->(FieldPos("L1_ENDCOB")) > 0 .AND. !Empty(SL1->L1_ENDCOB)
			cTxt += " Endereco: " + AllTrim(SL1->L1_ENDCOB) + cTXTSep
		endif
		
		//Dados do vendedor no RODAPÉ 
		If lMsgVend .and. SL1->(FieldPos("L1_VEND")) > 0 .and. !Empty(SL1->L1_VEND)
			cTxt += " Vendedor: " + AllTrim(SL1->L1_VEND) + " - " + AllTrim(Posicione("SA3",1,xFilial("SA3")+SL1->L1_VEND,"A3_NOME")) + cTXTSep
		EndIf

		//Observações digitadas no PDV 
		if IsInCallStack("STIPosMain") .AND. FINDFUNCTION( "U_GetMsgNf" )
			cAux := U_GetMsgNf()
			if !empty(cAux)
				cTxt += " Obs: " + AllTrim(cAux)
				if SL1->(FieldPos("L1_MENNOTA")) > 0
					STDSPBasket("SL1","L1_MENNOTA", SubStr(AllTrim(cAux),1,TamSX3("L1_MENNOTA")[1]) ) //para gravar na memória
				endif
			endif
		endif

	Else
		cAux := LJGetStation("LG_SERIE")
		If !Empty(cAux)
			cTxt += " Serie: " + AllTrim(cAux) + cTXTSep
		EndIf
		cAux := Alltrim(LJGetStation("LG_PDV"))
		If !Empty(cAux)
			cTxt += " PDV: " + cAux + cTXTSep
		EndIf
		cAux := PadR(xNumCaixa(),TamSX3("L1_OPERADO")[1])
		If !Empty(cAux)
			cTxt += " OPERADOR: " + cAux + cTXTSep
		EndIf
		cAux := PadR(STDNumMov(),TamSX3("L1_NUMMOV")[1])
		If !Empty(cAux)
			cTxt += " N.MOV: " + cAux + cTXTSep
		EndIf
		cAux := PadR(STFGetStation("CODIGO"),TamSX3("L1_ESTACAO")[1])
		If !Empty(cAux)
			cTxt += " ESTACAO: " + cAux + cTXTSep
		EndIf
		cAux := STDGPBasket("SL1","L1_PLACA")
		if !Empty(cAux)
			cTxt += " Placa: " + Transform(cAux,"@!R NNN-9N99") + cTXTSep
		endif
		if SL1->(ColumnPos("L1_ODOMETR")) > 0
			cAux := STDGPBasket("SL1","L1_ODOMETR")
			if !Empty(cAux)
				cTxt += " Odometro: " + Alltrim(Transform(cAux,"@E 999999999999")) + cTXTSep
			endif
		endif
		if SL1->(ColumnPos("L1_NOMMOTO")) > 0
			cAux := STDGPBasket("SL1","L1_NOMMOTO")
			if !empty(cAux)
				cTxt += " Motorista: " + AllTrim(cAux) + cTXTSep
			endif
		endif
		if SL1->(ColumnPos("L1_ENDCOB")) > 0
			cAux := STDGPBasket("SL1","L1_ENDCOB")
			if !empty(cAux)
				cTxt += " Endereco: " + AllTrim(cAux) + cTXTSep
			endif
		endif
		
		//Dados do vendedor no RODAPÉ 
		If lMsgVend .and. SL1->(ColumnPos("L1_VEND")) > 0
			cAux := STDGPBasket("SL1","L1_VEND") 
			If !Empty(cAux)
				cTxt += " Vendedor: " + AllTrim(cAux) + " - " + AllTrim(Posicione("SA3",1,xFilial("SA3")+cAux,"A3_NOME")) + cTXTSep
			EndIf
		EndIf

		//Observações digitadas no PDV 
		if FINDFUNCTION( "U_GetMsgNf" )
			cAux := U_GetMsgNf()
			if !empty(cAux)
				cTxt += " Obs: " + AllTrim(cAux) + cTXTSep
				if SL1->(FieldPos("L1_MENNOTA")) > 0
					STDSPBasket("SL1","L1_MENNOTA", SubStr(AllTrim(cAux),1,TamSX3("L1_MENNOTA")[1]) ) //para gravar na memória
				endif
			endif
		endif

		MsgFormulas(cNumSL1, @cTxt)

	EndIf

	//Mensagens informativas do cupom fiscal: Procon
	If !Empty(cMsgProcon)
		cTxt += " " + cMsgProcon + cTXTSep
	EndIf

	//Limitação: infCpl -  Informações Complementares de interesse do Contribuinte - Tamanho: 5000
	If Len(cTxt) > 5000
		cTxt := substr(cTxt,1,5000)
	EndIf

	cTxt := Alltrim(cTxt) //evitar erro: is invalid according to its datatype 'String' - The Pattern constraint failed.

	RestArea(aAreaSA1)
	RestArea(aAreaSL2)
	RestArea(aArea)

return cTxt

//
// Converte em valor da STRING em NUMERICO
// Ex.: 1) RetValr("0230011",3) -> 230.011
//      2) RetValr("565654550",2) -> 5,656,545.50
//
Static Function RetValr(cStr,nDec)
	cStr := SubStr(cStr,1,(Len(cStr)-nDec)) + "." + SubStr(cStr,(Len(cStr)-nDec)+1,Len(cStr)-(Len(cStr)-nDec))
Return Val(cStr)


Static Function MsgFormulas(cNumSL1, cMsgRet)

	Local aArea := GetArea()
	Local aAreaSL2 := SL2->(GetArea())
	Local aAreaSF4 := SF4->(GetArea())
	Local lC110			:= .F. // Indica se F4_FORINFC foi utilizado para preenchimento do SPED C110
	Local cMVNFEMSF4	:= AllTrim(GetNewPar("MV_NFEMSF4",""))
	Local cRetForm := ""

	SL2->(dbsetorder(1)) //L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
	If SL2->(dbseek(xFilial("SL2")+cNumSL1)) //
		While SL2->(!Eof()) .and. xFilial("SL2") == SL2->L2_FILIAL .and. cNumSL1 == SL2->L2_NUM
			
			dbSelectArea("SF4")
			dbSetOrder(1)
			MsSeek(xFilial("SF4")+SL2->L2_TES)

			/* Caso F4_FORINFC seja utilizado para preenchimento do SPED C110 (C5_MENPAD+C5_MENNOTA)
				esse campo não será considerado para compor a mensagem complementar.
				Poderá ser utilizado o F4_FORMULA em seu lugar
			*/
			dbSelectArea("SM4")
			SM4->( DbSetOrder( 1 ))
			lC110 := .F.
			If !Empty(SF4->F4_FORINFC) .And. SM4->( MsSeek( xFilial("SM4") + SF4->F4_FORINFC ) )
				lC110 := ("C5_MENPAD" $ SM4->M4_FORMULA) .And. ("C5_MENNOTA" $ SM4->M4_FORMULA)
			EndIf

			/* O campo F4_FORINFC é o substituto do F4_FORMULA e através do parâmetro MV_NFEMSF4 se determina 
			se o conteudo da formula devera compor a mensagem do cliente(="C") ou do fisco(="F").
			*/
			If !lC110 .And. !Empty(SF4->F4_FORINFC) .And. ( cMVNFEMSF4 == "C" .or. cMVNFEMSF4 == "F" )
				cRetForm := Formula(SF4->F4_FORINFC)
				if cRetForm <> NIL .And. ( (cMVNFEMSF4=="C" .And. !AllTrim(cRetForm) $ cMsgRet) .Or. (cMVNFEMSF4=="F" .And. !AllTrim(cRetForm)$cMsgRet) )
					If cMVNFEMSF4=="C"
						If Len(cMsgRet) > 0 .And. SubStr(cMsgRet, Len(cMsgRet), 1) <> " "
							cMsgRet += " "
						EndIf
						cMsgRet	+=	Alltrim(cRetForm) + " /"
					ElseIf cMVNFEMSF4=="F"
						If Len(cMsgRet) > 0 .And. SubStr(cMsgRet, Len(cMsgRet), 1) <> " "
							cMsgRet += " "
						EndIf
						cMsgRet	+=	Alltrim(cRetForm) + " /"
					EndIf
				endif
			ElseIf !Empty(SF4->F4_FORMULA) .and. ( cMVNFEMSF4 == "C" .or. cMVNFEMSF4 == "F" )
				cRetForm := Formula(SF4->F4_FORMULA)
				if cRetForm <> NIL .And. ( ( cMVNFEMSF4=="C" .And. !AllTrim(cRetForm) $ cMsgRet ) .Or. (cMVNFEMSF4=="F" .And. !AllTrim(cRetForm)$cMsgRet) )
					If cMVNFEMSF4=="C"
						If Len(cMsgRet) > 0 .And. SubStr(cMsgRet, Len(cMsgRet), 1) <> " "
							cMsgRet += " "
						EndIf
						cMsgRet	+=	Alltrim(cRetForm) + " /"
					ElseIf cMVNFEMSF4=="F"
						If Len(cMsgRet) > 0 .And. SubStr(cMsgRet, Len(cMsgRet), 1) <> " "
							cMsgRet += " "
						EndIf
						cMsgRet	+=	Alltrim(cRetForm) + " /"
					EndIf
				endif
			EndIf

			SL2->(dbskip())
		EndDo
	EndIf
	
	RestArea(aAreaSL2)
	RestArea(aAreaSF4)
	RestArea(aArea)

Return 
