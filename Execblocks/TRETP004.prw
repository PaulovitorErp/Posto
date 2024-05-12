#Include "Protheus.ch"


/*/{Protheus.doc} TRETP004
Chamado pelo P.E. MT121BRW para adicionar ao menu do pedido de compra 
a opção de caddastro do CRC.
@author Ricardo Quintais
@since 29/01/2015
@version 1.0
@return Nulo

@type function
/*/

User function TRETP004()  

Local lCrc := SuperGetMv("MV_XTPCRC",.F.,.T.) //habilita CRC

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return
EndIf
                     
If lCrc // apenas se a empresa for a 02, que é a do posto
	aAdd(aRotina,{"Cadastro CRC","U_OpenCRC()", 0, 4, 0, Nil }) //"Cadastrar CRC" 
EndIf

Return    

// rotina que chama função MVC para abrir o cadastro de CRC

User Function OpenCRC()

Local aArea 	:= GetArea()
Local aAreaZE3	:= ZE3->(GetArea())   
Local cNumCRC	:= ""  

ZE3->(DbSetOrder(2)) // ZE3_FILIAL + ZE3_PEDIDO
if ZE3->(DbSeek(xFilial("ZE3") + SC7->C7_NUM)) 
    
    // se o status for diferente de 1, permite apenas visualizar o CRC
	if ZE3->ZE3_STATUS == "1"
		FWExecView('ALTERAR','TRETA020',4,,{|| .T. }) 
	else
		FWExecView('VISUALIZAR','TRETA020',1,,{|| .T. }) 
	endif

else     

	if empty(SC7->C7_CONAPRO) .OR. AllTrim(SC7->C7_CONAPRO) == "L" // se o pedido de compras estiver liberado   
	
		cNumCRC := GetSXENum("ZE3","ZE3_NUMERO")
		 
		// verifico se o CRC já existe
		ZE3->(DbSetOrder(1)) // ZE3_FILIAL + ZE3_NUMERO 
		While ZE3->(DbSeek(xFilial("ZE3") + cNumCRC)) 
			ConfirmSX8()
			cNumCRC := GetSXENum("ZE3","ZE3_NUMERO")
		EndDo 

		// se nao existir o CRC, crio um novo	
		if RecLock("ZE3",.T.)
						
			ZE3->ZE3_FILIAL	:= xFilial("ZE3")
			ZE3->ZE3_NUMERO	:= cNumCRC 
			ZE3->ZE3_PEDIDO	:= SC7->C7_NUM 
			ZE3->ZE3_STATUS := "1" // status inicial em aberto        
			ZE3->ZE3_HRINI	:= Time() 
			ZE3->(MsUnlock())
			
			ConfirmSX8()
			
			// chamo a tela de alteração do CRC
			FWExecView('ALTERAR','TRETA020',4,,{|| .T. }) 
						
		endif   
	
	else
		Aviso( "Atenção!","Não é possível gerar o CRC para um pedido bloqueado!", {"Ok"} )
	endif
	
endif
                 
RestArea(aAreaZE3)
RestArea(aArea)

Return()
