#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7002
Ponto de Entrada chamado depois da gravação de todos os dados
e da impressão do cupom fiscal na Venda Assistida e após o
processamento do Job LjGrvBatch(FRONT LOJA).
@param ParamIxb
Parâmetros:
Nome			Tipo			Descrição
ExpN1			Numérico		Contém o tipo de operação de gravação, sendo:
1 - orçamento
2 - venda
3 - pedido
ExpA2			Array of Record	Array de 1 dimensão contendo os dados da devolução na seguinte ordem:
1 - série da NF de devolução
2 - número da NF de devolução
3 - cliente
4 - loja do cliente
5 - tipo de operação (1 - troca; 2 - devolução)
ExpN3			Array of Record	Contém a origem da chamada da função, sendo:
1 = Genérica
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
