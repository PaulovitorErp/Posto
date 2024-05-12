#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F040TRVSA1
O ponto de entrada F040TRVSA1 permite travar ou destravar os registros da Tabela de Cliente - SA1, na rotina Clientes - MATA030.
Essa ação é possível mesmo se os registros estiverem sendo utilizados por uma thread.

O ponto de entrada está presente nas funções FA040AxAlt e GeraParcSe1 da rotina Contas a Receber - FINA040 e A040DupRec e AtuSalDup do fonte -(MATXATU)

@author Totvs GO
@since 20/04/2018
@version 1.0

@return Lógico

@type function
/*/
User Function F040TRVSA1()

	Local lRet := .T.

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TRETP022")
		lRet := ExecBlock("TRETP022",.F.,.F.)
	EndIf

Return lRet
