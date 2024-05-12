#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720PROX
Esse ponto de entrada � chamado para controlar todas as mudan�as de painel.

@author Pablo Cavalcante
@since 26/11/2019
@version 1.0
@return lRet

@type function
/*/
User Function LJ720PROX()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP024")
		xRet := ExecBlock("TRETP024",.F.,.F.,aParam)
	EndIf

Return xRet