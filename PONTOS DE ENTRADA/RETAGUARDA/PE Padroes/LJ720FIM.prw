#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ720FIM
Esse ponto de entrada � executado ao final da rotina de troca/devolu��o, chamada na
venda assistida, na qual � passado o Array com os dados para uma eventual atualiza��o.

@author Pablo Cavalcante
@since 17/11/2017
@version 1.0
@return Nil

@type function
/*/
User Function LJ720FIM()

	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP015")
		ExecBlock("TRETP015",.F.,.F.,aParam)
	EndIf

Return
