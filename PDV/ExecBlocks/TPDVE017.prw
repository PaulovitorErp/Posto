#Include "PROTHEUS.CH"

/*/{Protheus.doc} TPDVE017
Função para chamar menu NFCe do venda assistida por outra rotina.                                                   
                                                                
@param xParam Parameter Description                             
@return xRet Return Description                                 
@author Danilo Brito
@since 30/08/2023                                                   
/*/                                                             
User Function TPDVE017() 

    Local oButton1           
    Local oButton2
    Local oButton3
    Local oButton4
    Local oButton5
    Local oButton6
    Local oGroup1
    Private oDlgNFCe

  DEFINE MSDIALOG oDlgNFCe TITLE "Menu Configurações NFCe" FROM 000, 000  TO 350, 300 COLORS 0, 16777215 PIXEL

    @ 008, 008 GROUP oGroup1 TO 158, 138 PROMPT "Menu Configurações NFCe" OF oDlgNFCe COLOR 0, 16777215 PIXEL
    @ 027, 035 BUTTON oButton1 PROMPT "Parâmetro" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION LjNFCePar()
    @ 047, 035 BUTTON oButton2 PROMPT "Configuração" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION LjNFCeCfg()
    @ 067, 035 BUTTON oButton3 PROMPT "Eventos" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION LjNFCeEven()
    @ 086, 035 BUTTON oButton4 PROMPT "Monitor" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION LjNFCeMnt()
    @ 105, 035 BUTTON oButton5 PROMPT "Exportar" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION LjNFCeExp()
    @ 125, 035 BUTTON oButton6 PROMPT "Fechar" SIZE 070, 012 OF oDlgNFCe PIXEL ACTION oDlgNFCe:End()

  ACTIVATE MSDIALOG oDlgNFCe CENTERED

Return
