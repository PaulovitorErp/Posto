#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} OM040BRW
Ponto de entrada usado para inserir botões específicos (browse), no cadastro de Motoristas (OMSA040).
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return xRet, Array com menus
@type function
/*/
user function OM040BRW()

	Local xRet

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP001")
		xRet := ExecBlock("TRETP001",.F.,.F.)
	EndIf

return xRet