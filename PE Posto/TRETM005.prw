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

	// confirma��o do cadastro
	if cIdPonto ==  'MODELPOS'

		cCodCartao	:= oModelU68:GetValue('U68_CODIGO')
		cNumCartao	:= oModelU68:GetValue('U68_NUM')
		cCodConcen	:= oModelU68:GetValue('U68_CONCEN')
		cCodMemori	:= oModelU68:GetValue('U68_MEMORI')
		cStatus		:= oModelU68:GetValue('U68_STATUS')
		cCodVend	:= oModelU68:GetValue('U68_VEND')

		if oObj:GetOperation() <> 5 // apenas se a opera��o for diferente de exclus�o

			// verifico se existe um cart�o identfid para esta concentradora com o mesmo n�mero
			U68->(DbSetOrder(4)) // U68_FILIAL + U68_CONCEN + U68_NUM
			if U68->(DbSeek(xFilial("U68") + cCodConcen + cNumCartao)) .AND. U68->U68_CODIGO <> cCodCartao

				cMsg := "Este n�mero do Identfid j� foi informado no registro " + U68->U68_CODIGO + "."
				Help(,,'Help',,cMsg,1,0)
				lRet := .F.

			else

				// se o n�mero de mem�ria estiver preenchido
				if !Empty(cCodMemori) .AND. cStatus == "2"

					// apago n�mero na concentradora
					lRet := U_TRETE004()

					if !lRet
						Help(,,'Help',,"Para desativar um Cart�o Identfid � necess�rio excluir o n�mero do cart�o na concentradora!",1,0)
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

		else // se a opera��o for exclus�o

			// se o n�mero de mem�ria estiver preenchido
			if !Empty(cCodMemori)

				// apago n�mero na concentradora
				lRet := U_TRETE004()

				if !lRet
					Help(,,'Help',,"Para excluir um Cart�o Identfid � necess�rio exclu�-lo na concentradora!",1,0)
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

		if oObj:GetOperation() == 3 // inclus�o

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"I")

		elseif oObj:GetOperation() == 4 // altera��o

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"A")

		elseif oObj:GetOperation() == 5 // exclus�o

			U_UReplica("U68",1,xFilial("U68") + oModelU68:GetValue('U68_CODIGO'),"E")

		endif

	EndIf

Return(lRet)
