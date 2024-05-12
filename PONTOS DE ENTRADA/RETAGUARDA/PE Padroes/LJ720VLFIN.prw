#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720VLFIN
Ponto de Entrada que permite efetuar validações no momento da finalização do processo de troca/devolução de mercadorias (Troca/Devolução).

@author Pablo Cavalcante
@since 17/11/2017
@version 1.0
@return lRet

@type function
/*/
User Function LJ720VLFIN()

	Local xRet
	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP014")
		xRet := ExecBlock("TRETP014",.F.,.F.,aParam)
	EndIf

Return xRet
