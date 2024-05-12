#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} StSelField
Ponto de entrada chamado para retornar os campos adicionais
a serem incluídos no processo de importação de cliente.

@author Danilo
@since 02/10/2018
@version 1.0
@return aRet
@type function
/*/
user function StSelField()

	Local aRet := {}
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP010")
		aRet := ExecBlock("TPDVP010",.F.,.F.,aParam)
	EndIf

Return aRet