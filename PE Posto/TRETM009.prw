#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETM009
Pontos de Entrada - Numeração LMC
@author TOTVS
@since 17/10/2018
@version P12
@param Nao recebe parametros
@return nulo
/*/
User Function TRETM009()

	Local aParam 		:= PARAMIXB
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local oModelUB4		:= oObj:GetModel("UB4MASTER")

	Local xRet 			:= .T.

	If cIdPonto == 'MODELPOS' .And. oObj:GetOperation() == 5 //Confirmação da exclusão

		If ExistUB4()

			xRet := .F.
			Help( ,, 'Help - MODELPOS',, 'Não é permitido a exclusão desta numeração, pois a mesma se encontra associada a página(s) LMC.', 1, 0 )
		Endif
	Endif

Return xRet

/*/{Protheus.doc} ExistUB4
Verifica existencia UB4
@author thebr
@since 30/11/2018
@version 1.0
@return Nil

@type function
/*/
Static Function ExistUB4()

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYVLDEXC") > 0
		QRYVLDEXC->(dbCloseArea())
	Endif

	cQry := "SELECT MIE_NRLIVR"
	cQry += " FROM "+RetSqlName("MIE")+""
	cQry += " WHERE D_E_L_E_T_	<> '*'"
	cQry += " AND MIE_FILIAL	= '"+xFilial("MIE")+"'"
	cQry += " AND MIE_NRLIVR	= '"+UB4->UB4_CODIGO+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETM009.txt",cQry)
	TcQuery cQry NEW Alias "QRYVLDEXC"

	If QRYVLDEXC->(!EOF())
		lRet := .T.
	Endif

	If Select("QRYVLDEXC") > 0
		QRYVLDEXC->(dbCloseArea())
	Endif

Return lRet
