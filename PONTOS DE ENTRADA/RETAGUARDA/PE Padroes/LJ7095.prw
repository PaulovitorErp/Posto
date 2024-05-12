#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7095
LJ7095 - Trava/Destrava bloqueio de processamento GravaBatch quando registro do cliente da venda com Lock

Obs.:
Validação é realizada no GravaBatch para evitar erro de Lock, na atualização do cliente pela rotina MatxAtu(A040DupRec),
para tratamento deve ser utilizado também o Ponto de Entrada F040TRVSA1.

Quando o Ponto de Entrada F040TRVSA1 retorna .F.,
os campos (A1_PRICOM, A1_ULTCOM, A1_NROCOM, A1_VACUM) não serão atualizados.

Nesse Ponto o registro do SA1 está posicionado no cliente da Venda 
O ponto de entrada será acionado antes de gravar a venda como ER,
respeitando assim configurações do Job LJGRVBATCH para reprocessar venda quando lock

@author Totvs GO
@since 20/04/2018
@version 1.0

@return Lógico (Se .T., permite continuar a gravação com registro Lock)

@type function
/*/
User Function LJ7095()

	Local lRet	 := .F.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP021")
		lRet := ExecBlock("TRETP021",.F.,.F.)
	EndIf

Return lRet
