#include "protheus.ch"
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETM015
Pontos de Entrada - Cadastro de Medição de Tanque

@author Maiki
@since 28/03/2018
@version 1.0
@return Nil
@type function
/*/
User Function TRETM015()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local oModelTQK		:= oObj:GetModel("TQKMASTER")
	Local xRet 			:= .T.

	Local lConsMed 		:= SuperGetMv("MV_XCONSME",.F.,.F.)

	If lConsMed

		If cIdPonto == "MODELVLDACTIVE" .And. oObj:GetOperation() == 5 //Exclusão

			If PossuiLmc(TQK->TQK_DTMEDI, TQK->TQK_PRODUT)
				Help( ,, 'Help',,'Identificado LMC com data e produto constantes nesta medição, operação cancelada.', 1, 0)
				xRet := .F.
			Endif

		ElseIf cIdPonto == 'MODELPOS' .And. (oObj:GetOperation() == 3 .Or. oObj:GetOperation() == 4) //Confirmação da inclusão ou alteração

			If PossuiLmc(oModelTQK:GetValue("TQK_DTMEDI"),oModelTQK:GetValue("TQK_PRODUT"))
				Help( ,, 'Help',,'Identificado LMC na data e produto selecionados, operação não permitida.', 1, 0)
				xRet := .F.
			Endif

		Endif
	Endif

Return xRet

/*/{Protheus.doc} PossuiLmc
Valida se possui LMC.

@author pablo
@since 26/10/2018
@version 1.0
@return Nil
@param dData, date, descricao
@param cProd, characters, descricao
@type function
/*/
Static Function PossuiLmc(dData,cProd)

	Local lRet	:= .F.

	DbSelectArea("MIE")
	MIE->(DbSetOrder(1)) //MIE_FILIAL+MIE_CODPRO+DTOS(MIE_DATA)+MIE_CODTAN+MIE_CODBIC

	If MIE->(DbSeek(xFilial("MIE")+cProd+DToS(dData)))
		lRet := .T.
	EndIf

Return lRet
