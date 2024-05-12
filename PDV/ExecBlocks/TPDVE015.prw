/*/{Protheus.doc} User Function TPDVE015
Função para controle de numeração L1_NUM para centralPDV versão 27 SQLite
@type  Function
@author danilo
@since 26/04/2023
@version 1    
/*/
User Function TPDVE015()
    
    Local cRet
    
	cRet := GetSxENum("SL1","L1_NUM")
	ConfirmSx8()

    LjGrvLog("TPDVE015", "TPDVE015: Novo numero de orcamento gerado (L1_NUM): "+cRet)

Return cRet
