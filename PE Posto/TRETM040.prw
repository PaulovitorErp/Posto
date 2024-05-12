#include 'protheus.ch'
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} TRETM040
Ponto de Entrada Cadastro de Recados
@author TOTVS
@since 22/08/2019
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETM040()
/***********************/
	
Local xRet      := .T.
Local aParam 	:= PARAMIXB
Local oObj		:= aParam[1] // objeto do modelo de dados
Local cIdPon	:= aParam[2] // ID do ponto de entrada    
Local nOpc      := oObj:GetOperation()         
                           
If cIdPon == 'FORMPOS' //Antes da Gravacao do Form 
	If Empty(M->U92_GRPCLI) .And. Empty(M->U92_CODCLI)
		Help( ,, 'Help',, 'Obrigatório o preenchimento do(s) campo(s) Grupo Clientes ou Cod.Clientes.', 1, 0 )
		xRet := .F.
	EndIf
EndIf

Return xRet
