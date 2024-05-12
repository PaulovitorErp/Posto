#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETM005
Ponto de entrada do cadastro identfid

@type function
@author Pablo
@since 26/06/2014
@version 1.0
/*/
User Function TRETM005()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local cIdModel		:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
	Local cClasse		:= IIf( oObj<> NIL, oObj:ClassName(), '' )
	Local oModelU68		:= oObj:GetModel( 'U68MASTER' )
	Local cPulaLinha	:= chr(13)+chr(10)
	Local lRet 			:= .T.
	Local cNumCartao	:= ""
	Local cCodCartao	:= ""
	Local cCodConcen	:= ""
	Local cCodMemori	:= ""
	Local cStatus		:= ""
	Local cMsg			:= ""
	Local lGrvSA3		:= SuperGetMV("MV_XIDTSA3",,.T.) //Define se vai gravar o campo A3_RFID automaticamente (default .T.)

	// confirmação do cadastro
	if cIdPonto ==  'MODELPOS'

		cCodCartao	:= oModelU68:GetValue('U68_CODIGO')
		cNumCartao	:= oModelU68:GetValue('U68_NUM')
		cCodConcen	:= oModelU68:GetValue('U68_CONCEN')
		cCodMemori	:= oModelU68:GetValue('U68_MEMORI')
		cStatus		:= oModelU68:GetValue('U68_STATUS')
		cCodVend	:= oModelU68:GetValue('U68_VEND')

		if oObj:GetOperation() <> 5 // apenas se a operação for diferente de exclusão

			// verifico se existe um cartão identfid para esta concentradora com o mesmo número
			U68->(DbSetOrder(4)) // U68_FILIAL + U68_CONCEN + U68_NUM
			if U68->(DbSeek(xFilial("U68") + cCodConcen + cNumCartao)) .AND. U68->U68_CODIGO <> cCodCartao

				cMsg := "Este número do Identfid já foi informado no registro " + U68->U68_CODIGO + "."
				Help(,,'Help',,cMsg,1,0)
				lRet := .F.

			else

				// se o número de memória estiver preenchido
				if !Empty(cCodMemori) .AND. cStatus == "2"

					// apago número na concentradora
					lRet := U_TRETE004()

					if !lRet
						Help(,,'Help',,"Para desativar um Cartão Identfid é necessário excluir o número do cartão na concentradora!",1,0)
					endif

				endif

			endif

			//-- tratamento do campo A3_RFID - Cod RF ID
			if lRet .and. lGrvSA3 .and. SA3->(FieldPos("A3_RFID"))>0
				SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
				if SA3->(DbSeek(xFilial("SA3")+cCodVend))
					RecLock("SA3")
						If TamSX3("A3_RFID")[1]/TamSX3("U68_NUM")[1] >= 2
							If (TamSX3("A3_RFID")[1]-Len(AllTrim(SA3->A3_RFID))) >= TamSX3("U68_NUM")[1]
								SA3->A3_RFID := AllTrim(SA3->A3_RFID) + cNumCartao
							Else
								SA3->A3_RFID := cNumCartao
							EndIf
						Else
							SA3->A3_RFID := cNumCartao
						EndIf
					SA3->(MsUnlock())
				endif
				//SA3->(DbSetOrder(9)) //A3_FILIAL+A3_RFID
			endif

		else // se a operação for exclusão

			// se o número de memória estiver preenchido
			if !Empty(cCodMemori)

				// apago número na concentradora
				lRet := U_TRETE004()

				if !lRet
					Help(,,'Help',,"Para excluir um Cartão Identfid é necessário excluí-lo na concentradora!",1,0)
				endif

			endif

			//-- tratamento do campo A3_RFID - Cod RF ID
			if lRet .and. lGrvSA3 .and. SA3->(FieldPos("A3_RFID"))>0
				SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
				if SA3->(DbSeek(xFilial("SA3")+cCodVend))
					RecLock("SA3")
					SA3->A3_RFID := AllTrim(StrTran( SA3->A3_RFID, cNumCartao, "" ))
					SA3->(MsUnlock())
				endif
				//SA3->(DbSetOrder(9)) //A3_FILIAL+A3_RFID
			endif

		endif

	ElseIf cIdPonto == 'MODELCOMMITNTTS'

		if oObj:GetOperation() == 3 // inclusão

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"I")

		elseif oObj:GetOperation() == 4 // alteração

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"A")

		elseif oObj:GetOperation() == 5 // exclusão

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"E")

		endif

	EndIf

Return(lRet)
