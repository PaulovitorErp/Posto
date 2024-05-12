#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LOJA070
Pontos de entrada MVC do cadastro de Adm Financeira.

@author Danilo
@since 08/10/2018
@version 1.0
@return xRet
@type function
/*/
User Function LOJA070()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETM001")
		xRet := ExecBlock("TRETM001",.F.,.F.,aParam)
	Endif

return xRet
