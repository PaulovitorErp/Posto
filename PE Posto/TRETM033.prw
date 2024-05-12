#include 'protheus.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} TRETM033
Ponto de Entrada da Rotina de Cadastro Negociação de Preços - Vale Serviços
@author TOTVS
@since 27/04/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/

/***********************/
User Function TRETM033()	
/***********************/

Local aParam     := PARAMIXB 
Local oObj       := aParam[1]
Local cIdPonto   := aParam[2]
Local cIdModel   := IIf(oObj<> NIL, oObj:GetId(), aParam[3])
Local cClasse    := IIf(oObj<> NIL, oObj:ClassName(), '') 
Local nOperation := IIf(oObj<> NIL, oObj:GetOperation(), 0) 
Local oModelUI0	 := oObj:GetModel('UI0MASTER')
Local oModelUI1  := oObj:GetModel('UI1DETAIL')  
Local oModelUIB  := oObj:GetModel('UIBDETAIL')  
Local xRet       := .T. 
Local cOperad 	 := "" 
Local nX, nY

If aParam <> NIL 

	If cIdPonto == 'MODELPOS'
		
		If oObj:GetOperation() == 3 .Or. oObj:GetOperation() == 4 // Inclusão Ou Alteração

			//Validação preenchimento dos campos do Cabeçalho
			If Empty(oModelUI0:GetValue("UI0_GRPCLI")) .And. (Empty(oModelUI0:GetValue("UI0_CLIENT")) .Or. Empty(oModelUI0:GetValue("UI0_LOJA"))) 
				Help( ,, 'Help - MODELPOS',, 'Necessariamente o Grupo de Cliente ou Cliente e Loja devem ser informados.', 1, 0 )
				xRet := .F.
			EndIf
		EndIf
	EndIf
EndIf 

Return xRet