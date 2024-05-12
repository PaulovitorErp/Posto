#include "PROTHEUS.CH"
#include "TOPCONN.CH"

/*/{Protheus.doc} MT103FIM
O ponto de entrada MT103FIM encontra-se no final da função A103NFISCAL.
Após o destravamento de todas as tabelas envolvidas na gravação do documento de entrada, depois de fechar a operação realizada neste.
É utilizado para realizar alguma operação após a gravação da NFE.

@author Totvs
@since 04/11/14
@version 1.0
@return Nulo
@type function
/*/

User Function MT103FIM()

	Local aParam := aClone(PARAMIXB)

	/////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                 //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP007")
		Execblock("TRETP007",.F.,.F.,aParam)
	EndIf

Return(Nil)
