#include 'protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TRETM031
Ponto de Entrada da Rotina de Cadastro de Serviços Fornecedor (TRETA031)
@author TOTVS
@since 25/04/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/

/***********************/
User Function TRETM031()
/***********************/

Local aParam     	:= PARAMIXB 
Local oObj       	:= aParam[1]
Local cIdPonto   	:= aParam[2]
Local cIdModel   	:= IIf(oObj<> NIL, oObj:GetId(), aParam[3]) //cIdModel   := aParam[3]
Local cClasse    	:= IIf(oObj<> NIL, oObj:ClassName(), '') 
Local nOperation 	:= IIf(oObj<> NIL, oObj:GetOperation(), 0) 
Local oModelUH8	 	:= oObj:GetModel('UH8MASTER') 
Local oModelUH9  	:= oObj:GetModel('UH9DETAIL')  
Local xRet       	:= .T. 
Local cOperad 	 	:= "" 

Local nI
Local aServ			:= {}

If aParam <> NIL 

 	If cIdPonto == 'MODELCOMMITNTTS' 
 		
 		If nOperation == 3 .Or. nOperation == 4 // Inclusão ou Alteração
 		
	 		// Atualiza Negociação de Preços
	 		For nI := 1 To oModelUH9:Length()
		
				// Posiciona na linha atual
				oModelUH9:Goline(nI)  
			
				If !oModelUH9:IsDeleted()
					
					AAdd(aServ,{oModelUH9:GetValue("UH9_PRODUT"),oModelUH9:GetValue("UH9_PRCUNI")})				
				EndIf
			Next nI
			
			If Len(aServ) > 0
				FWMsgRun(,{|oSay| UpdUIB(oModelUH8:GetValue("UH8_FORNEC"),oModelUH8:GetValue("UH8_LOJA"),aServ)},'Aguarde','Atualizando Negociação de Preços...')		
			Endif
		EndIf
 	EndIf
EndIf 

Return xRet

/**********************************************/
Static Function UpdUIB(cFornece,cLojaFor,aServ)
/**********************************************/

Local cQry 	:= ""
Local cQry2	:= ""
Local nI

DbSelectArea("UI1")
DbSelectArea("UIB")

If Select("QRYUI0") > 0
	QRYUI0->(DbCloseArea())
EndIf

cQry := "SELECT UI0_FILIAL, UI0_GRPCLI, UI0_CLIENT, UI0_LOJA"
cQry += " FROM "+RetSqlName("UI0")+""
cQry += " WHERE D_E_L_E_T_ <> '*'"
cQry += " AND UI0_FILIAL	= '"+xFilial("UI0")+"'"
cQry += " ORDER BY UI0_FILIAL, UI0_GRPCLI, UI0_CLIENT, UI0_LOJA"

cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETM031.txt",cQry)
TcQuery cQry NEW Alias "QRYUI0"

While QRYUI0->(!EOF())

	If Select("QRYUI1") > 0
		QRYUI1->(DbCloseArea())
	EndIf
	
	cQry := "SELECT UI1_FILIAL, UI1_GRPCLI, UI1_CLIENT, UI1_LOJA, UI1_FORNEC, UI1_LOJAFO"
	cQry += " FROM "+RetSqlName("UI1")+""
	cQry += " WHERE D_E_L_E_T_ <> '*'"
	cQry += " AND UI1_FILIAL	= '"+xFilial("UI1")+"'"
	cQry += " AND UI1_GRPCLI	= '"+QRYUI0->UI0_GRPCLI+"'"
	cQry += " AND UI1_CLIENT	= '"+QRYUI0->UI0_CLIENT+"'"
	cQry += " AND UI1_LOJA		= '"+QRYUI0->UI0_LOJA+"'"
	cQry += " AND UI1_FORNEC	= '"+cFornece+"'"
	cQry += " AND UI1_LOJAFO	= '"+cLojaFor+"'"
	cQry += " ORDER BY UI1_FILIAL, UI1_GRPCLI, UI1_CLIENT, UI1_LOJA, UI1_FORNEC, UI1_LOJAFO"
	
	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETM031.txt",cQry)
	TcQuery cQry NEW Alias "QRYUI1"
	
	If QRYUI1->(EOF())
		
		// Grupo de cliente Ou Cliente não possui o prestador de serviço relacionado
		// Inclui o prestador de serviço		
		RecLock("UI1",.T.)
		UI1->UI1_FILIAL := xFilial("UI1")
		UI1->UI1_GRPCLI := QRYUI0->UI0_GRPCLI
		UI1->UI1_CLIENT := QRYUI0->UI0_CLIENT
		UI1->UI1_LOJA 	:= QRYUI0->UI0_LOJA
		UI1->UI1_FORNEC := cFornece
		UI1->UI1_LOJAFO := cLojaFor
		UI1->UI1_NOME	:= Posicione("SA2",1,xFilial("SA2")+cFornece+cLojaFor,"A2_NOME")
		UI1->(MsUnlock())
		
		For nI := 1 To Len(aServ)
		
			// Inclui seus serviços
			RecLock("UIB",.T.)
			UIB->UIB_FILIAL := xFilial("UIB")
			UIB->UIB_GRPCLI	:= QRYUI0->UI0_GRPCLI
			UIB->UIB_CLIENT	:= QRYUI0->UI0_CLIENT
			UIB->UIB_LOJA	:= QRYUI0->UI0_LOJA
			UIB->UIB_FORNEC	:= cFornece
			UIB->UIB_LOJAFO	:= cLojaFor
			UIB->UIB_PRODUT	:= aServ[nI][1]
			UIB->(MsUnlock())
		Next nI
		
	Else

		For nI := 1 To Len(aServ)
		
			If !UIB->(DbSeek(xFilial("UIB")+QRYUI1->UI1_GRPCLI+QRYUI1->UI1_CLIENT+QRYUI1->UI1_LOJA+QRYUI1->UI1_FORNEC+QRYUI1->UI1_LOJAFO+aServ[nI][1]))

				// Possui o prestador de serviço relacionado, porém não possui o serviço cadastrado
				RecLock("UIB",.T.)
				UIB->UIB_FILIAL := xFilial("UIB")
				UIB->UIB_GRPCLI	:= QRYUI1->UI1_GRPCLI
				UIB->UIB_CLIENT	:= QRYUI1->UI1_CLIENT
				UIB->UIB_LOJA	:= QRYUI1->UI1_LOJA
				UIB->UIB_FORNEC	:= QRYUI1->UI1_FORNEC
				UIB->UIB_LOJAFO	:= QRYUI1->UI1_LOJAFO
				UIB->UIB_PRODUT	:= aServ[nI][1]
				UIB->(MsUnlock())
				
			EndIf
		Next nI
	EndIf

	QRYUI0->(DbSkip())
EndDo

If Select("QRYUI0") > 0
	QRYUI0->(DbCloseArea())
EndIf

If Select("QRYUI1") > 0
	QRYUI1->(DbCloseArea())
EndIf

Return