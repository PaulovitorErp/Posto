#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} TRETP005
Chamado pelo P.E. MT120ALT para validar a exclus�o quando existir CRC
@author Wellington Gon�alves
@since 01/05/2015
@version 1.0
@return L�gico

@type function
/*/

User Function TRETP005()

Local lCrc := SuperGetMv("MV_XTPCRC",.F.,.T.) //habilita CRC
Local aArea		:= GetArea()
Local aAreaZE5
//Local _nOpc	:= Paramixb[1]
Local _lRet := .T.

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
If !lMvPosto
	Return _lRet
EndIf

if lCrc // apenas se a empresa for 02

	if Type("_lCRC") == "U" // vari�vel private criada no fonte U_OpenCRC(). Se n�o existir � porque est� sendo chamado diretamente do pedido de compras
	
		If Paramixb[1] == 4 .OR. Paramixb[1] == 5  // Altera��o ou Exclus�o    
		    
		    aAreaZE5 := ZE5->(GetArea())
		    
			// caso tenha CRC para este pedido n�o ser� permitido alterar ou excluir
			If !Empty(SC7->C7_XCRC)
				Aviso( "Aten��o!","N�o � poss�vel alterar/excluir um pedido de compra que tenha CRC!", {"Ok"} )
				_lRet := .F.    
			else  
			
				// caso tenha uma amostra cadastrada para algum item do pedido n�o ser� permitido alterar ou excluir
				ZE5->(DbSetOrder(1)) // ZE5_FILIAL + ZE5_PEDIDO + ZE5_ITEMPE + ZE5_LACRAM           
				if ZE5->(DbSeek(xFilial("ZE5") + SC7->C7_NUM ))
					Aviso( "Aten��o!","N�o � poss�vel alterar/excluir um pedido de compra que tenha uma amostra de combust�vel!", {"Ok"} )
					_lRet := .F.    					
				endif 
			
			endif 
			
			RestArea(aAreaZE5)
		
		EndIf 
		
	endif 

endif 
               
RestArea(aArea)

Return(_lRet) 
