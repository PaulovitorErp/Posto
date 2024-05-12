#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STIMotSa
Ponto de entrada antes da sangria/suprimento ou abertura de caixa

@author thebr
@since 14/02/2019
@version 1.0
@return Nil

@type function
/*/
user function STIMotSa()

	Local lRet := .T.
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP024")
		lRet := ExecBlock("TPDVP024",.F.,.F.,aParam)
	EndIf

return lRet
