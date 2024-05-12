#include 'protheus.ch'

/*/{Protheus.doc} STFinishSale
Possibilitar a gravação de arquivos complementares. O ponto de entrada é executado após o fechamento do cupom e da venda.

Não é recomendado a utilização desse ponto de entrada para alterar as tabelas SL1, SL2 e/ou SL4, 
pois no ponto que esta localizado o ponto de entrada a venda já subiu para a retaguarda e não ira subir novamente.

@author Maiki Perin
@since 26/09/2018
@version P12
@param PARAMIXB
@return nulo
/*/
User function STFinishSale()

	Local aParam 	:= aClone(ParamIxb)
	Local aArea		:= GetArea()

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                   //
	///////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP005")
		ExecBlock("TPDVP005",.F.,.F.,aParam)
	EndIf

	RestArea(aArea)

Return
