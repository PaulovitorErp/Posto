#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720CABEC
Esse ponto de entrada é chamado para a incluisão de campos adicionais no cabeçalho da NF de devolução.

@author Pablo Cavalcante
@since 26/11/2019
@version 1.0
@return lRet

@type function
/*/
User Function LJ720CABEC()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP025")
		xRet := ExecBlock("TRETP025",.F.,.F.,aParam)
	EndIf

Return xRet