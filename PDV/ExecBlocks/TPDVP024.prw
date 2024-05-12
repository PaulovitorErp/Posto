#Include 'Protheus.ch'

Static nVlrOpen := 0

#DEFINE TYPEOPERATION 		1        			// 01 - Tipo da rotina: (1) Sangria / Entrada de troco (2)
#DEFINE CASHIER_ORIGIN 		2         			// 02 - Codigo do caixa de origem
#DEFINE CASHIER_DESTINY 	3 	        		// 03 - Codigo do caixa de destino
#DEFINE VALUE_MONEY 		4 					// 04 - Valor em dinheiro
#DEFINE VALUE_CHECK  		5     				// 05 - Valor em cheque
#DEFINE VALUE_CREDITCARD	6       			// 06 - Valor em cartao de credito
#DEFINE VALUE_DEBITCARD 	7 					// 07 - Valor em cartao de debito
#DEFINE VALUE_FINANCED 		8    				// 08 - Valor em financiado
#DEFINE VALUE_COVENANT 		9         			// 09 - Valor em convenio
#DEFINE VALUE_COUPONS 		10 					// 10 - Valor em vales
#DEFINE VALUE_OTHERS 		11         			// 11 - Valor em outros
#DEFINE AGENCY    		   12         			// 12 - Numero da agencia  
#DEFINE DV_AGENC     		13         			// 13 - Digito da agencia   
#DEFINE ACCOUNT             14 						// 14 - Numero da conta   
#DEFINE DV_ACCOUNT          15 						// 15 - Digito da conta   

/*/{Protheus.doc} TPDVP024 (STIMotSa)
Ponto de entrada antes da sangria/suprimento ou abertura de caixa

@author thebr
@since 14/02/2019
@version 1.0
@return Nil

@type function
/*/
User Function TPDVP024()

Local lRet := PARAMIXB[1]
Local aValues := iif(len(PARAMIXB)>=2,PARAMIXB[2],{})
Local lEmitNfce	:= Iif(FindFunction("LjEmitNFCe"), LjEmitNFCe(), .F.) // Sinaliza se utiliza NFC-e
Local nX := nTotal := 0
Local nViasAd := SuperGetMv("TP_SSVIASA",,0) //Define numero de vias adicionais para sangria e suprimentos
Local nPos := 0

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return lRet
EndIf

nVlrOpen := 0

if lRet
    If Isincallstack("STIConfirmBleeding")  // Foi chamado da tela de sangria / suprimentos
    
        If lEmitNfce .and. nViasAd > 0 .and. !empty(aValues)
            
            // Soma os valores recebidos  
            nTotal :=	(	aValues[VALUE_MONEY] 				+ ;
                            aValues[VALUE_CHECK] 				+ ;
                            aValues[VALUE_CREDITCARD] 		+ ;
                            aValues[VALUE_DEBITCARD] 		+ ;
                            aValues[VALUE_FINANCED] 		 	+ ;
                            aValues[VALUE_COVENANT] 			+ ;
                            aValues[VALUE_COUPONS] 			+ ;
                            aValues[VALUE_OTHERS] 			)  

            if nTotal > 0
                for nX :=1 to nViasAd      
                    //lRet := StaticCall(STBSupplyBleeding, STBImpSupNFCE, aValues[TYPEOPERATION], nTotal)
                    nPos := TYPEOPERATION
                    lRet := &("StaticCall(STBSupplyBleeding, STBImpSupNFCE, aValues[nPos], nTotal)")
                next nX
            endif
        EndIf

    Elseif Isincallstack("STWOpenSupply") // Foi chamado da abertura do caixa
        
        If lEmitNfce .and. nViasAd > 0 .and. !empty(aValues)
            // Soma os valores recebidos  
            nTotal := aValues[VALUE_MONEY]
            if nTotal > 0
                nVlrOpen := nTotal
            endif
        EndIf
        
    Else // Chamado do estorno do recebimento de titulos
    endif
endif

Return lRet

//Funçao para obter o valor de abertura
User Function T024VOpe()
Return nVlrOpen
