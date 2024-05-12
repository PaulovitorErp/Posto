#include "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} TRETE019
Geração NF-e de acobertamento
@author Maiki Perin
@since 14/03/2019
@version P11
@param cFatura
@return nulo                                                                                  

/*/

/****************************************************************************************************************/
User Function TRETE019(cFil,cPref,cTit,cParc,cTp,cCli,cLojaCli,lPdv,lMostraMsg,aCupsNf,lFatAut,cMsgAdic,cTpGerNf)
/****************************************************************************************************************/ 

	Local aArea			:= GetArea()
	Local lRet			:= .T.
	Local cQry 			:= ""  
	Local nI, nJ 

	Local nCont2		:= 0
	Local cTpFat		:= "" 
	Local lContinua            

	Local nPosAux		:= 0
	Local aCupons 		:= {} //Array com os cupons para geracao da NF 
	Local aRetorno		:= {}
	Local lNota 		:= .T. //Informa se é geração ou estorno da NF
	Local cBkpFil		:= cFilAnt

	Default lPdv		:= .F.                                           
	Default lMostraMsg	:= .T.
	Default aCupsNf     := {}                                                               
	Default lFatAut		:= .F.  
	Default cMsgAdic	:= ""  
	Default cTpGerNf 	:= ""

	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.

	Private lNfAcobert	:= SuperGetMv("MV_XNFACOB",.F.,.F.)

	If cPref == "FAT" //Fatura

		If Select("QRYCF") > 0
			QRYCF->(dbCloseArea())
		Endif                                              
		
		cQry := "SELECT DISTINCT SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA"
		cQry += " FROM "+RetSqlName("SF2")+" SF2 	INNER JOIN "+RetSqlName("SE1")+" SE1	ON SE1.E1_NUM		= SF2.F2_DOC"
		cQry += " 																			AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
		cQry += " 																			AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
		cQry += " 																			AND SE1.E1_LOJA		= SF2.F2_LOJA"
		cQry += " 																			AND SE1.D_E_L_E_T_	= ' '"
		cQry += " 																			AND SE1.E1_FILORIG 	= SF2.F2_FILIAL"      
		cQry += " 									INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
		cQry += " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
		cQry += " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
		cQry += " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
		cQry += " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
		cQry += " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
		cQry += " 																			AND FI7.FI7_PRFDES	= '"+cPref+"'"
		cQry += " 																			AND FI7.FI7_NUMDES	= '"+cTit+"'"
		cQry += " 																			AND FI7.FI7_PARDES	= '"+cParc+"'"
		cQry += " 																			AND FI7.FI7_TIPDES	= '"+cTp+"'"
		cQry += " 																			AND FI7.FI7_CLIDES	= '"+cCli+"'"
		cQry += " 																			AND FI7.FI7_LOJDES	= '"+cLojaCli+"'"
		cQry += " 																			AND FI7.D_E_L_E_T_	= ' '"
		cQry += " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7", cFil)+"'"
		cQry += " WHERE SF2.D_E_L_E_T_	 = ' '"
		
		//If cFil == Nil
		//	cQry += " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"      
		//Else
		//	cQry += " AND SF2.F2_FILIAL 	= '"+cFil+"'"      
		//Endif
		If lNfAcobert
			cQry += " AND SF2.F2_ESPECIE 	= 'NFCE'" //NFC-e
		Else
			cQry += " AND SF2.F2_ESPECIE	= 'CF'" //Cupom Fiscal
		Endif
		cQry += " AND SF2.F2_NFCUPOM	= '"+Space(TamSX3("F2_NFCUPOM")[1])+"'" //Não haja NF s/ CF
		cQry += " ORDER BY 1, 3, 2"
		
		cQry := ChangeQuery(cQry) 
		//MemoWrite("c:\temp\GeraNfe.txt",cQry)
		TcQuery cQry NEW Alias "QRYCF"
		
		While QRYCF->(!EOF()) 
		
			If !IsBlind()
				IncProc()   
			Endif

			if (nPosAux := aScan(aCupons, {|x| x[1] == QRYCF->F2_FILIAL }) ) == 0
				aadd(aCupons, {QRYCF->F2_FILIAL, {}/*aNFCs*/ } )
				nPosAux := len(aCupons)
			endif
		
			AAdd(aCupons[nPosAux][2],  {QRYCF->F2_DOC,;
										QRYCF->F2_SERIE,;
										QRYCF->F2_CLIENTE,;
										QRYCF->F2_LOJA})

			QRYCF->(DbSkip())
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
					If Empty(SF2->F2_NFCUPOM) .And. AllTrim(SF2->F2_ESPECIE)+"/" $ 'CF/NFCE/' //Não haja NF s/ CF e Cupom Fiscal
						AAdd(aCupons,{SF2->F2_FILIAL, {{cTit,;
									cPref,;
									cCli,;
									cLojaCli}}})
					Endif
				Endif
			Else
				aCupons := aClone(aCupsNf)
			Endif

		ElseIf Len(aCupsNf) == 0 

			AAdd(aCupons,{cFil, {{cTit,;
						cPref,;
						cCli,;
						cLojaCli}}})
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

							For nI := 1 to len(aCupons)

								SetMvValue("LJR131", "MV_PAR10", "")
								SetMvValue("LJR131", "MV_PAR11", "")
								MV_PAR10 := ""
								MV_PAR11 := ""

								lMsErroAuto := .F.
								cFilAnt := aCupons[nI][1]
							
								//Chama a rotina de nota sobre cupom
								LojR130(aCupons[nI][2],lNota,aCupons[nI][2][1][3],aCupons[nI][2][1][4])
			
								If lMsErroAuto 
									//MostraErro()
								EndIf
								
								aRetorno := RetNfCupom(aCupons[nI][2],1)   //Retorna o numero e serie da Nota Gerada
								
								SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
								
								If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
			
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
										//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[nI][2][1][1]+"/"+aCupons[nI][2][1][2]+" ")
									Else
										//Conout("Nota de acobertamento não encontrada! Verifique o cupom: "+aCupons[nI][2][1][1]+"/"+aCupons[nI][2][1][2]+" ")
									Endif
								EndIf
								
							Next nX
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
							cFilAnt := aCupons[nI][1]

							SetMvValue("LJR131", "MV_PAR10", "")
							SetMvValue("LJR131", "MV_PAR11", "")
							MV_PAR10 := ""
							MV_PAR11 := ""

							For nJ := 1 to Len(aCupons[nI][2])
							
								//Chama a rotina de nota sobre cupom
								LojR130({aCupons[nI][2][nJ]},lNota,aCupons[nI][2][nJ][3],aCupons[nI][2][nJ][4])
			
								If lMsErroAuto
									//MostraErro()
								EndIf
								
								aRetorno := RetNfCupom(aCupons[nI][2],nJ)   //Retorna o numero da Nota Gerado
								
								SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
								
								If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
			
									If IsBlind()
										If !lNfAcobert
											//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!")
										Else
											//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!")
										Endif
									Else
										If lMostraMsg
											If !lNfAcobert
												MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!","Atenção")
											Else
												MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!","Atenção")
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
										//Conout("Nota s/ cupom não encontrada! Verifique o cupom: "+aCupons[nI][2][nJ][1]+"/"+aCupons[nI][2][nJ][2]+" ")
									Else
										//Conout("Nota de acobertamento não encontrada! Verifique o cupom: "+aCupons[nI][2][nJ][1]+"/"+aCupons[nI][2][nJ][2]+" ")
									Endif
								EndIf
							Next nJ

						Next nI
						
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

				If Len(aCupons) > 0

					For nI := 1 To Len(aCupons)   

						SetMvValue("LJR131", "MV_PAR10", "")
						SetMvValue("LJR131", "MV_PAR11", "")
						MV_PAR10 := ""
						MV_PAR11 := ""

						lMsErroAuto := .F.
						cFilAnt := aCupons[nI][1] 

						//Chama a rotina de nota sobre cupom
						LojR130(aCupons[nI][2],lNota,aCupons[nI][2][1][3],aCupons[nI][2][1][4])

						If lMsErroAuto
							If !IsBlind()
								MostraErro()
							EndIf
						EndIf
						
						aRetorno := RetNfCupom(aCupons[nI][2],1)   //Retorna o numero e serie da Nota Gerada
						
						SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
						If !Empty(aRetorno[1]) .and. SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )

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
							//Conout("Nota Fiscal não encontrada! Verifique o cupom: "+aCupons[nI][2][1][1]+"/"+aCupons[nI][2][1][2]+" ")
							lRet := .F.
						EndIf

					next nI

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
		Else
			cTpFat := cTpGerNf
			
			If Empty(cTpFat) .Or. cTpFat == "S" //Aglutinada
			
				If Len(aCupons) > 0

					For nI := 1 To Len(aCupons)   

						SetMvValue("LJR131", "MV_PAR10", "")
						SetMvValue("LJR131", "MV_PAR11", "")
						MV_PAR10 := ""
						MV_PAR11 := ""

						lMsErroAuto := .F.
						cFilAnt := aCupons[nI][1] 

						//Chama a rotina de nota sobre cupom
						LojR130(aCupons[nI][2],lNota,aCupons[nI][2][1][3],aCupons[nI][2][1][4])
				
						If lMsErroAuto
							If !IsBlind()
								MostraErro()
							EndIf
						EndIf
					
						aRetorno := RetNfCupom(aCupons[nI][2],1)   //Retorna o numero e serie da Nota Gerada
						
						SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
						
						If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
				
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
							//Conout("Nota fiscal não encontrada! Verifique o cupom: "+aCupons[nI][2][1][1]+"/"+aCupons[nI][2][1][2]+" ")
						EndIf

					next nI

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

					SetMvValue("LJR131", "MV_PAR10", "")
					SetMvValue("LJR131", "MV_PAR11", "")
					MV_PAR10 := ""
					MV_PAR11 := ""

					nCont2++                               
					lMsErroAuto := .F.
					cFilAnt := aCupons[nI][1] 

					For nJ := 1 to Len(aCupons[nI][2])
					
						//Chama a rotina de nota sobre cupom
						LojR130({aCupons[nI][2][nJ]},lNota,aCupons[nI][2][nJ][3],aCupons[nI][2][nJ][4])
				
						If lMsErroAuto
							If !IsBlind()
								MostraErro()
							EndIf
						EndIf
								
						aRetorno := RetNfCupom(aCupons[nI][2],nJ)   //Retorna o numero da Nota Gerado
						
						SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
						
						If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )
				
							If IsBlind()
								//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!")
							Else
								If lMostraMsg
									MsgInfo("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ NFC-e <"+AllTrim(aCupons[nI][2][nJ][1])+"> gerada com sucesso!!","Atenção")
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
							//Conout("Nota fiscal não encontrada! Verifique o cupom: "+aCupons[nI][2][nJ][1]+"/"+aCupons[nI][2][nJ][2]+" ")
						EndIf

					Next nJ

				Next nI
				
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
		EndIf		
	Else 
		For nI := 1 To Len(aCupons)

			SetMvValue("LJR131", "MV_PAR10", "")
			SetMvValue("LJR131", "MV_PAR11", "")
			MV_PAR10 := ""
			MV_PAR11 := ""

			//Chama a rotina de nota sobre cupom
			LojR130(aCupons[nI][2],lNota,cCli,cLojaCli)

			If lMsErroAuto
				If !IsBlind()
					MostraErro()
				EndIf
			EndIf

			aRetorno := RetNfCupom(aCupons[nI][2],1)   //Retorna o numero e serie da Nota Gerada
			
			SF2->( DbSetOrder(1) ) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			
			If SF2->( DbSeek( xFilial("SF2") + aRetorno[1] + aRetorno[2] ) )

				If IsBlind()
					//Conout("Nota Fiscal <"+AllTrim(SF2->F2_DOC)+"> s/ CF <"+AllTrim(aCupons[nI][2][1][1])+"> gerada com sucesso!!")
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
			
		next nI
	Endif    

	cFilAnt := cBkpFil
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
	//Conout(" #### GERANFE --> NÃO FOI ENCONTRADO A NOTA DO CUPOM: "+cNrCupom+"/"+cSerCupom+" DATA: "+DTOC(dDataBase)+" HORA:"+Time()+" ")
EndIf 

RestArea(aAreaMDL)
		 
Return({cNumNota,cSerieNf})	
