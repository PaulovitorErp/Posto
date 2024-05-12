#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETM012
Ponto de entrada do cadastro de tanques
@author Wellington
@since 30/11/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETM012()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local cIdModel		:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
	Local cClasse		:= IIf( oObj<> NIL, oObj:ClassName(), '' )
	Local oModelZE0		:= oObj:GetModel( 'ZE0MASTER' )
	Local cPulaLinha	:= chr(13)+chr(10)
	Local lRet 			:= .T.
	Local cNumLogic		:= ""
	Local cCodTanque	:= ""
	Local cCodMedidor	:= ""
	Local cMsg			:= ""
	Local aArea			:= GetArea()
	Local cCondicao		:= ""
	Local bCondicao

	// confirmação do cadastro
	If cIdPonto ==  'MODELPOS' .AND. oObj:GetOperation() <> 5 // apenas se a operação for diferente de exclusão

		cCodTanque		:= oModelZE0:GetValue('ZE0_TANQUE')
		cNumLogic		:= oModelZE0:GetValue('ZE0_NUMMED')
		cCodMedidor		:= oModelZE0:GetValue('ZE0_MEDIDO')

		If !Empty(cCodTanque) .and. !Empty(cNumLogic) .and. !Empty(cCodMedidor)

			cCondicao := " ZE0->ZE0_FILIAL = '" + xFilial("ZE0") + "'"
			cCondicao += " .AND. ZE0->ZE0_TANQUE <> '" + cCodTanque + "'"
			cCondicao += " .AND. ZE0->ZE0_NUMMED = '" + cNumLogic + "'"
			cCondicao += " .AND. ZE0->ZE0_MEDIDO = '" + cCodMedidor + "'"

			// limpo os filtros da ZE0
			ZE0->(DbClearFilter())

			// executo o filtro na ZE0
			bCondicao 	:= "{|| " + cCondicao + " }"
			ZE0->(DbSetFilter(&bCondicao,cCondicao))

			// vou para a primeira linha
			ZE0->(DbGoTop())

			// se existe algum tanque fisico com este número lógico
			if ZE0->(!Eof())

				cMsg := "Este número lógico já foi informado no tanque fisico de código " + ZE0->ZE0_TANQUE + "."
				Help(,,'Help',,cMsg,1,0)
				lRet := .F.

			endif

			// limpo os filtros da ZE0
			ZE0->(DbClearFilter())

		EndIf

		RestArea(aArea)


	elseif cIdPonto == 'MODELCOMMITNTTS'

		if oObj:GetOperation() == 3 // inclusão

			U_UReplica("ZE0",1,xFilial("ZE0") + oModelZE0:GetValue('ZE0_TANQUE'),"I")

		elseif oObj:GetOperation() == 4 // alteração

			U_UReplica("ZE0",1,xFilial("ZE0") + oModelZE0:GetValue('ZE0_TANQUE'),"A")

		elseif oObj:GetOperation() == 5 // exclusão

			U_UReplica("ZE0",1,xFilial("ZE0") + oModelZE0:GetValue('ZE0_TANQUE'),"E")

		endif

	EndIf

Return(lRet)
