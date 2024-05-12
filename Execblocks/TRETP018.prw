#include 'protheus.ch'

/*/{Protheus.doc} TRETP018
Pontos de Entrada para rotina FINA460 (Liquidação) 
@author Maiki Perin
@since 05/04/2019
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User function TRETP018()
/***********************/

Local aParam		:= PARAMIXB
Local xRet			:= .T.
Local oObj			:= ''
Local cIdPonto		:= ''
Local cIdModel		:= ''

Local nVlrTit		:= 0

Local cPortador		:= ""
Local cAgencia		:= ""
Local cConta		:= ""
Local _nSEE			:= SuperGetMv("MV_XSEE",,0)
Local lSEEAuto		:= SuperGetMv("TP_SEEAUTO",.F.,.T.)

Local aAreaSE1		:= SE1->(GetArea())
Local nI
Local cMVTxPer		:= GetMV("MV_TXPER")

Local nPosAux

Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
//Caso o Posto Inteligente não esteja habilitado não faz nada...
If !lMvPosto
	Return xRet
EndIf

If aParam <> NIL

    oObj 		:= aParam[1]
    cIdPonto	:= aParam[2]
    cIdModel	:= aParam[3]
    
    //Model título gerado
    oModelFO1	:= oObj:GetModel("TITSELFO1")
    oModelFO2	:= oObj:GetModel("TITGERFO2")
 
    If cIdPonto == 'MODELPOS' // Bloco substitui o ponto de entrada F460TOK e FA460CON

		if IsInCallStack("U_TRETE016") .AND. type("__aTitTR016") == "A" .AND. !empty(__aTitTR016)
			//aadd(__aTitTR016, SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + ;
			//				SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA)
			For nI := 1 To oModelFO1:Length()
				oModelFO1:Goline(nI)
				cChaveFO1 := xFilial("SE1",oModelFO1:GetValue("FO1_FILORI")) + oModelFO1:GetValue("FO1_PREFIX") + oModelFO1:GetValue("FO1_NUM") + oModelFO1:GetValue("FO1_PARCEL") +;
					 oModelFO1:GetValue("FO1_TIPO") + oModelFO1:GetValue("FO1_CLIENT") + oModelFO1:GetValue("FO1_LOJA")
				nPosAux := aScan(__aTitTR016, cChaveFO1)
				if nPosAux == 0
					Help( ,, 'Help',, 'Titulo [' + cChaveFO1 + '] não selecionado para geração da fatura!', 1, 0 )
					xRet := .F.
					lMsErroAuto := .T.
					EXIT
				else
					aDel(__aTitTR016, nPosAux)
					aSize(__aTitTR016, len(__aTitTR016)-1)
				endif
			Next nI
			if xRet .AND. !empty(__aTitTR016) //tem que deletar todos
				Help( ,, 'Help',, 'Há titulos selecionados não encontrados pela rotina MATA460!', 1, 0 )
				xRet := .F.
				lMsErroAuto := .T.
			endif
		endif

	ElseIf cIdPonto == 'MODELCOMMITNTTS' // Bloco substitui o ponto de entrada F460GRV
    	
    	DbSelectArea("SE1")
    	SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

		If ChkFile("U88")
			DbSelectArea("U88")
			U88->(DbSetOrder(1)) // U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
		EndIf

		For nI := 1 To oModelFO2:Length()

			oModelFO2:Goline(nI)
			If !oModelFO2:IsDeleted()

				If SE1->(DbSeek(xFilial("SE1")+oModelFO2:GetValue("FO2_PREFIX")+oModelFO2:GetValue("FO2_NUM")+oModelFO2:GetValue("FO2_PARCEL")))
	   
					//Selecionando Banco, Agência e Conta
					If ChkFile("U88")
						If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+SE1->E1_CLIENTE+SE1->E1_LOJA))
							cPortador 	:= U88->U88_BANCOC
							cAgencia	:= U88->U88_AGC
							cConta		:= U88->U88_CONTAC
						EndIf
					EndIf
				
					If lSEEAuto
						If Empty(cPortador)
							If !Empty(_nSEE)
								DbSelectArea("SEE")
								SEE->(DbGoTo(_nSEE))
							    cPortador	:= SEE->EE_CODIGO
								cAgencia 	:= SEE->EE_AGENCIA
								cConta		:= SEE->EE_CONTA
							EndIf
						EndIf
					EndIf
				
					If !IsBlind() .And. !IsInCallStack("U_TRETE017")
					    cPortador	:= ""
						cAgencia 	:= ""
						cConta		:= ""
					EndIf
		
			    	RecLock("SE1",.F.)
			    	
						// Banco, Agência e Conta
						If !Empty(cPortador)
							SE1->E1_PORTADO	:= cPortador
						EndIf
						If !Empty(cAgencia)
							SE1->E1_AGEDEP	:= cAgencia
						EndIf
						If !Empty(cConta)
							SE1->E1_CONTA	:= cConta
						EndIf
			
						// Juros
						nVlrTit := oModelFO2:GetValue("FO2_VALOR")
						SE1->E1_VALJUR	:= nVlrTit * cMVTxPer / 100
						SE1->E1_PORCJUR	:= cMVTxPer
			
						// Usuário do faturamento
						If SE1->(FIELDPOS('E1_XUSRFAT')) > 0
							SE1->E1_XUSRFAT := UsrRetName(__cUserId)
						EndIf
			    	
			    	SE1->(MsUnlock())
			    	
			    	SE1->(DbSkip())
			    EndIf
			EndIf
	    Next nI
    Endif
Endif

RestArea(aAreaSE1)

Return xRet
