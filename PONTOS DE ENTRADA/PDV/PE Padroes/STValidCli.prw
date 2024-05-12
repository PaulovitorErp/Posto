#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STValidCli
Este Ponto de Entrada é executado após acionar a opção Selecionar Cliente,
presente na tela de Seleção de clientes no TOTVS PDV.

@author Danilo Brito
@since 02/10/2018
@version 1.0
@return lRet

@type function
/*/
User function STValidCli()

	Local xRet
	Local aParam 	:= aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP009")
		xRet := ExecBlock("TPDVP009",.F.,.F.,aParam)
	EndIf

Return xRet