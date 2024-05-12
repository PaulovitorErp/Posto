#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STEXITPOS
Validação para sair da tela PDV
@author thebr
@since 29/05/2019
@version 1.0
@return lRet
@type function
/*/
user function STEXITPOS()

	Local lRet := iif(Valtype(ParamIxb)=="A" .AND. !Empty(ParamIxb),ParamIxb[1], .T.)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP018")
		lRet := ExecBlock("TPDVP018",.F.,.F., lRet)
	EndIf

return lRet