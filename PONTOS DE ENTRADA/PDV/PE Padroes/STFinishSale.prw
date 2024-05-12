#include 'protheus.ch'

/*/{Protheus.doc} STFinishSale
Possibilitar a grava��o de arquivos complementares. O ponto de entrada � executado ap�s o fechamento do cupom e da venda.

N�o � recomendado a utiliza��o desse ponto de entrada para alterar as tabelas SL1, SL2 e/ou SL4, 
pois no ponto que esta localizado o ponto de entrada a venda j� subiu para a retaguarda e n�o ira subir novamente.

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
