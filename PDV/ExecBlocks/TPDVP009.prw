#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP009 (STValidCli)
Este Ponto de Entrada é executado após acionar a opção Selecionar Cliente,
presente na tela de Seleção de clientes no TOTVS PDV.

@author Danilo Brito
@since 02/10/2018
@version 1.0
@return lRet
@type function
/*/
User function TPDVP009()

	Local aArea := GetArea()
	Local aAreaSA1 := SA1->(GetArea())
	Local lRet := .T.
	Local cCodCli := PARAMIXB[1]
	Local cLojCli := PARAMIXB[2]
	Local cCPFMot := Iif(SL1->(FieldPos("L1_CGCMOTO")) > 0,Alltrim(STDGPBasket("SL1","L1_CGCMOTO")),Alltrim(STDGPBasket("SL1","L1_CGCCLI")))
	//Local cNomMot := ""
	Local cPlaca := Alltrim(STDGPBasket("SL1","L1_PLACA"))
	Local cOdome := ""
	Local cMsgRestr := ""
	Local lBlqAI0 := SuperGetMv("MV_XBLQAI0",,.F.) .AND. AI0->(FieldPos("AI0_XBLFIL")) > 0 //Habilita bloqueio de venda na filial, olhando para tabela AI0

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	//conout("TPDVP009 - Inicio"+ Time())

	//Avisos de obrigatoriedade de placa, cliente e amarracao
	SA1->(DbSetOrder(1))
	If SA1->(DbSeek(xFilial("SA1")+cCodCli+cLojCli))

		// verifico se o cadastro tem autorização para ser utilizado nesta filial/empresa
		If lBlqAI0 .AND. Posicione("AI0",1,xFilial("AI0")+SA1->A1_COD+SA1->A1_LOJA,"AI0_XBLFIL")=="S"
			lRet := .F.
			Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
		ElseIf !lBlqAI0 .AND. SA1->(FieldPos("A1_XFILBLQ")) > 0 .and. !Empty(SA1->A1_XFILBLQ) .and. (cFilAnt $ SA1->A1_XFILBLQ)
			lRet := .F.
			Aviso("Atenção!", "O cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+AllTrim(SA1->A1_NOME)+" não está autorizado nesta filial.", {"OK"}, 2)
		Else

			//atualizo nome do cliente na tela
			U_SetTbcCli(Alltrim(SA1->A1_NOME), SA1->A1_CGC, Alltrim(SA1->A1_MUN)+"-"+SA1->A1_EST)

			//tratamento para trazer nome do cliente como motorista também
			//POSTODV-472 - Chamado do Suporte [POSTO-670] – GATILHO DE NOME DO MOTORISTA - PDV
			//If SL1->(FieldPos("L1_NOMMOTO")) > 0
			//	//vejo se ja foi digitado anteriormente
			//	If Empty(Alltrim(STDGPBasket("SL1","L1_NOMMOTO")))
			//		STDSPBasket("SL1","L1_NOMMOTO", SubStr(SA1->A1_NOME,1,TamSX3("L1_NOMMOTO")[1]) ) //para gravaçao
			//	EndIf
			//EndIf

			//preenche os dados do cliente: CPF/CNPJ e Nome do Cliente	
			STDSPBasket("SL1","L1_CGCCLI", SubStr(SA1->A1_CGC,1,TamSX3("L1_CGCCLI")[1]) )
			STDSPBasket("SL1","L1_NOMCLI", SubStr(SA1->A1_NOME,1,TamSX3("L1_NOMCLI")[1]) )

			//gatilhar motorista, caso existe amarração de placa com motorista
			If !Empty(cPlaca) .and. Empty(cCPFMot)
				DbSelectArea("DA3")
				DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
				If DA3->(DbSeek(xFilial("DA3")+cPlaca)) .and. !Empty(DA3->DA3_MOTORI)
					DA4->(DbSetOrder(1)) //DA4_FILIAL+DA4_COD
					If DA4->(DbSeek(xFilial("DA4")+DA3->DA3_MOTORI))
						STDSPBasket("SL1","L1_CGCMOTO", SubStr(DA4->DA4_CGC,1,TamSX3("L1_CGCMOTO")[1]))
						//If Empty(Alltrim(STDGPBasket("SL1","L1_NOMMOTO")))
							STDSPBasket("SL1","L1_NOMMOTO", SubStr(DA4->DA4_NOME,1,TamSX3("L1_NOMMOTO")[1]))
						//EndIf
					EndIf
				EndIf
			EndIf

			//validações para obrigar placa, motorista e amarração
			If SA1->(ColumnPos("A1_XFROTA")) > 0 .AND. SA1->A1_XFROTA == "S" .AND. Empty(cPlaca)
				cMsgRestr += "- PLACA VEÍCULO" + CRLF
			EndIf
			If SA1->(ColumnPos("A1_XMOTOR")) > 0 .AND. SA1->A1_XMOTOR == "S" .AND. Empty(cCPFMot)
				cMsgRestr += "- CPF MOTORISTA" + CRLF
			EndIf
			If SA1->(ColumnPos("A1_XRESTRI")) > 0 .AND. SA1->A1_XRESTRI == "S"
				cMsgRestr += "- AMARRAÇÃO PLACA x CLIENTE" + CRLF
				If !Empty(cPlaca)
					DbSelectArea("DA3")
					DA3->(DbSetOrder(3)) //DA3_FILIAL+DA3_PLACA
					If !DA3->(DbSeek(xFilial("DA3")+cPlaca )) .OR. !(DA3->DA3_XCODCL+DA3->DA3_XLOJCL==SA1->A1_COD+SA1->A1_LOJA .OR. DA3->DA3_XGRPCL==SA1->A1_GRPVEN )
						STDSPBasket("SL1","L1_PLACA", Space(len(cPlaca)) ) //limpa a placa, porque a placa não pertence ao cliente (amarração)
						Aviso("Atenção!", "A placa "+cPlaca+" informada anteriormente não está vinculada a este cliente! Selecionar outra placa!", {"OK"}, 2)
					EndIf
				EndIf
			EndIf

			If SL1->(ColumnPos("L1_ODOMETR")) > 0
				cOdome := Alltrim(STDGPBasket("SL1","L1_ODOMETR"))
				If SA1->(ColumnPos("A1_XODOMET")) > 0 .AND. SA1->A1_XODOMET == "S" .AND. Empty(cOdome)
					cMsgRestr += "- ODÔMETRO (KM)" + CRLF
				EndIf
			EndIf

			If !empty(cMsgRestr)
				Aviso("Atenção!", "Para este cliente é obrigatório informar: " + CRLF + cMsgRestr, {"OK"}, 2)
			EndIf
		EndIf

		// chamo função que verifica se existe recado cadastrado
		U_GetRecado(cPlaca,cCPFMot,cCodCli,cLojCli,SA1->A1_GRPVEN)
	EndIf
	
	//conout("TPDVP009 - Fim " + Time())

	RestArea(aAreaSA1)
	RestArea(aArea)

Return lRet
