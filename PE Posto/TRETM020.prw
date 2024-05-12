#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETM020
Ponto de entrada do cadastro de CRC
@author Wellington Gonçalves
@since 23/12/2015
@version 1.0
@return Qualquer

@type function
/*/

User Function TRETM020()

	Local aArea		:= GetArea()
	Local aAreaSC7	:= SC7->(GetArea())
	Local aParam 	:= PARAMIXB
	Local xRet 		:= .T.
	Local oObj		:= aParam[1]
	Local cIdPonto 	:= aParam[2]
	Local cIdModel	:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
	Local cClasse 	:= IIf( oObj<> NIL, oObj:ClassName(), '' )
	Local oModelZE3	:= oObj:GetModel('ZE3MASTER')
	Local oView		:= FWViewActive()
	Private _lCRC	:= .T. // crio esta variável private para ser utilizada na validação da alteração do pedido de compras

	// ponto de entrada na abertura do Browse
	if cIdPonto ==  "MODELVLDACTIVE"

		if oObj:GetOperation() == 4 // alteração

			if ZE3->ZE3_STATUS <> '1' // pode alterar apenas CRC em aberto
				Help(,,'Help',,"Não é permitido alterar um CRC finalizado!",1,0)
				xRet := .F.
			endif

		elseif oObj:GetOperation() == 5 // exclusão

			if !EMPTY(ZE3->ZE3_NOTA) // pode excluir apenas se não gerou nota
				Help(,,'Help',,"Não é possível excluir um CRC que já tenha nota de entrada!",1,0)
				xRet := .F.
			endif

		endif

	ElseIf cIdPonto == 'MODELCOMMITNTTS' // após gravação

		if oObj:GetOperation() == 4 // alteração

			// percorro todos os itens do pedido de compras
			SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
			if SC7->(DbSeek(xFilial("SC7") + oModelZE3:GetValue('ZE3_PEDIDO')))

				While SC7->(!Eof()) .AND. SC7->C7_FILIAL == xFilial("SC7") .AND. SC7->C7_NUM == oModelZE3:GetValue('ZE3_PEDIDO')

					// preencho os itens do pedido de compras com o número do CRC
					if Empty(SC7->C7_XCRC)

						if RecLock("SC7",.F.)

							SC7->C7_XCRC 	:= oModelZE3:GetValue('ZE3_NUMERO')
							SC7->C7_XSTCRC 	:= "1"

							SC7->(MsUnLock())

						endif

					endif

					SC7->(DbSkip())

				EndDo

			endif

			// percorro todas as amostras
			ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
			if ZE5->(DbSeek(xFilial("ZE5") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) ))

				While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. ZE5->ZE5_PEDIDO == oModelZE3:GetValue( 'ZE3_PEDIDO' )

					// preencho todas as amostras com o número do CRC
					if Empty(ZE5->ZE5_CRC)

						if RecLock("ZE5",.F.)

							ZE5->ZE5_CRC := oModelZE3:GetValue('ZE3_NUMERO')
							ZE5->(MsUnLock())

						endif

					endif

					ZE5->(DbSkip())

				EndDo

			endif

			// verifico se já pode aprovar o CRC
			U_AprovCRC(oModelZE3:GetValue('ZE3_NUMERO'))

		elseif oObj:GetOperation() == 5 // exclusão

			// percorro todos os itens do pedido de compras
			SC7->(DbSetOrder(1)) // C7_FILIAL + C7_NUM + C7_ITEM + C7_SEQUEN
			if SC7->(DbSeek(xFilial("SC7") + oModelZE3:GetValue('ZE3_PEDIDO')))

				While SC7->(!Eof()) .AND. SC7->C7_FILIAL == xFilial("SC7") .AND. SC7->C7_NUM == oModelZE3:GetValue('ZE3_PEDIDO')

					// limpo o número do CRC
					if RecLock("SC7",.F.)

						SC7->C7_XCRC 	:= ""
						SC7->C7_XSTCRC 	:= ""

						SC7->(MsUnLock())

					endif

					SC7->(DbSkip())

				EndDo

			endif

			// percorro todas as amostras
			ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM
			if ZE5->(DbSeek(xFilial("ZE5") + oModelZE3:GetValue( 'ZE3_PEDIDO' ) ))

				While ZE5->(!Eof()) .AND. ZE5->ZE5_FILIAL == xFilial("ZE5") .AND. ZE5->ZE5_PEDIDO == oModelZE3:GetValue( 'ZE3_PEDIDO' )

					// limpo o número do CRC
					if RecLock("ZE5",.F.)

						ZE5->ZE5_CRC := ""
						ZE5->(MsUnLock())

					endif

					ZE5->(DbSkip())

				EndDo

			endif

		endif

	endif

	RestArea(aArea)
	RestArea(aAreaSC7)

Return(xRet)
