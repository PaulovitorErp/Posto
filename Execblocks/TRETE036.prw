#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE036
Geração NF-e s/ Cupom
@author Maiki Perin
@since 01/08/2014
@version P11
@param cFatura
@return nulo                                                                                  

/*/

/************************************************************************************************/
User Function TRETE036(cFil,cTp,cPref,cTit,cCli,cLojaCli,lPdv,lMostraMsg,aCupsNf,lFatAut,cMsgAdic,cTpGerNf,nContAux,cNfsGerada)
/************************************************************************************************/ 

Local aArea			:= GetArea()
Local lRet			:= .T.
Local cQry 			:= ""  
Local nI 

Local nCont			:= 0 
Local nCont2		:= 0
Local cTpFat		:= "" 
Local cNumNota		:= ""                                        
Local lContinua            

Local aCupons 		:= {} //Array com os cupons para geracao da NF 
Local aRetorno		:= {}
Local lNota 		:= .T. //Informa se é geração ou estorno da NF

Default lPdv		:= .F.                                           
Default lMostraMsg	:= .T.
Default aCupsNf     := {}                                                               
Default lFatAut		:= .F.  
Default cMsgAdic	:= ""  
Default cTpGerNf 	:= ""
Default nContAux	:= 0
Default cNfsGerada	:= ""

Private lMsHelpAuto := .T.
Private lMsErroAuto := .F.

Private lMarajo		:= SuperGetMv("MV_XMARAJO",.F.,.F.)

Private lNfAcobert	:= SuperGetMv("MV_XNFACOB",.F.,.F.)

if empty(cTp)
	cTp := "FT"
endif

If cPref == "FAT" //Fatura

	If Select("QRYCF") > 0
		QRYCF->(dbCloseArea())
	Endif                                              
	
	cQry := "SELECT DISTINCT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA"
	cQry += " FROM "+RetSqlName("SE1")+" SE1, "+RetSqlName("SF2")+" SF2"
	cQry += " WHERE SE1.D_E_L_E_T_	<> '*'"
	cQry += " AND SF2.D_E_L_E_T_	<> '*'"
	
	If cFil == Nil
		cQry += " AND SE1.E1_FILIAL 	= '"+xFilial("SE1")+"'"      
		cQry += " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"      
	Else
		cQry += " AND SE1.E1_FILIAL 	= '"+cFil+"'"      
		cQry += " AND SF2.F2_FILIAL 	= '"+cFil+"'"      
	Endif
	
	cQry += " AND SE1.E1_FILIAL		= SF2.F2_FILIAL"
	cQry += " AND SE1.E1_NUM		= SF2.F2_DOC"
	cQry += " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
	cQry += " AND SE1.E1_LOJA		= SF2.F2_LOJA"
	cQry += " AND SE1.E1_FATURA		= '"+cTit+"'"
	cQry += " AND SF2.F2_NFCUPOM	= '"+Space(12)+"'" //Não haja NF s/ CF
	If lNfAcobert
		cQry += " AND (SF2.F2_ESPECIE = 'CF' OR SF2.F2_ESPECIE = 'NFCE')" //Cupom Fiscal ou NFC-e
	Else
		cQry += " AND SF2.F2_ESPECIE	= 'CF'" //Cupom Fiscal
	Endif
	
	cQry += " ORDER BY 1"
	
	cQry := ChangeQuery(cQry) 
	//MemoWrite("c:\temp\TRETE036.txt",cQry)
	TcQuery cQry NEW Alias "QRYCF"
	
	If !IsBlind()
		QRYCF->(dbEval({|| nCont++}))
		ProcRegua(nCont)
	Endif
	
	QRYCF->(dbGoTop())
	
	While QRYCF->(!EOF()) 
	
		If !IsBlind()
			IncProc()   
		Endif
	
		AAdd(aCupons,{QRYCF->F2_DOC,;
					  QRYCF->F2_SERIE,;
					  QRYCF->F2_CLIENTE,;
					  QRYCF->F2_LOJA})

		QRYCF->(dbSkip())
	EndDo
Else
	If !IsBlind()
		ProcRegua(1)
    	IncProc()
  	Endif                   
  	
  	If !lPdv 
  	
  		If Len(aCupsNf) == 0
  	
		  	DbSelectArea("SF2")
		  	SF2->(DbSetOrder(2)) //F2_FILIAL+F2_CLIENTE+F2_LOJA+F2_DOC+F2_SERIE
		  	
		  	If SF2->(DbSeek(IIF(cFil == Nil,xFilial("SF2"),cFil)+cCli+cLojaCli+cTit+cPref))
		  		
		  		If !lNfAcobert
		
					If Empty(SF2->F2_NFCUPOM) .And. AllTrim(SF2->F2_ESPECIE) = 'CF' //Não haja NF s/ CF e Cupom Fiscal
			
						AAdd(aCupons,{cTit,;
									  cPref,;
									  cCli,;
									  cLojaCli})
					Endif
				Else
					If Empty(SF2->F2_NFCUPOM) .And. AllTrim(SF2->F2_ESPECIE) = 'NFCE' //Não haja NF s/ NFC-e e NFC-e
			
						AAdd(aCupons,{cTit,;
									  cPref,;
									  cCli,;
									  cLojaCli})
					Endif
				Endif
			Endif
		Else
			aCupons := aClone(aCupsNf)
		Endif

	ElseIf Len(aCupsNf) == 0 

		AAdd(aCupons,{cTit,;
					  cPref,;
					  cCli,;
					  cLojaCli})
	Else
		aCupons := aClone(aCupsNf)
	Endif
Endif

If !lPdv                    

	If Empty(AllTrim(cTpGerNf))

		DbSelectArea("U88")
		U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
		
		If U88->(DbSeek(xFilial("U88")+cTp+Space(6 - Len(cTp))+cCli+cLojaCli))
		
			cTpFat := U88->U88_GERANF
			
			If cFil == Nil
				cFil := xFilial("SE1")
			Endif
			
			If cFil $ U88->U88_FILAUT 
				lContinua := .T. 
			Else
				lContinua := .F.
			Endif
		
			If lContinua
			
				If cTpFat == "N" //Não
					
					If IsBlind()
						If !lNfAcobert
							//Conout("O Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+">, não admite geração de Nota s/ CF para a Forma de Pagamento <"+AllTrim(cTp)+">!!")
						Else
							//Conout("O Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+">, não admite geração de Nota s/ NFC-e para a Forma de Pagamento <"+AllTrim(cTp)+">!!")
						Endif
					Else
						If !lNfAcobert
							MsgInfo("O Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+">, não admite geração de Nota s/ CF para a Forma de Pagamento <"+AllTrim(cTp)+">!!","Atenção")
						Else
							MsgInfo("O Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+">, não admite geração de Nota s/ NFC-e para a Forma de Pagamento <"+AllTrim(cTp)+">!!","Atenção")
						Endif
					Endif
					
				    lRet := .F.
	
				ElseIf cTpFat == "S" //Aglutinada
				
					If Len(aCupons) > 0
						SetMvValue("LJR131", "MV_PAR10", "")
						SetMvValue("LJR131", "MV_PAR11", "")
						MV_PAR10 := ""
						MV_PAR11 := ""
						//Chama a rotina de nota sobre cupom
						if empty(cCli+cLojaCli)
							LojR130(aCupons,lNota,aCupons[1][3],aCupons[1][4])
						else
							LojR130(aCupons,lNota,cCli,cLojaCli)
						endif
	
						If lMsErroAuto 
							//MostraErro()
							DisarmTransaction()
							RollBackSx8()
						EndIf
						
						aRetorno := RetNfCupom(aCupons,1)   //Retorna o numero e serie da Nota Gerada
					    
					    SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
					    
					    If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
							nContAux++
							if !empty(cNfsGerada)
								cNfsGerada += ",  "
							endif
							cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
							If IsBlind()
								If !lNfAcobert
									//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF gerada com sucesso!!")
								Else
									//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e gerada com sucesso!!")
								Endif
							Else
								If lMostraMsg
									If !lNfAcobert
										MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF gerada com sucesso!!","Atenção")
									Else
										MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e gerada com sucesso!!","Atenção")
									Endif
								Endif
							Endif
						
							RecLock("SF2",.F.)
							If lFatAut //Faturamento automático
								SF2->F2_XNFFATU := "A"  
							Else
								SF2->F2_XNFFATU := "S"  
							Endif                
							SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
							SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
							SF2->(MsUnlock())
						Else
							If !lNfAcobert
								//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[1][1]+"/"+aCupons[1][2]+" ")
							Else
								//Conout("Nota de acobertamento não encontrada! Verifique o cupom: "+aCupons[1][1]+"/"+aCupons[1][2]+" ")
							Endif
						EndIf
							
					Else
						If IsBlind()
							//Conout("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!")
						Else        
							If lMostraMsg
								MsgInfo("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!","Atenção")
							Endif
						Endif
	
					    lRet := .F.
					Endif
		
				ElseIf cTpFat == "I" //Individual
	
					For nI := 1 To Len(aCupons)    
					
						nCont2++                               
						lMsErroAuto := .F.
						SetMvValue("LJR131", "MV_PAR10", "")
						SetMvValue("LJR131", "MV_PAR11", "")
						MV_PAR10 := ""
						MV_PAR11 := ""
						
						//Chama a rotina de nota sobre cupom
						if empty(cCli+cLojaCli)
							LojR130({aCupons[nI]},lNota,aCupons[nI][3],aCupons[nI][4])
						else
							LojR130({aCupons[nI]},lNota,cCli,cLojaCli)
						endif
	
						If lMsErroAuto
							DisarmTransaction()
							RollBackSx8()
						EndIf
		                
						aRetorno := RetNfCupom(aCupons,nI)   //Retorna o numero da Nota Gerado
						
						SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
						
						If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
							nContAux++
							if !empty(cNfsGerada)
								cNfsGerada += ",  "
							endif
							cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
							If IsBlind()
								If !lNfAcobert
									//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!")
								Else
									//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!")
								Endif
							Else
								If lMostraMsg
									If !lNfAcobert
										MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!","Atenção")
									Else
										MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!","Atenção")
									Endif
								Endif
							Endif
		
							//Flag para indicar NF s/ CF a partir da rotina de Faturamento Manual
							RecLock("SF2",.F.)
							If lFatAut //Faturamento automático
								SF2->F2_XNFFATU := "A" 
							Else
								SF2->F2_XNFFATU := "S" 
							Endif
							SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
							SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
							SF2->(MsUnlock())
					    Else
					    	If !lNfAcobert
					    		//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[nI][1]+"/"+aCupons[nI][2]+" ")
					    	Else
					    		//Conout("Nota de acobertamento não encontrada! Verifique o cupom: "+aCupons[nI][1]+"/"+aCupons[nI][2]+" ")
					    	Endif
						EndIf
					Next 
					
					If nCont2 == 0
		
						If IsBlind()                           
							//Conout("Cupons Fiscais não localizados Ou já possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!")
						Else
							If lMostraMsg
								MsgInfo("Cupons Fiscais não localizados Ou já possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!","Atenção")
							Endif
						Endif
	
					    lRet := .F.
					Endif
				Endif
			Else
				If IsBlind()
					If !lNfAcobert
						//Conout("Filial <"+cFil+"> não autorizada para geração de NF s/ CF, em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">!!")
					Else
						//Conout("Filial <"+cFil+"> não autorizada para geração de NF s/ NFC-e, em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">!!")
					Endif
				Else
					If lMostraMsg
						If !lNfAcobert
							MsgInfo("Filial <"+cFil+"> não autorizada para geração de NF s/ CF, em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">!!","Atenção")
						Else
							MsgInfo("Filial <"+cFil+"> não autorizada para geração de NF s/ NFC-e, em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">!!","Atenção")
						Endif
					Endif
				Endif
	
			    lRet := .F.
			Endif 
		Else
			If lMarajo
				
				If IsBlind()
					//Conout("Cadastro Cliente x Forma de Pagamento não localizado em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">, geração de NF s/ CF não permitida!!")
				Else
					If lMostraMsg
						MsgInfo("Cadastro Cliente x Forma de Pagamento não localizado em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">, geração de NF s/ CF não permitida!!","Atenção")
					Endif
				Endif
				
				lRet := .F.
			Else
				If lMostraMsg
					MsgInfo("Cadastro Cliente x Forma de Pagamento não localizado em função do Cliente <"+AllTrim(cCli)+"> Loja <"+AllTrim(cLojaCli)+"> para a Forma de Pagto. <"+AllTrim(cTp)+">, geração de NF-e não permitida!!","Atenção")
				Endif

				If Len(aCupons) > 0
					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""
				
					//Chama a rotina de nota sobre cupom
					if empty(cCli+cLojaCli)
						LojR130(aCupons,lNota,aCupons[1][3],aCupons[1][4])
					else
						LojR130(aCupons,lNota,cCli,cLojaCli)
					endif

					If lMsErroAuto 
						MostraErro()
						DisarmTransaction()
						RollBackSx8()
					EndIf
					
					aRetorno := RetNfCupom(aCupons,1)   //Retorna o numero e serie da Nota Gerada
				    
				    SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
				    
				    If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
						nContAux++
						if !empty(cNfsGerada)
							cNfsGerada += ",  "
						endif
						cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
						If IsBlind()
							//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> gerada com sucesso.")
						Else
							If lMostraMsg
								MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> gerada com sucesso.","Atenção")
							Endif
						Endif
					
						RecLock("SF2",.F.)
						If lFatAut //Faturamento automático
							SF2->F2_XNFFATU := "A"  
						Else
							SF2->F2_XNFFATU := "S"  
						Endif                
						SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
						SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
						SF2->(MsUnlock())
					Else
						//Conout("Nota Fiscal não encontrada! Verifique o cupom: "+aCupons[1][1]+"/"+aCupons[1][2]+" ")
					EndIf
						
				Else
					If IsBlind()
						//Conout("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!")
					Else        
						If lMostraMsg
							MsgInfo("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!","Atenção")
						Endif
					Endif

				    lRet := .F.
				Endif
			Endif
		Endif
	Else
		cTpFat := cTpGerNf
		
		If lMarajo
		        
			If cTpFat == "S" //Aglutinada
			
				If Len(aCupons) > 0
					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""
					
					//Chama a rotina de nota sobre cupom
					if empty(cCli+cLojaCli)
						LojR130(aCupons,lNota,aCupons[1][3],aCupons[1][4])
					else
						LojR130(aCupons,lNota,cCli,cLojaCli)
					endif
			
					If lMsErroAuto
						DisarmTransaction()
						RollBackSx8()
					EndIf
					
					aRetorno := RetNfCupom(aCupons,1)   //Retorna o numero e serie da Nota Gerada
				    
				    SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
				    
				    If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
						nContAux++
						if !empty(cNfsGerada)
							cNfsGerada += ",  "
						endif
						cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
						If IsBlind()
							//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF gerada com sucesso!!")
						Else
							If lMostraMsg
								MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF gerada com sucesso!!","Atenção")
							Endif
						Endif
					
						RecLock("SF2",.F.)
						If lFatAut //Faturamento automático
							SF2->F2_XNFFATU := "A"  
						Else
							SF2->F2_XNFFATU := "S"  
						Endif                
						SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
						SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
						SF2->(MsUnlock())
					Else
						//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[1][1]+"/"+aCupons[1][2]+" ")
					EndIf
						
				Else
					If IsBlind()
						//Conout("Cupom Fiscal não localizado ou possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!")
					Else        
						If lMostraMsg
							MsgInfo("Cupom Fiscal não localizado ou possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!","Atenção")
						Endif
					Endif
			
				    lRet := .F.
				Endif
			
			ElseIf cTpFat == "I" //Individual
			
				For nI := 1 To Len(aCupons)    
				
					nCont2++                               
					lMsErroAuto := .F.
					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""
					
					//Chama a rotina de nota sobre cupom
					if empty(cCli+cLojaCli)
						LojR130({aCupons[nI]},lNota,aCupons[nI][3],aCupons[nI][4])
					else
						LojR130({aCupons[nI]},lNota,cCli,cLojaCli)
					endif
			
					If lMsErroAuto
						DisarmTransaction()
						RollBackSx8()
					EndIf
			                
					aRetorno := RetNfCupom(aCupons,nI)   //Retorna o numero da Nota Gerado
					
					SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
					
					If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
						nContAux++
						if !empty(cNfsGerada)
							cNfsGerada += ",  "
						endif
						cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
						If IsBlind()
							//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!")
						Else
							If lMostraMsg
								MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!","Atenção")
							Endif
						Endif
			
						//Flag para indicar NF s/ CF a partir da rotina de Faturamento Manual
						RecLock("SF2",.F.)
						If lFatAut //Faturamento automático
							SF2->F2_XNFFATU := "A" 
						Else
							SF2->F2_XNFFATU := "S" 
						Endif
						SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
						SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
						SF2->(MsUnlock())
				    Else
						//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[nI][1]+"/"+aCupons[nI][2]+" ")
					EndIf
				Next 
				
				If nCont2 == 0
			
					If IsBlind()                            
						//Conout("Cupons Fiscais não localizados ou possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!")
					Else
						If lMostraMsg
							MsgInfo("Cupons Fiscais não localizados ou possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!","Atenção")
						Endif
					Endif
			
				    lRet := .F.
				Endif
			Endif	
		Else

			If Empty(cTpFat) .Or. cTpFat == "S" //Aglutinada
			
				If Len(aCupons) > 0
					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""

					//Chama a rotina de nota sobre cupom
					if empty(cCli+cLojaCli)
						LojR130(aCupons,lNota,aCupons[1][3],aCupons[1][4])
					else
						LojR130(aCupons,lNota,cCli,cLojaCli)
					endif

					If lMsErroAuto
						DisarmTransaction()
						RollBackSx8()
					EndIf
					
					aRetorno := RetNfCupom(aCupons,1)   //Retorna o numero e serie da Nota Gerada
				    
				    SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
				    
				    If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
						nContAux++
						if !empty(cNfsGerada)
							cNfsGerada += ",  "
						endif
						cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
						If IsBlind()
							//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e gerada com sucesso!!")
						Else
							If lMostraMsg
								MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e gerada com sucesso!!","Atenção")
							Endif
						Endif
					
						RecLock("SF2",.F.)
						If lFatAut //Faturamento automático
							SF2->F2_XNFFATU := "A"  
						Else
							SF2->F2_XNFFATU := "S"  
						Endif                
						SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
						SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
						SF2->(MsUnlock())
					Else
						//Conout("Nota fiscal não encontrada! Verifique o cupom: "+aCupons[1][1]+"/"+aCupons[1][2]+" ")
					EndIf
						
				Else
					If IsBlind()
						//Conout("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!")
					Else        
						If lMostraMsg
							MsgInfo("Cupom Fiscal não localizado Ou já possui Nota Fiscal relacionada, referente ao título "+AllTrim(cTit)+"!!","Atenção")
						Endif
					Endif
			
				    lRet := .F.
				Endif
			
			Else
			
				For nI := 1 To Len(aCupons)    
				
					nCont2++                               
					lMsErroAuto := .F.
					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""
					
					//Chama a rotina de nota sobre cupom
					if empty(cCli+cLojaCli)
						LojR130({aCupons[nI]},lNota,aCupons[nI][3],aCupons[nI][4])
					else
						LojR130({aCupons[nI]},lNota,cCli,cLojaCli)
					endif
			
					If lMsErroAuto
						DisarmTransaction()
						RollBackSx8()
					EndIf
			                
					aRetorno := RetNfCupom(aCupons,nI)   //Retorna o numero da Nota Gerado
					
					SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
					
					If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
						nContAux++
						if !empty(cNfsGerada)
							cNfsGerada += ",  "
						endif
						cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
						If IsBlind()
							//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!")
						Else
							If lMostraMsg
								MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][1])+"> gerada com sucesso!!","Atenção")
							Endif
						Endif
			
						//Flag para indicar NF s/ CF a partir da rotina de Faturamento Manual
						RecLock("SF2",.F.)
						If lFatAut //Faturamento automático
							SF2->F2_XNFFATU := "A" 
						Else
							SF2->F2_XNFFATU := "S" 
						Endif
						SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
						SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
						SF2->(MsUnlock())
				    Else
						//Conout("Nota fiscal não encontrada! Verifique o cupom: "+aCupons[nI][1]+"/"+aCupons[nI][2]+" ")
					EndIf
				Next 
				
				If nCont2 == 0
			
					If IsBlind()                            
						//Conout("Cupons Fiscais não localizados ou possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!")
					Else
						If lMostraMsg
							MsgInfo("Cupons Fiscais não localizados ou possuem Nota Fiscal relacionada, referente ao título <"+AllTrim(cTit)+">!!","Atenção")
						Endif
					Endif
			
				    lRet := .F.
				Endif
			Endif
		Endif
	EndIf		
Else 
	SetMvValue("LJR131", "MV_PAR10", "")
	SetMvValue("LJR131", "MV_PAR11", "")
	MV_PAR10 := ""
	MV_PAR11 := ""

	//Chama a rotina de nota sobre cupom
	LojR130(aCupons,lNota,cCli,cLojaCli)

	If lMsErroAuto
		DisarmTransaction()
		RollBackSx8()
	EndIf

	aRetorno := RetNfCupom(aCupons,1)   //Retorna o numero e serie da Nota Gerada
    
    SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
    
    If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
		nContAux++
		if !empty(cNfsGerada)
			cNfsGerada += ",  "
		endif
		cNfsGerada += AllTrim(SF2->F2_DOC) + "/"+ AllTrim(SF2->F2_SERIE)
		If IsBlind()
			//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[1][1])+"> gerada com sucesso!!")
		Else
			If lMostraMsg
				MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF gerada com sucesso!!","Atenção")
			Endif
		Endif
	
		If RecLock("SF2",.F.) 
			SF2->F2_TPFRETE := "S" // Acrescentado por Wellington Gonçalves dia 05/01/2015. Na nota sobre cupom não deve gerar frete
			SF2->F2_XMSGADI := cMsgAdic //Mensagem adicional no DANFE
			SF2->(MsUnlock())  
		Endif
	Endif
Endif    

RestArea(aArea)
          
Return lRet

/********************************************************
/ Funcao para Retonar o Numero da Nota S/ Cupom Gerada
/*******************************************************/
Static Function RetNfCupom(aCupons,nLin)

Local cNumNota  := space(TamSX3("F2_DOC")[1])
Local cSerieNf	:= space(TamSX3("F2_SERIE")[1])
Local aAreaMDL  := MDL->( GetArea() )
Local cNrCupom  := "" 
Local cSerCupom := "" 

Default nLin    := 1 

cNrCupom  := Padr( Alltrim(aCupons[nLin][1]), TamSX3("MDL_CUPOM")[1])
cSerCupom := Padr( Alltrim(aCupons[nLin][2]), TamSX3("MDL_SERCUP")[1])

MDL->( DbSetOrder(2) ) ////MDL_FILIAL+MDL_CUPOM+MDL_SERCUP+MDL_NFCUP+MDL_SERIE

If MDL->( DbSeek( xFilial("MDL") + cNrCupom + cSerCupom ) ) 
	cNumNota := MDL->MDL_NFCUP  
	cSerieNf := MDL->MDL_SERIE
Else                                                              
	//Conout(" #### TRETE036 --> NÃO FOI ENCONTRADO A NOTA DO CUPOM: "+cNrCupom+"/"+cSerCupom+" DATA: "+DTOC(dDataBase)+" HORA:"+Time()+" ")
EndIf 

RestArea(aAreaMDL)
		 
Return({cNumNota,cSerieNf})	
