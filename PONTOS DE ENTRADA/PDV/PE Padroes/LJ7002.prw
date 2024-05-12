#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7002
Ponto de Entrada chamado depois da grava��o de todos os dados
e da impress�o do cupom fiscal na Venda Assistida e ap�s o
processamento do Job LjGrvBatch(FRONT LOJA).
@param ParamIxb
Par�metros:
Nome			Tipo			Descri��o
ExpN1			Num�rico		Cont�m o tipo de opera��o de grava��o, sendo:
1 - or�amento
2 - venda
3 - pedido
ExpA2			Array of Record	Array de 1 dimens�o contendo os dados da devolu��o na seguinte ordem:
1 - s�rie da NF de devolu��o
2 - n�mero da NF de devolu��o
3 - cliente
4 - loja do cliente
5 - tipo de opera��o (1 - troca; 2 - devolu��o)
ExpN3			Array of Record	Cont�m a origem da chamada da fun��o, sendo:
1 = Gen�rica
2 = GRVBatch

@return Nenhum(nulo)
@author Totvs - Goias
/*/
user function LJ7002()

	Local aParam := aClone(ParamIxb)

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP001")
		ExecBlock("TPDVP001",.F.,.F.,aParam)
	Endif

return
