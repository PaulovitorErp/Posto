#include 'protheus.ch'


/*/{Protheus.doc} MA103OPC
Ponto de Entrada utilizado para adicionar itens no menu do Documento de Entrada
@author Totvs TBC
@since 13/10/2017
@version 1.0
@return Array
@type function
/*/

User Function MA103OPC()

	Local _aRotNew	:= {}
	Local _aRotina	:= aClone(Paramixb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP003")
		_aRotNew := ExecBlock("TRETP003",.F.,.F.,_aRotina)
	EndIf

Return _aRotNew
