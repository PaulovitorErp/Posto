#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} OM060BRW
Ponto de entrada usado para inserir botões específicos (browse), no cadastro de Veiculos (OMSA060).
@author Danilo Brito
@since 25/09/2018
@version 1.0
@return xRet, Array com menus
@type function
/*/
user function OM060BRW()

	Local xRet

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP002")
		xRet := ExecBlock("TRETP002",.F.,.F.)
	EndIf

return xRet