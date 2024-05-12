#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STCpCuston
Gravação de campos customizados na SE5 de sangria e suprimento
@author thebr
@since 27/12/2018
@version 1.0
@return aRet

@type function
/*/
User function STCpCuston()

	Local aParam  := aClone(ParamIxb)
	Local aRet := {}

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP012")
		aRet := ExecBlock("TPDVP012",.F.,.F.,aParam)
	Endif

Return aRet
