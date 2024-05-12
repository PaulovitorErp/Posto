#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} TRETP005
Chamado pelo P.E. MT120ALT para validar a exclusão quando existir CRC
@author Wellington Gonçalves
@since 01/05/2015
@version 1.0
@return Lógico

@type function
/*/

User Function TRETP005()

Local lCrc := SuperGetMv("MV_XTPCRC",.F.,.T.) //habilita CRC
Local aArea		:= GetArea()
Local aAreaZE5
//Local _nOpc	:= Paramixb[1]
Local _lRet := .T.

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return _lRet
EndIf

if lCrc // apenas se a empresa for 02

	if Type("_lCRC") == "U" // variável private criada no fonte U_OpenCRC(). Se não existir é porque está sendo chamado diretamente do pedido de compras
	
		If Paramixb[1] == 4 .OR. Paramixb[1] == 5  // Alteração ou Exclusão    
		    
		    aAreaZE5 := ZE5->(GetArea())
		    
			// caso tenha CRC para este pedido não será permitido alterar ou excluir
			If !Empty(SC7->C7_XCRC)
				Aviso( "Atenção!","Não é possível alterar/excluir um pedido de compra que tenha CRC!", {"Ok"} )
				_lRet := .F.    
			else  
			
				// caso tenha uma amostra cadastrada para algum item do pedido não será permitido alterar ou excluir
				ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM           
				if ZE5->(DbSeek(xFilial("ZE5") + SC7->C7_NUM ))
					Aviso( "Atenção!","Não é possível alterar/excluir um pedido de compra que tenha uma amostra de combustível!", {"Ok"} )
					_lRet := .F.    					
				endif 
			
			endif 
			
			RestArea(aAreaZE5)
		
		EndIf 
		
	endif 

endif 
               
RestArea(aArea)

Return(_lRet) 
