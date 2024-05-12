
#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StiCusSFil
No fonte "StiCustomerSelection" foi acrescentado o PE com a funcionalidade citada, 
com o nome temporário de "StiCusSFil", estará posicionado na tabela "SA1" no registro a ser analisado, 
o retorno esperado pela User Function é um vetor contendo:
[01] - Bloco de codigo com expressão ADVPL
[02] - Expressão string em ADVPL equivalente a do bloco de código

O retorno será avaliado em cada parte do fonte como ".T." será descartado o registro em questão que atenda a expressão ADVPL

@author pablo
@since 09/10/2019
@version 1.0
@return xRet
@type function
/*/
User Function StiCusSFil()

	Local aParam 	:= aClone(ParamIxb)
	Local aRet      := {{|| .F. }, ".F."}
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP025")
		aRet := ExecBlock("TPDVP025",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return aRet
